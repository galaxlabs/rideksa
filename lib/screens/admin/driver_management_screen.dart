import 'package:flutter/material.dart';
import '../../core/theme.dart';

class DriverManagementScreen extends StatelessWidget {
  const DriverManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person_add, color: AppColors.primary),
              ),
              title: const Text('Add New Driver'),
              subtitle: const Text('Register a new driver to your fleet'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAddDriverDialog(context),
            ),
          ),
          const SizedBox(height: 16),
          Text('Registered Drivers', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Column(children: [
            Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary.withAlpha(80)),
            const SizedBox(height: 8),
            Text('No drivers registered yet', style: TextStyle(color: AppColors.textSecondary.withAlpha(150))),
          ])))),
        ],
      ),
    );
  }

  void _showAddDriverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Driver'),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(decoration: InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person))),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Vehicle Plate', prefixIcon: Icon(Icons.directions_car))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Add Driver')),
        ],
      ),
    );
  }
}
