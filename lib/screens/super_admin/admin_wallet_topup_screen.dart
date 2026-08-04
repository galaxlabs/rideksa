import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/wallet_service.dart';

class AdminWalletTopUpScreen extends StatefulWidget {
  const AdminWalletTopUpScreen({super.key});

  @override
  State<AdminWalletTopUpScreen> createState() => _AdminWalletTopUpScreenState();
}

class _AdminWalletTopUpScreenState extends State<AdminWalletTopUpScreen> {
  final _userId = TextEditingController();
  final _amount = TextEditingController(text: '500');
  final _reference = TextEditingController(text: 'ADMIN_TEST_CREDIT');
  String _role = 'passenger';
  bool _saving = false;

  @override
  void dispose() {
    _userId.dispose();
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _topUp() async {
    final userId = _userId.text.trim();
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (userId.isEmpty || amount <= 0) return;
    setState(() => _saving = true);
    await context.read<WalletService>().getOrCreateWallet(userId, _role);
    await context.read<WalletService>().topUp(
      userId,
      amount,
      paymentMethod: 'admin_test_credit',
      paymentRef: _reference.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallet credited and transaction completed'), backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Wallet Top Up')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: AppColors.primary.withAlpha(12), child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text('For testing, admin can credit user wallets directly. Production Saudi payments should verify gateway/bank callback first, then credit wallet after transaction status is completed.', style: TextStyle(color: AppColors.textSecondary)),
        )),
        const SizedBox(height: 16),
        TextField(controller: _userId, decoration: const InputDecoration(labelText: 'User ID / Firebase UID', prefixIcon: Icon(Icons.person_search))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _role,
          decoration: const InputDecoration(labelText: 'Wallet Role', prefixIcon: Icon(Icons.account_circle)),
          items: const [
            DropdownMenuItem(value: 'passenger', child: Text('Passenger')),
            DropdownMenuItem(value: 'driver', child: Text('Driver')),
            DropdownMenuItem(value: 'travelAgent', child: Text('Travel Agent')),
            DropdownMenuItem(value: 'admin', child: Text('Company Admin')),
          ],
          onChanged: (v) => setState(() => _role = v ?? _role),
        ),
        const SizedBox(height: 12),
        TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (﷼)', prefixIcon: Icon(Icons.payments))),
        const SizedBox(height: 12),
        TextField(controller: _reference, decoration: const InputDecoration(labelText: 'Reference', prefixIcon: Icon(Icons.receipt_long))),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _saving ? null : _topUp, child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Credit Wallet')),
      ]),
    );
  }
}
