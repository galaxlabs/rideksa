import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_play_integrity_wrapper/flutter_play_integrity_wrapper.dart';
import 'app_config_service.dart';
import 'frappe_api_client.dart';

class PlayIntegrityException implements Exception {
  final String code;
  final String message;
  const PlayIntegrityException(this.code, this.message);
  @override
  String toString() => 'PlayIntegrityException($code): $message';
}

class IntegrityResult {
  final bool passed;
  final String? token;
  final String? appVerdict;
  final String? deviceVerdict;
  final String? accountVerdict;
  final String? error;
  const IntegrityResult({
    required this.passed,
    this.token,
    this.appVerdict,
    this.deviceVerdict,
    this.accountVerdict,
    this.error,
  });
}

class IntegrityService {
  final FrappeApiClient _frappe;
  final FlutterPlayIntegrityWrapper _wrapper = FlutterPlayIntegrityWrapper();

  IntegrityService(this._frappe);

  bool get supported {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) return true;
    return false;
  }

  Future<IntegrityResult> runCheck() async {
    if (!supported) {
      return const IntegrityResult(passed: false, error: 'Play Integrity only runs on Android devices');
    }
    try {
      final token = await _wrapper.requestIntegrityToken(
        cloudProjectNumber: AppConfigService.instance.config.playIntegrityProjectNumber,
      );
      if (token == null || token.isEmpty) {
        return const IntegrityResult(passed: false, error: 'No integrity token returned');
      }
      final verdict = await _frappe.verifyPlayIntegrity(token);
      final appVerdict = verdict['app_verdict'] as String?;
      final deviceVerdict = verdict['device_verdict'] as String?;
      final accountVerdict = verdict['account_verdict'] as String?;
      final status = verdict['status'] as String? ?? 'error';
      final passed = status == 'verified';
      return IntegrityResult(
        passed: passed,
        token: token,
        appVerdict: appVerdict,
        deviceVerdict: deviceVerdict,
        accountVerdict: accountVerdict,
        error: passed ? null : (verdict['message'] as String? ?? 'Integrity check failed'),
      );
    } on PlayIntegrityException catch (e) {
      return IntegrityResult(passed: false, error: '${e.code}: ${e.message}');
    } on PlatformException catch (e) {
      return IntegrityResult(passed: false, error: e.message ?? 'Platform integrity error');
    } catch (e) {
      return IntegrityResult(passed: false, error: e.toString());
    }
  }
}
