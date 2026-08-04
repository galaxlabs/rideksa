class RouteModel {
  final String id;
  final String source;
  final String destination;
  final String? sourceArabic;
  final String? destinationArabic;
  final double distanceKm;
  final int? estimatedDurationMin;
  final String? routeType;
  final double? baseFare;
  final double? perKmRate;

  RouteModel({
    required this.id,
    required this.source,
    required this.destination,
    this.sourceArabic,
    this.destinationArabic,
    required this.distanceKm,
    this.estimatedDurationMin,
    this.routeType,
    this.baseFare,
    this.perKmRate,
  });

  String get displayLabel => '$source → $destination';
  String get displayLabelAr => '${sourceArabic ?? source} ← ${destinationArabic ?? destination}';
  String get displayDistance => '${distanceKm.toStringAsFixed(0)} km';
  String get displayDuration => estimatedDurationMin != null
      ? '${estimatedDurationMin! ~/ 60}h ${estimatedDurationMin! % 60}m'
      : '';

  factory RouteModel.fromJson(Map<String, dynamic> json) => RouteModel(
    id: json['id'] as String? ?? json['name'] as String? ?? '',
    source: json['from_city'] as String? ?? json['source'] as String? ?? '',
    destination: json['to_city'] as String? ?? json['destination'] as String? ?? '',
    sourceArabic: json['from_city_ar'] as String? ?? json['source_arabic'] as String?,
    destinationArabic: json['to_city_ar'] as String? ?? json['destination_arabic'] as String?,
    distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
    estimatedDurationMin: json['estimated_duration_minutes'] as int?,
    routeType: json['route_type'] as String?,
    baseFare: (json['base_fare'] as num?)?.toDouble(),
    perKmRate: (json['per_km_rate'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'destination': destination,
    'from_city_ar': sourceArabic,
    'to_city_ar': destinationArabic,
    'distance_km': distanceKm,
    'estimated_duration_minutes': estimatedDurationMin,
    'route_type': routeType,
    'base_fare': baseFare,
    'per_km_rate': perKmRate,
  };
}
