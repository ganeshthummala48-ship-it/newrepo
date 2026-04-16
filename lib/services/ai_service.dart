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

    final url = Uri.parse("${AppConstants.baseUrl}/ask_ai");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "question": message,
          "lang": langCode,
        }),
      );

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
