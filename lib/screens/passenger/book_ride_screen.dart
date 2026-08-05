import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/places_service.dart';
import '../../services/pricing_service.dart';
import '../../services/frappe_api_client.dart';
import '../../widgets/place_autocomplete_field.dart';

class BookRideScreen extends StatefulWidget {
  final Map<String, dynamic>? routeExtra;
  const BookRideScreen({super.key, this.routeExtra});
  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  final PlacesService _places = PlacesService();
  final PricingService _pricing = PricingService();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();
  final _groupController = TextEditingController();
  final _pickupTimeController = TextEditingController(text: '07:00');
  final _dropoffTimeController = TextEditingController(text: '17:00');
  final _durationController = TextEditingController(text: '1 month');
  final _rentalDaysController = TextEditingController(text: '1');
  PlaceDetails? _pickupPlace;
  PlaceDetails? _dropoffPlace;
  int _passengers = 1;
  bool _isGroupBooking = false;
  bool _submitting = false;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _vehicleType = 'Sedan';
  String _bookingMode = 'scheduled';
  String _serviceType = 'ride';
  String _routineCategory = 'office';
  String _fareMode = 'flat';
  double _routeKm = 0;
  double _baseFare = 0;
  double _perPassengerRate = 0;
  List<_PassengerRow> _passengerRows = [];
  List<Map<String, dynamic>> _savedGroups = [];
  String? _selectedSavedGroup;
  bool _loadingGroups = false;

  double get _fare => double.tryParse(_priceController.text) ?? 0;
  double get _platformFee => _fare * 0.05;

  Future<void> _loadSavedGroups() async {
    if (_loadingGroups) return;
    setState(() => _loadingGroups = true);
    try {
      final frappe = context.read<FrappeApiClient>();
      _savedGroups = await frappe.listMyGroups();
    } catch (_) {
      _savedGroups = [];
    } finally {
      if (mounted) setState(() => _loadingGroups = false);
    }
  }

  Future<void> _applySavedGroup(String groupId) async {
    try {
      final frappe = context.read<FrappeApiClient>();
      final group = await frappe.getGroup(groupId);
      final passengers = (group['passengers'] as List?) ?? [];
      for (final row in _passengerRows) {
        row.controller.dispose();
      }
      _passengerRows.clear();
      _groupController.text = group['group_name']?.toString() ?? '';
      for (final p in passengers) {
        _passengerRows.add(_PassengerRow(
          controller: TextEditingController(text: p['passenger_name']?.toString() ?? ''),
          mobileController: TextEditingController(text: p['mobile_no']?.toString() ?? ''),
        ));
      }
      _passengers = _passengerRows.length;
      _selectedSavedGroup = groupId;
      setState(() {});
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _passengerRows.add(_PassengerRow(controller: TextEditingController()));
    final route = widget.routeExtra;
    if (route != null) {
      final from = route['from'] as String? ?? route['source'] as String? ?? '';
      final to =
          route['to'] as String? ?? route['destination'] as String? ?? '';
      _pickupController.text = from;
      _dropoffController.text = to;
      _routeKm =
          (route['km'] as num?)?.toDouble() ??
          (route['distance_km'] as num?)?.toDouble() ??
          0;
    }
    _dateController.text = _formatDate(_date);
    _refreshFare();
  }

  double get _flatEstimate => _routeKm > 0
      ? _baseFare > 0
            ? _baseFare
            : (_routeKm * 1.5)
      : _pricing.estimate(vehicleType: _vehicleType, passengers: 1);

  Future<void> _refreshFare() async {
    double flat = 0;
    double perPassenger = 0;
    try {
      final frappe = context.read<FrappeApiClient>();
      final quote = await frappe.getPriceQuote(
        vehicleType: _vehicleType,
        distanceKm: _routeKm > 0 ? _routeKm : null,
        passengerCount: _passengers,
        fareMode: _fareMode,
      );
      if (quote.isNotEmpty) {
        flat = (quote['final_fare'] as num?)?.toDouble() ?? 0;
        perPassenger = (quote['per_passenger_rate'] as num?)?.toDouble() ?? 0;
        final ruleMin = (quote['minimum_fare'] as num?)?.toDouble();
        if (flat > 0) _baseFare = flat;
        if (perPassenger > 0) _perPassengerRate = perPassenger;
        if (ruleMin != null && _baseFare < ruleMin) _baseFare = ruleMin;
      }
    } catch (_) {}
    final display = _fareMode == 'flat'
        ? (flat > 0 ? flat : _flatEstimate)
        : (_perPassengerRate > 0
              ? _perPassengerRate * _passengers
              : _flatEstimate * _passengers);
    _priceController.text = display.toStringAsFixed(0);
    setState(() {});
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null)
      setState(() {
        _date = d;
        _dateController.text = _formatDate(d);
      });
  }

