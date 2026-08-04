import 'package:flutter/material.dart';
import '../../core/theme.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Earnings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              const Text('﷼ 0', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                Column(children: [
                  const Text('This Week', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Text('﷼ 0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
                Column(children: [
                  const Text('This Month', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Text('﷼ 0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Recent Trips', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text('Commission: 5% / trip', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Column(children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondary.withAlpha(80)),
            const SizedBox(height: 8),
            Text('No trips completed yet', style: TextStyle(color: AppColors.textSecondary.withAlpha(150))),
          ])))),
        ]),
      ),
    );
  }
}
