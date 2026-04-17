import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

enum VoiceState { idle, speaking, listening }

class VoiceService {
  static final FlutterTts _flutterTts = FlutterTts();
  static final stt.SpeechToText _speech = stt.SpeechToText();

  static VoiceState _state = VoiceState.idle;
  static VoiceState get state => _state;

  // Listeners for state changes
  static final List<VoidCallback> _stateListeners = [];

  static void addStateListener(VoidCallback listener) {
    _stateListeners.add(listener);
  }

  static void removeStateListener(VoidCallback listener) {
    _stateListeners.remove(listener);
  }

  static void _setState(VoiceState newState) {
    _state = newState;
    for (final listener in _stateListeners) {
      listener();
    }
  }

  static Future<void> init() async {
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      _setState(VoiceState.idle);
    });

    _flutterTts.setCancelHandler(() {
      _setState(VoiceState.idle);
    });

    _flutterTts.setErrorHandler((msg) {
      _setState(VoiceState.idle);
    });
  }

  static String getLocaleId(String languageCode) {
    switch (languageCode) {
      case "hi": return "hi-IN";
      case "te": return "te-IN";
      case "ta": return "ta-IN";
      case "kn": return "kn-IN";
      case "bn": return "bn-IN";
      case "mr": return "mr-IN";
      case "gu": return "gu-IN";
      case "ml": return "ml-IN";
      case "pa": return "pa-IN";
      case "or": return "or-IN";
      default: return "en-IN";
    }
  }

  /// Speak text in the given language code
  static Future<void> speak(String text, String languageCode) async {
    await stop();
    String locale = getLocaleId(languageCode);
    await _flutterTts.setLanguage(locale);
    _setState(VoiceState.speaking);
    await _flutterTts.speak(text);
  }

  /// Convenience: speak using the profile language from LocaleProvider
  static Future<void> speakInProfileLanguage(String text, BuildContext context) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    await speak(text, localeProvider.locale.languageCode);
  }

  /// Get the current language code from context
  static String getLanguageCode(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    return localeProvider.locale.languageCode;
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
    _setState(VoiceState.idle);
  }

  /// Listen for speech input. Returns the recognized text via a Completer.
  static Future<String> listenForCommand(String languageCode, {
    Function(String)? onPartialResult,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // 🛑 Ensure we stop speaking before we start listening
    await stop();
    
    final completer = Completer<String>();

    bool available = await _speech.initialize(
      debugLogging: true,
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          _setState(VoiceState.idle);
          if (!completer.isCompleted) {
            completer.complete('');
          }
        }
      },
      onError: (val) {
        _setState(VoiceState.idle);
        if (!completer.isCompleted) {
          completer.complete('');
        }
      },
    );

    if (!available) {
      return '';
    }

    _setState(VoiceState.listening);
    String lastResult = '';

    await _speech.listen(
      onResult: (val) {
        lastResult = val.recognizedWords;
        if (onPartialResult != null) onPartialResult(lastResult);
        if (val.finalResult && !completer.isCompleted) {
          completer.complete(lastResult);
        }
      },
      localeId: getLocaleId(languageCode),
      listenFor: timeout,
      pauseFor: const Duration(seconds: 3),
    );

    // Safety timeout
    Future.delayed(timeout + const Duration(seconds: 2), () {
      if (!completer.isCompleted) {
        _speech.stop();
        _setState(VoiceState.idle);
        completer.complete(lastResult);
      }
    });

    return completer.future;
  }

  static Future<void> stopListening() async {
    await _speech.stop();
    _setState(VoiceState.idle);
  }
}
