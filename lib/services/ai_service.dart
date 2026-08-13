import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AIService {
  static Future<String> getAIResponse(
    String message, {
    String language = "en",
  }) async {
    // Map full language names to ISO codes
    final Map<String, String> langMap = {
      "english": "en", "telugu": "te", "hindi": "hi",
      "marathi": "mr", "tamil": "ta", "bengali": "bn",
      "gujarati": "gu", "kannada": "kn", "malayalam": "ml",
      "punjabi": "pa", "odia": "or",
    };
    String langCode = language.toLowerCase();
    langCode = langMap[langCode] ?? langCode;

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    final body = jsonEncode({
      "question": message,
      "lang": langCode,
    });

    // 1. Try Primary URL (Local / AppConstants.baseUrl)
    try {
      final response = await http.post(
        Uri.parse("${AppConstants.baseUrl}/ask_ai"),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["answer"] ?? "No response from AI.";
      }
    } catch (e) {
      // Ignore primary error and fall through to production Render URL
    }

    // 2. Fallback to Production Render URL
    try {
      final response = await http.post(
        Uri.parse("${AppConstants.renderUrl}/ask_ai"),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["answer"] ?? "No response from AI.";
      }
      return "Cloud AI server returned status ${response.statusCode}. Please try again.";
    } catch (e) {
      return "Network error connecting to AI server. Please check your internet connection.";
    }
  }
}
