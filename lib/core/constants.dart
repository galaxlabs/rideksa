class AppConstants {
  static const String appName = 'RideKSA';
  static const String appVersion = '0.0.8';
  static const String backendBaseUrl = 'https://ftms.galaxylabs.online';
  static const String defaultCurrency = 'SAR';
  static const double defaultVatRate = 15.0;
  static const double commissionRate = 0.05;

  // Play Integrity API: from Play Console > Setup > App integrity > Play Integrity API.
  // This is the Google Cloud project number linked to your Play app.
  static const String playIntegrityCloudProjectNumber = '482669449729';

  static const double minRidePrice = 10.0;
  static const double maxRidePrice = 50000.0;
  static const double testCreditAmount = 500.0;
  static const int cancelCutoffMinutes = 60;
  static const int firstReminderHoursBefore = 6;
  static const int earlyReminderIntervalMinutes = 30;
  static const int finalReminderHoursBefore = 1;
  static const int finalReminderIntervalMinutes = 15;
  static const int searchRadiusKm = 50;
  static const int driverRefreshIntervalSec = 30;
  static const int locationUpdateIntervalSec = 10;
  static const int maxOfferDurationMinutes = 30;

  static const String firestoreUsers = 'users';
  static const String firestoreDrivers = 'drivers';
  static const String firestoreActiveRides = 'active_rides';
  static const String firestoreActiveOffers = 'active_offers';
  static const String firestoreActiveTrips = 'active_trips';
  static const String firestoreCompanies = 'companies';
  static const String firestoreRoutes = 'routes';
  static const String firestoreWallets = 'wallets';
  static const String firestoreTransactions = 'transactions';
  static const String firestoreSubscriptions = 'subscriptions';
  static const String firestoreCommissions = 'commissions';
  static const String firestoreVehicles = 'vehicles';
  static const String firestoreContracts = 'contracts';
  static const String firestoreChatMessages = 'chat_messages';
  static const String firestoreGroupInvites = 'group_invites';
  static const String firestoreGroupMembers = 'group_members';
  static const String firestoreTripTransfers = 'trip_transfers';
}
