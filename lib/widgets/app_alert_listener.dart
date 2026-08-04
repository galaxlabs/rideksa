import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class AppAlertListener extends StatefulWidget {
  final Widget child;
  const AppAlertListener({super.key, required this.child});

  @override
  State<AppAlertListener> createState() => _AppAlertListenerState();
}

class _AppAlertListenerState extends State<AppAlertListener> {
  NotificationService? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<NotificationService>();
    if (_service == next) return;
    _service?.alertMessage.removeListener(_showAlert);
    _service = next;
    _service?.alertMessage.addListener(_showAlert);
  }

  @override
  void dispose() {
    _service?.alertMessage.removeListener(_showAlert);
    super.dispose();
  }

  void _showAlert() {
    final message = _service?.alertMessage.value;
    if (!mounted || message == null || message.isEmpty) return;
    _service?.alertMessage.value = null;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('RideKSA Alert'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
