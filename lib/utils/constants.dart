import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // 🔗 API Base URLs
  // Use http://10.0.2.2:8000 for Android Emulator connecting to localhost
  // Use http://127.0.0.1:8000 for iOS Simulator
  // Use actual IP for Physical Devices
  static const String _localIP = '10.86.142.73'; // Your machine IP
  static const String _renderUrl = 'https://newrepo-bhe1.onrender.com';

  static String get baseUrl {
    if (kReleaseMode) {
      return _renderUrl;
    }
    // In debug mode, we prefer local IP but allow for emulator fallback if needed
    // Note: If you are on an Android Emulator, 10.0.2.2 is usually better than the machine IP
    return 'http://$_localIP:8000'; 
  }

  // 🔑 API Keys
  static const String googleMapsApiKey = 'AIzaSyASnZckQ6FaWSl8L6HibN6J9EjfPq86QEM';
  static const String marketApiKey =
      '579b464db66ec23bdd000001f5b1cddc55b948ae5f23f72870cde25e';
  static const String weatherApiKey = '2254ffc3bbd3014aec24a3f9463afebc';
  // Ambee Risk & Environmental Data API
  static const String ambeeApiKey = 'VpudQBx8yAgkBlXoxRM7zwCZwdkuSywt';
  // AgroMonitoring API Key for Soil and Satellite Data
  static const String agroMonitoringApiKey = '34973b5563d691891776bf2f6774ad13';

  // 🤖 AI is handled server-side via Groq API (no local Ollama needed)

  // 🎨 Global UI Colors
  static const Color primaryColor = Colors.green;
  static const Color secondaryColor = Colors.lightGreen;
  static const Color backgroundColor = Color(0xFFF5F7F5);
  static const Color cardColor = Colors.white;
  static const String appLogo = 'assets/icon/applogo.png';

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

  static const Map<String, String> langNames = {
    "te": "Telugu", "hi": "Hindi", "mr": "Marathi", "ta": "Tamil",
    "bn": "Bengali", "gu": "Gujarati", "kn": "Kannada", "ml": "Malayalam",
    "pa": "Punjabi", "or": "Odia"
  };
}
