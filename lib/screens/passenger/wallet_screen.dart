import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/frappe_api_client.dart';
import '../../widgets/sidebar_page.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _subscribed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribed) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<WalletProvider>().subscribe(user.uid, user.role.name);
        _subscribed = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    return SidebarPage(
      title: 'My Wallet',
      path: '/passenger/wallet',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Wallet Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wallet.balanceFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showTopUpDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Top Up'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total: ${wallet.transactions.length}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (wallet.transactions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: AppColors.textSecondary.withAlpha(80),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: AppColors.textSecondary.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...wallet.transactions.map(
                (tx) => Card(
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tx.type.name == 'credit'
                            ? AppColors.success.withAlpha(20)
                            : Colors.red.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        tx.type.name == 'credit'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: tx.type.name == 'credit'
                            ? AppColors.success
                            : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      tx.description?.split('\n').first ?? tx.reason.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${tx.createdAt.toString().split(' ').first} • ${tx.status.name}',
                    ),
                    trailing: Text(
                      tx.amountFormatted,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tx.type.name == 'credit'
                            ? AppColors.success
                            : Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTopUpDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final frappe = context.read<FrappeApiClient>();
    final isAdmin = auth.user?.role.name == 'superAdmin' ||
        auth.user?.role.name == 'admin';
    final controller = TextEditingController();
    var paymentMethod = 'moyaser';
    var processing = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Top Up Wallet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (﷼)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'moyaser',
                      child: Text('Moyasser (Card / Mada / Apple Pay)'),
                    ),
                    if (isAdmin)
                      const DropdownMenuItem(
                        value: 'test_credit',
                        child: Text('Test Credit (Admin only)'),
                      ),
                  ],
                  onChanged: (v) => setDialogState(
                    () => paymentMethod = v ?? paymentMethod,
                  ),
                ),
                const SizedBox(height: 12),
                if (paymentMethod == 'moyaser')
                  const Text(
                    'You will be redirected to Moyasser to complete payment securely.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                if (paymentMethod == 'test_credit')
                  const Text(
                    'Instantly credits your wallet without real payment (testing only).',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                if (processing)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: processing
                  ? null
                  : () async {
                      final amt = double.tryParse(controller.text) ?? 0;
                      if (amt <= 0) return;
                      if (paymentMethod == 'test_credit') {
                        Navigator.pop(ctx);
                        context.read<WalletProvider>().topUp(
                          amt,
                          paymentMethod: 'test_wallet',
                        );
                        return;
                      }
                      setDialogState(() => processing = true);
                      try {
                        final result = await frappe.createMoyasserPayment(
                          amount: amt,
                          description: 'RideKSA wallet top-up',
                        );
                        final url = result['payment_url']?.toString() ?? '';
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (url.isNotEmpty) {
                          await launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Complete payment in the browser. Your wallet will credit automatically.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() => processing = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Payment failed: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Proceed'),
            ),
          ],
        ),
      ),
    );
  }
}
