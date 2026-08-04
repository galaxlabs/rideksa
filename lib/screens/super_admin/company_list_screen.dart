import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CompanyListScreen extends StatelessWidget {
  const CompanyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Companies')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Column(children: [
            Icon(Icons.business_outlined, size: 48, color: AppColors.textSecondary.withAlpha(80)),
            const SizedBox(height: 8),
            Text('No companies registered', style: TextStyle(color: AppColors.textSecondary.withAlpha(150))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddCompanyDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Company'),
            ),
          ])))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCompanyDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddCompanyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Company'),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(decoration: InputDecoration(labelText: 'Company Name', prefixIcon: Icon(Icons.business))),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Name (Arabic)', prefixIcon: Icon(Icons.language))),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Add')),
        ],
      ),
    );
  }
}
