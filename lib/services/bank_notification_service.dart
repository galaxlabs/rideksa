import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/wallet_model.dart';
import '../services/firestore_service.dart';

class BankNotificationEvent {
  final String app;
  final String title;
  final String text;
  final double? amount;
  BankNotificationEvent({
    required this.app,
    required this.title,
    required this.text,
  }) : amount = BankNotificationService.parseAmount('$title $text');
}

class BankNotificationService {
  static const EventChannel _channel = EventChannel(
    'rideksa/bank_notifications',
  );
  final FirestoreService _firestore;
  StreamSubscription? _sub;
  final ValueNotifier<BankNotificationEvent?> lastEvent =
      ValueNotifier<BankNotificationEvent?>(null);
  final ValueNotifier<bool> listenerReady = ValueNotifier<bool>(false);

  BankNotificationService(this._firestore);

  static const Set<String> _bankAppHints = {
    'com.sadad',
    'sadad',
    'mada',
    'com.alrajhi',
    'rajhi',
    'com.albilad',
    'bilyad',
    'com.riyadbank',
    'riyad',
    'com.snbspp',
    'samba',
    'com.alahlia',
    'alahli',
    'com.ncb',
    'ncb',
    'com.arriyadh',
    'riyadh',
    'com.stcpay',
    'stc pay',
    'stcpay',
    'apple',
    'bank',
    'bnp',
    'hsbc',
    'emirates',
    'cib',
    'meethaq',
    'mobily',
    'wester',
    'wallet',
    'pay',
  };

  static double? parseAmount(String text) {
    final patterns = [
      RegExp(
        r'(?:SAR|SR|ر\.س|ر.س|رس|﷼)\s*([0-9][0-9,]*\.?[0-9]{0,2})',
        caseSensitive: false,
      ),
      RegExp(
        r'([0-9][0-9,]*\.?[0-9]{0,2})\s*(?:SAR|SR|ر\.س|ر.س|رس|﷼)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:amount|مبلغ)\s*(?:of|:|-)?\s*([0-9][0-9,]*\.?[0-9]{0,2})',
        caseSensitive: false,
      ),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(text);
      if (m != null) {
        final cleaned = m.group(1)!.replaceAll(',', '');
        return double.tryParse(cleaned);
      }
    }
    return null;
  }

  Future<void> startListening() async {
    if (_sub != null) return;
    if (kIsWeb) return;
    try {
      _sub = _channel.receiveBroadcastStream().listen((event) {
        if (event is! Map) return;
        final ev = BankNotificationEvent(
          app: event['app']?.toString() ?? '',
          title: event['title']?.toString() ?? '',
          text: event['text']?.toString() ?? '',
        );
        lastEvent.value = ev;
        _autoVerify(ev);
      }, onError: (e) => debugPrint('BANK NOTIFICATION ERROR: $e'));
      listenerReady.value = true;
    } catch (e) {
      debugPrint('BANK NOTIFICATION LISTEN FAIL: $e');
    }
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    listenerReady.value = false;
  }

  bool isLikelyBankEvent(BankNotificationEvent e) {
    final all = '${e.app} ${e.title} ${e.text}'.toLowerCase();
    return _bankAppHints.any(all.contains);
  }

  Future<void> _autoVerify(BankNotificationEvent event) async {
    final amount = event.amount;
    if (amount == null || amount <= 0) return;
    try {
      final pending = await _firestore.getPendingTopUps();
      for (final tx in pending) {
        if (tx.status != TransactionStatus.pending) continue;
        if ((tx.amount - amount).abs() < 0.01) {
          await _firestore.completePendingTopUp(tx);
          debugPrint(
            'BANK VERIFY: matched top-up ${tx.id} amount ${tx.amount}',
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('BANK VERIFY ERROR: $e');
    }
  }

  void dispose() {
    stopListening();
    lastEvent.dispose();
    listenerReady.dispose();
  }
}
