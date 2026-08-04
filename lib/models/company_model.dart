class CompanyModel {
  final String id;
  final String name;
  final String? nameArabic;
  final String? registrationNo;
  final String? taxId;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? address;
  final String? city;
  final String? country;
  final String? subscriptionPlan;
  final DateTime? subscriptionExpiry;
  final bool isActive;
  final double commissionRate;
  final String? businessType;
  final String? contactPerson;
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.name,
    this.nameArabic,
    this.registrationNo,
    this.taxId,
    this.phone,
    this.email,
    this.logoUrl,
    this.address,
    this.city,
    this.country,
    this.subscriptionPlan,
    this.subscriptionExpiry,
    this.isActive = true,
    this.commissionRate = 0.05,
    this.businessType,
    this.contactPerson,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CompanyModel.fromJson(Map<String, dynamic> json) => CompanyModel(
    id: json['id'] as String? ?? json['name'] as String? ?? '',
    name: json['company_name'] as String? ?? json['name'] as String? ?? '',
    nameArabic: json['company_name_arabic'] as String?,
    registrationNo: json['company_registration'] as String?,
    taxId: json['tax_id'] as String?,
    phone: json['phone_no'] as String? ?? json['phone'] as String?,
    email: json['email'] as String?,
    logoUrl: json['company_logo'] as String? ?? json['logo'] as String?,
    address: json['address'] as String?,
    city: json['city'] as String?,
    country: json['country'] as String?,
    subscriptionPlan: json['subscription_plan'] as String?,
    subscriptionExpiry: (json['subscription_expiry'] as dynamic)?.toDate(),
    isActive: json['is_active'] as bool? ?? true,
    commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.05,
    businessType: json['business_type'] as String?,
    contactPerson: json['contact_person'] as String?,
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_name': name,
    'company_name_arabic': nameArabic,
    'company_registration': registrationNo,
    'tax_id': taxId,
    'phone_no': phone,
    'email': email,
    'company_logo': logoUrl,
    'address': address,
    'city': city,
    'country': country,
    'subscription_plan': subscriptionPlan,
    'subscription_expiry': subscriptionExpiry,
    'is_active': isActive,
    'commission_rate': commissionRate,
    'business_type': businessType,
    'contact_person': contactPerson,
    'created_at': createdAt,
  };
}