  List<Map<String, dynamic>> _buildPassengerList() {
    final rows = _passengerRows
        .map(
          (r) => {
            'passenger_name': r.controller.text.trim(),
            'mobile_no': r.mobile.trim(),
          },
        )
        .where((r) => (r['passenger_name'] as String).isNotEmpty)
        .toList();
    if (rows.isNotEmpty) return rows;
    return [
      {
        'passenger_name':
            context.read<AuthProvider>().user?.displayName ?? 'Passenger',
        'mobile_no': context.read<AuthProvider>().user?.phone ?? '',
      },
    ];
  }

  Future<void> _submit() async {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty)
      return;
    setState(() => _submitting = true);
    try {
      final rideProvider = context.read<RideProvider>();
      final auth = context.read<AuthProvider>();
      final loc = context.read<LocationProvider>();
      if (_bookingMode == 'now') {
        final ok = await loc.initialize();
        if (!ok || loc.position == null) {
          throw Exception(
            'Current booking requires GPS pickup from your current city/location. Use scheduled booking for other cities.',
          );
        }
        if (_pickupPlace == null)
          _pickupController.text = 'Current GPS location';
      }
      final passengerRows = _buildPassengerList();
      final rowCount = passengerRows.length > 1
          ? passengerRows.length
          : _passengers;
      final userId = auth.user?.uid;
      if (userId == null) throw Exception('Login is required');
      final preferences = await SharedPreferences.getInstance();
      final operationKey = 'pending_booking_operation:$userId';
      var operationId = preferences.getString(operationKey);
      if (operationId == null) {
        operationId = const Uuid().v4();
        await preferences.setString(operationKey, operationId);
      }
      final groupNameText = _isGroupBooking ? _groupController.text.trim() : null;
      if (groupNameText != null && groupNameText.isNotEmpty) {
        try {
          final frappe = context.read<FrappeApiClient>();
          await frappe.saveGroup(
            groupName: groupNameText,
            groupLeaderName: auth.user?.displayName,
            groupLeaderMobile: auth.user?.phone,
            isGroupLeaderSelf: true,
            group: _selectedSavedGroup,
            passengers: passengerRows,
          );
        } catch (_) {
          // Group save is best-effort; booking should still proceed
        }
      }
      await rideProvider.createRideRequest(
        id: operationId,
        pickupLocation: _pickupController.text.trim(),
        dropoffLocation: _dropoffController.text.trim(),
        pickupLat: _pickupPlace?.latitude ?? loc.position?.latitude,
        pickupLng: _pickupPlace?.longitude ?? loc.position?.longitude,
        travelDate: _date,
        vehicleType: _vehicleType,
        passengersCount: rowCount,
        offeredPrice: _fare,
        bookingType: _isGroupBooking ? 'group' : 'single',
        serviceType: _serviceType,
        routineCategory: _serviceType == 'pick_drop' ? _routineCategory : null,
        contractDuration: _serviceType == 'pick_drop'
            ? _durationController.text.trim()
            : null,
        pickupTime: _serviceType == 'pick_drop'
            ? _pickupTimeController.text.trim()
            : null,
        dropoffTime: _serviceType == 'pick_drop'
            ? _dropoffTimeController.text.trim()
            : null,
        rentalDays: _serviceType == 'rent_car'
            ? int.tryParse(_rentalDaysController.text.trim()) ?? 1
            : 1,
        groupName: groupNameText,
        passengerNames: passengerRows
            .map((r) => r['passenger_name'].toString())
            .toList(),
        passengerRows: passengerRows,
        passengerId: auth.user?.uid,
        passengerName: auth.user?.displayName,
        passengerPhone: auth.user?.phone,
        notes: _notesController.text.trim(),
      );
      await preferences.remove(operationKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride request submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _groupController.dispose();
    _pickupTimeController.dispose();
    _dropoffTimeController.dispose();
    _durationController.dispose();
    _rentalDaysController.dispose();
    for (final row in _passengerRows) {
      row.controller.dispose();
    }
    _places.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlaceAutocompleteField(
              placesService: _places,
              controller: _pickupController,
              labelText: 'Pickup City / GPS Location',
              prefixIcon: Icons.trip_origin,
              onPlaceSelected: (p) => _pickupPlace = p,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final loc = context.read<LocationProvider>();
                  final ok = await loc.initialize();
                  if (!mounted || !ok || loc.position == null) return;
                  setState(() {
                    _pickupController.text = 'Current GPS location';
                  });
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Use my current GPS pickup'),
              ),
            ),
            const SizedBox(height: 12),
            PlaceAutocompleteField(
              placesService: _places,
              controller: _dropoffController,
              labelText: 'Drop-off Location',
              prefixIcon: Icons.location_on,
              onPlaceSelected: (p) => _dropoffPlace = p,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _serviceType,
              decoration: const InputDecoration(
                labelText: 'Service Type',
                prefixIcon: Icon(Icons.miscellaneous_services),
              ),
              items: const [
                DropdownMenuItem(value: 'ride', child: Text('Ride / Trip')),
                DropdownMenuItem(
                  value: 'pick_drop',
                  child: Text('Scheduled Pick & Drop'),
                ),
                DropdownMenuItem(
                  value: 'rent_car',
                  child: Text('Rent a Car / Vehicle'),
                ),
              ],
              onChanged: (v) => setState(() {
                _serviceType = v ?? _serviceType;
                if (_serviceType == 'pick_drop') _bookingMode = 'scheduled';
              }),
            ),
            const SizedBox(height: 12),
            if (_serviceType == 'pick_drop') ...[
              DropdownButtonFormField<String>(
                value: _routineCategory,
                decoration: const InputDecoration(
                  labelText: 'Routine Type',
                  prefixIcon: Icon(Icons.business_center),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'kids_school',
                    child: Text('Kids / School'),
                  ),
                  DropdownMenuItem(
                    value: 'factory',
                    child: Text('Factory Staff'),
                  ),
                  DropdownMenuItem(
                    value: 'site',
                    child: Text('Project / Site'),
                  ),
                  DropdownMenuItem(value: 'company', child: Text('Company')),
                  DropdownMenuItem(value: 'office', child: Text('Office')),
                ],
                onChanged: (v) =>
                    setState(() => _routineCategory = v ?? _routineCategory),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pickupTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Time',
                        prefixIcon: Icon(Icons.schedule),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _dropoffTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Drop Time',
                        prefixIcon: Icon(Icons.schedule_send),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Contract Duration',
                  hintText: 'Example: 1 month, 6 months, school term',
                  prefixIcon: Icon(Icons.date_range),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_serviceType == 'rent_car') ...[
              TextField(
                controller: _rentalDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rental Days',
                  prefixIcon: Icon(Icons.car_rental),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'now',
                  label: Text('On time'),
                  icon: Icon(Icons.flash_on),
                ),
                ButtonSegment(
                  value: 'scheduled',
                  label: Text('Scheduled'),
                  icon: Icon(Icons.event),
                ),
              ],
              selected: {_bookingMode},
              onSelectionChanged: (v) => setState(() => _bookingMode = v.first),
            ),
            const SizedBox(height: 8),
            Text(
              _bookingMode == 'now'
                  ? 'On-time booking uses your current city/GPS pickup.'
                  : _serviceType == 'pick_drop'
                  ? 'Pick & drop is a routine contract marketplace request.'
                  : 'Scheduled booking can start from any city.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Travel Date',
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.date_range),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vehicle Type',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Sedan', 'SUV', 'Van', 'Bus', 'Luxury']
                  .map(
                    (v) => ChoiceChip(
                      label: Text(v),
                      selected: _vehicleType == v,
                      selectedColor: AppColors.primaryLight,
                      onSelected: (_) => setState(() {
                        _vehicleType = v;
                        _refreshFare();
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Group / family booking'),
              subtitle: const Text(
                'Add family members or group passengers (one row per person)',
              ),
              value: _isGroupBooking,
              onChanged: (v) {
                setState(() => _isGroupBooking = v);
                if (v) _loadSavedGroups();
              },
            ),
            if (_isGroupBooking) ...[
              TextField(
                controller: _groupController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  prefixIcon: Icon(Icons.groups),
                ),
              ),
              const SizedBox(height: 12),
              if (_savedGroups.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  value: _selectedSavedGroup,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Apply saved group',
                    prefixIcon: Icon(Icons.save_outlined),
                  ),
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Enter passengers manually'),
                    ),
                    ..._savedGroups.map((g) => DropdownMenuItem<String?>(
                      value: g['name']?.toString(),
                      child: Text(
                        '${g['group_name'] ?? g['name']} (${g['seat_count'] ?? 0} pax)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                  ],
                  onChanged: (v) {
                    if (v != null) _applySavedGroup(v);
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (_loadingGroups)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              Text(
                'Passengers & Family Members',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Add one row per passenger. These are stored as passenger rows in the booking.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ..._passengerRows.asMap().entries.map(
                (entry) => _PassengerRowInput(
                  key: ValueKey(entry.key),
                  row: entry.value,
                  index: entry.key,
                  canRemove: _passengerRows.length > 1,
                  onRemove: () => setState(() {
                    _passengerRows[entry.key].controller.dispose();
                    _passengerRows.removeAt(entry.key);
                    _passengers = _passengerRows.length;
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _passengerRows.add(
                      _PassengerRow(controller: TextEditingController()),
                    );
                    _passengers = _passengerRows.length;
                  }),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Passenger'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Pricing',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'flat',
                  label: Text('Flat Rate'),
                  icon: Icon(Icons.attach_money),
                ),
                ButtonSegment(
                  value: 'per_passenger',
                  label: Text('Per Passenger'),
                  icon: Icon(Icons.people),
                ),
              ],
              selected: {_fareMode},
              onSelectionChanged: (v) => setState(() {
                _fareMode = v.first;
                _refreshFare();
              }),
            ),
            const SizedBox(height: 6),
            Text(
              _fareMode == 'flat'
                  ? 'Flat rate: total trip fare based on route distance from backend pricing.'
                  : 'Per passenger: fare multiplies by the number of passengers.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Your Offer (﷼)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: AppColors.primary.withAlpha(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _FeeRow(
                      label: 'Platform fee (5%)',
                      value: '﷼ ${_platformFee.toStringAsFixed(2)}',
                    ),
                    const Divider(),
                    _FeeRow(
                      label: 'Driver/company receives',
                      value: '﷼ ${(_fare - _platformFee).toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),
            if (!_isGroupBooking) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Passengers:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle,
                      color: AppColors.primary,
                    ),
                    onPressed: _passengers > 1
                        ? () => setState(() {
                            _passengers--;
                            _refreshFare();
                          })
                        : null,
                  ),
                  Text(
                    '$_passengers',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.primary,
                    ),
                    onPressed: _passengers < 10
                        ? () => setState(() {
                            _passengers++;
                            _refreshFare();
                          })
                        : null,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Ride Request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerRow {
  final TextEditingController controller;
  final TextEditingController mobileController;
  _PassengerRow({required this.controller, TextEditingController? mobileController})
    : mobileController = mobileController ?? TextEditingController();
  String get mobile => mobileController.text.trim();
}

class _PassengerRowInput extends StatelessWidget {
  final _PassengerRow row;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  const _PassengerRowInput({
    super.key,
    required this.row,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: row.controller,
              decoration: InputDecoration(
                labelText: 'Passenger ${index + 1} Name',
                prefixIcon: const Icon(Icons.person, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: row.mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile (optional)',
                prefixIcon: Icon(Icons.phone, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: canRemove ? onRemove : null,
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
