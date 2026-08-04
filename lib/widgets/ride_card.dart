import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/ride_request_model.dart';

class RideCard extends StatelessWidget {
  final RideRequestModel ride;
  final VoidCallback? onTap;
  final Widget? trailing;
  const RideCard({super.key, required this.ride, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ride.passengerName ?? 'Rider', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${ride.passengersCount} pax • ${ride.vehicleType}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('﷼ ${ride.offeredPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(ride.status.name, style: TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.trip_origin, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(ride.pickupLocation, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                const Icon(Icons.arrow_forward, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(ride.dropoffLocation, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              ]),
            ),
            if (trailing != null) ...[const SizedBox(height: 12), Row(children: [Expanded(child: trailing!)])],
          ]),
        ),
      ),
    );
  }
}
