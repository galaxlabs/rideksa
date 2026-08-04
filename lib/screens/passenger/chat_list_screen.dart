import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/frappe_api_client.dart';
import '../../widgets/sidebar_page.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _bookings = [];
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
      final bookings = await _frappe.getMyBookings();
      if (!mounted) return;
      setState(() { _bookings = bookings; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarPage(
      title: 'Chat',
      path: '/passenger/chat',
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.grey)))
              : _bookings.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No conversations yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Chat is available per ride', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ]))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final b = _bookings[index];
                        return Card(
                          child: ListTile(
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: AppColors.primary.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.chat, color: AppColors.primary, size: 20),
                            ),
                            title: Text(b['booking_title']?.toString() ?? b['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${b['pickup_point'] ?? ''} → ${b['drop_point'] ?? ''}'),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => context.push('/chat/${Uri.encodeComponent(b['name'].toString())}'),
                          ),
                        );
                      },
                    ),
    );
  }
}
