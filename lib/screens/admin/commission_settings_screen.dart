import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class CommissionSettingsScreen extends StatelessWidget {
  const CommissionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commission Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withAlpha(30)),
            ),
            child: Column(children: [
              const Icon(Icons.percent, color: AppColors.primary, size: 40),
              const SizedBox(height: 12),
              Text('Commission Rate: ${(AppConstants.commissionRate * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 4),
              const Text('Fixed rate on every completed trip', style: TextStyle(color: AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(height: 24),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Commission Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const _DetailRow(label: 'Rate Type', value: 'Fixed Percentage'),
            const Divider(),
            const _DetailRow(label: 'Rate', value: '5%'),
            const Divider(),
            const _DetailRow(label: 'No Cap', value: 'Unlimited'),
            const Divider(),
            const _DetailRow(label: 'Applies To', value: 'All Completed Trips'),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Revenue Distribution', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const _DetailRow(label: 'Driver', value: '95%'),
            const Divider(),
            const _DetailRow(label: 'Company', value: '5%'),
          ]))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withAlpha(40)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(child: Text('Commission is deducted from the fare before payout to driver. Rate is fixed at ${(AppConstants.commissionRate * 100).toStringAsFixed(0)}% with no maximum limit.', style: TextStyle(color: AppColors.warning.withAlpha(200), fontSize: 13))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
