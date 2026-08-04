enum RideStatus { draft, pending, offered, accepted, cancelled, expired }

class RideRequestModel {
  final String id;
  final String? passengerId;
  final String? passengerName;
  final String? passengerPhone;
  final String? routeId;
  final String pickupLocation;
  final String dropoffLocation;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final DateTime travelDate;
  final String? departureTime;
  final String vehicleType;
  final int passengersCount;
  final double offeredPrice;
  final double platformFee;
  final String bookingType;
  final String serviceType;
  final String? routineCategory;
  final String? contractDuration;
  final String? pickupTime;
  final String? dropoffTime;
  final int rentalDays;
  final String paymentStatus;
  final String paymentProvider;
  final String? groupName;
  final List<String> passengerNames;
  final List<Map<String, dynamic>> passengerRows;
  final String? contractId;
  final String marketVisibility;
  final String? targetCompanyId;
  final String? targetDriverId;
  final String? vehicleRequirement;
  final int seatsRequired;
  final bool hidePriceFromPassengers;
  final bool isFinalAmountLocked;
  final double? finalAmount;
  final String? acceptedOfferId;
  final bool chatEnabled;
  final double passengerRating;
  final double providerRating;
  final bool providerCompleted;
  final bool customerCompleted;
  final RideStatus status;
  final String? companyId;
  final String? assignedDriverId;
  final String? frappeBookingId;
  final String? notes;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool prepaid;
  final bool canCancelAfterCutoff;
  final DateTime? reminderStartAt;
  final DateTime? finalReminderStartAt;
  final int offerCount;

  RideRequestModel({
    required this.id,
    this.passengerId,
    this.passengerName,
    this.passengerPhone,
    this.routeId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    required this.travelDate,
    this.departureTime,
    this.vehicleType = 'Sedan',
    this.passengersCount = 1,
    required this.offeredPrice,
    double? platformFee,
    this.bookingType = 'single',
    this.serviceType = 'ride',
    this.routineCategory,
    this.contractDuration,
    this.pickupTime,
    this.dropoffTime,
    this.rentalDays = 1,
    this.paymentStatus = 'reserved',
    this.paymentProvider = 'test_wallet',
    this.groupName,
    this.passengerNames = const [],
    this.passengerRows = const [],
    this.contractId,
    this.marketVisibility = 'open_market',
    this.targetCompanyId,
    this.targetDriverId,
    this.vehicleRequirement,
    int? seatsRequired,
    this.hidePriceFromPassengers = false,
    this.isFinalAmountLocked = false,
    this.finalAmount,
    this.acceptedOfferId,
    this.chatEnabled = true,
    this.passengerRating = 5,
    this.providerRating = 5,
    this.providerCompleted = false,
    this.customerCompleted = false,
    this.status = RideStatus.pending,
    this.companyId,
    this.assignedDriverId,
    this.frappeBookingId,
    this.notes,
    DateTime? createdAt,
    this.expiresAt,
    this.prepaid = false,
    this.canCancelAfterCutoff = false,
    this.reminderStartAt,
    this.finalReminderStartAt,
    this.offerCount = 0,
  }) : seatsRequired = seatsRequired ?? passengersCount,
       platformFee = platformFee ?? offeredPrice * 0.05,
       createdAt = createdAt ?? DateTime.now();

