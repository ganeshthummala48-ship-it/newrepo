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

  // --- Wake word / continuous listening state ---
  static bool _isWakeWordListening = false;
  static bool get isWakeWordListening => _isWakeWordListening;

  // Multilingual wake words (all map to the same trigger)
  static const List<String> _wakeWords = [
    'hey farmer', 'hey farmerai', 'farmer ai',
    'किसान', 'kisan',            // Hindi
    'రైతు', 'raitu',             // Telugu
    'விவசாயி', 'vivasayi',       // Tamil
    'ರೈತ', 'raita',              // Kannada
    'কৃষক', 'krishak',           // Bengali
    'शेतकरी', 'shetkari',        // Marathi
    'ખેડૂત', 'khedut',           // Gujarati
    'കർഷക', 'karshaka',          // Malayalam
    'ਕਿਸਾਨ',                     // Punjabi
    'ଚାଷୀ', 'chasi',             // Odia
  ];

  static VoidCallback? _onWakeWordDetected;
  static String _wakeWordLocale = 'en-IN';

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

  // ---------------------------------------------------------------------------
  // Wake-word / Hands-Free continuous listening
  // ---------------------------------------------------------------------------

  /// Start continuous background listening for a wake word.
  /// [languageCode] is used to pick the STT locale.
  /// [onDetected] is called (on the Dart main isolate) when the wake word is heard.
  static Future<void> startWakeWordListening(
    String languageCode,
    VoidCallback onDetected,
  ) async {
    if (_isWakeWordListening) return;
    _isWakeWordListening = true;
    _onWakeWordDetected = onDetected;
    _wakeWordLocale = getLocaleId(languageCode);
    _wakeWordLoop();
  }

  /// Stop continuous background listening.
  static Future<void> stopWakeWordListening() async {
    _isWakeWordListening = false;
    _onWakeWordDetected = null;
    await _speech.stop();
  }

  /// Pause the loop temporarily (called while command listening is active).
  static void pauseWakeWord() {
    _speech.stop();
  }

  /// Resume the wake-word loop (called after command listening finishes).
  static void resumeWakeWord() {
    if (_isWakeWordListening) {
      _wakeWordLoop();
    }
  }

  static bool _containsWakeWord(String text) {
    final lower = text.toLowerCase();
    for (final w in _wakeWords) {
      if (lower.contains(w.toLowerCase())) return true;
    }
    return false;
  }

  /// Internal loop: listen → check → restart.
  static Future<void> _wakeWordLoop() async {
    if (!_isWakeWordListening) return;

    // Don't start if a command is being processed
    if (_state == VoiceState.listening || _state == VoiceState.speaking) {
      await Future.delayed(const Duration(seconds: 1));
      _wakeWordLoop();
      return;
    }

    final initialized = await _speech.initialize(
      debugLogging: false,
      onError: (_) {
        // On error, wait a moment and retry
        if (_isWakeWordListening) {
          Future.delayed(const Duration(seconds: 2), _wakeWordLoop);
        }
      },
    );

    if (!initialized || !_isWakeWordListening) return;

    final wakeCompleter = Completer<void>();

    await _speech.listen(
      onResult: (val) {
        if (_containsWakeWord(val.recognizedWords) && !wakeCompleter.isCompleted) {
          wakeCompleter.complete();
        }
      },
      localeId: _wakeWordLocale,
      listenFor: const Duration(seconds: 6),
      pauseFor: const Duration(seconds: 4),
      listenOptions: stt.SpeechListenOptions(cancelOnError: false),
    );

    // Wait: either wake word found OR the listen session ends naturally
    await Future.any([
      wakeCompleter.future,
      Future.delayed(const Duration(seconds: 10)),
    ]);

    await _speech.stop();

    if (!_isWakeWordListening) return;

    if (wakeCompleter.isCompleted) {
      // Wake word was heard — fire callback
      _onWakeWordDetected?.call();
      // Give time for the command overlay to open before looping back
      await Future.delayed(const Duration(seconds: 8));
    } else {
      // Normal timeout — restart immediately
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Loop again
    _wakeWordLoop();
  }

  // ---------------------------------------------------------------------------
  // Normal TTS + Command listening
  // ---------------------------------------------------------------------------

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

  /// Listen for a voice command.
  ///
  /// Listens until the user finishes speaking (detected via silence) or until
  /// [maxListenDuration] elapses. The [pauseFor] silence gap (default 2.5 s)
  /// determines how long after the user stops talking before the session ends.
  static Future<String> listenForCommand(
    String languageCode, {
    Function(String)? onPartialResult,
    Duration maxListenDuration = const Duration(seconds: 30),
    Duration silenceGap = const Duration(milliseconds: 2500),
  }) async {
    // 🛑 Ensure we stop speaking before we start listening
    await stop();
    
    final completer = Completer<String>();

    bool available = await _speech.initialize(
      debugLogging: false,
      onStatus: (status) {
        // 'done' fires when the engine finishes after silence
        if ((status == 'notListening' || status == 'done') &&
            !completer.isCompleted) {
          _setState(VoiceState.idle);
          completer.complete('');
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
        // Complete as soon as the engine signals a final result
        if (val.finalResult && !completer.isCompleted) {
          completer.complete(lastResult);
        }
      },
      localeId: getLocaleId(languageCode),
      listenFor: maxListenDuration,   // hard upper bound
      pauseFor: silenceGap,           // stops naturally after silence
    );

    // Hard-cap safety: if neither finalResult nor status 'done' fires within
    // maxListenDuration + 5 s, resolve with whatever we have so far.
    Future.delayed(maxListenDuration + const Duration(seconds: 5), () {
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
