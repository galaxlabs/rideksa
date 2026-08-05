import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ride_request_model.dart';
import '../models/trip_model.dart';
import '../models/company_model.dart';
import '../models/route_model.dart';
import 'firestore_service.dart';
import 'frappe_api_client.dart';

class SyncService {
  final FirestoreService _firestore;
  final FrappeApiClient _frappe;
  Timer? _syncTimer;

  SyncService(this._firestore, this._frappe);

  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncAll());
  }

  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> syncAll() async {
    await Future.wait([syncRoutes(), syncCompanies()]);
  }

  Future<void> syncRoutes() async {
    try {
      final routes = await _frappe.getAvailableRoutes();
      final models = routes.map((r) => RouteModel.fromJson(r)).toList();
      await _firestore.setRoutes(models);
    } catch (_) {}
  }

  Future<void> syncCompanies() async {
    try {
      final companies = await _frappe.getList(
        'Company',
        fields: [
          'name',
          'company_name',
          'custom_company_name_arabic',
          'phone_no',
          'email',
          'company_logo',
        ],
      );
      for (final c in companies) {
        final model = CompanyModel(
          id: c['name'] as String? ?? '',
          name: c['company_name'] as String? ?? c['name'] as String? ?? '',
          nameArabic: c['custom_company_name_arabic'] as String?,
          phone: c['phone_no'] as String?,
          email: c['email'] as String?,
          logoUrl: c['company_logo'] as String?,
        );
        await _firestore.setCompany(model);
      }
    } catch (_) {}
  }

  Future<String?> pushRideToFrappe(RideRequestModel ride) async {
    try {
      final result = await _frappe.createBooking(
        pickup: ride.pickupLocation,
        dropoff: ride.dropoffLocation,
        date: ride.travelDate.toIso8601String().split('T').first,
        customerName: ride.passengerName,
        phone: ride.passengerPhone,
        passengers: ride.passengersCount,
        fare: ride.offeredPrice,
        vehicleType: ride.vehicleType,
        pickupLat: ride.pickupLat,
        pickupLng: ride.pickupLng,
        externalReference: ride.id,
        passengerList: ride.passengerRows.isNotEmpty
            ? ride.passengerRows
            : null,
        groupName: ride.groupName,
      );
      final frappeId = result['name'] as String?;
      return frappeId;
    } catch (e) {
      debugPrint('pushRideToFrappe failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> acceptBookingAsCaptain({
    required String booking,
    required double offeredFare,
    String? vehicle,
  }) {
    return _frappe.acceptBookingAsCaptain(
      booking: booking,
      offeredFare: offeredFare,
      vehicle: vehicle,
    );
  }

  Future<Map<String, dynamic>> completeTrip(TripModel trip) {
    return _frappe.completeAssignedTrip(
      trip: trip.frappeTripId,
      booking: trip.bookingId,
      operationId: 'complete:${trip.id}',
    );
  }

  void dispose() {
    stopSync();
  }
}
