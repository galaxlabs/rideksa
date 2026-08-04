enum SubscriptionPlan { basic, professional, enterprise }
enum SubscriptionStatus { active, expired, cancelled }

class SubscriptionModel {
  final String id;
  final String companyId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final String? currency;
  final int maxDrivers;
  final int maxVehicles;
  final bool hasReports;
  final bool hasApi;
  final bool hasWhiteLabel;
  final DateTime? cancelledAt;
  final DateTime createdAt;

  SubscriptionModel({
    required this.id,
    required this.companyId,
    required this.plan,
    this.status = SubscriptionStatus.active,
    required this.startDate,
    required this.endDate,
    required this.price,
    this.currency = 'SAR',
    this.maxDrivers = 5,
    this.maxVehicles = 5,
    this.hasReports = false,
    this.hasApi = false,
    this.hasWhiteLabel = false,
    this.cancelledAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(endDate);
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  static Map<SubscriptionPlan, SubscriptionPlanInfo> get plans => {
    SubscriptionPlan.basic: SubscriptionPlanInfo(
      name: 'Basic', price: 299, maxDrivers: 5, maxVehicles: 5,
      hasReports: false, hasApi: false, hasWhiteLabel: false,
    ),
    SubscriptionPlan.professional: SubscriptionPlanInfo(
      name: 'Professional', price: 799, maxDrivers: 20, maxVehicles: 20,
      hasReports: true, hasApi: true, hasWhiteLabel: false,
    ),
    SubscriptionPlan.enterprise: SubscriptionPlanInfo(
      name: 'Enterprise', price: 1999, maxDrivers: 100, maxVehicles: 100,
      hasReports: true, hasApi: true, hasWhiteLabel: true,
    ),
  };

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) => SubscriptionModel(
    id: json['id'] as String? ?? '',
    companyId: json['company_id'] as String? ?? '',
    plan: SubscriptionPlan.values.firstWhere(
      (p) => p.name == (json['plan'] as String? ?? ''),
      orElse: () => SubscriptionPlan.basic,
    ),
    status: SubscriptionStatus.values.firstWhere(
      (s) => s.name == (json['status'] as String? ?? ''),
      orElse: () => SubscriptionStatus.active,
    ),
    startDate: (json['start_date'] as dynamic)?.toDate() ?? DateTime.now(),
    endDate: (json['end_date'] as dynamic)?.toDate() ?? DateTime.now(),
    price: (json['price'] as num?)?.toDouble() ?? 0,
    currency: json['currency'] as String? ?? 'SAR',
    maxDrivers: json['max_drivers'] as int? ?? 5,
    maxVehicles: json['max_vehicles'] as int? ?? 5,
    hasReports: json['has_reports'] as bool? ?? false,
    hasApi: json['has_api'] as bool? ?? false,
    hasWhiteLabel: json['has_white_label'] as bool? ?? false,
    cancelledAt: (json['cancelled_at'] as dynamic)?.toDate(),
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'plan': plan.name,
    'status': status.name,
    'start_date': startDate,
    'end_date': endDate,
    'price': price,
    'currency': currency,
    'max_drivers': maxDrivers,
    'max_vehicles': maxVehicles,
    'has_reports': hasReports,
    'has_api': hasApi,
    'has_white_label': hasWhiteLabel,
    'cancelled_at': cancelledAt,
    'created_at': createdAt,
  };
}

class SubscriptionPlanInfo {
  final String name;
  final double price;
  final int maxDrivers;
  final int maxVehicles;
  final bool hasReports;
  final bool hasApi;
  final bool hasWhiteLabel;

  const SubscriptionPlanInfo({
    required this.name,
    required this.price,
    required this.maxDrivers,
    required this.maxVehicles,
    required this.hasReports,
    required this.hasApi,
    required this.hasWhiteLabel,
  });
}
