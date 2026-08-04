enum DriverStatus { offline, online, onTrip }

class DriverModel {
  final String id;
  final String userId;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? companyId;
  final String? vehicleId;
  final String? vehicleType;
  final String? vehiclePlate;
  final DriverStatus status;
  final double? latitude;
  final double? longitude;
  final double? lastKnownLat;
  final double? lastKnownLng;
  final double rating;
  final int totalTrips;
  final double totalEarnings;
  final bool isAvailable;
  final DateTime? lastLocationUpdate;
  final DateTime createdAt;
  final double? distanceKm;

  DriverModel({
    required this.id,
    required this.userId,
    this.fullName,
    this.phone,
    this.email,
    this.companyId,
    this.vehicleId,
    this.vehicleType,
    this.vehiclePlate,
    this.status = DriverStatus.offline,
    this.latitude,
    this.longitude,
    this.lastKnownLat,
    this.lastKnownLng,
    this.rating = 5.0,
    this.totalTrips = 0,
    this.totalEarnings = 0.0,
    this.isAvailable = false,
    this.lastLocationUpdate,
    DateTime? createdAt,
    this.distanceKm,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
    id: json['id'] as String? ?? json['name'] as String? ?? '',
    userId: json['user_id'] as String? ?? json['uid'] as String? ?? '',
    fullName: json['full_name'] as String? ?? json['name'] as String?,
    phone: json['mobile_no'] as String? ?? json['phone'] as String?,
    email: json['email'] as String?,
    companyId: json['company_id'] as String?,
    vehicleId: json['vehicle_id'] as String?,
    vehicleType: json['vehicle_type'] as String?,
    vehiclePlate: json['vehicle_plate'] as String?,
    status: DriverStatus.values.firstWhere(
      (s) => s.name == (json['status'] as String? ?? ''),
      orElse: () => DriverStatus.offline,
    ),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    lastKnownLat: (json['last_known_lat'] as num?)?.toDouble(),
    lastKnownLng: (json['last_known_lng'] as num?)?.toDouble(),
    rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
    totalTrips: json['total_trips'] as int? ?? 0,
    totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
    isAvailable: json['is_available'] as bool? ?? false,
    lastLocationUpdate: (json['last_location_update'] as dynamic)?.toDate(),
    createdAt: (json['created_at'] as dynamic)?.toDate(),
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'full_name': fullName,
    'mobile_no': phone,
    'email': email,
    'company_id': companyId,
    'vehicle_id': vehicleId,
    'vehicle_type': vehicleType,
    'vehicle_plate': vehiclePlate,
    'status': status.name,
    'latitude': latitude,
    'longitude': longitude,
    'last_known_lat': lastKnownLat,
    'last_known_lng': lastKnownLng,
    'rating': rating,
    'total_trips': totalTrips,
    'total_earnings': totalEarnings,
    'is_available': isAvailable,
    'last_location_update': lastLocationUpdate,
    'created_at': createdAt,
    'distance_km': distanceKm,
  };
}