  factory RideRequestModel.fromJson(Map<String, dynamic> json) => RideRequestModel(
    id: json['id'] as String? ?? '',
    passengerId: json['passenger_id'] as String?,
    passengerName: json['passenger_name'] as String?,
    passengerPhone: json['passenger_phone'] as String? ?? json['mobile_no'] as String?,
    routeId: json['route_id'] as String?,
    pickupLocation: json['pickup_location'] as String? ?? json['pickup_point'] as String? ?? '',
    dropoffLocation: json['dropoff_location'] as String? ?? json['drop_point'] as String? ?? '',
    pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
    pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
    dropoffLat: (json['dropoff_lat'] as num?)?.toDouble(),
    dropoffLng: (json['dropoff_lng'] as num?)?.toDouble(),
    travelDate: (json['travel_date'] as dynamic)?.toDate() ?? DateTime.now(),
    departureTime: json['departure_time'] as String?,
    vehicleType: json['vehicle_type'] as String? ?? 'Sedan',
    passengersCount: json['passengers_count'] as int? ?? 1,
    offeredPrice: (json['offered_price'] as num?)?.toDouble() ?? 0,
    platformFee: (json['platform_fee'] as num?)?.toDouble(),
    bookingType: json['booking_type'] as String? ?? 'single',
    serviceType: json['service_type'] as String? ?? 'ride',
    routineCategory: json['routine_category'] as String?,
    contractDuration: json['contract_duration'] as String?,
    pickupTime: json['pickup_time'] as String?,
    dropoffTime: json['dropoff_time'] as String?,
    rentalDays: json['rental_days'] as int? ?? 1,
    paymentStatus: json['payment_status'] as String? ?? 'reserved',
    paymentProvider: json['payment_provider'] as String? ?? 'test_wallet',
    groupName: json['group_name'] as String?,
    passengerNames: (json['passenger_names'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    passengerRows: (json['passenger_rows'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(),
    contractId: json['contract_id'] as String?,
    marketVisibility: json['market_visibility'] as String? ?? 'open_market',
    targetCompanyId: json['target_company_id'] as String?,
    targetDriverId: json['target_driver_id'] as String?,
    vehicleRequirement: json['vehicle_requirement'] as String?,
    seatsRequired: json['seats_required'] as int?,
    hidePriceFromPassengers: json['hide_price_from_passengers'] as bool? ?? false,
    isFinalAmountLocked: json['is_final_amount_locked'] as bool? ?? false,
    finalAmount: (json['final_amount'] as num?)?.toDouble(),
    acceptedOfferId: json['accepted_offer_id'] as String?,
    chatEnabled: json['chat_enabled'] as bool? ?? true,
    passengerRating: (json['passenger_rating'] as num?)?.toDouble() ?? 5,
    providerRating: (json['provider_rating'] as num?)?.toDouble() ?? 5,
    providerCompleted: json['provider_completed'] as bool? ?? false,
    customerCompleted: json['customer_completed'] as bool? ?? false,
    status: RideStatus.values.firstWhere(
      (s) => s.name == (json['status'] as String? ?? ''),
      orElse: () => RideStatus.pending,
    ),
    companyId: json['company_id'] as String?,
    assignedDriverId: json['assigned_driver_id'] as String?,
    frappeBookingId: json['frappe_booking_id'] as String?,
    notes: json['notes'] as String?,
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
    expiresAt: (json['expires_at'] as dynamic)?.toDate(),
    prepaid: json['prepaid'] as bool? ?? false,
    canCancelAfterCutoff: json['can_cancel_after_cutoff'] as bool? ?? false,
    reminderStartAt: (json['reminder_start_at'] as dynamic)?.toDate(),
    finalReminderStartAt: (json['final_reminder_start_at'] as dynamic)?.toDate(),
    offerCount: json['offer_count'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'passenger_id': passengerId,
    'passenger_name': passengerName,
    'passenger_phone': passengerPhone,
    'route_id': routeId,
    'pickup_location': pickupLocation,
    'dropoff_location': dropoffLocation,
    'pickup_lat': pickupLat,
    'pickup_lng': pickupLng,
    'dropoff_lat': dropoffLat,
    'dropoff_lng': dropoffLng,
    'travel_date': travelDate,
    'departure_time': departureTime,
    'vehicle_type': vehicleType,
    'passengers_count': passengersCount,
    'offered_price': offeredPrice,
    'platform_fee': platformFee,
    'booking_type': bookingType,
    'service_type': serviceType,
    'routine_category': routineCategory,
    'contract_duration': contractDuration,
    'pickup_time': pickupTime,
    'dropoff_time': dropoffTime,
    'rental_days': rentalDays,
    'payment_status': paymentStatus,
    'payment_provider': paymentProvider,
    'group_name': groupName,
    'passenger_names': passengerNames,
    'passenger_rows': passengerRows,
    'contract_id': contractId,
    'market_visibility': marketVisibility,
    'target_company_id': targetCompanyId,
    'target_driver_id': targetDriverId,
    'vehicle_requirement': vehicleRequirement,
    'seats_required': seatsRequired,
    'hide_price_from_passengers': hidePriceFromPassengers,
    'is_final_amount_locked': isFinalAmountLocked,
    'final_amount': finalAmount,
    'accepted_offer_id': acceptedOfferId,
    'chat_enabled': chatEnabled,
    'passenger_rating': passengerRating,
    'provider_rating': providerRating,
    'provider_completed': providerCompleted,
    'customer_completed': customerCompleted,
    'status': status.name,
    'company_id': companyId,
    'assigned_driver_id': assignedDriverId,
    'frappe_booking_id': frappeBookingId,
    'notes': notes,
    'created_at': createdAt,
    'expires_at': expiresAt,
    'prepaid': prepaid,
    'can_cancel_after_cutoff': canCancelAfterCutoff,
    'reminder_start_at': reminderStartAt,
    'final_reminder_start_at': finalReminderStartAt,
    'offer_count': offerCount,
  };
}
