import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// Fetches agricultural risk data using the Ambee API (https://www.getambee.com).
/// Uses real GPS coordinates for hyperlocal environmental alerts.
class RiskService {
  static const String _ambeeBase = 'https://api.ambeedata.com';
  static const Duration _timeout = Duration(seconds: 15);

  static Map<String, String> get _headers => {
    'x-api-key': AppConstants.ambeeApiKey,
    'Content-Type': 'application/json',
  };

  // ─── Current Weather by coordinates ───────────────────────────────────────
  static Future<Map<String, dynamic>?> getCurrentWeatherByCoords({
    required double lat,
    required double lon,
  }) async {
    // Try Ambee weather endpoint
    final url = Uri.parse('$_ambeeBase/weather/by-lat-lng?lat=$lat&lng=$lon');
    try {
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Ambee returns { "data": {...} }
        return body;
      }
      print(
        'Ambee weather ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 200))}',
      );
    } catch (e) {
      print('Ambee weather error: $e');
    }

    // Fallback: OpenWeatherMap with coordinates
    try {
      final owmUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$lat&lon=$lon&appid=${AppConstants.weatherApiKey}&units=metric',
      );
      final res = await http.get(owmUrl).timeout(_timeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Normalize to a similar shape as Ambee
        return {
          'data': {
            'temperature': body['main']['temp'],
            'humidity': body['main']['humidity'],
            'windSpeed': body['wind']['speed'],
            'description': body['weather'][0]['description'],
            'summary': body['weather'][0]['main'],
            'precipitation': body['rain']?['1h'] ?? 0,
          },
          'source': 'OpenWeatherMap',
        };
      }
    } catch (e) {
      print('OWM weather fallback error: $e');
    }

    return null;
  }

  // ─── Severe weather / disaster alerts ─────────────────────────────────────
  static Future<List<dynamic>> getSevereWeatherAlerts({
    required double lat,
    required double lon,
  }) async {
    // Try Ambee disasters endpoint
    try {
      final url = Uri.parse(
        '$_ambeeBase/disasters/by-lat-lng?lat=$lat&lng=$lon',
      );
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List?) ?? [];
      }
      print(
        'Ambee disasters ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 200))}',
      );
    } catch (e) {
      print('Ambee disasters error: $e');
    }

    // Fallback: OpenWeatherMap alerts (free tier may not include this)
    try {
      final owmUrl = Uri.parse(
        'https://api.openweathermap.org/data/3.0/onecall'
        '?lat=$lat&lon=$lon&exclude=current,minutely,hourly,daily'
        '&appid=${AppConstants.weatherApiKey}',
      );
      final res = await http.get(owmUrl).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final alerts = data['alerts'] as List? ?? [];
        return alerts
            .map(
              (a) => {
                'event': a['event'],
                'description': a['description'],
                'type': 'Weather Alert',
              },
            )
            .toList();
      }
    } catch (e) {
      print('OWM alerts fallback error: $e');
    }

    return []; // No alerts = no data, not an error
  }

  // ─── Pollen data ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getPollenData({
    required double lat,
    required double lon,
  }) async {
    try {
      final url = Uri.parse(
        '$_ambeeBase/latest/pollen/by-lat-lng?lat=$lat&lng=$lon',
      );
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) return jsonDecode(res.body);
      print('Ambee pollen ${res.statusCode}');
    } catch (e) {
      print('Ambee pollen error: $e');
    }
    return null;
  }

  // ─── Composite summary for AI prompt ──────────────────────────────────────
  static String buildWeatherContext(Map<String, dynamic>? weather) {
    if (weather == null) return 'Weather data unavailable.';
    try {
      // Handle both Ambee { data: {...} } and normalized OWM format
      final data = (weather['data'] is Map)
          ? weather['data'] as Map<String, dynamic>
          : weather;

      final parts = <String>[];
      final temp = data['temperature'] ?? data['temp'];
      final humidity = data['humidity'];
      final precip = data['precipIntensity'] ?? data['precipitation'];
      final windSpeed = data['windSpeed'] ?? data['wind_speed'];
      final summary = data['summary'] ?? data['description'];
      final source = weather['source'] ?? 'Ambee';

      if (temp != null) parts.add('Temperature: ${temp}°C');
      if (humidity != null) parts.add('Humidity: $humidity%');
      if (precip != null && precip != 0) parts.add('Precipitation: $precip mm');
      if (windSpeed != null) parts.add('Wind: $windSpeed km/h');
      if (summary != null) parts.add('Conditions: $summary');
      parts.add('(Source: $source)');

      return parts.join(', ');
    } catch (e) {
      return 'Could not parse weather data.';
    }
  }
}
