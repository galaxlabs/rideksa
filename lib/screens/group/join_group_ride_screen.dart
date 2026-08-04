import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/frappe_api_client.dart';

class JoinGroupRideScreen extends StatefulWidget {
  final String inviteId;
  const JoinGroupRideScreen({super.key, required this.inviteId});

  @override
  State<JoinGroupRideScreen> createState() => _JoinGroupRideScreenState();
}

class _JoinGroupRideScreenState extends State<JoinGroupRideScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _nationality = TextEditingController();
  final _documentNo = TextEditingController();
  String _documentType = 'passport';
  bool _joining = false;
  String? _error;

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

  bool _validDocument() {
    final value = _documentNo.text.trim();
    if (value.isEmpty) return false;
    final pattern = _documentType == 'iqama'
        ? RegExp(r'^\d{10}$')
        : RegExp(r'^[A-Z0-9-]{5,20}$', caseSensitive: false);
    return pattern.hasMatch(value);
  }

  bool _validForm() {
    return _name.text.trim().isNotEmpty &&
        _mobile.text.trim().isNotEmpty &&
        _nationality.text.trim().isNotEmpty &&
        _validDocument();
  }

  Future<void> _join() async {
    if (!_validForm()) {
      setState(
        () => _error =
            'Fill full name, mobile, nationality and a valid document number.',
      );
      return;
    }
    setState(() {
      _joining = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final frappe = context.read<FrappeApiClient>();
    final user = auth.user;
    try {
      final result = await frappe.joinBookingGroup(
        token: Uri.decodeComponent(widget.inviteId),
        passengerName: _name.text.trim(),
        mobileNo: _mobile.text.trim(),
        nationality: _nationality.text.trim(),
        documentType: _documentType,
        documentNumber: _documentNo.text.trim(),
      );
      final apiError = result['error']?.toString();
      if (apiError != null && apiError.isNotEmpty) {
        throw Exception(apiError);
      }
      if (user != null) {
        await auth.updateProfile(
          displayName: _name.text.trim(),
          phone: _mobile.text.trim(),
          nationality: _nationality.text.trim(),
          documentType: _documentType,
          documentNo: _documentNo.text.trim(),
        );
      }
      if (!mounted) return;
      setState(() => _joining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You joined the group ride'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Group Ride')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.primary.withAlpha(12),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Join as a guest passenger. No signup is required; just complete passenger details.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile No',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nationality,
            decoration: const InputDecoration(
              labelText: 'Nationality',
              prefixIcon: Icon(Icons.flag),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _documentType,
            decoration: const InputDecoration(
              labelText: 'Document Type',
              prefixIcon: Icon(Icons.badge),
            ),
            items: const [
              DropdownMenuItem(value: 'passport', child: Text('Passport')),
              DropdownMenuItem(
                value: 'national_id',
                child: Text('National ID'),
              ),
              DropdownMenuItem(
                value: 'iqama',
                child: Text('Iqama / Saudi Resident ID'),
              ),
            ],
            onChanged: (v) =>
                setState(() => _documentType = v ?? _documentType),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _documentNo,
            decoration: const InputDecoration(
              labelText: 'Document No',
              prefixIcon: Icon(Icons.numbers),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _joining ? null : _join,
            child: _joining
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Accept Invite and Join'),
          ),
        ],
      ),
    );
  }
}
