import "package:go_router/go_router.dart";
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class SuperDashboardScreen extends StatelessWidget {
  const SuperDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
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
              const Text('Platform Overview', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Manage all companies, subscriptions & platform settings', style: TextStyle(color: Colors.white.withAlpha(180))),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _SuperCard(icon: Icons.business, label: 'Companies', value: '0', color: AppColors.primary, onTap: () => context.push( '/super-admin/companies'))),
            const SizedBox(width: 12),
            Expanded(child: _SuperCard(icon: Icons.subscriptions, label: 'Subscriptions', value: '0', color: AppColors.accent, onTap: () => context.push( '/super-admin/subscriptions'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _SuperCard(icon: Icons.people, label: 'Total Drivers', value: '0', color: const Color(0xFF2D9A5A), onTap: () {})),
            const SizedBox(width: 12),
            Expanded(child: _SuperCard(icon: Icons.trending_up, label: 'Revenue', value: '﷼ 0', color: const Color(0xFFD4AF37), onTap: () {})),
          ]),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
              title: const Text('Admin Wallet Top Up'),
              subtitle: const Text('Credit passenger/agent/driver wallets for testing'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/super-admin/wallet-topup'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Platform Stats', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            _StatRow(label: 'Active Companies', value: '0'),
            const Divider(),
            _StatRow(label: 'Active Subscriptions', value: '0'),
            const Divider(),
            _StatRow(label: 'Total Trips (All)', value: '0'),
            const Divider(),
            _StatRow(label: 'Platform Revenue', value: '﷼ 0'),
          ]))),
        ]),
      ),
    );
  }
}

class _SuperCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  const _SuperCard({required this.icon, required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22)),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
