import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SearchResult {
  final String displayName;
  final LatLng position;
  final String type;

  SearchResult({
    required this.displayName,
    required this.position,
    required this.type,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      displayName: json['display_name'] ?? '',
      position: LatLng(
        double.parse(json['lat'] ?? '0'),
        double.parse(json['lon'] ?? '0'),
      ),
      type: json['type'] ?? 'unknown',
    );
  }
}

class NominatimSearchService {
  static const String baseUrl = 'https://nominatim.openstreetmap.org';

  static Future<List<SearchResult>> search(String query, {
    LatLng? viewbox,
    String countryCode = 'TN', // Tunisia
    int limit = 5,
  }) async {
    try {
      final queryParameters = <String, String>{
        'q': query,
        'format': 'json',
        'limit': limit.toString(),
        'countrycodes': countryCode,
        'addressdetails': '1',
        'extratags': '1',
      };

      if (viewbox != null) {
        queryParameters['viewbox'] = '${viewbox.longitude - 0.1},${viewbox.latitude + 0.1},${viewbox.longitude + 0.1},${viewbox.latitude - 0.1}';
        queryParameters['bounded'] = '1';
      }

      final uri = Uri.parse('$baseUrl/search').replace(
        queryParameters: queryParameters,
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'ConstructionProject/1.0 (your-email@example.com)',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => SearchResult.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Search error: $e');
    }
  }
}