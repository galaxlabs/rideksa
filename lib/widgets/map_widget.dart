import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SimpleMapWidget extends StatelessWidget {
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final double? currentLat;
  final double? currentLng;
  final double height;

  const SimpleMapWidget({
    super.key,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.currentLat,
    this.currentLng,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final hasPickup = pickupLat != null && pickupLng != null;
    final hasDropoff = dropoffLat != null && dropoffLng != null;
    final hasBoth = hasPickup && hasDropoff;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.map_outlined, size: 48, color: AppColors.textSecondary.withAlpha(80)),
          const SizedBox(height: 8),
          Text(
            hasBoth ? 'Route Map View' :
            hasPickup ? 'Pickup Location' : 'Map Preview',
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          if (hasBoth) ...[
            const SizedBox(height: 4),
            Text('Route between pickup & dropoff', style: TextStyle(color: AppColors.textSecondary.withAlpha(150), fontSize: 12)),
          ],
        ]),
      ),
    );
  }
}
