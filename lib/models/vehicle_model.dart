class VehicleModel {
  final String id;
  final String? plateNumber;
  final String? make;
  final String? model;
  final int? year;
  final String? color;
  final String? type;
  final int? seatingCapacity;
  final String? companyId;
  final String? driverId;
  final bool isActive;

  VehicleModel({
    required this.id,
    this.plateNumber,
    this.make,
    this.model,
    this.year,
    this.color,
    this.type,
    this.seatingCapacity,
    this.companyId,
    this.driverId,
    this.isActive = true,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
    id: json['id'] as String? ?? json['name'] as String? ?? '',
    plateNumber: json['plate_number'] as String? ?? json['license_plate'] as String?,
    make: json['make'] as String?,
    model: json['model'] as String?,
    year: json['year'] as int?,
    color: json['color'] as String?,
    type: json['vehicle_type'] as String? ?? json['type'] as String?,
    seatingCapacity: json['seating_capacity'] as int?,
    companyId: json['company_id'] as String?,
    driverId: json['driver_id'] as String?,
    isActive: json['is_active'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'plate_number': plateNumber,
    'make': make,
    'model': model,
    'year': year,
    'color': color,
    'vehicle_type': type,
    'seating_capacity': seatingCapacity,
    'company_id': companyId,
    'driver_id': driverId,
    'is_active': isActive,
  };
}

class VehicleType {
  final String id;
  final String name;
  final String? code;
  final int? defaultSeatingCapacity;
  final double? baseFare;
  final double? perKmRate;

  VehicleType({
    required this.id,
    required this.name,
    this.code,
    this.defaultSeatingCapacity,
    this.baseFare,
    this.perKmRate,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) => VehicleType(
    id: json['id'] as String? ?? json['name'] as String? ?? '',
    name: json['type_name'] as String? ?? json['name'] as String? ?? '',
    code: json['type_code'] as String?,
    defaultSeatingCapacity: json['default_seating_capacity'] as int?,
    baseFare: (json['base_fare'] as num?)?.toDouble(),
    perKmRate: (json['per_km_rate'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type_name': name,
    'type_code': code,
    'default_seating_capacity': defaultSeatingCapacity,
    'base_fare': baseFare,
    'per_km_rate': perKmRate,
  };
}
