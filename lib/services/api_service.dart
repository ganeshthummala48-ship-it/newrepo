import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {

  // 📊 MARKET PRICE API
  static Future<List<dynamic>> fetchMarketPrices({
    required String state,
    required String district,
    required String commodity,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070'
        '?api-key=${AppConstants.marketApiKey}'
        '&format=json'
        '&filters[state]=$state'
        '&filters[district]=$district'
        '&filters[commodity]=$commodity'
        '&limit=5',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['records'];
      } else {
        throw Exception('Failed to load market prices (Code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error while fetching market prices: $e');
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
        throw Exception('Failed to load weather data (Code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error while fetching weather: $e');
    }
  }
}
