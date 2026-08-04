import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/chat_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class RideChatScreen extends StatefulWidget {
  final String rideRequestId;
  const RideChatScreen({super.key, required this.rideRequestId});

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthProvider>().user;
    await context.read<FirestoreService>().sendChatMessage(ChatMessageModel(
      id: const Uuid().v4(),
      rideRequestId: widget.rideRequestId,
      senderId: user?.uid ?? 'guest',
      senderName: user?.displayName ?? user?.roleLabel ?? 'Guest',
      message: text,
    ));
    _message.clear();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Ride Chat')),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<ChatMessageModel>>(
            stream: context.read<FirestoreService>().streamChatMessages(widget.rideRequestId),
            builder: (context, snap) {
              final messages = snap.data ?? [];
              if (messages.isEmpty) return const Center(child: Text('No messages yet'));
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final mine = msg.senderId == userId;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(color: mine ? Colors.green.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(msg.senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(msg.message),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Expanded(child: TextField(controller: _message, decoration: const InputDecoration(hintText: 'Message...', border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
            ]),
          ),
        ),
      ]),
    );
  }
}
