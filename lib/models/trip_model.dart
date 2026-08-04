enum TripStatus { pending, checkedIn, boarded, inProgress, completed, cancelled }

class TripModel {
  final String id;
  final String? rideRequestId;
  final String? bookingId;
  final String? passengerId;
  final String? passengerName;
  final String? driverId;
  final String? driverName;
  final String? vehicleId;
  final String? vehiclePlate;
  final String pickupLocation;
  final String dropoffLocation;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final double? currentLat;
  final double? currentLng;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final double distance;
  final double fare;
  final double commissionAmount;
  final double driverEarnings;
  final TripStatus status;
  final String? companyId;
  final String? frappeTripId;
  final String? publicUrl;
  final String? qrCode;
  final String? notes;
  final bool providerCompleted;
  final bool customerCompleted;
  final double passengerRating;
  final double providerRating;
  final DateTime createdAt;

  TripModel({
    required this.id,
    this.rideRequestId,
    this.bookingId,
    this.passengerId,
    this.passengerName,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehiclePlate,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.currentLat,
    this.currentLng,
    this.departureTime,
    this.arrivalTime,
    this.distance = 0,
    this.fare = 0,
    this.commissionAmount = 0,
    this.driverEarnings = 0,
    this.status = TripStatus.pending,
    this.companyId,
    this.frappeTripId,
    this.publicUrl,
    this.qrCode,
    this.notes,
    this.providerCompleted = false,
    this.customerCompleted = false,
    this.passengerRating = 5,
    this.providerRating = 5,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
    id: json['id'] as String? ?? json['name'] as String? ?? '',
    rideRequestId: json['ride_request_id'] as String?,
    bookingId: json['booking_id'] as String?,
    passengerId: json['passenger_id'] as String?,
    passengerName: json['passenger_name'] as String?,
    driverId: json['driver_id'] as String?,
    driverName: json['driver_name'] as String?,
    vehicleId: json['vehicle_id'] as String?,
    vehiclePlate: json['vehicle_plate'] as String?,
    pickupLocation: json['pickup_location'] as String? ?? json['from_location'] as String? ?? '',
    dropoffLocation: json['dropoff_location'] as String? ?? json['to_location'] as String? ?? '',
    pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
    pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
    dropoffLat: (json['dropoff_lat'] as num?)?.toDouble(),
    dropoffLng: (json['dropoff_lng'] as num?)?.toDouble(),
    currentLat: (json['current_lat'] as num?)?.toDouble(),
    currentLng: (json['current_lng'] as num?)?.toDouble(),
    departureTime: (json['departure_time'] as dynamic)?.toDate(),
    arrivalTime: (json['arrival_time'] as dynamic)?.toDate(),
    distance: (json['distance'] as num?)?.toDouble() ?? 0,
    fare: (json['fare'] as num?)?.toDouble() ?? (json['trip_value'] as num?)?.toDouble() ?? 0,
    commissionAmount: (json['commission_amount'] as num?)?.toDouble() ?? 0,
    driverEarnings: (json['driver_earnings'] as num?)?.toDouble() ?? 0,
    status: TripStatus.values.firstWhere(
      (s) => s.name == (json['status'] as String? ?? ''),
      orElse: () => TripStatus.pending,
    ),
    companyId: json['company_id'] as String?,
    frappeTripId: json['frappe_trip_id'] as String?,
    publicUrl: json['public_url'] as String?,
    qrCode: json['qr_code'] as String?,
    notes: json['notes'] as String?,
    providerCompleted: json['provider_completed'] as bool? ?? false,
    customerCompleted: json['customer_completed'] as bool? ?? false,
    passengerRating: (json['passenger_rating'] as num?)?.toDouble() ?? 5,
    providerRating: (json['provider_rating'] as num?)?.toDouble() ?? 5,
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ride_request_id': rideRequestId,
    'booking_id': bookingId,
    'passenger_id': passengerId,
    'passenger_name': passengerName,
    'driver_id': driverId,
    'driver_name': driverName,
    'vehicle_id': vehicleId,
    'vehicle_plate': vehiclePlate,
    'pickup_location': pickupLocation,
    'dropoff_location': dropoffLocation,
    'pickup_lat': pickupLat,
    'pickup_lng': pickupLng,
    'dropoff_lat': dropoffLat,
    'dropoff_lng': dropoffLng,
    'current_lat': currentLat,
    'current_lng': currentLng,
    'departure_time': departureTime,
    'arrival_time': arrivalTime,
    'distance': distance,
    'fare': fare,
    'commission_amount': commissionAmount,
    'driver_earnings': driverEarnings,
    'status': status.name,
    'company_id': companyId,
    'frappe_trip_id': frappeTripId,
    'public_url': publicUrl,
    'qr_code': qrCode,
    'notes': notes,
    'provider_completed': providerCompleted,
    'customer_completed': customerCompleted,
    'passenger_rating': passengerRating,
    'provider_rating': providerRating,
    'created_at': createdAt,
  };
}
