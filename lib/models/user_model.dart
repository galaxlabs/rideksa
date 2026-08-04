enum UserRole { passenger, driver, customerCompany, partnerCompany, admin, travelAgent, superAdmin }

class UserModel {
  final String uid;
  final String? phone;
  final String? email;
  final String? displayName;
  final UserRole role;
  final String? companyId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? frappeUserId;
  final String? fcmToken;
  final String? nationality;
  final String? documentType;
  final String? documentNo;
  final String? lastDeviceId;
  final String? lastDeviceLabel;
  final int loginCount;

  UserModel({
    required this.uid,
    this.phone,
    this.email,
    this.displayName,
    required this.role,
    this.companyId,
    this.isActive = true,
    DateTime? createdAt,
    this.lastLogin,
    this.frappeUserId,
    this.fcmToken,
    this.nationality,
    this.documentType,
    this.documentNo,
    this.lastDeviceId,
    this.lastDeviceLabel,
    this.loginCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] as String? ?? '',
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    displayName: json['display_name'] as String?,
    role: UserRole.values.firstWhere(
      (r) => r.name.toLowerCase() == (json['role'] as String? ?? '').toLowerCase(),
      orElse: () => UserRole.passenger,
    ),
    companyId: json['company_id'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
    lastLogin: (json['last_login'] as dynamic)?.toDate(),
    frappeUserId: json['frappe_user_id'] as String?,
    fcmToken: json['fcm_token'] as String?,
    nationality: json['nationality'] as String?,
    documentType: json['document_type'] as String?,
    documentNo: json['document_no'] as String?,
    lastDeviceId: json['last_device_id'] as String?,
    lastDeviceLabel: json['last_device_label'] as String?,
    loginCount: json['login_count'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'phone': phone,
    'email': email,
    'display_name': displayName,
    'role': role.name,
    'company_id': companyId,
    'is_active': isActive,
    'created_at': createdAt,
    'last_login': lastLogin,
    'frappe_user_id': frappeUserId,
    'fcm_token': fcmToken,
    'nationality': nationality,
    'document_type': documentType,
    'document_no': documentNo,
    'last_device_id': lastDeviceId,
    'last_device_label': lastDeviceLabel,
    'login_count': loginCount,
  };

  String get roleLabel {
    switch (role) {
      case UserRole.passenger: return 'Passenger';
      case UserRole.driver: return 'Driver';
      case UserRole.customerCompany: return 'Customer Company';
      case UserRole.partnerCompany: return 'Partner / Transport Company';
      case UserRole.admin: return 'Company Admin';
      case UserRole.travelAgent: return 'Travel Agent';
      case UserRole.superAdmin: return 'Super Admin';
    }
  }
}
