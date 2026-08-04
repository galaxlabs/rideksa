import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/places_service.dart';
import '../../widgets/place_autocomplete_field.dart';
import '../../widgets/sidebar_page.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final PlacesService _places = PlacesService();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  PlaceDetails? _fromPlace;
  PlaceDetails? _toPlace;
  List<Map<String, dynamic>> _suggestedRoutes = [];
  bool _showSuggestions = true;

  static const _popularRoutes = [
    {'from': 'Riyadh', 'to': 'Jeddah', 'km': 949},
    {'from': 'Riyadh', 'to': 'Dammam', 'km': 395},
    {'from': 'Riyadh', 'to': 'Makkah', 'km': 793},
    {'from': 'Riyadh', 'to': 'Madinah', 'km': 720},
    {'from': 'Jeddah', 'to': 'Makkah', 'km': 79},
    {'from': 'Jeddah', 'to': 'Madinah', 'km': 420},
    {'from': 'Dammam', 'to': 'Riyadh', 'km': 395},
    {'from': 'Dammam', 'to': 'Al-Ahsa', 'km': 150},
    {'from': 'Makkah', 'to': 'Madinah', 'km': 447},
    {'from': 'Abha', 'to': 'Jeddah', 'km': 600},
  ];

  void _onFromSelected(PlaceDetails place) {
    _fromPlace = place;
    _filterRoutes();
  }

  void _onToSelected(PlaceDetails place) {
    _toPlace = place;
    _filterRoutes();
  }

  void _filterRoutes() {
    final from = (_fromPlace?.name ?? _fromController.text).toLowerCase();
    final to = (_toPlace?.name ?? _toController.text).toLowerCase();
    setState(() {
      if (from.isEmpty && to.isEmpty) {
        _suggestedRoutes = [];
        _showSuggestions = true;
        return;
      }
      _suggestedRoutes = _popularRoutes.where((r) {
        final matchFrom =
            from.isEmpty || r['from'].toString().toLowerCase().contains(from);
        final matchTo =
            to.isEmpty || r['to'].toString().toLowerCase().contains(to);
        return matchFrom && matchTo;
      }).toList();
      _showSuggestions = false;
    });
  }

  void _selectRoute(Map<String, dynamic> route) {
    context.push('/passenger/book', extra: route);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _places.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SidebarPage(
      title: 'Search Routes',
      path: '/passenger/search',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  PlaceAutocompleteField(
                    placesService: _places,
                    controller: _fromController,
                    labelText: 'From (City)',
                    prefixIcon: Icons.trip_origin,
                    onPlaceSelected: _onFromSelected,
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.swap_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  PlaceAutocompleteField(
                    placesService: _places,
                    controller: _toController,
                    labelText: 'To (City)',
                    prefixIcon: Icons.location_on,
                    onPlaceSelected: _onToSelected,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_fromController.text.isNotEmpty &&
                              _toController.text.isNotEmpty)
                          ? _filterRoutes
                          : null,
                      child: const Text('Search Routes'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_showSuggestions) ...[
              Text(
                'Popular Routes',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._popularRoutes.map(
                (r) =>
                    _PopularRouteCard(route: r, onTap: () => _selectRoute(r)),
              ),
            ] else ...[
              if (_suggestedRoutes.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.textSecondary.withAlpha(80),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No routes found for this search',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different city name',
                            style: TextStyle(
                              color: AppColors.textSecondary.withAlpha(150),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                Text(
                  'Available Routes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._suggestedRoutes.map(
                  (r) =>
                      _PopularRouteCard(route: r, onTap: () => _selectRoute(r)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PopularRouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  final VoidCallback onTap;
  const _PopularRouteCard({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final src = route['from'] as String? ?? '';
    final dst = route['to'] as String? ?? '';
    final km = route['km'] ?? 0;
    final colors = AppColors.vehicleColors.values.toList();
    final color = colors[src.hashCode % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    src.isNotEmpty ? src[0].toUpperCase() : 'R',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$src → $dst',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$km km',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary.withAlpha(120),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
