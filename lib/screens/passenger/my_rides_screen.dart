import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../services/frappe_api_client.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});
  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  List<Map<String, dynamic>> _rides = [];
  bool _loading = true;
  String? _error;

  FrappeApiClient get _frappe => context.read<FrappeApiClient>();

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

  bool _canCancel(Map<String, dynamic> ride) {
    final status = ride['booking_status'] as String?;
    final negotiation = ride['negotiation_status'] as String?;
    if (status == 'Cancelled' || negotiation == 'Cancelled') return false;
    if (negotiation == 'Trip Created' || negotiation == 'Confirmed') return false;
    return true;
  }

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
      setState(() { _rides = bookings; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _cancel(Map<String, dynamic> ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this ride?'),
        content: Text('Your ride from ${ride['pickup_point'] ?? ride['route'] ?? ''} will be cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Ride')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Ride'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final name = ride['name'] as String?;
    if (name == null) return;
    try {
      await _frappe.cancelBooking(name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride cancelled'), backgroundColor: AppColors.success));
      _load();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancel failed: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
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
              : _rides.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No rides yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rides.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final ride = _rides[index];
                          final name = ride['name'] ?? '';
                          final status = ride['booking_status'] ?? ride['negotiation_status'] ?? '';
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => context.push('/passenger/ride-detail/${Uri.encodeComponent(name.toString())}'),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Expanded(child: Text(ride['booking_title']?.toString() ?? name.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: _statusColor(status).withAlpha(25), borderRadius: BorderRadius.circular(6)),
                                    child: Text(status, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600, fontSize: 12)),
                                  ),
                                ]),
                                const SizedBox(height: 12),
                                Row(children: [const Icon(Icons.trip_origin, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(ride['pickup_point'] ?? '', style: const TextStyle(fontSize: 14)))]),
                                const SizedBox(height: 4),
                                Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(ride['drop_point'] ?? '', style: const TextStyle(fontSize: 14)))]),
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(ride['booking_date']?.toString() ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.people, size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('${ride['passenger_count'] ?? ride['seat_count'] ?? 1}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ]),
                                if (ride['quoted_fare'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text('Fare: ﷼ ${ride['quoted_fare']}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                                ],
                                if (_canCancel(ride)) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _cancel(ride),
                                      icon: const Icon(Icons.cancel_outlined, size: 18),
                                      label: const Text('Cancel Ride'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: BorderSide(color: Colors.red.withAlpha(120)),
                                        minimumSize: const Size(0, 40),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                    ),
                                  ),
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
}
