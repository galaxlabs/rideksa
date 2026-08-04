import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sidebar_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _location = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return SidebarPage(
      title: 'Settings',
      path: '/settings',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Column(children: [
            ListTile(
              leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              title: const Text('Push Notifications'),
              subtitle: const Text('Ride updates, offers, group invites'),
              trailing: Switch(value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
              title: const Text('GPS Location'),
              subtitle: const Text('Use current location for pickup'),
              trailing: Switch(value: _location, onChanged: (v) => setState(() => _location = v)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch app theme'),
              trailing: Switch(value: _darkMode, onChanged: (v) => setState(() => _darkMode = v)),
            ),
          ])),
          const SizedBox(height: 16),
          Card(child: Column(children: [
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppColors.primary),
              title: const Text('Account'),
              subtitle: Text(auth.user?.email ?? auth.user?.displayName ?? 'Signed in'),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.primary),
              title: Text('App Version'),
              subtitle: Text('0.0.1'),
            ),
          ])),
        ],
      ),
    );
  }
}
