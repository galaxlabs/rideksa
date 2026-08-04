import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/app_config_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/frappe_api_client.dart';
import 'services/location_service.dart';
import 'services/sync_service.dart';
import 'services/wallet_service.dart';
import 'services/commission_service.dart';
import 'services/notification_service.dart';
import 'services/integrity_service.dart';
import 'services/bank_notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/ride_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/location_provider.dart';
import 'widgets/app_alert_listener.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PLATFORM ERROR: $error');
      debugPrintStack(stackTrace: stack);
      return false;
    };
    await AppConfigService.instance.load();
    try {
      await Firebase.initializeApp(
        options: AppConfigService.instance.firebaseOptions,
      );
    } catch (e) {
      debugPrint('FIREBASE INIT ERROR: $e');
    }
    runApp(const _Providers());
  }, (error, stack) {
    debugPrint('ZONE ERROR: $error');
    debugPrintStack(stackTrace: stack);
  });
}

class _Providers extends StatelessWidget {
  const _Providers({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final frappe = FrappeApiClient();
    final authService = AuthService(firestore, frappe);
    final locationService = LocationService();
    final syncService = SyncService(firestore, frappe);
    final walletService = WalletService(firestore);
    final commissionService = CommissionService(firestore);
    final notificationService = NotificationService(firestore);
    final integrityService = IntegrityService(frappe);
    final bankNotificationService = BankNotificationService(firestore);
    bankNotificationService.startListening();

    return MultiProvider(
      providers: [
        Provider<FirestoreService>.value(value: firestore),
        Provider<FrappeApiClient>.value(value: frappe),
        Provider<WalletService>.value(value: walletService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<IntegrityService>.value(value: integrityService),
        Provider<BankNotificationService>.value(value: bankNotificationService),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService, firestore, syncService)),
        ChangeNotifierProvider(create: (_) => RideProvider(firestore, syncService, walletService, commissionService, locationService, notificationService)),
        ChangeNotifierProvider(create: (_) => DriverProvider(firestore, locationService, notificationService)),
        ChangeNotifierProvider(create: (_) => WalletProvider(walletService, firestore)),
        ChangeNotifierProvider(create: (_) => LocationProvider(locationService)),
      ],
      child: const AppAlertListener(
        child: AppDependencies(
          child: RideKSAApp(),
        ),
      ),
    );
  }
}
