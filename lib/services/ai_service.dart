import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AIService {
  /// Sends a prompt to the backend which bridges to Ollama.
  static Future<String> getAIResponse(String prompt) async {
    try {
      // 🚀 Use the backend /ask_ai endpoint as a bridge
      final url = Uri.parse('${AppConstants.baseUrl}/ask_ai');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'question': prompt}),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'No response from AI.';
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to AI Assistant: $e');
    }
  }

  /// Optional: Use Gemini as a fallback or if explicitly requested
  static Future<String> getGeminiResponse(String prompt) async {
    try {
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${AppConstants.geminiApiKey}",
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      } else {
        throw Exception('Gemini error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to Gemini: $e');
    }
  }
}
