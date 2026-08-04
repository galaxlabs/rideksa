import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_sidebar.dart';

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      drawer: AppSidebar(currentPath: '/passenger'),
      appBar: AppBar(
        leading: Builder(builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        )),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(AppConstants.appName),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.wallet_outlined),
            onPressed: () => context.push('/passenger/wallet'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.logout().then((_) => context.go('/auth/login'))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome${auth.user?.displayName != null ? ', ${auth.user!.displayName}' : ''}!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Choose a city, set GPS pickup, or book a group trip.', style: TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => context.push( '/passenger/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Row(children: [
                    Icon(Icons.search, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Search city routes or use your current location...', style: TextStyle(color: AppColors.textSecondary)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Row(children: [
            _QuickActionCard(icon: Icons.search, label: 'Search\nRoutes', onTap: () => context.push( '/passenger/search')),
            const SizedBox(width: 12),
            _QuickActionCard(icon: Icons.groups, label: 'Book\nGroup', onTap: () => context.push('/passenger/book')),
            const SizedBox(width: 12),
            _QuickActionCard(icon: Icons.account_balance_wallet, label: 'Wallet\nBalance', onTap: () => context.push( '/passenger/wallet')),
          ]),
          const SizedBox(height: 24),
          Text('Recent Rides', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Column(children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary.withAlpha(80)),
            const SizedBox(height: 8),
            Text('No rides yet. Book your first ride!', style: TextStyle(color: AppColors.textSecondary.withAlpha(150))),
          ])))),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) context.push( '/passenger/my-rides');
          if (i == 2) context.push( '/passenger/history');
          if (i == 3) context.push( '/passenger/wallet');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.primary), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary), label: 'Rides'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history, color: AppColors.primary), label: 'History'),
          NavigationDestination(icon: Icon(Icons.wallet_outlined), selectedIcon: Icon(Icons.wallet, color: AppColors.primary), label: 'Wallet'),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.primary.withAlpha(15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ])),
        ),
      ),
    );
  }
}
