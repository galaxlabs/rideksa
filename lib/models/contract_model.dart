class ContractModel {
  final String id;
  final String ownerId;
  final String? companyId;
  final String title;
  final String counterpartyType;
  final String counterpartyName;
  final String routeSummary;
  final int expectedPassengers;
  final double contractValue;
  final double platformFee;
  final String repeatSchedule;
  final String serviceType;
  final String? routineCategory;
  final String? pickupTime;
  final String? dropoffTime;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  ContractModel({
    required this.id,
    required this.ownerId,
    this.companyId,
    required this.title,
    required this.counterpartyType,
    required this.counterpartyName,
    required this.routeSummary,
    required this.expectedPassengers,
    required this.contractValue,
    double? platformFee,
    required this.repeatSchedule,
    this.serviceType = 'contract_trip',
    this.routineCategory,
    this.pickupTime,
    this.dropoffTime,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    DateTime? createdAt,
  }) : platformFee = platformFee ?? contractValue * 0.05,
       createdAt = createdAt ?? DateTime.now();

  factory ContractModel.fromJson(Map<String, dynamic> json) => ContractModel(
    id: json['id'] as String? ?? '',
    ownerId: json['owner_id'] as String? ?? '',
    companyId: json['company_id'] as String?,
    title: json['title'] as String? ?? '',
    counterpartyType: json['counterparty_type'] as String? ?? 'company',
    counterpartyName: json['counterparty_name'] as String? ?? '',
    routeSummary: json['route_summary'] as String? ?? '',
    expectedPassengers: json['expected_passengers'] as int? ?? 1,
    contractValue: (json['contract_value'] as num?)?.toDouble() ?? 0,
    platformFee: (json['platform_fee'] as num?)?.toDouble(),
    repeatSchedule: json['repeat_schedule'] as String? ?? 'one_time',
    serviceType: json['service_type'] as String? ?? 'contract_trip',
    routineCategory: json['routine_category'] as String?,
    pickupTime: json['pickup_time'] as String?,
    dropoffTime: json['dropoff_time'] as String?,
    startDate: (json['start_date'] as dynamic)?.toDate() ?? DateTime.now(),
    endDate: (json['end_date'] as dynamic)?.toDate(),
    isActive: json['is_active'] as bool? ?? true,
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'company_id': companyId,
    'title': title,
    'counterparty_type': counterpartyType,
    'counterparty_name': counterpartyName,
    'route_summary': routeSummary,
    'expected_passengers': expectedPassengers,
    'contract_value': contractValue,
    'platform_fee': platformFee,
    'repeat_schedule': repeatSchedule,
    'service_type': serviceType,
    'routine_category': routineCategory,
    'pickup_time': pickupTime,
    'dropoff_time': dropoffTime,
    'start_date': startDate,
    'end_date': endDate,
    'is_active': isActive,
    'created_at': createdAt,
  };
}
