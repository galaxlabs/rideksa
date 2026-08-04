import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/ride_provider.dart';

class ActiveTripScreen extends StatefulWidget {
  final String tripId;
  const ActiveTripScreen({super.key, required this.tripId});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  @override
  void initState() {
    super.initState();
    final location = context.read<LocationProvider>();
    if (location.hasPermission) {
      location.startForegroundTracking();
    }
  }

  @override
  void dispose() {
    context.read<LocationProvider>().stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final trip = ride.activeTrip;

    return Scaffold(
      appBar: AppBar(title: const Text('Active Trip')),
      body: trip == null
          ? const Center(child: Text('No active trip'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(children: [
                    const Text('Trip in Progress', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(trip.pickupLocation, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Icon(Icons.arrow_downward, color: Colors.white60, size: 20),
                    Text(trip.dropoffLocation, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('﷼ ${trip.fare.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),
                Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                  _InfoRow(icon: Icons.person, label: 'Passenger', value: trip.passengerName ?? 'N/A'),
                  const Divider(),
                  _InfoRow(icon: Icons.directions_car, label: 'Vehicle', value: trip.vehiclePlate ?? 'N/A'),
                  const Divider(),
                  _InfoRow(icon: Icons.route, label: 'Distance', value: '${trip.distance.toStringAsFixed(1)} km'),
                  const Divider(),
                  _InfoRow(icon: Icons.payments, label: 'Driver Earnings', value: '﷼ ${(trip.fare * 0.95).toStringAsFixed(2)} (5% commission)'),
                  const Divider(),
                  _InfoRow(icon: Icons.star, label: 'Default Rating', value: '${trip.providerRating.toStringAsFixed(1)} / 5.0'),
                  const Divider(),
                  _InfoRow(icon: Icons.verified, label: 'Completion Verification', value: trip.providerCompleted && trip.customerCompleted ? 'Both confirmed' : 'Needs both sides'),
                ]))),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ride.markTripCompletion(widget.tripId, providerSide: true),
                    icon: const Icon(Icons.task_alt),
                    label: const Text('Mark Provider Side Complete'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showTransferDialog(context, trip.fare),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Sell / Transfer Trip'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<LocationProvider>().stopTracking();
                      ride.completeTrip(widget.tripId);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete Trip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ]),
            ),
    );
  }

  void _showTransferDialog(BuildContext context, double originalFare) {
    final sellRate = TextEditingController(text: originalFare.toStringAsFixed(0));
    final reason = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        final sell = double.tryParse(sellRate.text) ?? originalFare;
        final profit = sell > originalFare ? sell - originalFare : 0;
        final platformFee = profit * 0.05;
        return AlertDialog(
          title: const Text('Sell / Transfer Trip'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Original booking: ﷼ ${originalFare.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            TextField(controller: sellRate, keyboardType: TextInputType.number, onChanged: (_) => setDialogState(() {}), decoration: const InputDecoration(labelText: 'Sell Rate (﷼)', prefixIcon: Icon(Icons.payments))),
            const SizedBox(height: 12),
            TextField(controller: reason, maxLines: 2, decoration: const InputDecoration(labelText: 'Reason', hintText: 'Vehicle issue, unavailable, breakdown, etc.')),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.trending_up, label: 'Profit', value: '﷼ ${profit.toStringAsFixed(2)}'),
            _InfoRow(icon: Icons.percent, label: '5% fee on profit', value: '﷼ ${platformFee.toStringAsFixed(2)}'),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              final auth = context.read<AuthProvider>();
              await context.read<RideProvider>().createTripTransfer(
                sellerId: auth.user?.uid ?? 'provider',
                sellAmount: sell,
                reason: reason.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            }, child: const Text('Publish Transfer')),
          ],
        );
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
