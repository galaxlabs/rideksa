import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/contract_model.dart';
import '../../models/group_invite_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../services/firestore_service.dart';

class ContractBookingScreen extends StatefulWidget {
  const ContractBookingScreen({super.key});

  @override
  State<ContractBookingScreen> createState() => _ContractBookingScreenState();
}

class _ContractBookingScreenState extends State<ContractBookingScreen> {
  final _title = TextEditingController();
  final _counterparty = TextEditingController();
  final _targetId = TextEditingController();
  final _pickup = TextEditingController();
  final _dropoff = TextEditingController();
  final _passengers = TextEditingController(text: '10');
  final _passengerNames = TextEditingController();
  final _vehicleRequirement = TextEditingController();
  final _pickupTime = TextEditingController(text: '07:00');
  final _dropoffTime = TextEditingController(text: '17:00');
  final _duration = TextEditingController(text: '1 month');
  final _price = TextEditingController();
  final _notes = TextEditingController();
  String _counterpartyType = 'company';
  String _marketVisibility = 'open_market';
  String _repeat = 'one_time';
  String _serviceType = 'contract_trip';
  String _routineCategory = 'office';
  String _vehicleType = 'Bus';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;
  final List<GroupMemberModel> _members = [];

  double get _fare => double.tryParse(_price.text.trim()) ?? 0;
  double get _fee => _fare * 0.05;

  @override
  void dispose() {
    _title.dispose();
    _counterparty.dispose();
    _targetId.dispose();
    _pickup.dispose();
    _dropoff.dispose();
    _passengers.dispose();
    _passengerNames.dispose();
    _vehicleRequirement.dispose();
    _pickupTime.dispose();
    _dropoffTime.dispose();
    _duration.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_pickup.text.trim().isEmpty || _dropoff.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final contractId = const Uuid().v4();
    final rideRequestId = const Uuid().v4();
    final inviteId = const Uuid().v4();
    final names = _passengerNames.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    await firestore.setContract(ContractModel(
      id: contractId,
      ownerId: auth.user?.uid ?? 'guest',
      companyId: auth.user?.companyId,
      title: _title.text.trim().isEmpty ? '${_pickup.text} to ${_dropoff.text}' : _title.text.trim(),
      counterpartyType: _counterpartyType,
      counterpartyName: _counterparty.text.trim(),
      routeSummary: '${_pickup.text.trim()} -> ${_dropoff.text.trim()}',
      expectedPassengers: int.tryParse(_passengers.text.trim()) ?? names.length,
      contractValue: _fare,
      repeatSchedule: _repeat,
      serviceType: _serviceType,
      routineCategory: _routineCategory,
      pickupTime: _serviceType == 'pick_drop' ? _pickupTime.text.trim() : null,
      dropoffTime: _serviceType == 'pick_drop' ? _dropoffTime.text.trim() : null,
      startDate: _date,
    ));
    await context.read<RideProvider>().createRideRequest(
      id: rideRequestId,
      pickupLocation: _pickup.text.trim(),
      dropoffLocation: _dropoff.text.trim(),
      travelDate: _date,
      vehicleType: _vehicleType,
      passengersCount: int.tryParse(_passengers.text.trim()) ?? names.length,
      offeredPrice: _fare,
      bookingType: _serviceType == 'pick_drop' ? 'routine_contract' : 'contract',
      serviceType: _serviceType,
      routineCategory: _serviceType == 'pick_drop' ? _routineCategory : null,
      contractDuration: _serviceType == 'pick_drop' ? _duration.text.trim() : null,
      pickupTime: _serviceType == 'pick_drop' ? _pickupTime.text.trim() : null,
      dropoffTime: _serviceType == 'pick_drop' ? _dropoffTime.text.trim() : null,
      groupName: _title.text.trim(),
      passengerNames: [..._members.map((m) => m.fullName), ...names],
      contractId: contractId,
      marketVisibility: _marketVisibility,
      targetCompanyId: _marketVisibility == 'target_company' ? _targetId.text.trim() : null,
      targetDriverId: _marketVisibility == 'target_driver' ? _targetId.text.trim() : null,
      vehicleRequirement: _vehicleRequirement.text.trim(),
      seatsRequired: int.tryParse(_passengers.text.trim()) ?? names.length,
      hidePriceFromPassengers: true,
      passengerId: auth.user?.uid,
      passengerName: auth.user?.displayName,
      companyId: auth.user?.companyId,
      notes: _notes.text.trim(),
    );
    await firestore.setGroupInvite(GroupInviteModel(
      id: inviteId,
      rideRequestId: rideRequestId,
      createdBy: auth.user?.uid ?? 'guest',
    ));
    for (final member in _members) {
      await firestore.setGroupMember(GroupMemberModel(
        id: member.id,
        rideRequestId: rideRequestId,
        fullName: member.fullName,
        mobileNo: member.mobileNo,
        nationality: member.nationality,
        documentType: member.documentType,
        documentNo: member.documentNo,
      ));
    }
    if (!mounted) return;
    setState(() => _saving = false);
    final inviteLink = '${Uri.base.origin}/#/join/$inviteId';
    await Clipboard.setData(ClipboardData(text: inviteLink));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contract booking created. Invite link copied: $inviteLink'), backgroundColor: AppColors.success));
    Navigator.pop(context);
  }

