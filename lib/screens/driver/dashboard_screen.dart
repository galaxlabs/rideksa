import "package:go_router/go_router.dart";
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/ride_provider.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});
  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final driver = context.read<DriverProvider>();
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      driver.subscribeToProfile(auth.user!.uid);
      driver.subscribeToNearbyRides();
      context.read<RideProvider>().subscribeToDriverActiveTrip(auth.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>();
    final auth = context.watch<AuthProvider>();
    final activeTrip = context.watch<RideProvider>().activeTrip;
    final isOnline = driver.isOnline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          Switch(
            value: isOnline,
            activeColor: AppColors.success,
            onChanged: (v) => driver.setOnline(v),
          ),
          IconButton(
            icon: const Icon(Icons.directions_car),
            tooltip: 'My vehicles',
            onPressed: () => context.push('/driver/vehicles'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                auth.logout().then((_) => context.go('/auth/login')),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppColors.success.withAlpha(20)
                      : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOnline
                        ? AppColors.success.withAlpha(60)
                        : Colors.grey.withAlpha(40),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? AppColors.success : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isOnline
                          ? 'You are online — receiving ride requests'
                          : 'Go online to receive ride requests',
                      style: TextStyle(
                        color: isOnline ? AppColors.success : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (activeTrip != null) ...[
                ElevatedButton.icon(
                  onPressed: () =>
                      context.go('/driver/active-trip/${activeTrip.id}'),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Resume Active Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  _StatCard(
                    icon: Icons.inbox,
                    label: 'Nearby Rides',
                    value: '${driver.nearbyRides.length}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.star,
                    label: 'Rating',
                    value:
                        '${driver.profile?.rating.toStringAsFixed(1) ?? '5.0'}',
                    color: const Color(0xFFD4AF37),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    icon: Icons.trending_up,
                    label: 'Trips',
                    value: '${driver.profile?.totalTrips ?? 0}',
                    color: const Color(0xFF2D9A5A),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.account_balance_wallet,
                    label: 'Earnings',
                    value:
                        '﷼ ${driver.profile?.totalEarnings.toStringAsFixed(0) ?? '0'}',
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nearby Ride Requests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (driver.nearbyRides.isNotEmpty)
                    Text(
                      'RINGING: ${driver.nearbyRides.length} rides',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (driver.nearbyRides.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 40,
                            color: AppColors.textSecondary.withAlpha(100),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No ride requests nearby',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...driver.nearbyRides.map((ride) => _RideCard(ride: ride)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) context.push('/driver/nearby');
          if (i == 2) context.push('/driver/earnings');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppColors.primary),
            label: 'Nearby',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up, color: AppColors.primary),
            label: 'Earnings',
          ),
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final dynamic ride;
  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.passengerName ??
                              ride.serviceType.replaceAll('_', ' '),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          ride.serviceType == 'pick_drop'
                              ? '${ride.routineCategory ?? 'routine'} • ${ride.pickupTime ?? '-'}-${ride.dropoffTime ?? '-'}'
                              : ride.vehicleType,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '﷼ ${ride.offeredPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trip_origin,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ride.pickupLocation,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ride.dropoffLocation,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final provider = context.read<RideProvider>();
                          final offer = await provider.makeOffer(
                            rideRequestId: ride.id,
                            driverId: auth.user?.uid ?? 'driver',
                            driverName: auth.user?.displayName,
                            offererType: auth.user?.companyId == null
                                ? 'driver'
                                : 'company',
                            companyId: auth.user?.companyId,
                            vehicleType: ride.vehicleType,
                            seatCapacity: ride.seatsRequired,
                            price: ride.offeredPrice,
                            message: 'Accepted from realtime alert',
                          );
                          await provider.acceptOffer(ride.id, offer);
                          if (context.mounted) {
                            final tripId = provider.activeTrip?.id;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ride accepted. It is removed from market.',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            if (tripId != null) {
                              context.go('/driver/active-trip/$tripId');
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ride declined locally. It may still appear if open market.',
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
