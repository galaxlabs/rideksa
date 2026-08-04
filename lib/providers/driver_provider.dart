import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/driver_model.dart';
import '../models/ride_request_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class DriverProvider extends ChangeNotifier {
  final FirestoreService _firestore;
  final LocationService _locationService;
  final NotificationService _notificationService;

  DriverModel? _myProfile;
  List<RideRequestModel> _nearbyRides = [];
  List<DriverModel> _onlineDrivers = [];
  StreamSubscription? _profileSub;
  StreamSubscription? _ridesSub;
  bool _loading = false;
  bool _isOnline = false;

  DriverProvider(this._firestore, this._locationService, this._notificationService);

  DriverModel? get profile => _myProfile;
  List<RideRequestModel> get nearbyRides => _nearbyRides;
  List<DriverModel> get onlineDrivers => _onlineDrivers;
  bool get loading => _loading;
  bool get isOnline => _isOnline;

  void subscribeToProfile(String driverId) {
    _profileSub?.cancel();
    _profileSub = _firestore.streamDriver(driverId).listen((driver) {
      _myProfile = driver;
      notifyListeners();
    });
  }

  void subscribeToNearbyRides({String? companyId}) {
    _ridesSub?.cancel();
    _ridesSub = _firestore.streamActiveRides(companyId: companyId).listen((rides) {
      final previousIds = _nearbyRides.map((r) => r.id).toSet();
      if (_myProfile?.latitude != null && _myProfile?.longitude != null) {
        _nearbyRides = _locationService.filterByRadius(
          rides.map((r) => DriverModel(
            id: r.id, userId: r.passengerId ?? '',
            fullName: r.passengerName, latitude: r.pickupLat,
            longitude: r.pickupLng, createdAt: DateTime.now(),
          )).toList(),
          _myProfile!.latitude!, _myProfile!.longitude!,
        ).map((d) => rides.firstWhere((r) => r.id == d.id)).toList();
      } else {
        _nearbyRides = rides;
      }
      for (final ride in _nearbyRides) {
        if (!previousIds.contains(ride.id)) {
          _notificationService.showRideOpportunity(ride);
          break;
        }
      }
      notifyListeners();
    });
  }

  Future<void> setOnline(bool online) async {
    _isOnline = online;
    if (_myProfile != null) {
      final pos = await _locationService.getCurrentPosition();
      final updated = DriverModel(
        id: _myProfile!.id, userId: _myProfile!.userId,
        fullName: _myProfile!.fullName, phone: _myProfile!.phone,
        vehicleType: _myProfile!.vehicleType, vehiclePlate: _myProfile!.vehiclePlate,
        status: online ? DriverStatus.online : DriverStatus.offline,
        latitude: pos.latitude, longitude: pos.longitude,
        lastKnownLat: pos.latitude, lastKnownLng: pos.longitude,
        rating: _myProfile!.rating, totalTrips: _myProfile!.totalTrips,
        isAvailable: online, lastLocationUpdate: DateTime.now(),
        companyId: _myProfile!.companyId, createdAt: _myProfile!.createdAt,
      );
      await _firestore.setDriver(updated);
      _myProfile = updated;
    }
    notifyListeners();
  }

  Future<void> updateLocation(double lat, double lng) async {
    if (_myProfile == null || !_isOnline) return;
    await _firestore.updateUser(_myProfile!.userId, {
      'latitude': lat, 'longitude': lng,
      'last_location_update': DateTime.now(),
    });
    _myProfile = DriverModel(
      id: _myProfile!.id, userId: _myProfile!.userId,
      fullName: _myProfile!.fullName, latitude: lat, longitude: lng,
      status: _myProfile!.status, isAvailable: _isOnline,
      rating: _myProfile!.rating, totalTrips: _myProfile!.totalTrips,
      companyId: _myProfile!.companyId, createdAt: _myProfile!.createdAt,
      vehicleType: _myProfile!.vehicleType, vehiclePlate: _myProfile!.vehiclePlate,
    );
  }

  Future<void> saveProfile(DriverModel driver) async {
    _loading = true;
    notifyListeners();
    await _firestore.setDriver(driver);
    _myProfile = driver;
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _ridesSub?.cancel();
    super.dispose();
  }
}
