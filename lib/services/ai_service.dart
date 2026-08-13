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
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
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
      } else {
        throw Exception("Backend AI Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }
}
