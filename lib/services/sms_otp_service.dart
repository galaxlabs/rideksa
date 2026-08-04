import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sms_autofill/sms_autofill.dart';

class SmsOtpService {
  final SmsAutoFill _smsAutoFill = SmsAutoFill();
  StreamSubscription<String>? _sub;
  final ValueNotifier<String?> receivedCode = ValueNotifier<String?>(null);
  bool _listening = false;

  Future<String?> get appSignature => _smsAutoFill.getAppSignature;

  Future<void> startListening() async {
    if (_listening) return;
    _listening = true;
    try {
      _sub = _smsAutoFill.code.listen((code) {
        if (code.isEmpty) return;
        receivedCode.value = code;
      });
      await _smsAutoFill.listenForCode();
    } catch (e) {
      debugPrint('SMS OTP listen error: $e');
      _listening = false;
    }
  }

  Future<void> stopListening() async {
    _listening = false;
    await _sub?.cancel();
    _sub = null;
    receivedCode.value = null;
  }

  void dispose() {
    stopListening();
    receivedCode.dispose();
  }
}
