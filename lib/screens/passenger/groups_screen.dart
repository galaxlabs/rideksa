import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/frappe_api_client.dart';
import '../../widgets/sidebar_page.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;
  String? _error;
  String? _sharing;

  FrappeApiClient get _frappe => context.read<FrappeApiClient>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final bookings = await _frappe.getMyBookings();
      final groups = bookings.where((b) => b['booking_group_code'] != null && b['booking_group_code'].toString().isNotEmpty).toList();
      if (!mounted) return;
      setState(() { _groups = groups; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _share(Map<String, dynamic> group) async {
    final name = group['name']?.toString();
    if (name == null) return;
    setState(() => _sharing = name);
    try {
      final invite = await _frappe.createGroupInvite(name);
      final token = invite['token']?.toString() ?? '';
      if (!mounted) return;
      setState(() => _sharing = null);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Group Invite'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Share this link with friends so they can join the group ride:'),
            const SizedBox(height: 12),
            SelectableText(token.isEmpty ? 'Invite token could not be created' : token, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sharing = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarPage(
      title: 'Group Rides',
      path: '/passenger/groups',
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
              : _groups.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.groups, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No group rides yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Book a group ride to create a shareable invite', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _groups.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final g = _groups[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(g['booking_title']?.toString() ?? g['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                                    child: Text('Group: ${g['booking_group_code']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                Text('${g['pickup_point'] ?? ''} → ${g['drop_point'] ?? ''}', style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('${g['booking_date'] ?? ''}  •  ${g['passenger_count'] ?? 1} passenger(s)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(child: OutlinedButton.icon(
                                    onPressed: () => context.push('/passenger/ride-detail/${g['name']}'),
                                    icon: const Icon(Icons.visibility_outlined, size: 18),
                                    label: const Text('View'),
                                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                                  )),
                                  const SizedBox(width: 8),
                                  Expanded(child: OutlinedButton.icon(
                                    onPressed: _sharing == g['name'] ? null : () => _share(g),
                                    icon: _sharing == g['name']
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.share_outlined, size: 18),
                                    label: const Text('Share'),
                                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                                  )),
                                ]),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
