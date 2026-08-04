import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../services/frappe_api_client.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingName;
  const BookingDetailScreen({super.key, required this.bookingName});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Map<String, dynamic>? _booking;
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final booking = await _frappe.getBookingDetail(widget.bookingName);
      if (!mounted) return;
      setState(() { _booking = booking; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  bool get _canCancel {
    final b = _booking;
    if (b == null) return false;
    final status = b['booking_status'] as String?;
    final negotiation = b['negotiation_status'] as String?;
    if (status == 'Cancelled' || negotiation == 'Cancelled') return false;
    if (negotiation == 'Trip Created' || negotiation == 'Confirmed') return false;
    return true;
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this ride?'),
        content: const Text('This will cancel the booking. Depending on the policy, a penalty may apply.'),
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
    try {
      await _frappe.cancelBooking(widget.bookingName);
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
      appBar: AppBar(title: const Text('Ride Details')),
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
              : _booking == null
                  ? const Center(child: Text('Booking not found'))
                  : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    final b = _booking!;
    final status = (b['booking_status'] ?? b['negotiation_status'] ?? '').toString();
    final passengers = (b['passengers'] as List?) ?? [];
    final offers = (b['offers'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(b['booking_title']?.toString() ?? b['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _statusColor(status).withAlpha(25), borderRadius: BorderRadius.circular(6)),
                    child: Text(status, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ]),
                if (b['booking_group_code'] != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.group, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Group: ${b['booking_group_code']}', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                  ]),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Route',
            child: Column(children: [
              _row(Icons.trip_origin, 'Pickup', b['pickup_point'] ?? ''),
              _row(Icons.location_on, 'Drop-off', b['drop_point'] ?? ''),
              _row(Icons.route, 'Route', b['route'] ?? '—'),
            ]),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Details',
            child: Column(children: [
              _row(Icons.calendar_today, 'Date', b['booking_date']?.toString() ?? ''),
              _row(Icons.directions_car, 'Vehicle', b['vehicle_type'] ?? '—'),
              _row(Icons.people, 'Passengers', '${b['passenger_count'] ?? b['seat_count'] ?? 1}'),
              _row(Icons.schedule, 'Negotiation', b['negotiation_status'] ?? '—'),
            ]),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Fare',
            child: Column(children: [
              if (b['quoted_fare'] != null) _row(Icons.attach_money, 'Quoted Fare', '﷼ ${b['quoted_fare']}'),
              if (b['minimum_offer_fare'] != null) _row(Icons.trending_down, 'Minimum Offer', '﷼ ${b['minimum_offer_fare']}'),
              if (b['maximum_offer_fare'] != null) _row(Icons.trending_up, 'Maximum Offer', '﷼ ${b['maximum_offer_fare']}'),
              if (b['platform_fee_amount'] != null) _row(Icons.percent, 'Platform Fee', '﷼ ${b['platform_fee_amount']}'),
              if (b['payment_status'] != null) _row(Icons.payment, 'Payment', b['payment_status'].toString()),
            ]),
          ),
          if (passengers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Passengers (${passengers.length})',
              child: Column(children: passengers.map<Widget>((p) {
                final name = p['passenger_name'] ?? 'Passenger';
                final docType = p['document_type'] ?? '';
                final docNo = p['document_number'] ?? '';
                final nationality = p['nationality'] ?? '';
                final mobile = p['mobile_no'] ?? '';
                final doc = [docType, docNo].where((e) => e.toString().isNotEmpty).join(': ');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text([nationality, mobile, doc].where((e) => e.isNotEmpty).join('  •  '), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ])),
                  ]),
                );
              }).toList()),
            ),
          ],
          if (offers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Offers (${offers.length})',
              child: Column(children: offers.map<Widget>((o) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.local_taxi, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${o['vehicle'] ?? 'Vehicle'}  •  ${o['captain_user'] ?? ''}', style: const TextStyle(fontSize: 13))),
                    Text('﷼ ${o['offered_fare'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ]),
                );
              }).toList()),
            ),
          ],
          if (b['notes'] != null && b['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(title: 'Notes', child: Text(b['notes'].toString())),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/chat/${widget.bookingName}'),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Chat'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
              ),
            ),
            if (_canCancel) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cancel,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withAlpha(120)),
                    minimumSize: const Size(0, 46),
                  ),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ]),
      ),
    );
  }
}
