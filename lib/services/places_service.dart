import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class PlacesService {
  final http.Client _client;

  PlacesService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<PlacePrediction>> autocomplete(String query,
      {double? lat, double? lng, double radius = 50000}) async {
    if (query.trim().isEmpty) return [];

    // Google Places REST endpoints do not allow browser CORS. Frappe keeps
    // the Google key private and returns the same normalized place contract.
    final uri = Uri.parse(
      '${AppConstants.backendBaseUrl}/api/method/ftms.api.maps.search_ksa_places',
    ).replace(queryParameters: {'query': query.trim(), 'limit': '8'});

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = data['message'] as List<dynamic>? ?? [];
      final places = rows.map((row) {
        final place = row as Map<String, dynamic>;
        final mainText = (place['name_en'] ?? place['display_name'] ?? '').toString();
        final description = (place['display_name'] ?? mainText).toString();
        return PlacePrediction(
          placeId: (place['place_id'] ?? '').toString(),
          description: description,
          mainText: mainText,
          secondaryText: description == mainText
              ? (place['region'] ?? '').toString()
              : description,
          latitude: (place['latitude'] as num?)?.toDouble(),
          longitude: (place['longitude'] as num?)?.toDouble(),
        );
      }).where((place) => place.mainText.isNotEmpty).toList();
      final normalizedQuery = query.trim().toLowerCase();
      places.sort((a, b) {
        int score(PlacePrediction place) {
          final main = place.mainText.toLowerCase();
          final description = place.description.toLowerCase();
          if (main == normalizedQuery) return 0;
          if (main.startsWith(normalizedQuery)) return 1;
          if (description.startsWith(normalizedQuery)) return 2;
          return 3;
        }
        return score(a).compareTo(score(b));
      });
      return places;
    } catch (_) {
      return [];
    }
  }

  Future<PlaceDetails?> getDetails(String placeId) async {
    return null;
  }

  void dispose() {
    _client.close();
  }
}

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double? latitude;
  final double? longitude;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.latitude,
    this.longitude,
  });
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
  });
}
