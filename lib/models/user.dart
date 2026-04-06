class User {
  final int id;
  final String email;
  final String? businessName;
  final String? displayName;
  final String role;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  const User({
    required this.id,
    required this.email,
    this.businessName,
    this.displayName,
    this.role = 'cashier',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  String get name => displayName ?? businessName ?? email;

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isCashier => role == 'cashier';

  factory User.fromJson(Map<String, dynamic> json) {
    final isActiveRaw = json['isActive'] ?? json['is_active'];
    final isActive = isActiveRaw == null ? true : (isActiveRaw == 1 || isActiveRaw == true);
    final roleRaw = json['role'] as String?;
    final role = (roleRaw ?? 'cashier').toLowerCase().trim();
    final roleValid = role == 'admin' || role == 'manager' || role == 'cashier' ? role : 'cashier';

    return User(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      businessName: (json['businessName'] ?? json['business_name']) as String?,
      displayName: (json['displayName'] ?? json['display_name']) as String?,
      role: roleValid,
      isActive: isActive,
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString() ?? '',
      updatedAt: (json['updatedAt'] ?? json['updated_at'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'businessName': businessName,
    'displayName': displayName,
    'role': role,
    'isActive': isActive,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
