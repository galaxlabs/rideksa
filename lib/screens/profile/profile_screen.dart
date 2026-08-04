import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _nationality = TextEditingController();
  final _documentNo = TextEditingController();
  String _documentType = 'passport';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name.text = user?.displayName ?? '';
    _mobile.text = user?.phone ?? '';
    _nationality.text = user?.nationality ?? '';
    _documentType = user?.documentType ?? 'passport';
    _documentNo.text = user?.documentNo ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _nationality.dispose();
    _documentNo.dispose();
    super.dispose();
  }

  String? _validateDocument(String value) {
    if (value.isEmpty) return null;
    final pattern = switch (_documentType) {
      'passport' => RegExp(r'^[A-Z0-9]{6,12}$', caseSensitive: false),
      'national_id' => RegExp(r'^[A-Z0-9-]{5,20}$', caseSensitive: false),
      'iqama' => RegExp(r'^\d{10}$'),
      _ => RegExp(r'^[A-Z0-9-]{5,20}$', caseSensitive: false),
    };
    return pattern.hasMatch(value) ? null : 'Invalid ${_documentType.replaceAll('_', ' ')} format';
  }

  Future<void> _save() async {
    final docError = _validateDocument(_documentNo.text.trim());
    if (docError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(docError), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _saving = true);
    await context.read<AuthProvider>().updateProfile(
      displayName: _name.text.trim(),
      phone: _mobile.text.trim(),
      nationality: _nationality.text.trim(),
      documentType: _documentType,
      documentNo: _documentNo.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved'), backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(radius: 34, backgroundColor: AppColors.primary, child: Text((user?.displayName?.isNotEmpty == true ? user!.displayName![0] : 'R').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.displayName ?? 'Passenger', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(user?.email ?? user?.phone ?? 'Complete your travel profile', style: TextStyle(color: AppColors.textSecondary)),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 12),
          TextField(controller: _mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile No', prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 12),
          TextField(controller: _nationality, decoration: const InputDecoration(labelText: 'Nationality', prefixIcon: Icon(Icons.flag))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _documentType,
            decoration: const InputDecoration(labelText: 'Document Type', prefixIcon: Icon(Icons.badge)),
            items: const [
              DropdownMenuItem(value: 'passport', child: Text('Passport')),
              DropdownMenuItem(value: 'national_id', child: Text('National ID')),
              DropdownMenuItem(value: 'iqama', child: Text('Iqama / Saudi Resident ID')),
            ],
            onChanged: (v) => setState(() => _documentType = v ?? _documentType),
          ),
          const SizedBox(height: 12),
          TextField(controller: _documentNo, decoration: InputDecoration(labelText: 'Document No', helperText: _documentType == 'iqama' ? '10 digits' : 'Global alphanumeric format', prefixIcon: const Icon(Icons.numbers))),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Profile')),
        ],
      ),
    );
  }
}
