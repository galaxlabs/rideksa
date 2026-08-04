import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/sms_otp_service.dart';

class OTPSCreen extends StatefulWidget {
  final String phone;
  const OTPSCreen({super.key, required this.phone});
  @override
  State<OTPSCreen> createState() => _OTPSCreenState();
}

class _OTPSCreenState extends State<OTPSCreen> {
  final _otpController = TextEditingController();
  final SmsOtpService _smsOtpService = SmsOtpService();
  bool _loading = false;
  bool _autoVerifying = false;

  @override
  void initState() {
    super.initState();
    _smsOtpService.startListening();
    _smsOtpService.receivedCode.addListener(_onCodeReceived);
  }

  void _onCodeReceived() {
    final code = _smsOtpService.receivedCode.value;
    if (code == null || code.isEmpty || _autoVerifying) return;
    _autoVerifying = true;
    _otpController.text = code;
    if (mounted) setState(() {});
    _verify();
  }

  Future<void> _verify() async {
    if (_otpController.text.length < 4) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    await auth.verifyOTP(_otpController.text.trim());
    if (mounted) {
      setState(() {
        _loading = false;
        _autoVerifying = false;
      });
      if (auth.state == AuthState.authenticated) {
        context.go('/passenger');
      }
    }
  }

  @override
  void dispose() {
    _smsOtpService.receivedCode.removeListener(_onCodeReceived);
    _smsOtpService.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.primary.withAlpha(30), shape: BoxShape.circle),
              child: const Icon(Icons.smartphone, color: AppColors.primaryLight, size: 32),
            ),
            const SizedBox(height: 24),
            const Text('Verify OTP', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Enter the code sent to ${widget.phone}', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.sms_outlined, color: AppColors.accentLight, size: 14),
              const SizedBox(width: 6),
              Text('Code auto-detected from SMS', style: TextStyle(color: AppColors.accentLight.withAlpha(180), fontSize: 12)),
            ]),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                TextField(
                  controller: _otpController,
                  style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 12),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(50), fontSize: 24, letterSpacing: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    filled: true, fillColor: Colors.white.withAlpha(12),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.read<AuthProvider>().sendOTP(widget.phone),
              child: Text('Resend OTP', style: TextStyle(color: AppColors.accentLight)),
            ),
          ]),
        ),
      ),
    );
  }
}
