import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/places_service.dart';

class PlaceAutocompleteField extends StatefulWidget {
  final PlacesService placesService;
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final Function(PlaceDetails place)? onPlaceSelected;
  final double? currentLat;
  final double? currentLng;

  const PlaceAutocompleteField({
    super.key,
    required this.placesService,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.onPlaceSelected,
    this.currentLat,
    this.currentLng,
  });

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  List<PlacePrediction> _predictions = [];
  bool _showSuggestions = false;
  Timer? _debounce;
  bool _loading = false;

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() { _predictions = []; _showSuggestions = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loading = true);
      final results = await widget.placesService.autocomplete(
        query,
        lat: widget.currentLat,
        lng: widget.currentLng,
      );
      if (mounted) {
        setState(() {
          _predictions = results;
          _showSuggestions = results.isNotEmpty;
          _loading = false;
        });
      }
    });
  }

  Future<void> _selectPlace(PlacePrediction prediction) async {
    final details = PlaceDetails(
      placeId: prediction.placeId,
      name: prediction.mainText,
      address: prediction.description,
      latitude: prediction.latitude,
      longitude: prediction.longitude,
    );
    if (mounted) {
      widget.controller.text = prediction.mainText;
      setState(() => _showSuggestions = false);
      widget.onPlaceSelected?.call(details);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            prefixIcon: Icon(widget.prefixIcon,
                color: widget.labelText.contains('Drop') ? Colors.red : AppColors.primary),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          widget.controller.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null),
          ),
          onChanged: _onSearchChanged,
          onTap: () {
            if (_predictions.isNotEmpty) {
              setState(() => _showSuggestions = true);
            }
          },
        ),
        if (_showSuggestions && _predictions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _predictions.length,
                separatorBuilder: (_, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = _predictions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.location_on_outlined,
                        color: AppColors.primary, size: 20),
                    title: Text(p.mainText,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: Text(p.secondaryText,
                        style: const TextStyle(fontSize: 12)),
                    onTap: () => _selectPlace(p),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
