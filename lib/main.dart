import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import 'services/app_config_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/frappe_api_client.dart';
import 'services/firestore_service.dart';
import 'services/sync_service.dart';
import 'services/wallet_service.dart';
import 'services/notification_service.dart';
import 'services/http_client.dart';
import 'services/integrity_service.dart';
import 'services/location_service.dart';
import 'services/bank_notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/ride_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/location_provider.dart';
import 'widgets/app_alert_listener.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: AppConfigService.instance.firebaseOptions,
  );
}

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (!kIsWeb && Firebase.apps.isNotEmpty) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        if (!kDebugMode && !kIsWeb && Firebase.apps.isNotEmpty) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        }
        debugPrint('PLATFORM ERROR: $error');
        debugPrintStack(stackTrace: stack);
        return false;
      };
      await AppConfigService.instance.load();
      try {
        await Firebase.initializeApp(
          options: AppConfigService.instance.firebaseOptions,
        );
        if (!kIsWeb) {
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
            !kDebugMode,
          );
        }
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      } catch (e) {
        debugPrint('FIREBASE INIT ERROR: $e');
      }
      runApp(const _Providers());
    },
    (error, stack) {
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } else {
        debugPrint('ZONE ERROR: $error');
        debugPrintStack(stackTrace: stack);
      }
    },
  );
}

class _Providers extends StatelessWidget {
  const _Providers();

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final frappe = FrappeApiClient(client: createFrappeHttpClient());
    final authService = AuthService(firestore, frappe);
    final locationService = LocationService();
    final syncService = SyncService(firestore, frappe);
    final walletService = WalletService(firestore);
    final notificationService = NotificationService(firestore, frappe);
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
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, firestore, syncService),
        ),
        ChangeNotifierProvider(
          create: (_) => RideProvider(
            firestore,
            syncService,
            walletService,
            locationService,
            notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              DriverProvider(firestore, locationService, notificationService),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(walletService, firestore),
        ),
        ChangeNotifierProvider(
          create: (_) => LocationProvider(locationService),
        ),
      ],
      child: const AppAlertListener(
        child: AppDependencies(child: RideKSAApp()),
      ),
    );
  }
}
