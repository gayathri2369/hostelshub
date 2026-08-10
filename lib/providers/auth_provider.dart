import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../utils/supabase_config.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Local fallback user store
  final List<UserModel> _localUsers = [];

  UserModel? get currentUser => _currentUser;
  bool get isLoading         => _isLoading;
  bool get isLoggedIn        => _currentUser != null;
  String? get errorMessage   => _errorMessage;

  static const _localUserKey    = 'current_user';
  static const _localUsersKey   = 'all_users';

  SupabaseClient get _sb => Supabase.instance.client;

  AuthProvider() { _init(); }

  // ── Init: restore session from Supabase OR SharedPreferences ─────────────
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      final session = _sb.auth.currentSession;
      if (session != null) {
        await _fetchSupabaseProfile(session.user.id, session.user.email ?? '');
      }
    } else {
      await _loadLocalSession();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SUPABASE PATH
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _fetchSupabaseProfile(String userId, String email) async {
    try {
      final row = await _sb
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('id', userId)
          .single();
      _currentUser = UserModel.fromSupabase(row, email: email);
    } catch (_) {
      _currentUser = null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOCAL FALLBACK PATH (SharedPreferences)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadLocalSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_localUsersKey);
      if (usersJson != null) {
        final List decoded = jsonDecode(usersJson);
        _localUsers
          ..clear()
          ..addAll(decoded.map((e) => UserModel.fromMap(e as Map<String, dynamic>)));
      }
      final userJson = prefs.getString(_localUserKey);
      if (userJson != null) {
        _currentUser = UserModel.fromMap(
            jsonDecode(userJson) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _saveLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _localUsersKey,
        jsonEncode(_localUsers.map((u) => u.toMap()).toList()));
    if (_currentUser != null) {
      await prefs.setString(_localUserKey, jsonEncode(_currentUser!.toMap()));
    } else {
      await prefs.remove(_localUserKey);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PUBLIC API  (auto-routes to Supabase or local)
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    required String hostelName,
    required String roomNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      return _registerSupabase(
        name: name, email: email, phone: phone, password: password,
        role: role, hostelName: hostelName, roomNumber: roomNumber,
      );
    } else {
      return _registerLocal(
        name: name, email: email, phone: phone, password: password,
        role: role, hostelName: hostelName, roomNumber: roomNumber,
      );
    }
  }

  Future<bool> _registerSupabase({
    required String name, required String email, required String phone,
    required String password, required UserRole role,
    required String hostelName, required String roomNumber,
  }) async {
    try {
      final response = await _sb.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name, 'phone': phone, 'role': role.name,
          'hostel_name': hostelName, 'room_number': roomNumber,
        },
      );
      if (response.user == null) {
        _errorMessage = 'Registration failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 800));
      await _fetchSupabaseProfile(response.user!.id, email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Network error. Check your connection.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> _registerLocal({
    required String name, required String email, required String phone,
    required String password, required UserRole role,
    required String hostelName, required String roomNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_localUsers.any(
        (u) => u.email.toLowerCase() == email.toLowerCase())) {
      _errorMessage = 'An account with this email already exists.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    final user = UserModel(
      id: const Uuid().v4(),
      name: name, email: email, phone: phone,
      role: role, hostelName: hostelName, roomNumber: roomNumber,
    );
    _localUsers.add(user);
    _currentUser = user;
    await _saveLocalSession();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      return _loginSupabase(email: email, password: password);
    } else {
      return _loginLocal(email: email, password: password);
    }
  }

  Future<bool> _loginSupabase({
    required String email, required String password,
  }) async {
    try {
      final response = await _sb.auth.signInWithPassword(
          email: email, password: password);
      if (response.user == null) {
        _errorMessage = 'Invalid email or password.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await _fetchSupabaseProfile(response.user!.id, email);
      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Network error. Check your connection.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> _loginLocal({
    required String email, required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final user = _localUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => UserModel(
          id: '', name: '', email: '', phone: '',
          role: UserRole.buyer, hostelName: '', roomNumber: ''),
    );
    if (user.id.isEmpty) {
      _errorMessage = 'No account found with this email.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    _currentUser = user;
    await _saveLocalSession();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    if (SupabaseConfig.isConfigured) {
      await _sb.auth.signOut();
    }
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localUserKey);
    notifyListeners();
  }

  Future<void> updateProfile(UserModel updated) async {
    _isLoading = true;
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      try {
        await _sb
            .from(SupabaseConfig.profilesTable)
            .update({
              ...updated.toSupabase(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', updated.id);
      } catch (_) {}
    } else {
      final idx = _localUsers.indexWhere((u) => u.id == updated.id);
      if (idx != -1) _localUsers[idx] = updated;
    }

    _currentUser = updated;
    await _saveLocalSession();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> switchRole(UserRole role) async {
    if (_currentUser == null) return;
    await updateProfile(_currentUser!.copyWith(role: role));
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
