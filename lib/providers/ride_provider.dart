import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../core/errors.dart';
import '../models/ride_request_model.dart';
import '../models/ride_offer_model.dart';
import '../models/trip_model.dart';
import '../models/trip_transfer_model.dart';
import '../services/firestore_service.dart';
import '../services/sync_service.dart';
import '../services/wallet_service.dart';
import '../services/commission_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/pricing_service.dart';

class RideProvider extends ChangeNotifier {
  final FirestoreService _firestore;
  final SyncService _syncService;
  final WalletService _walletService;
  final CommissionService _commissionService;
  final LocationService _locationService;
  final NotificationService _notificationService;
  final PricingService _pricingService = PricingService();
  final Uuid _uuid = const Uuid();

  List<RideRequestModel> _activeRides = [];
  List<RideOfferModel> _offers = [];
  RideRequestModel? _selectedRide;
  TripModel? _activeTrip;
  StreamSubscription? _ridesSub;
  StreamSubscription? _offersSub;
  StreamSubscription? _tripSub;
  bool _loading = false;
  String? _error;

  RideProvider(
    this._firestore,
    this._syncService,
    this._walletService,
    this._commissionService,
    this._locationService,
    this._notificationService,
  );

  List<RideRequestModel> get activeRides => _activeRides;
  List<RideOfferModel> get offers => _offers;
  RideRequestModel? get selectedRide => _selectedRide;
  TripModel? get activeTrip => _activeTrip;
  bool get loading => _loading;
  String? get error => _error;

  void subscribeToActiveRides({String? companyId}) {
    _ridesSub?.cancel();
    _ridesSub = _firestore.streamActiveRides(companyId: companyId).listen((rides) {
      _activeRides = rides;
      notifyListeners();
    });
  }

  void subscribeToOffers(String rideRequestId) {
    _offersSub?.cancel();
    _offersSub = _firestore.streamOffersForRide(rideRequestId).listen((offers) {
      _offers = offers;
      notifyListeners();
    });
  }

  void subscribeToTrip(String tripId) {
    _tripSub?.cancel();
    _tripSub = _firestore.streamActiveTrip(tripId).listen((trip) {
      _activeTrip = trip;
      notifyListeners();
    });
  }

