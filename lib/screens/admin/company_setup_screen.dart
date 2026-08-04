import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/company_model.dart';
import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class CompanySetupScreen extends StatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  final _companyName = TextEditingController();
  final _contactPerson = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _registration = TextEditingController();
  final _plate = TextEditingController();
  final _vehicleType = TextEditingController(text: 'Bus');
  final _capacity = TextEditingController(text: '45');
  String _businessType = 'travel_agent';
  bool _saving = false;

  @override
  void dispose() {
    _companyName.dispose();
    _contactPerson.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    _registration.dispose();
    _plate.dispose();
    _vehicleType.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_companyName.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthProvider>();
    final id = const Uuid().v4();
    final company = CompanyModel(
      id: id,
      name: _companyName.text.trim(),
      contactPerson: _contactPerson.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      city: _city.text.trim(),
      registrationNo: _registration.text.trim(),
      businessType: _businessType,
      commissionRate: 0.05,
    );
    await firestore.setCompany(company);
    await auth.updateRole(auth.user?.role ?? UserRole.admin, companyId: id);
    if (_plate.text.trim().isNotEmpty) {
      await firestore.setVehicle(VehicleModel(
        id: const Uuid().v4(),
        plateNumber: _plate.text.trim(),
        type: _vehicleType.text.trim(),
        seatingCapacity: int.tryParse(_capacity.text.trim()) ?? 1,
        companyId: id,
      ));
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company profile saved'), backgroundColor: AppColors.success));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Platform')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Company / Travel Agent Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Platform fee is fixed at 5% for every completed trip.', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _businessType,
                  decoration: const InputDecoration(labelText: 'Business Type', prefixIcon: Icon(Icons.business)),
                  items: const [
                    DropdownMenuItem(value: 'travel_agent', child: Text('Travel Agent')),
                    DropdownMenuItem(value: 'transport_company', child: Text('Transport Company')),
                    DropdownMenuItem(value: 'fleet_owner', child: Text('Fleet Owner')),
                  ],
                  onChanged: (v) => setState(() => _businessType = v ?? _businessType),
                ),
                const SizedBox(height: 12),
                TextField(controller: _companyName, decoration: const InputDecoration(labelText: 'Company Name', prefixIcon: Icon(Icons.apartment))),
                const SizedBox(height: 12),
                TextField(controller: _contactPerson, decoration: const InputDecoration(labelText: 'Contact Person', prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 12),
                TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
                const SizedBox(height: 12),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
                const SizedBox(height: 12),
                TextField(controller: _city, decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city))),
                const SizedBox(height: 12),
                TextField(controller: _registration, decoration: const InputDecoration(labelText: 'Registration / CR Number', prefixIcon: Icon(Icons.badge))),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('First Vehicle (optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(controller: _plate, decoration: const InputDecoration(labelText: 'Vehicle Plate', prefixIcon: Icon(Icons.confirmation_number))),
                const SizedBox(height: 12),
                TextField(controller: _vehicleType, decoration: const InputDecoration(labelText: 'Vehicle Type', prefixIcon: Icon(Icons.directions_bus))),
                const SizedBox(height: 12),
                TextField(controller: _capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seats', prefixIcon: Icon(Icons.event_seat))),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save and Join Platform'),
          ),
        ],
      ),
    );
  }
}
