import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _PlanCard(
            name: 'Basic',
            price: '﷼ 299/mo',
            features: ['5 Drivers max', '5 Vehicles max', 'Basic reports'],
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _PlanCard(
            name: 'Professional',
            price: '﷼ 799/mo',
            features: ['20 Drivers max', '20 Vehicles max', 'Advanced reports', 'API access'],
            color: AppColors.accent,
            popular: true,
          ),
          const SizedBox(height: 12),
          _PlanCard(
            name: 'Enterprise',
            price: '﷼ 1,999/mo',
            features: ['100 Drivers max', '100 Vehicles max', 'Full reports', 'API access', 'White label'],
            color: const Color(0xFFD4AF37),
          ),
        ]),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final List<String> features;
  final Color color;
  final bool popular;
  const _PlanCard({required this.name, required this.price, required this.features, required this.color, this.popular = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: popular ? Border.all(color: color, width: 2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              if (popular) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                child: Text('Most Popular', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(Icons.check_circle, size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                Text(f, style: const TextStyle(fontSize: 14)),
              ]),
            )),
          ]),
        ),
      ),
    );
  }
}
