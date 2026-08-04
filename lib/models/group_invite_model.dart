class GroupInviteModel {
  final String id;
  final String rideRequestId;
  final String createdBy;
  final DateTime expiresAt;
  final DateTime createdAt;

  GroupInviteModel({
    required this.id,
    required this.rideRequestId,
    required this.createdBy,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) : expiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 24)),
       createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory GroupInviteModel.fromJson(Map<String, dynamic> json) => GroupInviteModel(
    id: json['id'] as String? ?? '',
    rideRequestId: json['ride_request_id'] as String? ?? '',
    createdBy: json['created_by'] as String? ?? '',
    expiresAt: (json['expires_at'] as dynamic)?.toDate(),
    createdAt: (json['created_at'] as dynamic)?.toDate(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ride_request_id': rideRequestId,
    'created_by': createdBy,
    'expires_at': expiresAt,
    'created_at': createdAt,
  };
}

class GroupMemberModel {
  final String id;
  final String rideRequestId;
  final String fullName;
  final String mobileNo;
  final String nationality;
  final String documentType;
  final String documentNo;
  final String status;
  final String? userId;
  final DateTime createdAt;

  GroupMemberModel({
    required this.id,
    required this.rideRequestId,
    required this.fullName,
    required this.mobileNo,
    required this.nationality,
    required this.documentType,
    required this.documentNo,
    this.status = 'pending',
    this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) => GroupMemberModel(
    id: json['id'] as String? ?? '',
    rideRequestId: json['ride_request_id'] as String? ?? '',
    fullName: json['full_name'] as String? ?? '',
    mobileNo: json['mobile_no'] as String? ?? '',
    nationality: json['nationality'] as String? ?? '',
    documentType: json['document_type'] as String? ?? 'passport',
    documentNo: json['document_no'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    userId: json['user_id'] as String?,
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ride_request_id': rideRequestId,
    'full_name': fullName,
    'mobile_no': mobileNo,
    'nationality': nationality,
    'document_type': documentType,
    'document_no': documentNo,
    'status': status,
    'user_id': userId,
    'created_at': createdAt,
  };
}
