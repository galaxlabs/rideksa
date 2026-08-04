enum OfferStatus { pending, accepted, rejected, withdrawn }

class RideOfferModel {
  final String id;
  final String rideRequestId;
  final String driverId;
  final String? driverName;
  final String? driverPhone;
  final String offererType;
  final String? companyId;
  final String? companyName;
  final String? vehicleType;
  final String? vehiclePlate;
  final int? seatCapacity;
  final double price;
  final bool isFinal;
  final String? message;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  RideOfferModel({
    required this.id,
    required this.rideRequestId,
    required this.driverId,
    this.driverName,
    this.driverPhone,
    this.offererType = 'driver',
    this.companyId,
    this.companyName,
    this.vehicleType,
    this.vehiclePlate,
    this.seatCapacity,
    required this.price,
    this.isFinal = false,
    this.message,
    this.status = OfferStatus.pending,
    DateTime? createdAt,
    this.respondedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RideOfferModel.fromJson(Map<String, dynamic> json) => RideOfferModel(
    id: json['id'] as String? ?? '',
    rideRequestId: json['ride_request_id'] as String? ?? '',
    driverId: json['driver_id'] as String? ?? '',
    driverName: json['driver_name'] as String?,
    driverPhone: json['driver_phone'] as String?,
    offererType: json['offerer_type'] as String? ?? 'driver',
    companyId: json['company_id'] as String?,
    companyName: json['company_name'] as String?,
    vehicleType: json['vehicle_type'] as String?,
    vehiclePlate: json['vehicle_plate'] as String?,
    seatCapacity: json['seat_capacity'] as int?,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    isFinal: json['is_final'] as bool? ?? false,
    message: json['message'] as String?,
    status: OfferStatus.values.firstWhere(
      (s) => s.name == (json['status'] as String? ?? ''),
      orElse: () => OfferStatus.pending,
    ),
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
    respondedAt: (json['responded_at'] as dynamic)?.toDate(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ride_request_id': rideRequestId,
    'driver_id': driverId,
    'driver_name': driverName,
    'driver_phone': driverPhone,
    'offerer_type': offererType,
    'company_id': companyId,
    'company_name': companyName,
    'vehicle_type': vehicleType,
    'vehicle_plate': vehiclePlate,
    'seat_capacity': seatCapacity,
    'price': price,
    'is_final': isFinal,
    'message': message,
    'status': status.name,
    'created_at': createdAt,
    'responded_at': respondedAt,
  };
}
