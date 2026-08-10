enum UserRole { buyer, seller }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String hostelName;
  final String roomNumber;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.hostelName,
    required this.roomNumber,
    this.avatarUrl,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? hostelName,
    String? roomNumber,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      hostelName: hostelName ?? this.hostelName,
      roomNumber: roomNumber ?? this.roomNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  /// Supabase INSERT/UPDATE payload (snake_case, no id/email — those live in auth)
  Map<String, dynamic> toSupabase() {
    return {
      'name':        name,
      'phone':       phone,
      'role':        role.name,
      'hostel_name': hostelName,
      'room_number': roomNumber,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }

  /// Build from Supabase profiles row + email from auth session
  factory UserModel.fromSupabase(Map<String, dynamic> row, {String email = ''}) {
    return UserModel(
      id:          row['id']          as String,
      name:        (row['name']        as String?) ?? '',
      email:       email,
      phone:       (row['phone']       as String?) ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == (row['role'] ?? 'buyer'),
        orElse: () => UserRole.buyer,
      ),
      hostelName:  (row['hostel_name'] as String?) ?? '',
      roomNumber:  (row['room_number'] as String?) ?? '',
      avatarUrl:   row['avatar_url']  as String?,
    );
  }

  // Legacy JSON helpers kept for SharedPreferences session cache
  Map<String, dynamic> toMap() => {
    'id':          id,
    'name':        name,
    'email':       email,
    'phone':       phone,
    'role':        role.name,
    'hostelName':  hostelName,
    'roomNumber':  roomNumber,
    'avatarUrl':   avatarUrl,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id:         (map['id']         as String?) ?? '',
      name:       (map['name']       as String?) ?? '',
      email:      (map['email']      as String?) ?? '',
      phone:      (map['phone']      as String?) ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.buyer,
      ),
      hostelName: (map['hostelName'] as String?) ?? '',
      roomNumber: (map['roomNumber'] as String?) ?? '',
      avatarUrl:  map['avatarUrl']   as String?,
    );
  }
}
