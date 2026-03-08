import 'package:flutter/material.dart';

class AppConstants {
  // 🔗 API Base URLs
  // Use http://10.0.2.2:8000 for Android Emulator connecting to localhost
  // Use http://127.0.0.1:8000 for iOS Simulator
  // Use actual IP for Physical Devices
  // 🌐 Production URL – backend deployed on Render (works without laptop)
  // To switch back to local dev: replace with 'http://192.168.1.11:8000'
  static const String _renderUrl = 'https://farmerai-backend.onrender.com';

  static String get baseUrl => _renderUrl;

  // 🔑 API Keys
  static const String marketApiKey =
      '579b464db66ec23bdd000001f5b1cddc55b948ae5f23f72870cde25e';
  static const String weatherApiKey = '2254ffc3bbd3014aec24a3f9463afebc';

  // 🤖 AI is handled server-side via Groq API (no local Ollama needed)

  // 🎨 Global UI Colors
  static const Color primaryColor = Colors.green;
  static const Color secondaryColor = Colors.lightGreen;
  static const Color backgroundColor = Color(0xFFF5F7F5);
  static const Color cardColor = Colors.white;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Colors.green, Colors.lightGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 📏 UI Helpers
  static const double defaultPadding = 16.0;
  static const double cardRadius = 16.0;

  static final BorderRadius defaultBorderRadius = BorderRadius.circular(
    cardRadius,
  );
}