  Future<RideRequestModel> createRideRequest({
    String? id,
    required String pickupLocation,
    required String dropoffLocation,
    double? pickupLat,
    double? pickupLng,
    required DateTime travelDate,
    String? vehicleType,
    int passengersCount = 1,
    double offeredPrice = 0,
    String bookingType = 'single',
    String serviceType = 'ride',
    String? routineCategory,
    String? contractDuration,
    String? pickupTime,
    String? dropoffTime,
    int rentalDays = 1,
    String? groupName,
    List<String> passengerNames = const [],
    List<Map<String, dynamic>> passengerRows = const [],
    String? contractId,
    String marketVisibility = 'open_market',
    String? targetCompanyId,
    String? targetDriverId,
    String? vehicleRequirement,
    int? seatsRequired,
    bool hidePriceFromPassengers = false,
    String? passengerId,
    String? passengerName,
    String? passengerPhone,
    String? companyId,
    String? notes,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      if (passengerId == null || passengerId.isEmpty) {
        throw const AppException('Login is required before booking so payment can be reserved.');
      }
      if (await _firestore.hasOpenTaskForUser(passengerId)) {
        throw const AppException('Complete your previous ride and transaction before creating a new booking.');
      }
      final rideId = id ?? _uuid.v4();
      final finalOffer = _pricingService.clampOffer(offeredPrice);
      final ride = RideRequestModel(
        id: rideId,
        passengerId: passengerId,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        travelDate: travelDate,
        vehicleType: vehicleType ?? 'Sedan',
        passengersCount: passengersCount,
        offeredPrice: finalOffer,
        bookingType: bookingType,
        serviceType: serviceType,
        routineCategory: routineCategory,
        contractDuration: contractDuration,
        pickupTime: pickupTime,
        dropoffTime: dropoffTime,
        rentalDays: rentalDays,
        groupName: groupName,
        passengerNames: passengerNames,
        passengerRows: passengerRows,
        contractId: contractId,
        marketVisibility: marketVisibility,
        targetCompanyId: targetCompanyId,
        targetDriverId: targetDriverId,
        vehicleRequirement: vehicleRequirement,
        seatsRequired: seatsRequired,
        hidePriceFromPassengers: hidePriceFromPassengers,
        companyId: companyId,
        notes: notes,
        prepaid: true,
        reminderStartAt: travelDate.subtract(const Duration(hours: AppConstants.firstReminderHoursBefore)),
        finalReminderStartAt: travelDate.subtract(const Duration(hours: AppConstants.finalReminderHoursBefore)),
      );
      await _walletService.reserveForBooking(passengerId, finalOffer, rideId);
      await _firestore.setActiveRide(ride);
      _syncService.pushRideToFrappe(ride);
      _selectedRide = ride;
      _loading = false;
      notifyListeners();
      return ride;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<RideOfferModel> makeOffer({
    required String rideRequestId,
    required String driverId,
    String? driverName,
    String offererType = 'driver',
    String? companyId,
    String? companyName,
    String? vehicleType,
    String? vehiclePlate,
    int? seatCapacity,
    required double price,
    String? message,
  }) async {
    if (await _firestore.hasOpenTaskForProvider(driverId)) {
      throw const AppException('Complete your current accepted ride before accepting or offering on another ride.');
    }
    final finalPrice = _pricingService.clampOffer(price);
    final offer = RideOfferModel(
      id: _uuid.v4(),
      rideRequestId: rideRequestId,
      driverId: driverId,
      driverName: driverName,
      offererType: offererType,
      companyId: companyId,
      companyName: companyName,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
      seatCapacity: seatCapacity,
      price: finalPrice,
      message: message,
    );
    await _firestore.setOffer(offer);
    await _firestore.updateActiveRide(rideRequestId, {'offer_count': FieldValue.increment(1), 'status': RideStatus.offered.name});
    return offer;
  }

  Future<void> acceptOffer(String rideRequestId, RideOfferModel offer) async {
    if (await _firestore.hasOpenTaskForProvider(offer.driverId)) {
      throw const AppException('Provider already has an active ride.');
    }
    final acceptedAt = DateTime.now();
    await _firestore.updateOffer(offer.id, {'status': 'accepted', 'responded_at': acceptedAt, 'is_final': true});
    await _firestore.updateActiveRide(rideRequestId, {
      'status': 'accepted',
      'assigned_driver_id': offer.driverId,
      'accepted_offer_id': offer.id,
      'final_amount': offer.price,
      'platform_fee': offer.price * 0.05,
      'is_final_amount_locked': true,
    });

    final ride = _activeRides.firstWhere((r) => r.id == rideRequestId);
    final trip = TripModel(
      id: _uuid.v4(),
      rideRequestId: rideRequestId,
      bookingId: ride.frappeBookingId,
      passengerId: ride.passengerId,
      passengerName: ride.passengerName,
      driverId: offer.driverId,
      driverName: offer.driverName,
      vehiclePlate: offer.vehiclePlate,
      pickupLocation: ride.pickupLocation,
      dropoffLocation: ride.dropoffLocation,
      pickupLat: ride.pickupLat,
      pickupLng: ride.pickupLng,
      departureTime: ride.travelDate,
      distance: _locationService.calculateDistance(
        ride.pickupLat ?? 0, ride.pickupLng ?? 0,
        ride.dropoffLat ?? 0, ride.dropoffLng ?? 0,
      ),
      fare: offer.price,
      commissionAmount: offer.price * 0.05,
      driverEarnings: offer.price * 0.95,
      companyId: ride.companyId,
    );
    await _firestore.setActiveTrip(trip);
    _notificationService.scheduleTripReminders(trip);
    _syncService.pushTripToFrappe(trip);
    _activeTrip = trip;
    notifyListeners();
  }

  Future<void> completeTrip(String tripId) async {
    final trip = _activeTrip;
    if (trip == null) return;
    final completed = TripModel(
      id: trip.id, rideRequestId: trip.rideRequestId,
      bookingId: trip.bookingId, passengerId: trip.passengerId,
      passengerName: trip.passengerName, driverId: trip.driverId,
      driverName: trip.driverName, vehicleId: trip.vehicleId,
      vehiclePlate: trip.vehiclePlate, pickupLocation: trip.pickupLocation,
      dropoffLocation: trip.dropoffLocation, pickupLat: trip.pickupLat,
      pickupLng: trip.pickupLng, dropoffLat: trip.dropoffLat,
      dropoffLng: trip.dropoffLng, departureTime: trip.departureTime,
      arrivalTime: DateTime.now(), distance: trip.distance,
      fare: trip.fare, status: TripStatus.completed,
      commissionAmount: trip.commissionAmount,
      driverEarnings: trip.driverEarnings,
      companyId: trip.companyId, frappeTripId: trip.frappeTripId,
      providerCompleted: true,
      customerCompleted: true,
      passengerRating: trip.passengerRating,
      providerRating: trip.providerRating,
    );
    await _firestore.setActiveTrip(completed);
    await _commissionService.recordCommission(completed);
    if (trip.driverId != null) {
      await _walletService.creditEarnings(trip.driverId!, trip.fare, trip.id, trip.companyId ?? '');
    }
    await _firestore.deleteActiveRide(trip.rideRequestId ?? '');
    await _firestore.deleteActiveTrip(tripId);
    _activeTrip = null;
    _selectedRide = null;
    notifyListeners();
  }

  Future<void> markTripCompletion(String tripId, {required bool providerSide}) async {
    final trip = _activeTrip;
    if (trip == null) return;
    final providerDone = providerSide ? true : trip.providerCompleted;
    final customerDone = providerSide ? trip.customerCompleted : true;
    await _firestore.updateActiveTrip(tripId, {
      'provider_completed': providerDone,
      'customer_completed': customerDone,
      if (providerDone && customerDone) 'status': TripStatus.completed.name,
    });
  }

  Future<void> cancelRide(String rideId) async {
    final ride = _selectedRide ?? _activeRides.where((r) => r.id == rideId).firstOrNull;
    if (ride != null && ride.travelDate.difference(DateTime.now()).inMinutes <= AppConstants.cancelCutoffMinutes) {
      throw const AppException('Cancellation is not allowed within 1 hour of trip start.');
    }
    await _firestore.updateActiveRide(rideId, {'status': 'cancelled'});
    await _firestore.deleteActiveRide(rideId);
    notifyListeners();
  }

  Future<TripTransferModel> createTripTransfer({
    required String sellerId,
    required double sellAmount,
    String? reason,
  }) async {
    final trip = _activeTrip;
    if (trip == null || trip.rideRequestId == null) {
      throw const AppException('No active trip available to transfer.');
    }
    final transfer = TripTransferModel(
      id: _uuid.v4(),
      rideRequestId: trip.rideRequestId!,
      tripId: trip.id,
      sellerId: sellerId,
      originalAmount: trip.fare,
      sellAmount: _pricingService.clampOffer(sellAmount),
      reason: reason,
    );
    await _firestore.setTripTransfer(transfer);
    _notificationService.notifyTransferOpportunity('Trip transfer available: ﷼ ${transfer.sellAmount.toStringAsFixed(0)} for ${trip.pickupLocation} to ${trip.dropoffLocation}.');
    return transfer;
  }

  Future<void> acceptTripTransfer(TripTransferModel transfer, String buyerId) async {
    if (await _firestore.hasOpenTaskForProvider(buyerId)) {
      throw const AppException('Complete your current ride before accepting transferred trips.');
    }
    await _firestore.setTripTransfer(TripTransferModel(
      id: transfer.id,
      rideRequestId: transfer.rideRequestId,
      tripId: transfer.tripId,
      sellerId: transfer.sellerId,
      buyerId: buyerId,
      originalAmount: transfer.originalAmount,
      sellAmount: transfer.sellAmount,
      status: 'accepted',
      reason: transfer.reason,
      createdAt: transfer.createdAt,
      acceptedAt: DateTime.now(),
    ));
    await _firestore.updateActiveTrip(transfer.tripId, {
      'driver_id': buyerId,
      'fare': transfer.sellAmount,
      'commission_amount': transfer.sellAmount * AppConstants.commissionRate,
      'driver_earnings': transfer.sellAmount * (1 - AppConstants.commissionRate),
    });
  }

  void selectRide(RideRequestModel ride) {
    _selectedRide = ride;
    notifyListeners();
  }

  @override
  void dispose() {
    _ridesSub?.cancel();
    _offersSub?.cancel();
    _tripSub?.cancel();
    super.dispose();
  }
}
