import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/frappe_api_client.dart';
import '../../widgets/sidebar_page.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
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
      final bookings = await _frappe.getMyBookings();
      if (!mounted) return;
      setState(() { _bookings = bookings; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarPage(
      title: 'Bookings',
      path: '/passenger/bookings',
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
              : _bookings.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.event_note_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No bookings yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final b = _bookings[index];
                          final status = b['booking_status'] ?? b['negotiation_status'] ?? '';
                          return Card(
                            child: InkWell(
                              onTap: () => context.push('/passenger/ride-detail/${Uri.encodeComponent(b['name'].toString())}'),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Text(b['booking_title']?.toString() ?? b['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: _statusColor(status).withAlpha(25), borderRadius: BorderRadius.circular(6)),
                                      child: Text(status.toString(), style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600, fontSize: 12)),
                                    ),
                                  ]),
                                  const SizedBox(height: 10),
                                  Text('${b['pickup_point'] ?? ''} → ${b['drop_point'] ?? ''}', style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Text(b['booking_date']?.toString() ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    const SizedBox(width: 16),
                                    Text('${b['vehicle_type'] ?? ''}  •  ${b['passenger_count'] ?? 1} pax', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  ]),
                                  if (b['quoted_fare'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text('Fare: ﷼ ${b['quoted_fare']}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                                  ],
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'Draft': return Colors.blue;
      case 'Pending': return Colors.orange;
      case 'Awaiting Offers': return Colors.orange;
      case 'Accepted': return Colors.green;
      case 'Confirmed': return AppColors.success;
      case 'Trip Created': return AppColors.success;
      case 'inProgress': return Colors.teal;
      case 'Completed': return AppColors.success;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
