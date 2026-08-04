import "package:go_router/go_router.dart";
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company / Travel Agent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout().then((_) => context.go( '/auth/login')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Grow Your Transport Business', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Manage contracts, group bookings, vehicles, drivers, and 5% platform fees', style: TextStyle(color: Colors.white.withAlpha(180))),
            ]),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.business_center, color: AppColors.primary),
              ),
              title: const Text('Setup company / travel agent profile'),
              subtitle: const Text('Add company details and first vehicle'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin/setup-company'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.accent.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.handshake, color: AppColors.accent),
              ),
              title: const Text('Create contract / group booking'),
              subtitle: const Text('Repeated trips with passenger names and route details'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin/contracts/new'),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _MenuCard(icon: Icons.people, label: 'Drivers', subtitle: 'Manage drivers', color: AppColors.primary, onTap: () => context.push( '/admin/drivers'))),
            const SizedBox(width: 12),
            Expanded(child: _MenuCard(icon: Icons.directions_car, label: 'Vehicles', subtitle: 'Add buses & cars', color: AppColors.accent, onTap: () => context.push('/admin/setup-company'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MenuCard(icon: Icons.percent, label: 'Commissions', subtitle: '5% per trip', color: const Color(0xFF2D9A5A), onTap: () => context.push( '/admin/commissions'))),
            const SizedBox(width: 12),
            Expanded(child: _MenuCard(icon: Icons.groups, label: 'Groups', subtitle: 'Contract trips', color: const Color(0xFFD4AF37), onTap: () => context.push('/admin/contracts/new'))),
          ]),
          const SizedBox(height: 24),
          Text('Quick Stats', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            _StatRow(label: 'Active Drivers', value: '0'),
            const Divider(),
            _StatRow(label: 'Active Vehicles', value: '0'),
            const Divider(),
            _StatRow(label: 'Today\'s Trips', value: '0'),
            const Divider(),
            _StatRow(label: 'Revenue (Today)', value: '﷼ 0'),
            const Divider(),
            _StatRow(label: 'Total Commission', value: '﷼ 0'),
          ]))),
        ]),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
