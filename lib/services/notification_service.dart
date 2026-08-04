import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/constants.dart';
import '../models/ride_request_model.dart';
import '../models/trip_model.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestore;
  final ValueNotifier<String?> alertMessage = ValueNotifier<String?>(null);
  final Map<String, List<Timer>> _reminderTimers = {};

  NotificationService(this._firestore);

  Future<String?> getFcmToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<void> requestPermission() async {
    try {
      await _messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
    } catch (_) {}
  }

  Future<void> updateFcmToken(String userId) async {
    final token = await getFcmToken();
    if (token != null) {
      await _firestore.updateUser(userId, {'fcm_token': token});
    }
  }

  void handleForegroundMessages(void Function(RemoteMessage msg) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  void handleNotificationTap(void Function(RemoteMessage msg) handler) {
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }

  Future<RemoteMessage?> getInitialMessage() async {
    return _messaging.getInitialMessage();
  }

  void showRideOpportunity(RideRequestModel ride) {
    _ring();
    alertMessage.value = 'New ${ride.vehicleType} request: ${ride.pickupLocation} to ${ride.dropoffLocation}';
  }

  void scheduleTripReminders(TripModel trip) {
    _cancelReminders(trip.id);
    final timers = <Timer>[];
    final now = DateTime.now();
    final start = trip.departureTime;
    if (start == null) return;

    void addReminder(DateTime at, String message) {
      final delay = at.difference(now);
      if (delay.isNegative) return;
      timers.add(Timer(delay, () {
        _ring();
        alertMessage.value = message;
      }));
    }

    var early = start.subtract(const Duration(hours: AppConstants.firstReminderHoursBefore));
    final finalWindow = start.subtract(const Duration(hours: AppConstants.finalReminderHoursBefore));
    while (early.isBefore(finalWindow)) {
      addReminder(early, 'Trip reminder: ${_timeLeft(start)} remaining for ${trip.pickupLocation}.');
      early = early.add(const Duration(minutes: AppConstants.earlyReminderIntervalMinutes));
    }

    var finalReminder = finalWindow;
    while (finalReminder.isBefore(start)) {
      addReminder(finalReminder, 'Final trip reminder: ${_timeLeft(start)} remaining. Prepare vehicle and passengers.');
      finalReminder = finalReminder.add(const Duration(minutes: AppConstants.finalReminderIntervalMinutes));
    }

    _reminderTimers[trip.id] = timers;
  }

  void notifyTransferOpportunity(String message) {
    _ring();
    alertMessage.value = message;
  }

  void showRideCompleted(String tripId, double fare, String? dropoff) {
    _ring();
    alertMessage.value = 'Ride complete! Driver dropped you at ${dropoff ?? 'your destination'}. Fare charged ﷼ ${fare.toStringAsFixed(2)}.';
  }

  void showPaymentVerified(double amount) {
    _ring();
    alertMessage.value = 'Payment verified! Your bank transfer of ﷼ ${amount.toStringAsFixed(2)} was confirmed and your wallet has been credited.';
  }

  void _cancelReminders(String tripId) {
    for (final timer in _reminderTimers[tripId] ?? <Timer>[]) {
      timer.cancel();
    }
    _reminderTimers.remove(tripId);
  }

  void _ring() {
    SystemSound.play(SystemSoundType.alert);
  }

  String _timeLeft(DateTime start) {
    final left = start.difference(DateTime.now());
    if (left.inHours >= 1) return '${left.inHours}h ${left.inMinutes % 60}m';
    return '${left.inMinutes}m';
  }
}
