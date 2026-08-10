import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../utils/supabase_config.dart';

class ProductProvider extends ChangeNotifier {
  final List<ProductModel> _allProducts = [];
  final Set<String>  _wishlistIds = {};
  bool _isLoading = false;
  String _searchQuery = '';
  ProductCategory? _selectedCategory;
  RealtimeChannel? _productsChannel;

  static const _productsKey = 'all_products';
  static const _wishlistKey = 'wishlist_ids';

  SupabaseClient get _sb => Supabase.instance.client;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ProductCategory? get selectedCategory => _selectedCategory;

  List<ProductModel> get allProducts {
    // Deduplicate by ID (safety check)
    final seen = <String>{};
    final unique = <ProductModel>[];
    for (final p in _allProducts) {
      if (seen.add(p.id)) unique.add(p);
    }
    return List.unmodifiable(unique);
  }

  List<ProductModel> get filteredProducts {
    // Deduplicate by ID first
    final seen = <String>{};
    final unique = <ProductModel>[];
    for (final p in _allProducts) {
      if (seen.add(p.id)) unique.add(p);
    }
    
    return unique.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.sellerName.toLowerCase().contains(q);
      final matchCat =
          _selectedCategory == null || p.category == _selectedCategory;
      return matchSearch && matchCat && p.status == ProductStatus.available;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<ProductModel> get wishlistProducts {
    // Deduplicate by ID
    final seen = <String>{};
    final unique = <ProductModel>[];
    for (final p in _allProducts) {
      if (_wishlistIds.contains(p.id) && seen.add(p.id)) {
        unique.add(p);
      }
    }
    return unique;
  }

  List<ProductModel> productsForSeller(String sellerId) {
    // Deduplicate by ID (safety check)
    final seen = <String>{};
    final unique = <ProductModel>[];
    for (final p in _allProducts) {
      if (p.sellerId == sellerId && seen.add(p.id)) {
        unique.add(p);
      }
    }
    return unique..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  bool isWishlisted(String id) => _wishlistIds.contains(id);

  ProductModel? getProductById(String id) {
    try { return _allProducts.firstWhere((p) => p.id == id); }
    catch (_) { return null; }
  }

  // ── Public init ─────────────────────────────────────────────────────────────
  // Guard against multiple calls — only reload if list is empty or forced
  bool _loaded = false;

  Future<void> loadData(String userId, {bool force = false}) async {
    // Don't reload unless forced or first time
    if (_loaded && !force) return;

    _isLoading = true;
    notifyListeners();

    // Unsubscribe old channel before reloading (prevent duplicate subscriptions)
    _productsChannel?.unsubscribe();
    _productsChannel = null;

    if (SupabaseConfig.isConfigured) {
      await Future.wait([
        _fetchFromSupabase(),
        _fetchWishlistSupabase(userId),
      ]);
      _subscribeRealtime();
    } else {
      await _loadLocalData();
      await _loadLocalWishlist(userId);
    }

    // Deduplicate _allProducts by ID (final cleanup)
    _deduplicateProducts();

    _loaded = true;
    _isLoading = false;
    notifyListeners();
  }

  /// Remove duplicate products by ID from the internal list
  void _deduplicateProducts() {
    final seen = <String>{};
    final unique = <ProductModel>[];
    for (final p in _allProducts) {
      if (seen.add(p.id)) unique.add(p);
    }
    if (unique.length != _allProducts.length) {
      _allProducts.clear();
      _allProducts.addAll(unique);
    }
  }

  Future<void> refresh(String userId) => loadData(userId, force: true);

  // ══════════════════════════════════════════════════════════════════════════
  //  SUPABASE PATH
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _fetchFromSupabase() async {
    try {
      final rows = await _sb
          .from(SupabaseConfig.productsTable)
          .select()
          .order('created_at', ascending: false);
      _allProducts.clear();
      for (final row in rows as List) {
        final p = ProductModel.fromSupabase(row as Map<String, dynamic>);
        p.isWishlisted = _wishlistIds.contains(p.id);
        _allProducts.add(p);
      }
    } catch (_) {}
  }

  Future<void> _fetchWishlistSupabase(String userId) async {
    try {
      final rows = await _sb
          .from(SupabaseConfig.wishlistsTable)
          .select('product_id')
          .eq('user_id', userId);
      _wishlistIds.clear();
      for (final row in rows as List) {
        _wishlistIds.add(row['product_id'] as String);
      }
    } catch (_) {}
  }

  void _subscribeRealtime() {
    _productsChannel?.unsubscribe();
    _productsChannel = _sb
        .channel('public:products')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.productsTable,
          callback: (payload) {
            final p = ProductModel.fromSupabase(payload.newRecord);
            p.isWishlisted = _wishlistIds.contains(p.id);
            if (!_allProducts.any((x) => x.id == p.id)) {
              _allProducts.insert(0, p);
              notifyListeners();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConfig.productsTable,
          callback: (payload) {
            final updated = ProductModel.fromSupabase(payload.newRecord);
            updated.isWishlisted = _wishlistIds.contains(updated.id);
            final idx = _allProducts.indexWhere((p) => p.id == updated.id);
            if (idx != -1) { _allProducts[idx] = updated; notifyListeners(); }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: SupabaseConfig.productsTable,
          callback: (payload) {
            final id = payload.oldRecord['id'] as String?;
            if (id != null) {
              _allProducts.removeWhere((p) => p.id == id);
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOCAL FALLBACK PATH
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ── One-time migration: wipe old demo data if schema version changed ──
      const int schemaVersion = 3;  // Bumped to 3 to force clean slate
      final storedVersion = prefs.getInt('products_schema_version') ?? 0;
      if (storedVersion < schemaVersion) {
        await prefs.remove(_productsKey);
        await prefs.setInt('products_schema_version', schemaVersion);
      }

      final json = prefs.getString(_productsKey);
      if (json != null) {
        final List decoded = jsonDecode(json);
        _allProducts.clear();
        _allProducts.addAll(
            decoded.map((e) => ProductModel.fromMap(e as Map<String, dynamic>)));
      } else {
        _allProducts.clear();
        _seedDemo();
      }
    } catch (_) {
      _allProducts.clear();
      _seedDemo();
    }
  }

  Future<void> _loadLocalWishlist(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('${_wishlistKey}_$userId');
      _wishlistIds.clear();
      if (list != null) _wishlistIds.addAll(list);
    } catch (_) {}
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _productsKey,
        jsonEncode(_allProducts.map((p) => p.toMap()).toList()));
  }

  Future<void> _saveLocalWishlist(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        '${_wishlistKey}_$userId', _wishlistIds.toList());
  }

  void _seedDemo() {
    // Use fixed UUIDs for demo products to prevent duplicates on re-seed
    _allProducts.addAll([
      ProductModel(
        id: 'demo-calc-001', title: 'Scientific Calculator',
        description: 'Casio FX-991EX, barely used. Perfect for engineering students.',
        category: ProductCategory.electronics, price: 450,
        imageUrls: ['https://images.unsplash.com/photo-1611457194403-d3f142eb9d74?w=600&q=80'],
        sellerId: 'demo1', sellerName: 'Rahul Sharma',
        sellerHostel: 'Block A Hostel', sellerPhone: '9876543210',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ProductModel(
        id: 'demo-book-001', title: 'Engineering Mathematics Book',
        description: 'RD Sharma Vol 1 & 2. Good condition, all pages intact.',
        category: ProductCategory.books, price: 200,
        imageUrls: ['https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=600&q=80'],
        sellerId: 'demo2', sellerName: 'Priya Singh',
        sellerHostel: 'Girls Hostel C', sellerPhone: '9876543211',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ProductModel(
        id: 'demo-fan-001', title: 'Table Fan',
        description: 'Usha table fan, 3 speed settings. Works perfectly.',
        category: ProductCategory.electronics, price: 600,
        imageUrls: ['https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=600&q=80'],
        sellerId: 'demo3', sellerName: 'Amit Kumar',
        sellerHostel: 'Block B Hostel', sellerPhone: '9876543212',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ProductModel(
        id: 'demo-chair-001', title: 'Study Chair',
        description: 'Comfortable study chair with armrests. Slightly used.',
        category: ProductCategory.furniture, price: 800,
        imageUrls: ['https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=600&q=80'],
        sellerId: 'demo1', sellerName: 'Rahul Sharma',
        sellerHostel: 'Block A Hostel', sellerPhone: '9876543210',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ProductModel(
        id: 'demo-bat-001', title: 'Cricket Bat',
        description: 'SS Ton cricket bat, 1 season used.',
        category: ProductCategory.sports, price: 350,
        imageUrls: ['https://images.unsplash.com/photo-1624526267940-ab832fd6428c?w=600&q=80'],
        sellerId: 'demo2', sellerName: 'Priya Singh',
        sellerHostel: 'Girls Hostel C', sellerPhone: '9876543211',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ProductModel(
        id: 'demo-jacket-001', title: 'Winter Jacket',
        description: 'Navy blue jacket size M. Excellent condition.',
        category: ProductCategory.clothing, price: 500,
        imageUrls: ['https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&q=80'],
        sellerId: 'demo3', sellerName: 'Amit Kumar',
        sellerHostel: 'Block B Hostel', sellerPhone: '9876543212',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ]);
    _saveLocalData();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SHARED PUBLIC OPERATIONS  (routes to Supabase or local)
  // ══════════════════════════════════════════════════════════════════════════

  Future<ProductModel?> addProduct({
    required String title, required String description,
    required ProductCategory category, required double price,
    required List<String> imageUrls,
    required String sellerId, required String sellerName,
    required String sellerHostel, required String sellerPhone,
  }) async {
    _isLoading = true;
    notifyListeners();

    ProductModel? product;

    if (SupabaseConfig.isConfigured) {
      try {
        // For now, use local paths directly since storage bucket isn't configured
        // Images will be stored locally on the device
        final finalImageUrls = imageUrls; // Use local paths
        
        final row = await _sb
            .from(SupabaseConfig.productsTable)
            .insert({
              'title': title, 'description': description,
              'category': category.name, 'price': price,
              'image_urls': finalImageUrls,
              'seller_id': sellerId, 'seller_name': sellerName,
              'seller_hostel': sellerHostel, 'seller_phone': sellerPhone,
              'status': 'available',
            })
            .select()
            .single();
        product = ProductModel.fromSupabase((row as Map).cast<String, dynamic>());
        if (!_allProducts.any((p) => p.id == product!.id)) {
          _allProducts.insert(0, product);
        }
      } catch (e) {
        debugPrint('Error adding product to Supabase: $e');
        // Fall back to local storage if Supabase fails
        product = ProductModel(
          id: const Uuid().v4(), title: title, description: description,
          category: category, price: price, imageUrls: imageUrls,
          sellerId: sellerId, sellerName: sellerName,
          sellerHostel: sellerHostel, sellerPhone: sellerPhone,
          createdAt: DateTime.now(),
        );
        if (!_allProducts.any((p) => p.id == product!.id)) {
          _allProducts.insert(0, product);
        }
        await _saveLocalData();
      }
    } else {
      product = ProductModel(
        id: const Uuid().v4(), title: title, description: description,
        category: category, price: price, imageUrls: imageUrls,
        sellerId: sellerId, sellerName: sellerName,
        sellerHostel: sellerHostel, sellerPhone: sellerPhone,
        createdAt: DateTime.now(),
      );
      // Only insert if not already in list
      if (!_allProducts.any((p) => p.id == product!.id)) {
        _allProducts.insert(0, product);
      }
      await _saveLocalData();
    }

    _isLoading = false;
    notifyListeners();
    return product;
  }

  Future<void> markAsSold(String productId) async {
    if (SupabaseConfig.isConfigured) {
      try {
        await _sb.from(SupabaseConfig.productsTable)
            .update({'status': 'sold'}).eq('id', productId);
      } catch (_) {}
    }
    final idx = _allProducts.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _allProducts[idx] = _allProducts[idx].copyWith(status: ProductStatus.sold);
      if (!SupabaseConfig.isConfigured) await _saveLocalData();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (SupabaseConfig.isConfigured) {
      try {
        await _sb.from(SupabaseConfig.productsTable)
            .delete().eq('id', productId);
      } catch (_) {}
    }
    _allProducts.removeWhere((p) => p.id == productId);
    _wishlistIds.remove(productId);
    if (!SupabaseConfig.isConfigured) await _saveLocalData();
    notifyListeners();
  }

  Future<void> toggleWishlist(String productId, String userId) async {
    final wasWishlisted = _wishlistIds.contains(productId);
    if (wasWishlisted) { _wishlistIds.remove(productId); }
    else { _wishlistIds.add(productId); }
    _syncFlag(productId);
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      try {
        if (wasWishlisted) {
          await _sb.from(SupabaseConfig.wishlistsTable)
              .delete().eq('user_id', userId).eq('product_id', productId);
        } else {
          await _sb.from(SupabaseConfig.wishlistsTable)
              .insert({'user_id': userId, 'product_id': productId});
        }
      } catch (_) {
        // Revert on failure
        if (wasWishlisted) { _wishlistIds.add(productId); }
        else { _wishlistIds.remove(productId); }
        _syncFlag(productId);
        notifyListeners();
      }
    } else {
      await _saveLocalWishlist(userId);
    }
  }

  void _syncFlag(String productId) {
    final idx = _allProducts.indexWhere((p) => p.id == productId);
    if (idx != -1) _allProducts[idx].isWishlisted = _wishlistIds.contains(productId);
  }

  void setSearchQuery(String q) { _searchQuery = q; notifyListeners(); }
  void setCategory(ProductCategory? c) { _selectedCategory = c; notifyListeners(); }
  void clearFilters() { _searchQuery = ''; _selectedCategory = null; notifyListeners(); }

  /// Call on logout so next login gets a fresh load
  void reset() {
    _allProducts.clear();
    _wishlistIds.clear();
    _loaded = false;
    _productsChannel?.unsubscribe();
    _productsChannel = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _productsChannel?.unsubscribe();
    super.dispose();
  }
}
