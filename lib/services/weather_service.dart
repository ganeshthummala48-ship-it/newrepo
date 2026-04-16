import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  static Future<Map<String, dynamic>> getCurrentWeather(String location) async {
    final url = Uri.parse(
      '$_baseUrl/weather?q=$location&appid=${AppConstants.weatherApiKey}&units=metric',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load weather data: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getForecast(String location) async {
    final url = Uri.parse(
      '$_baseUrl/forecast?q=$location&appid=${AppConstants.weatherApiKey}&units=metric',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load forecast data: ${response.body}');
    }
  }

  static String getWeatherDescription(Map<String, dynamic> weatherData) {
    if (weatherData.containsKey('weather') &&
        weatherData['weather'].isNotEmpty) {
      return weatherData['weather'][0]['description'];
    }
    return 'Unknown';
  }

  static double getTemperature(Map<String, dynamic> weatherData) {
    return (weatherData['main']['temp'] as num).toDouble();
  }

  static int getHumidity(Map<String, dynamic> weatherData) {
    return weatherData['main']['humidity'] as int;
  }
}
