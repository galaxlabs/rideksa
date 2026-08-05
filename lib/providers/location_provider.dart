import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _service;

  Position? _position;
  String? _address;
  bool _hasPermission = false;
  bool _isTracking = false;
  StreamSubscription<Position>? _sub;

  LocationProvider(this._service);

  Position? get position => _position;
  String? get address => _address;
  bool get hasPermission => _hasPermission;
  bool get isTracking => _isTracking;

  Future<bool> initialize() async {
    _hasPermission = await _service.requestPermission();
    if (_hasPermission) {
      _position = await _service.getCurrentPosition();
    }
    notifyListeners();
    return _hasPermission;
  }

  Future<void> refreshPosition() async {
    _position = await _service.getCurrentPosition();
    notifyListeners();
  }

  Future<String> getAddress() async {
    if (_position == null) return '';
    _address = await _service.getAddressFromLatLng(
      _position!.latitude,
      _position!.longitude,
    );
    notifyListeners();
    return _address ?? '';
  }

  void startTracking({void Function(Position)? onPosition}) {
    if (_isTracking) return;
    _isTracking = true;
    _sub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50,
          ),
        ).listen((pos) {
          _position = pos;
          onPosition?.call(pos);
          notifyListeners();
        });
  }

  void startForegroundTracking({void Function(Position)? onPosition}) {
    if (_isTracking) return;
    _isTracking = true;
    _service.startForegroundTracking(
      (pos) {
        _position = pos;
        onPosition?.call(pos);
        notifyListeners();
      },
      onError: (_) => _trackingStopped(),
      onDone: _trackingStopped,
    );
  }

  void _trackingStopped() {
    _isTracking = false;
    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    _sub?.cancel();
    _sub = null;
    _service.stopTracking();
    notifyListeners();
  }

  double distanceTo(double lat, double lng) {
    if (_position == null) return 0;
    return Geolocator.distanceBetween(
          _position!.latitude,
          _position!.longitude,
          lat,
          lng,
        ) /
        1000;
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
