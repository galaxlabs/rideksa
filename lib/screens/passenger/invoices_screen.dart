import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/frappe_api_client.dart';
import '../../widgets/sidebar_page.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});
  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _loading = true;
  String? _error;

  FrappeApiClient get _frappe => context.read<FrappeApiClient>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final invoices = await _frappe.getMyInvoices();
      if (!mounted) return;
      setState(() { _invoices = invoices; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarPage(
      title: 'Invoices',
      path: '/passenger/invoices',
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : _invoices.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No invoices yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _invoices.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final inv = _invoices[index];
                          final status = inv['status']?.toString() ?? '';
                          return Card(
                            child: ListTile(
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: AppColors.primary.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.receipt, color: AppColors.primary, size: 20),
                              ),
                              title: Text(inv['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${inv['invoice_date'] ?? ''}  •  ${inv['customer'] ?? '—'}'),
                              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('﷼ ${inv['grand_total'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                Text(status, style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Paid': return AppColors.success;
      case 'Submitted': return Colors.teal;
      case 'Draft': return Colors.blue;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
