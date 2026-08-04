import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/role_select_screen.dart';
import '../screens/passenger/home_screen.dart';
import '../screens/passenger/search_screen.dart';
import '../screens/passenger/book_ride_screen.dart';
import '../screens/passenger/my_rides_screen.dart';
import '../screens/passenger/booking_detail_screen.dart';
import '../screens/passenger/history_screen.dart';
import '../screens/passenger/invoices_screen.dart';
import '../screens/passenger/notifications_screen.dart';
import '../screens/passenger/groups_screen.dart';
import '../screens/passenger/bookings_screen.dart';
import '../screens/passenger/chat_list_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/update_screen.dart';
import '../screens/passenger/wallet_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/chat/ride_chat_screen.dart';
import '../screens/group/join_group_ride_screen.dart';
import '../screens/driver/dashboard_screen.dart';
import '../screens/driver/nearby_rides_screen.dart';
import '../screens/driver/active_trip_screen.dart';
import '../screens/driver/earnings_screen.dart';
import '../screens/driver/vehicles_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/company_setup_screen.dart';
import '../screens/admin/contract_booking_screen.dart';
import '../screens/admin/driver_management_screen.dart';
import '../screens/admin/commission_settings_screen.dart';
import '../screens/super_admin/super_dashboard_screen.dart';
import '../screens/super_admin/company_list_screen.dart';
import '../screens/super_admin/subscription_plans_screen.dart';
import '../screens/super_admin/admin_wallet_topup_screen.dart';
import '../screens/setup_guide_screen.dart';

final GlobalKey<NavigatorState> _rootNavigator = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    navigatorKey: _rootNavigator,
    initialLocation: '/auth/login',
    refreshListenable: auth,
    errorBuilder: (context, state) => AppRouteErrorScreen(error: state.error),
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final location = state.matchedLocation;
      final onAuthPage = location.startsWith('/auth');
      final publicInvite = location.startsWith('/join/');
      if (publicInvite) return null;
      if (location == '/auth/role-select') return '/auth/login';
      if (!loggedIn && !onAuthPage) return '/auth/login';
      if (loggedIn && onAuthPage) {
        final role = auth.user?.role;
        if (role == UserRole.passenger) return '/passenger';
        if (role == UserRole.driver) return '/driver';
        if (role == UserRole.customerCompany ||
            role == UserRole.partnerCompany ||
            role == UserRole.admin ||
            role == UserRole.travelAgent)
          return '/admin';
        if (role == UserRole.superAdmin) return '/super-admin';
        return '/auth/role-select';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) => OTPSCreen(phone: state.extra as String),
      ),
      GoRoute(
        path: '/auth/role-select',
        builder: (_, __) => const RoleSelectScreen(),
      ),

      GoRoute(
        path: '/passenger',
        builder: (_, __) => const PassengerHomeScreen(),
      ),
      GoRoute(
        path: '/passenger/search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/passenger/book',
        builder: (_, state) =>
            BookRideScreen(routeExtra: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: '/passenger/my-rides',
        builder: (_, __) => const MyRidesScreen(),
      ),
      GoRoute(
        path: '/passenger/ride-detail/:name',
        builder: (_, state) => BookingDetailScreen(
          bookingName: state.pathParameters['name'] ?? '',
        ),
      ),
      GoRoute(
        path: '/passenger/history',
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/passenger/invoices',
        builder: (_, __) => const InvoicesScreen(),
      ),
      GoRoute(
        path: '/passenger/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/passenger/groups',
        builder: (_, __) => const GroupsScreen(),
      ),
      GoRoute(
        path: '/passenger/bookings',
        builder: (_, __) => const BookingsScreen(),
      ),
      GoRoute(
        path: '/passenger/chat',
        builder: (_, __) => const ChatListScreen(),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/update', builder: (_, __) => const UpdateScreen()),
      GoRoute(
        path: '/passenger/wallet',
        builder: (_, __) => const WalletScreen(),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
        path: '/chat/:rideId',
        builder: (_, state) =>
            RideChatScreen(rideRequestId: state.pathParameters['rideId'] ?? ''),
      ),
      GoRoute(
        path: '/join/:inviteId',
        builder: (_, state) => JoinGroupRideScreen(
          inviteId: state.pathParameters['inviteId'] ?? '',
        ),
      ),

      GoRoute(
        path: '/driver',
        builder: (_, __) => const DriverDashboardScreen(),
      ),
      GoRoute(
        path: '/driver/nearby',
        builder: (_, __) => const NearbyRidesScreen(),
      ),
      GoRoute(
        path: '/driver/active-trip',
        builder: (_, state) => ActiveTripScreen(tripId: state.extra as String),
      ),
      GoRoute(
        path: '/driver/earnings',
        builder: (_, __) => const EarningsScreen(),
      ),
      GoRoute(
        path: '/driver/vehicles',
        builder: (_, __) => const DriverVehiclesScreen(),
      ),

      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(
        path: '/admin/setup-company',
        builder: (_, __) => const CompanySetupScreen(),
      ),
      GoRoute(
        path: '/admin/contracts/new',
        builder: (_, __) => const ContractBookingScreen(),
      ),
      GoRoute(
        path: '/admin/drivers',
        builder: (_, __) => const DriverManagementScreen(),
      ),
      GoRoute(
        path: '/admin/commissions',
        builder: (_, __) => const CommissionSettingsScreen(),
      ),

      GoRoute(path: '/setup', builder: (_, __) => const SetupGuideScreen()),
      GoRoute(
        path: '/super-admin',
        builder: (_, __) => const SuperDashboardScreen(),
      ),
      GoRoute(
        path: '/super-admin/companies',
        builder: (_, __) => const CompanyListScreen(),
      ),
      GoRoute(
        path: '/super-admin/subscriptions',
        builder: (_, __) => const SubscriptionPlansScreen(),
      ),
      GoRoute(
        path: '/super-admin/wallet-topup',
        builder: (_, __) => const AdminWalletTopUpScreen(),
      ),
    ],
  );
}

class AppRouteErrorScreen extends StatelessWidget {
  final Exception? error;
  const AppRouteErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Something went wrong'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/passenger'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'This page could not be opened.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'Please go back and try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/passenger'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Go Home'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/settings'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