  void _addMemberDialog() {
    final name = TextEditingController();
    final mobile = TextEditingController();
    final nationality = TextEditingController();
    final docNo = TextEditingController();
    var docType = 'passport';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Add Passenger'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 10),
          TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile No')),
          const SizedBox(height: 10),
          TextField(controller: nationality, decoration: const InputDecoration(labelText: 'Nationality')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: docType,
            decoration: const InputDecoration(labelText: 'Document Type'),
            items: const [
              DropdownMenuItem(value: 'passport', child: Text('Passport')),
              DropdownMenuItem(value: 'national_id', child: Text('National ID')),
              DropdownMenuItem(value: 'iqama', child: Text('Iqama')),
            ],
            onChanged: (v) => setDialogState(() => docType = v ?? docType),
          ),
          const SizedBox(height: 10),
          TextField(controller: docNo, decoration: const InputDecoration(labelText: 'Document No')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (name.text.trim().isEmpty) return;
            setState(() => _members.add(GroupMemberModel(
              id: const Uuid().v4(),
              rideRequestId: '',
              fullName: name.text.trim(),
              mobileNo: mobile.text.trim(),
              nationality: nationality.text.trim(),
              documentType: docType,
              documentNo: docNo.text.trim(),
            )));
            Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contract / Group Booking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(color: AppColors.primary.withAlpha(12), child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text('Travel agents can book from any country. No GPS is required here. Group passengers can join the ride, but the agreed offer price is hidden from them.', style: TextStyle(color: AppColors.textSecondary)),
          )),
          const SizedBox(height: 12),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Group / Contract Title', prefixIcon: Icon(Icons.groups))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _serviceType,
            decoration: const InputDecoration(labelText: 'Marketplace Service', prefixIcon: Icon(Icons.storefront)),
            items: const [
              DropdownMenuItem(value: 'contract_trip', child: Text('Group Trip / Travel Plan')),
              DropdownMenuItem(value: 'pick_drop', child: Text('Scheduled Pick & Drop Contract')),
              DropdownMenuItem(value: 'rent_car', child: Text('Rent a Car / Vehicle Contract')),
            ],
            onChanged: (v) => setState(() {
              _serviceType = v ?? _serviceType;
              if (_serviceType == 'pick_drop') _repeat = 'daily';
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _marketVisibility,
            decoration: const InputDecoration(labelText: 'Send Request To', prefixIcon: Icon(Icons.campaign)),
            items: const [
              DropdownMenuItem(value: 'open_market', child: Text('Open market: any company/driver can offer')),
              DropdownMenuItem(value: 'target_company', child: Text('Target company')),
              DropdownMenuItem(value: 'target_driver', child: Text('Target driver/captain')),
            ],
            onChanged: (v) => setState(() => _marketVisibility = v ?? _marketVisibility),
          ),
          if (_marketVisibility != 'open_market') ...[
            const SizedBox(height: 12),
            TextField(controller: _targetId, decoration: const InputDecoration(labelText: 'Target company/driver ID or phone', prefixIcon: Icon(Icons.search))),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _counterpartyType,
            decoration: const InputDecoration(labelText: 'Contract With', prefixIcon: Icon(Icons.handshake)),
            items: const [
              DropdownMenuItem(value: 'company', child: Text('Company')),
              DropdownMenuItem(value: 'driver', child: Text('Driver / Captain')),
            ],
            onChanged: (v) => setState(() => _counterpartyType = v ?? _counterpartyType),
          ),
          const SizedBox(height: 12),
          TextField(controller: _counterparty, decoration: const InputDecoration(labelText: 'Company or Driver Name', prefixIcon: Icon(Icons.badge))),
          const SizedBox(height: 12),
          TextField(controller: _pickup, decoration: const InputDecoration(labelText: 'Pickup City / KSA Location', prefixIcon: Icon(Icons.trip_origin))),
          const SizedBox(height: 12),
          TextField(controller: _dropoff, decoration: const InputDecoration(labelText: 'Drop-off City / KSA Location', prefixIcon: Icon(Icons.location_on))),
          const SizedBox(height: 12),
          if (_serviceType == 'pick_drop') ...[
            DropdownButtonFormField<String>(
              value: _routineCategory,
              decoration: const InputDecoration(labelText: 'Routine / Business Category', prefixIcon: Icon(Icons.category)),
              items: const [
                DropdownMenuItem(value: 'kids_school', child: Text('Kids / School')),
                DropdownMenuItem(value: 'factory', child: Text('Factory Staff')),
                DropdownMenuItem(value: 'site', child: Text('Sites / Projects')),
                DropdownMenuItem(value: 'company', child: Text('Companies')),
                DropdownMenuItem(value: 'office', child: Text('Offices')),
              ],
              onChanged: (v) => setState(() => _routineCategory = v ?? _routineCategory),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _pickupTime, decoration: const InputDecoration(labelText: 'Daily Pickup Time', prefixIcon: Icon(Icons.schedule)))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _dropoffTime, decoration: const InputDecoration(labelText: 'Daily Drop Time', prefixIcon: Icon(Icons.schedule_send)))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _duration, decoration: const InputDecoration(labelText: 'Contract Duration', hintText: 'Example: monthly, 6 months, school term', prefixIcon: Icon(Icons.timelapse))),
            const SizedBox(height: 12),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
            subtitle: const Text('Start / travel date'),
            trailing: const Icon(Icons.edit_calendar),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _repeat,
            decoration: const InputDecoration(labelText: 'Repeat Schedule', prefixIcon: Icon(Icons.repeat)),
            items: const [
              DropdownMenuItem(value: 'one_time', child: Text('One time')),
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
            ],
            onChanged: (v) => setState(() => _repeat = v ?? _repeat),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: ['Van', 'Bus', 'Coaster', 'SUV'].map((v) => ChoiceChip(label: Text(v), selected: _vehicleType == v, onSelected: (_) => setState(() => _vehicleType = v))).toList()),
          const SizedBox(height: 12),
          TextField(controller: _vehicleRequirement, maxLines: 2, decoration: const InputDecoration(labelText: 'Vehicle Requirements', hintText: 'Example: 45 seats, AC bus, luggage space, Umrah group', prefixIcon: Icon(Icons.directions_bus))),
          const SizedBox(height: 12),
          TextField(controller: _passengers, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Passenger Count', prefixIcon: Icon(Icons.people))),
          const SizedBox(height: 12),
          TextField(controller: _passengerNames, maxLines: 5, decoration: const InputDecoration(labelText: 'Passenger Names / Group Members', hintText: 'One passenger per line', prefixIcon: Icon(Icons.list_alt))),
          const SizedBox(height: 12),
          Card(child: Column(children: [
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: const Text('Add detailed passenger'),
              subtitle: const Text('Name, mobile, nationality, document type and number'),
              trailing: const Icon(Icons.add_circle),
              onTap: _addMemberDialog,
            ),
            if (_members.isNotEmpty) const Divider(height: 1),
            ..._members.map((m) => ListTile(
              dense: true,
              title: Text(m.fullName),
              subtitle: Text('${m.nationality} • ${m.documentType}: ${m.documentNo}'),
              trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _members.remove(m))),
            )),
          ])),
          const SizedBox(height: 12),
          TextField(controller: _price, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Agent Budget / Expected Offer (﷼)', helperText: 'Hidden from group passengers. Final amount locks after accepted offer.', prefixIcon: Icon(Icons.payments))),
          const SizedBox(height: 12),
          Card(color: AppColors.primary.withAlpha(12), child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
            _FeeRow(label: 'Platform fee (5%)', value: '﷼ ${_fee.toStringAsFixed(2)}'),
            const Divider(),
            _FeeRow(label: 'Provider amount after acceptance', value: '﷼ ${(_fare - _fee).toStringAsFixed(2)}'),
          ]))),
          const SizedBox(height: 12),
          TextField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Contract Notes', prefixIcon: Icon(Icons.note))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create Contract Booking'),
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  const _FeeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]);
  }
}
