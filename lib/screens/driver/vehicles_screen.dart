import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/frappe_api_client.dart';

class DriverVehiclesScreen extends StatefulWidget {
  const DriverVehiclesScreen({super.key});
  @override
  State<DriverVehiclesScreen> createState() => _DriverVehiclesScreenState();
}

class _DriverVehiclesScreenState extends State<DriverVehiclesScreen> {
  final _plate = TextEditingController();
  final _capacity = TextEditingController(text: '4');
  List<Map<String, dynamic>> _makes = [], _models = [], _types = [], _vehicles = [];
  String? _make, _model, _type, _error;
  bool _loading = true, _saving = false;

  FrappeApiClient get _api => context.read<FrappeApiClient>();

  List<Map<String, dynamic>> _rows(dynamic value) => value is List
      ? value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
      : [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final catalog = await _api.getVehicleCatalog();
      final vehicles = await _api.listMyVehicles();
      if (!mounted) return;
      setState(() { _makes = _rows(catalog['makes']); _vehicles = vehicles; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); }
  }

  Future<void> _onMakeChanged(String? value) async {
    setState(() { _make = value; _model = null; _type = null; _models = []; _types = []; });
    if (value == null) return;
    try {
      final catalog = await _api.getVehicleCatalog(make: value);
      if (mounted) setState(() => _models = _rows(catalog['models']));
    } catch (_) {}
  }

  Future<void> _onModelChanged(String? value) async {
    setState(() { _model = value; _type = null; _types = []; });
    if (value == null) return;
    try {
      final catalog = await _api.getVehicleCatalog(make: _make, model: value);
      if (mounted) setState(() => _types = _rows(catalog['types']));
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_plate.text.trim().isEmpty || _make == null || _model == null) {
      setState(() => _error = 'Plate, make, and model are required.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await _api.registerVehicle(
        plateNo: _plate.text.trim(), vehicleMake: _make!, vehicleModel: _model!,
        vehicleType: _type, passengerCapacity: int.tryParse(_capacity.text.trim()),
      );
      _plate.clear(); _make = null; _model = null; _type = null;
      if (mounted) await _load();
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() { _plate.dispose(); _capacity.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        if (_error != null) Container(
          padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: AppColors.error.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Text(_error!, style: const TextStyle(color: AppColors.error)),
        ),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Register a vehicle', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(controller: _plate, decoration: const InputDecoration(
            labelText: 'Plate number', hintText: 'e.g. ABC 1234 or No Plate',
          )),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _make,
            decoration: const InputDecoration(labelText: 'Make'),
            items: _makes.map((r) => DropdownMenuItem(value: r['name'] as String?, child: Text((r['make_name'] ?? r['name'] ?? '').toString()))).toList(),
            onChanged: _onMakeChanged,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _model,
            decoration: const InputDecoration(labelText: 'Model'),
            items: _models.map((r) => DropdownMenuItem(value: r['name'] as String?, child: Text((r['model_name'] ?? r['name'] ?? '').toString()))).toList(),
            onChanged: _onModelChanged,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Vehicle type'),
            items: _types.map((r) => DropdownMenuItem(value: r['name'] as String?, child: Text((r['type_name'] ?? r['name'] ?? '').toString()))).toList(),
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 10),
          TextField(controller: _capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Passenger capacity')),
          const SizedBox(height: 14),
          ElevatedButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.add), label: Text(_saving ? 'Saving...' : 'Add vehicle')),
        ]))),
        const SizedBox(height: 16),
        Text('Registered vehicles (${_vehicles.length})', style: Theme.of(context).textTheme.titleMedium),
        ..._vehicles.map((v) => Card(child: ListTile(
          leading: const Icon(Icons.directions_car, color: AppColors.primary),
          title: Text((v['vehicle_name'] ?? v['name'] ?? '').toString()),
          subtitle: Text('${v['plate_no'] ?? 'No plate'} \u2022 ${v['vehicle_make'] ?? ''} ${v['vehicle_model'] ?? ''}'),
          trailing: Text((v['status'] ?? 'Active').toString()),
        ))),
      ]),
    );
  }
}