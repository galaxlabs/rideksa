import 'package:flutter/material.dart';
import '../core/theme.dart';

class SetupGuideScreen extends StatelessWidget {
  const SetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RideKSA Setup Guide')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Section(title: '1. Firebase Setup', children: [
            _Step(number: '1', text: 'Go to https://console.firebase.google.com'),
            _Step(number: '2', text: 'Create a project named "RideKSA"'),
            _Step(number: '3', text: 'Register Android app with package name:'),
            _Code(text: 'com.galaxylabs.ftms'),
            _Step(number: '4', text: 'Download google-services.json'),
            _Step(number: '5', text: 'Place it at:'),
            _Code(text: 'rideksa/android/app/google-services.json'),
            _Step(number: '6', text: 'Enable Firebase Authentication → Phone sign-in'),
            _Step(number: '7', text: 'Enable Cloud Firestore (start in test mode)'),
            _Step(number: '8', text: 'Enable Cloud Messaging (FCM)'),
          ]),
          const SizedBox(height: 20),
          _Section(title: '2. Google Maps & Places API', children: [
            _Step(number: '1', text: 'Go to https://console.cloud.google.com'),
            _Step(number: '2', text: 'Select your project or create one'),
            _Step(number: '3', text: 'Enable these APIs:'),
            _Bullet(text: 'Maps SDK for Android'),
            _Bullet(text: 'Places API'),
            _Bullet(text: 'Geocoding API'),
            _Step(number: '4', text: 'Create an API key'),
            _Step(number: '5', text: 'Open AndroidManifest.xml and replace:'),
            _Code(text: 'YOUR_GOOGLE_MAPS_API_KEY_HERE'),
            _Step(number: '6', text: '(Optional) Restrict the API key to Android app'),
            _Code(text: 'com.galaxylabs.ftms'),
          ]),
          const SizedBox(height: 20),
          _Section(title: '3. Build & Run', children: [
            _Step(number: '1', text: 'Open terminal in rideksa/ directory'),
            _Code(text: 'cd E:\\Projects\\ftms-platform\\rideksa'),
            _Step(number: '2', text: 'Install dependencies'),
            _Code(text: 'flutter pub get'),
            _Step(number: '3', text: 'Run the app'),
            _Code(text: 'flutter run'),
            _Step(number: '4', text: 'For release build (APK):'),
            _Code(text: 'flutter build apk'),
          ]),
          const SizedBox(height: 20),
          _Section(title: '4. Verification', children: [
            _Bullet(text: 'OTP login works → Firebase Auth is set up'),
            _Bullet(text: 'Search shows place suggestions → Places API is working'),
            _Bullet(text: 'Ride requests appear in Firestore console → Firestore is set up'),
            _Bullet(text: 'Map renders → Maps SDK is configured'),
          ]),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    ]);
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ]),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ]),
    );
  }
}

class _Code extends StatelessWidget {
  final String text;
  const _Code({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8, left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.primary)),
    );
  }
}
