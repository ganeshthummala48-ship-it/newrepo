import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  // 📊 MARKET PRICE API
  static Future<List<dynamic>> fetchMarketPrices({
    required String state,
    String? district,
    String? commodity,
    double? lat,
    double? lon,
  }) async {
    try {
      String filterQuery = '&filters[state]=${Uri.encodeComponent(state)}';
      if (district != null && district.isNotEmpty) {
        filterQuery += '&filters[district]=${Uri.encodeComponent(district)}';
      }
      if (commodity != null && commodity.isNotEmpty) {
        filterQuery += '&filters[commodity]=${Uri.encodeComponent(commodity)}';
      }

      // Fetch from data.gov.in directly to bypass backend network limits
      final url = Uri.parse(
        'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070'
        '?api-key=${AppConstants.marketApiKey}'
        '&format=json'
        '$filterQuery'
        '&limit=100', // Increased limit for better regional coverage
      );

      final response = await http.get(url);
      print('ApiService: Calling URL: $url');
      print('ApiService: Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> records = data['records'] ?? [];

        // Apply proximity sorting if location is available
        if (lat != null && lon != null && records.isNotEmpty) {
          final coordinates = await fetchMandiCoordinates();
          
          for (var record in records) {
            final marketName = record['market'] ?? '';
            final districtName = record['district'] ?? '';
            final coord = coordinates[marketName] ?? coordinates[districtName];
            
            if (coord != null) {
              final dLat = double.tryParse(coord['lat'].toString()) ?? 0;
              final dLon = double.tryParse(coord['lon'].toString()) ?? 0;
              record['distance_km'] = _calculateDistance(lat, lon, dLat, dLon);
            } else {
              record['distance_km'] = null;
            }
          }

          records.sort((a, b) {
            final distA = a['distance_km'] as double?;
            final distB = b['distance_km'] as double?;
            if (distA == null && distB == null) return 0;
            if (distA == null) return 1;
            if (distB == null) return -1;
            return distA.compareTo(distB);
          });
        }
        return records;
      } else {
        throw Exception(
          'Failed to load market prices (Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Network error while fetching market prices: $e');
    }
  }

  // 🌍 MANDI COORDINATES API
  static Future<Map<String, dynamic>> fetchMandiCoordinates() async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/mandi-coordinates');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // 📐 DISTANCE HELPER
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = 0.5 - math.cos((lat2 - lat1) * p) / 2 + 
            math.cos(lat1 * p) * math.cos(lat2 * p) * 
            (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(c)); // 2 * R; R = 6371 km
  }

  // 🌍 DISTRICTS API
  static Future<List<String>> fetchDistricts(String state) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/districts?state=${Uri.encodeComponent(state)}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['districts'] ?? []);
      } else {
        throw Exception('Failed to load districts');
      }
    } catch (e) {
      throw Exception('Network error while fetching districts: $e');
    }
  }

  // ☁️ WEATHER API
  static Future<Map<String, dynamic>> fetchWeather(String city) async {
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?q=$city&appid=${AppConstants.weatherApiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load weather data (Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Network error while fetching weather: $e');
    }
  }
}
