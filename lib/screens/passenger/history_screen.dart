import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/frappe_api_client.dart';
import '../../widgets/sidebar_page.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _trips = [];
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
      final trips = await _frappe.getMyTrips();
      if (!mounted) return;
      setState(() { _trips = trips; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarPage(
      title: 'History',
      path: '/passenger/history',
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
              : _trips.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No trip history yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _trips.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final trip = _trips[index];
                          return Card(
                            child: ListTile(
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: AppColors.primary.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.directions_bus, color: AppColors.primary, size: 20),
                              ),
                              title: Text(trip['trip_title']?.toString() ?? trip['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${trip['trip_date'] ?? ''}  •  ${trip['route'] ?? '—'}'),
                              trailing: Text(trip['trip_status']?.toString() ?? '', style: TextStyle(color: _statusColor(trip['trip_status']?.toString()), fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'Completed': return AppColors.success;
      case 'inProgress': return Colors.teal;
      case 'Cancelled': return Colors.red;
      case 'Scheduled': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
