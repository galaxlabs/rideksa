import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/group_invite_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

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
  GroupInviteModel? _invite;
  bool _loading = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _load();
    final user = context.read<AuthProvider>().user;
    _name.text = user?.displayName ?? '';
    _mobile.text = user?.phone ?? '';
    _nationality.text = user?.nationality ?? '';
    _documentType = user?.documentType ?? 'passport';
    _documentNo.text = user?.documentNo ?? '';
  }

  Future<void> _load() async {
    final invite = await context.read<FirestoreService>().getGroupInvite(widget.inviteId);
    if (!mounted) return;
    setState(() { _invite = invite; _loading = false; });
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

  Future<void> _join() async {
    final invite = _invite;
    if (invite == null || invite.isExpired || !_validDocument()) return;
    setState(() => _joining = true);
    final user = context.read<AuthProvider>().user;
    await context.read<FirestoreService>().setGroupMember(GroupMemberModel(
      id: const Uuid().v4(),
      rideRequestId: invite.rideRequestId,
      fullName: _name.text.trim(),
      mobileNo: _mobile.text.trim(),
      nationality: _nationality.text.trim(),
      documentType: _documentType,
      documentNo: _documentNo.text.trim(),
      status: 'accepted',
      userId: user?.uid,
    ));
    if (user != null) {
      await context.read<AuthProvider>().updateProfile(
        displayName: _name.text.trim(),
        phone: _mobile.text.trim(),
        nationality: _nationality.text.trim(),
        documentType: _documentType,
        documentNo: _documentNo.text.trim(),
      );
    }
    if (!mounted) return;
    setState(() => _joining = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You joined the group ride'), backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    final invite = _invite;
    return Scaffold(
      appBar: AppBar(title: const Text('Join Group Ride')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : invite == null || invite.isExpired
              ? const Center(child: Text('Invite link expired or invalid. Links are valid for 24 hours.'))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  Card(color: AppColors.primary.withAlpha(12), child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Complete passenger details to join this group ride. Price agreement is private between travel agent and provider.'),
                  )),
                  const SizedBox(height: 12),
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
                  TextField(controller: _documentNo, decoration: const InputDecoration(labelText: 'Document No', prefixIcon: Icon(Icons.numbers))),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _joining ? null : _join, child: _joining ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Accept Invite and Join')),
                ]),
    );
  }
}
