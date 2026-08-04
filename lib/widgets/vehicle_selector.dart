import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/vehicle_model.dart';

class VehicleSelector extends StatelessWidget {
  final List<VehicleType> types;
  final String? selectedId;
  final Function(VehicleType) onSelected;
  const VehicleSelector({super.key, required this.types, this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 10, children: types.map((t) => _buildCard(t)).toList());
  }

  Widget _buildCard(VehicleType type) {
    final name = type.name;
    final seats = type.defaultSeatingCapacity ?? 0;
    final color = AppColors.vehicleColors[name] ?? AppColors.primary;
    final icon = AppColors.vehicleIcons[name] ?? Icons.directions_car;
    final isSelected = selectedId == type.id;

    return GestureDetector(
      onTap: () => onSelected(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : const Color(0xFFE5E7EB), width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: color.withAlpha(50), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withAlpha(40) : color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isSelected ? Colors.white : color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (seats > 0) ...[
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.person, size: 11, color: isSelected ? Colors.white70 : AppColors.textSecondary),
              const SizedBox(width: 2),
              Text('$seats', style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : AppColors.textSecondary)),
            ]),
          ],
        ]),
      ),
    );
  }
}
