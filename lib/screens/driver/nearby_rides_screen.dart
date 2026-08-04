import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/ride_provider.dart';

class NearbyRidesScreen extends StatelessWidget {
  const NearbyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Rides')),
      body: driver.nearbyRides.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.explore_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No nearby rides', style: TextStyle(color: Colors.grey, fontSize: 16)),
              SizedBox(height: 8),
              Text('Go online to see ride requests near you', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: driver.nearbyRides.length,
              separatorBuilder: (_, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ride = driver.nearbyRides[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.person, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(ride.passengerName ?? 'Rider', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${ride.serviceType.replaceAll('_', ' ')} • ${ride.passengersCount} passenger${ride.passengersCount > 1 ? 's' : ''} • ${ride.vehicleRequirement?.isNotEmpty == true ? ride.vehicleRequirement : ride.vehicleType}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ])),
                        Text(ride.hidePriceFromPassengers ? 'Offer' : '﷼ ${ride.offeredPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                      ]),
                      if (ride.groupName?.isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        Chip(label: Text('Group: ${ride.groupName}'), avatar: const Icon(Icons.groups, size: 16)),
                      ],
                      if (ride.marketVisibility != 'open_market') ...[
                        const SizedBox(height: 8),
                        Text('Targeted request: ${ride.marketVisibility.replaceAll('_', ' ')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                      if (ride.serviceType == 'pick_drop') ...[
                        const SizedBox(height: 8),
                        Text('Routine: ${ride.routineCategory ?? '-'} • ${ride.pickupTime ?? '-'} to ${ride.dropoffTime ?? '-'} • ${ride.contractDuration ?? '-'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 16),
                      Row(children: [
                        const Icon(Icons.trip_origin, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(ride.pickupLocation, style: const TextStyle(fontSize: 13))),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(child: Text(ride.dropoffLocation, style: const TextStyle(fontSize: 13))),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(ride.travelDate.toString().split(' ').first, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const Spacer(),
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(ride.departureTime ?? 'Flexible', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: ElevatedButton(
                          onPressed: () => _showOfferDialog(context, ride.id, ride.vehicleType, ride.seatsRequired),
                          child: const Text('Make Offer'),
                        )),
                      ]),
                    ]),
                  ),
                );
              },
            ),
    );
  }

  void _showOfferDialog(BuildContext context, String rideId, String defaultVehicle, int seatsRequired) {
    final price = TextEditingController();
    final vehicle = TextEditingController(text: defaultVehicle);
    final seats = TextEditingController(text: seatsRequired.toString());
    final plate = TextEditingController();
    final message = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Make Final Offer'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Final Amount (﷼)', prefixIcon: Icon(Icons.payments))),
            const SizedBox(height: 12),
            TextField(controller: vehicle, decoration: const InputDecoration(labelText: 'Vehicle Type', prefixIcon: Icon(Icons.directions_bus))),
            const SizedBox(height: 12),
            TextField(controller: seats, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seat Capacity', prefixIcon: Icon(Icons.event_seat))),
            const SizedBox(height: 12),
            TextField(controller: plate, decoration: const InputDecoration(labelText: 'Vehicle Plate', prefixIcon: Icon(Icons.confirmation_number))),
            const SizedBox(height: 12),
            TextField(controller: message, maxLines: 2, decoration: const InputDecoration(labelText: 'Message / Conditions', prefixIcon: Icon(Icons.chat))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              await context.read<RideProvider>().makeOffer(
                rideRequestId: rideId,
                driverId: auth.user?.uid ?? 'provider',
                driverName: auth.user?.displayName,
                offererType: auth.user?.companyId == null ? 'driver' : 'company',
                companyId: auth.user?.companyId,
                vehicleType: vehicle.text.trim(),
                vehiclePlate: plate.text.trim(),
                seatCapacity: int.tryParse(seats.text.trim()),
                price: double.tryParse(price.text.trim()) ?? 0,
                message: message.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Submit Offer'),
          ),
        ],
      ),
    );
  }
}
