import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/driver_model.dart';

class LocationService {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSub;

  Position? get currentPosition => _currentPosition;

  Future<bool> requestPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<Position> getCurrentPosition() async {
    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return _currentPosition!;
  }

  void startTracking(void Function(Position pos) onUpdate) {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        timeLimit: null,
      ),
    ).listen(onUpdate);
  }

  void startForegroundTracking(void Function(Position pos) onUpdate) {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'RideKSA trip in progress',
          notificationText: 'Live location sharing is active',
          notificationChannelName: 'RideKSA Live Trip Tracking',
          enableWakeLock: true,
          enableWifiLock: true,
          setOngoing: true,
        ),
      ),
    ).listen(onUpdate);
  }

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return '${p.street ?? ''}, ${p.locality ?? ''}, ${p.country ?? ''}';
      }
    } catch (_) {}
    return '$lat, $lng';
  }

  Future<List<Placemark>> getPlacemarks(double lat, double lng) async {
    try {
      return await placemarkFromCoordinates(lat, lng);
    } catch (_) {
      return [];
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  List<DriverModel> filterByRadius(List<DriverModel> drivers, double lat, double lon, {double radiusKm = 50}) {
    return drivers.where((d) {
      if (d.latitude == null || d.longitude == null) return false;
      final dist = calculateDistance(lat, lon, d.latitude!, d.longitude!);
      return dist <= radiusKm;
    }).map((d) {
      final dist = calculateDistance(lat, lon, d.latitude!, d.longitude!);
      return DriverModel(
        id: d.id, userId: d.userId, fullName: d.fullName,
        phone: d.phone, vehicleType: d.vehicleType,
        vehiclePlate: d.vehiclePlate, status: d.status,
        latitude: d.latitude, longitude: d.longitude,
        rating: d.rating, totalTrips: d.totalTrips,
        isAvailable: d.isAvailable, distanceKm: double.parse(dist.toStringAsFixed(1)),
        companyId: d.companyId, createdAt: d.createdAt,
      );
    }).toList();
  }

  double estimateFare(double distanceKm, {double baseFare = 10, double perKmRate = 1.5}) {
    return baseFare + (distanceKm * perKmRate);
  }

  int estimateDurationMinutes(double distanceKm, {double avgSpeedKmh = 60}) {
    return (distanceKm / avgSpeedKmh * 60).ceil();
  }

  void dispose() {
    stopTracking();
  }
}
