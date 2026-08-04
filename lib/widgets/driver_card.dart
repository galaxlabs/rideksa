import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/driver_model.dart';

class DriverCard extends StatelessWidget {
  final DriverModel driver;
  final VoidCallback? onTap;
  const DriverCard({super.key, required this.driver, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: driver.isAvailable ? AppColors.success.withAlpha(20) : Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person, color: driver.isAvailable ? AppColors.success : Colors.grey, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(driver.fullName ?? 'Driver', style: const TextStyle(fontWeight: FontWeight.w600)),
              Row(children: [
                if (driver.vehicleType != null) Text('${driver.vehicleType}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                if (driver.vehiclePlate != null) Text(' • ${driver.vehiclePlate}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star, color: Color(0xFFD4AF37), size: 16),
                const SizedBox(width: 4),
                Text(driver.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
              if (driver.distanceKm != null) Text('${driver.distanceKm!.toStringAsFixed(1)} km', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ]),
          ]),
        ),
      ),
    );
  }
}
