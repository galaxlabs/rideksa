class CommissionModel {
  final String id;
  final String tripId;
  final String companyId;
  final String? driverId;
  final double fare;
  final double commissionRate;
  final double commissionAmount;
  final double driverEarnings;
  final String? status;
  final DateTime createdAt;

  CommissionModel({
    required this.id,
    required this.tripId,
    required this.companyId,
    this.driverId,
    required this.fare,
    this.commissionRate = 0.05,
    required this.commissionAmount,
    required this.driverEarnings,
    this.status = 'completed',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static CommissionModel calculate({
    required String id,
    required String tripId,
    required String companyId,
    String? driverId,
    required double fare,
    double rate = 0.05,
  }) {
    final commissionAmount = fare * rate;
    final driverEarnings = fare - commissionAmount;
    return CommissionModel(
      id: id,
      tripId: tripId,
      companyId: companyId,
      driverId: driverId,
      fare: fare,
      commissionRate: rate,
      commissionAmount: commissionAmount,
      driverEarnings: driverEarnings,
    );
  }

  factory CommissionModel.fromJson(Map<String, dynamic> json) => CommissionModel(
    id: json['id'] as String? ?? '',
    tripId: json['trip_id'] as String? ?? '',
    companyId: json['company_id'] as String? ?? '',
    driverId: json['driver_id'] as String?,
    fare: (json['fare'] as num?)?.toDouble() ?? 0,
    commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.05,
    commissionAmount: (json['commission_amount'] as num?)?.toDouble() ?? 0,
    driverEarnings: (json['driver_earnings'] as num?)?.toDouble() ?? 0,
    status: json['status'] as String? ?? 'completed',
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'trip_id': tripId,
    'company_id': companyId,
    'driver_id': driverId,
    'fare': fare,
    'commission_rate': commissionRate,
    'commission_amount': commissionAmount,
    'driver_earnings': driverEarnings,
    'status': status,
    'created_at': createdAt,
  };
}
