import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/wallet_model.dart';

class WalletCard extends StatelessWidget {
  final WalletModel wallet;
  const WalletCard({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Text('﷼ ${wallet.balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Column(children: [
            const Text('Earned', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text('﷼ ${wallet.totalEarned.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          Column(children: [
            const Text('Spent', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text('﷼ ${wallet.totalSpent.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
        ]),
      ]),
    );
  }
}
