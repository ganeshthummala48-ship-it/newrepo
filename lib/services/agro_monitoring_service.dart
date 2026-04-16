import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AgroMonitoringService {
  static const String _baseUrl = 'https://api.agromonitoring.com/agro/1.0';
  static final String _apiKey = AppConstants.agroMonitoringApiKey;

  // 🌍 1. CREATE POLYGON
  // Registers a farm area to get a polyid. Required for soil and satellite data.
  static Future<String> createPolygon(String name, List<List<double>> coordinates) async {
    final url = Uri.parse('$_baseUrl/polygons?appid=$_apiKey');
    
    final payload = {
      "name": name,
      "geo_json": {
        "type": "Feature",
        "properties": {},
        "geometry": {
          "type": "Polygon",
          "coordinates": [coordinates]
        }
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id']; // polyid
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        // AgroMonitoring returns 400/422 if polygon intersects or is invalid, 
        // try to parse existing if possible, but for simplicity throw error for demo.
        final data = jsonDecode(response.body);
        throw Exception('Failed to create polygon: ${data['message']}');
      } else {
        throw Exception('Failed to create polygon: Code ${response.statusCode}');
      }
    } catch (e) {
      print('AgroMonitoringService Error (createPolygon): $e');
      rethrow;
    }
  }

  // 🔍 1b. GET EXISTING POLYGON ID
  // If polygon already exists, fetch the first one from the account.
  static Future<String?> getExistingPolygonId() async {
    final url = Uri.parse('$_baseUrl/polygons?appid=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> polygons = jsonDecode(response.body);
        if (polygons.isNotEmpty) {
          return polygons.first['id'];
        }
      }
      return null;
    } catch (e) {
      print('AgroMonitoringService Error (getExistingPolygonId): $e');
      return null;
    }
  }

  // 🌱 2. GET CURRENT SOIL DATA
  static Future<Map<String, dynamic>> getCurrentSoilData(String polyId) async {
    final url = Uri.parse('$_baseUrl/soil?polyid=$polyId&appid=$_apiKey');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load soil data: Code ${response.statusCode}');
      }
    } catch (e) {
      print('AgroMonitoringService Error (getCurrentSoilData): $e');
      rethrow;
    }
  }

  // 🌤 3. GET WEATHER FORECAST OR CURRENT
  static Future<List<dynamic>> getWeatherForecast(double lat, double lon) async {
    final url = Uri.parse('$_baseUrl/weather/forecast?lat=$lat&lon=$lon&appid=$_apiKey');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
         throw Exception('Failed to load weather data: Code ${response.statusCode}');
      }
    } catch (e) {
      print('AgroMonitoringService Error (getWeatherForecast): $e');
      rethrow;
    }
  }

  // 🛰 4. GET SATELLITE IMAGES (NDVI / TRUE COLOR)
  static Future<List<dynamic>> getSatelliteImages(String polyId, DateTime start, DateTime end) async {
    final startUnix = (start.millisecondsSinceEpoch / 1000).round();
    final endUnix = (end.millisecondsSinceEpoch / 1000).round();
    
    final url = Uri.parse('$_baseUrl/image/search?start=$startUnix&end=$endUnix&polyid=$polyId&appid=$_apiKey');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Returns list of available images
      } else {
         throw Exception('Failed to load satellite images: Code ${response.statusCode}');
      }
    } catch (e) {
      print('AgroMonitoringService Error (getSatelliteImages): $e');
      rethrow;
    }
  }
}
