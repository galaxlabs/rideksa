import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/frappe_api_client.dart';
import '../../widgets/sidebar_page.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  FrappeApiClient get _frappe => context.read<FrappeApiClient>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await _frappe.getMyNotifications();
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    final name = item['name'];
    if (name == null) return;
    await _frappe.markNotificationRead(name.toString());
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return SidebarPage(
      title: 'Notifications',
      path: '/passenger/notifications',
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
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
              : _items.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notifications', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final n = _items[index];
                          final read = (n['status']?.toString() ?? '') == 'Read';
                          return Card(
                            child: ListTile(
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: AppColors.primary.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                                child: Icon(
                                  n['event_type']?.toString() == 'booking' ? Icons.receipt_long : Icons.circle_notifications,
                                  color: AppColors.primary, size: 20,
                                ),
                              ),
                              title: Text(n['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(n['message']?.toString() ?? ''),
                              isThreeLine: true,
                              trailing: read
                                  ? null
                                  : IconButton(icon: const Icon(Icons.done), onPressed: () => _markRead(n), tooltip: 'Mark read'),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
