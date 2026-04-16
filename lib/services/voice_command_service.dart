import 'package:flutter/material.dart';
import '../screens/market_screen.dart';
import '../screens/disease_screen.dart';
import '../screens/disease_gallery_screen.dart';
import '../screens/crop_screen.dart';
import '../screens/crop_calendar_screen.dart';
import '../screens/assistant_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/history_screen.dart';
import '../screens/yield_profit_screen.dart';
import '../screens/schemes_screen.dart';
import '../screens/risk_alerts_screen.dart';
import '../screens/community_screen.dart';
import '../screens/farm_map_screen.dart';
import '../screens/fertilizer_screen.dart';

class VoiceCommandResult {
  final Widget? screen;
  final String? routeName;
  final String screenLabel;

  VoiceCommandResult({this.screen, this.routeName, required this.screenLabel});
}

class VoiceCommandService {
  /// Map of keywords → screen builders and labels.
  /// Supports all Indian languages.
  static final List<_CommandEntry> _commands = [
    _CommandEntry(
      keywords: [
        'market', 'mandi', 'price', 'prices',
        'बाजार', 'मंडी', // Hindi
        'మార్కెట్', 'ధరలు', // Telugu
        'சந்தை', 'விலை', // Tamil
        'ಮಾರುಕಟ್ಟೆ', 'ಬೆಲೆ', // Kannada
        'বাজার', 'দাম', // Bengali
        'बाजार', 'भाव', // Marathi
        'બજાર', 'ભાવ', // Gujarati
        'വിപണി', 'വില', // Malayalam
        'ਮੰਡੀ', 'ਭਾਅ', // Punjabi
        'ବଜାର', 'ଦାମ', // Odia
      ],
      labels: {
        'en': 'Market Prices', 'hi': 'बाजार भाव', 'te': 'మార్కెట్ ధరలు',
        'ta': 'சந்தை விலைகள்', 'kn': 'ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳು', 'bn': 'বাজার দর',
        'mr': 'बाजारभाव', 'gu': 'બજારભાવ', 'ml': 'വിപണി വിലകൾ',
        'pa': 'ਮੰਡੀ ਭਾਅ', 'or': 'ବଜାର ଦାମ',
      },
      builder: () => const MarketScreen(),
    ),
    _CommandEntry(
      keywords: [
        'disease', 'detection', 'scan',
        'रोग', 'बीमारी', 'రోగం', 'వ్యాధి',
        'நோய்', 'ರೋಗ', 'রোগ', 'रोग', 'રોગ', 'രോഗം', 'ਰੋਗ', 'ରୋଗ',
      ],
      labels: {
        'en': 'Disease Detection', 'hi': 'रोग पहचान', 'te': 'రోగ నిర్ధారణ',
        'ta': 'நோய் கண்டறிதல்', 'kn': 'ರೋಗ ಪತ್ತೆ', 'bn': 'রোগ নির্ণয়',
        'mr': 'रोग ओळख', 'gu': 'રોગ ઓળખ', 'ml': 'രോഗ നിർണ്ണയം',
        'pa': 'ਰੋਗ ਪਛਾਣ', 'or': 'ରୋଗ ଚିହ୍ନଟ',
      },
      builder: () => const DiseaseScreen(),
    ),
    _CommandEntry(
      keywords: [
        'disease guide', 'gallery',
        'रोग गाइड', 'వ్యాధి గైడ్',
        'நோய் வழிகாட்டி', 'ರೋಗ ಮಾರ್ಗದರ್ಶಿ',
        'রোগ গাইড', 'রോ গ গাইড', 'રોગ ગાઇડ', 'രോഗ ഗൈഡ്',
        'ਰੋਗ ਗਾਈਡ', 'ରୋଗ ଗାଇଡ୍',
      ],
      labels: {
        'en': 'Disease Guide', 'hi': 'रोग गाइड', 'te': 'వ్యాధి గైడ్',
        'ta': 'நோய் வழிகாட்டி', 'kn': 'ರೋಗ ಮಾರ್ಗದರ್ಶಿ', 'bn': 'রোগ গাইড',
        'mr': 'रोग मार्गदर्शक', 'gu': 'રોગ ગાઇડ', 'ml': 'രോഗ ഗൈഡ്',
        'pa': 'ਰੋਗ ਗਾਈਡ', 'or': 'ରୋଗ ଗାଇଡ୍',
      },
      builder: () => const DiseaseGalleryScreen(),
    ),
    _CommandEntry(
      keywords: [
        'crop', 'recommendation',
        'फसल', 'సిఫార్సు', 'పంట',
        'பயிர்', 'ಬೆಳೆ', 'ফসল', 'पीक', 'પાક', 'വിള', 'ਫਸਲ', 'ଫସଲ',
      ],
      labels: {
        'en': 'Crop Recommendation', 'hi': 'फसल सिफारिश', 'te': 'పంట సిఫార్సు',
        'ta': 'பயிர் பரிந்துரை', 'kn': 'ಬೆಳೆ ಶಿಫಾರಸು', 'bn': 'ফসল সুপারিশ',
        'mr': 'पीक शिफारस', 'gu': 'પાક ભલામણ', 'ml': 'വിള ശുപാർശ',
        'pa': 'ਫਸਲ ਸਿਫਾਰਸ਼', 'or': 'ଫସଲ ସୁପାରିଶ',
      },
      builder: () => const CropScreen(),
    ),
    _CommandEntry(
      keywords: [
        'calendar', 'crop calendar',
        'कैलेंडर', 'క్యాలెండర్',
        'நாள்காட்டி', 'ಕ್ಯಾಲೆಂಡರ್', 'ক্যালেন্ডার', 'कॅलेंडर', 'કૅલેન્ડર',
        'കലണ്ടർ', 'ਕੈਲੰਡਰ', 'କ୍ୟାଲେଣ୍ଡର',
      ],
      labels: {
        'en': 'Crop Calendar', 'hi': 'फसल कैलेंडर', 'te': 'పంట క్యాలెండర్',
        'ta': 'பயிர் நாள்காட்டி', 'kn': 'ಬೆಳೆ ಕ್ಯಾಲೆಂಡರ್', 'bn': 'ফসল ক্যালেন্ডার',
        'mr': 'पीक कॅलेंडर', 'gu': 'પાક કૅલેન્ડર', 'ml': 'വിള കലണ്ടർ',
        'pa': 'ਫਸਲ ਕੈਲੰਡਰ', 'or': 'ଫସଲ କ୍ୟାଲେଣ୍ଡର',
      },
      builder: () => const CropCalendarScreen(),
    ),
    _CommandEntry(
      keywords: [
        'assistant', 'ai', 'ask', 'chat',
        'सहायक', 'सवाल', 'అసిస్టెంట్', 'అడగండి',
        'உதவியாளர்', 'ಸಹಾಯಕ', 'সহকারী', 'सहाय्यक', 'સહાયક',
        'സഹായി', 'ਸਹਾਇਕ', 'ସହାୟକ',
      ],
      labels: {
        'en': 'AI Assistant', 'hi': 'एआई सहायक', 'te': 'AI అసిస్టెంట్',
        'ta': 'AI உதவியாளர்', 'kn': 'AI ಸಹಾಯಕ', 'bn': 'AI সহকারী',
        'mr': 'AI सहाय्यक', 'gu': 'AI સહાયક', 'ml': 'AI സഹായി',
        'pa': 'AI ਸਹਾਇਕ', 'or': 'AI ସହାୟକ',
      },
      builder: () => const AIAssistantScreen(),
    ),
    _CommandEntry(
      keywords: [
        'profile', 'my profile',
        'प्रोफाइल', 'ప్రొఫైల్',
        'சுயவிவரம்', 'ಪ್ರೊಫೈಲ್', 'প্রোফাইল', 'प्रोफाईल', 'પ્રોફાઈલ',
        'പ്രൊഫൈൽ', 'ਪ੍ਰੋਫਾਈਲ', 'ପ୍ରୋଫାଇଲ',
      ],
      labels: {
        'en': 'My Profile', 'hi': 'मेरी प्रोफ़ाइल', 'te': 'నా ప్రొఫైల్',
        'ta': 'எனது சுயவிவரம்', 'kn': 'ನನ್ನ ಪ್ರೊಫೈಲ್', 'bn': 'আমার প্রোফাইল',
        'mr': 'माझी प्रोफाईल', 'gu': 'મારી પ્રોફાઈલ', 'ml': 'എന്റെ പ്രൊഫൈൽ',
        'pa': 'ਮੇਰੀ ਪ੍ਰੋਫਾਈਲ', 'or': 'ମୋ ପ୍ରୋଫାଇଲ',
      },
      builder: () => const ProfileScreen(),
    ),
    _CommandEntry(
      keywords: [
        'history', 'prediction',
        'इतिहास', 'చరిత్ర',
        'வரலாறு', 'ಇತಿಹಾಸ', 'ইতিহাস', 'इतिहास', 'ઇતિહાસ',
        'ചരിത്രം', 'ਇਤਿਹਾਸ', 'ଇତିହାସ',
      ],
      labels: {
        'en': 'Prediction History', 'hi': 'पूर्वानुमान इतिहास', 'te': 'అంచనా చరిత్ర',
        'ta': 'கணிப்பு வரலாறு', 'kn': 'ಪೂರ್ವಾನುಮಾನ ಇತಿಹಾಸ', 'bn': 'ভবিষ্যদ্বাণী ইতিহাস',
        'mr': 'अंदाज इतिहास', 'gu': 'અંદાજ ઇતિહાસ', 'ml': 'പ്രവചന ചരിത്രം',
        'pa': 'ਅੰਦਾਜ਼ ਇਤਿਹਾਸ', 'or': 'ଅନୁମାନ ଇତିହାସ',
      },
      builder: () => const HistoryScreen(),
    ),
    _CommandEntry(
      keywords: [
        'yield', 'profit', 'income',
        'उपज', 'लाभ', 'దిగుబడి', 'లాభం',
        'மகசூல்', 'ಇಳುವರಿ', 'ফলন', 'उत्पन्न', 'ઉપજ', 'വിളവ്', 'ਪੈਦਾਵਾਰ', 'ଅମଳ',
      ],
      labels: {
        'en': 'Yield & Profit', 'hi': 'उपज और लाभ', 'te': 'దిగుబడి & లాభం',
        'ta': 'மகசூல் & லாபம்', 'kn': 'ಇಳುವರಿ & ಲಾಭ', 'bn': 'ফলন ও মুনাফা',
        'mr': 'उत्पन्न व नफा', 'gu': 'ઉપજ અને નફો', 'ml': 'വിളവ് & ലാഭം',
        'pa': 'ਪੈਦਾਵਾਰ ਅਤੇ ਫਾਇਦਾ', 'or': 'ଅମଳ ଓ ଲାଭ',
      },
      builder: () => const YieldProfitScreen(),
    ),
    _CommandEntry(
      keywords: [
        'scheme', 'government',
        'सरकारी', 'योजना', 'ప్రభుత్వ', 'పథకాలు',
        'அரசு', 'திட்டம்', 'ಸರ್ಕಾರ', 'ಯೋಜನೆ', 'সরকার', 'योजना', 'યોજના',
        'സർക്കാർ', 'ਸਰਕਾਰ', 'ସରକାର',
      ],
      labels: {
        'en': 'Government Schemes', 'hi': 'सरकारी योजनाएं', 'te': 'ప్రభుత్వ పథకాలు',
        'ta': 'அரசு திட்டங்கள்', 'kn': 'ಸರ್ಕಾರಿ ಯೋಜನೆಗಳು', 'bn': 'সরকারি প্রকল্প',
        'mr': 'सरकारी योजना', 'gu': 'સરકારી યોજનાઓ', 'ml': 'സർക്കാർ പദ്ധതികൾ',
        'pa': 'ਸਰਕਾਰੀ ਯੋਜਨਾਵਾਂ', 'or': 'ସରକାରୀ ଯୋଜନା',
      },
      builder: () => const SchemesScreen(),
    ),
    _CommandEntry(
      keywords: [
        'risk', 'alert', 'warning', 'weather',
        'जोखिम', 'चेतावनी', 'ప్రమాదం', 'హెచ్చరిక',
        'ஆபத்து', 'ಅಪಾಯ', 'ঝুঁকি', 'धोका', 'જોખમ', 'അപകടം', 'ਖ਼ਤਰਾ', 'ବିପଦ',
      ],
      labels: {
        'en': 'Risk Alerts', 'hi': 'जोखिम चेतावनी', 'te': 'ప్రమాద హెచ్చరికలు',
        'ta': 'ஆபத்து எச்சரிக்கைகள்', 'kn': 'ಅಪಾಯ ಎಚ್ಚರಿಕೆಗಳು', 'bn': 'ঝুঁকি সতর্কতা',
        'mr': 'धोका सूचना', 'gu': 'જોખમ ચેતવણી', 'ml': 'അപകട മുന്നറിയിപ്പുകൾ',
        'pa': 'ਖ਼ਤਰੇ ਦੀ ਚੇਤਾਵਨੀ', 'or': 'ବିପଦ ସତର୍କ',
      },
      builder: () => const RiskAlertsScreen(),
    ),
    _CommandEntry(
      keywords: [
        'community', 'farmer',
        'समुदाय', 'किसान', 'సమాజం', 'రైతు',
        'சமூகம்', 'ಸಮುದಾಯ', 'সম্প্রদায়', 'समुदाय', 'સમુદાય', 'സമൂഹം', 'ਭਾਈਚਾਰਾ', 'ସମୁଦାୟ',
      ],
      labels: {
        'en': 'Farmers Community', 'hi': 'किसान समुदाय', 'te': 'రైతుల సమాజం',
        'ta': 'விவசாய சமூகம்', 'kn': 'ರೈತರ ಸಮುದಾಯ', 'bn': 'কৃষক সম্প্রদায়',
        'mr': 'शेतकरी समुदाय', 'gu': 'ખેડૂત સમુદાય', 'ml': 'കർഷക സമൂഹം',
        'pa': 'ਕਿਸਾਨ ਭਾਈਚਾਰਾ', 'or': 'ଚାଷୀ ସମୁଦାୟ',
      },
      builder: () => const CommunityScreen(),
    ),
    _CommandEntry(
      keywords: [
        'map', 'farm map',
        'नक्शा', 'మ్యాప్',
        'வரைபடம்', 'ನಕ್ಷೆ', 'মানচিত্র', 'नकाशा', 'નકશો', 'മാപ്പ്', 'ਨਕਸ਼ਾ', 'ମାନଚିତ୍ର',
      ],
      labels: {
        'en': 'Farm Map', 'hi': 'फार्म नक्शा', 'te': 'ఫార్మ్ మ్యాప్',
        'ta': 'பண்ணை வரைபடம்', 'kn': 'ಫಾರ್ಮ್ ನಕ್ಷೆ', 'bn': 'ফার্ম মানচিত্র',
        'mr': 'शेत नकाशा', 'gu': 'ફાર્મ નકશો', 'ml': 'ഫാം മാപ്പ്',
        'pa': 'ਫਾਰਮ ਨਕਸ਼ਾ', 'or': 'ଫାର୍ମ ମାନଚିତ୍ର',
      },
      builder: () => const FarmMapScreen(),
    ),
    _CommandEntry(
      keywords: [
        'fertilizer',
        'खाद', 'ఎరువులు',
        'உரம்', 'ಗೊಬ್ಬರ', 'সার', 'खत', 'ખાતર', 'വളം', 'ਖਾਦ', 'ସାର',
      ],
      labels: {
        'en': 'Fertilizer', 'hi': 'खाद', 'te': 'ఎరువులు',
        'ta': 'உரம்', 'kn': 'ಗೊಬ್ಬರ', 'bn': 'সার',
        'mr': 'खत', 'gu': 'ખાતર', 'ml': 'വളം',
        'pa': 'ਖਾਦ', 'or': 'ସାର',
      },
      builder: () => const FertilizerScreen(),
    ),
    _CommandEntry(
      keywords: [
        'contract', 'service', 'labour', 'machinery',
        'अनुबंध', 'सेवा', 'ఒప్పందం', 'సేవ',
        'ஒப்பந்தம்', 'ಗುತ್ತಿಗೆ', 'চুক্তি', 'करार', 'કરાર', 'കരാർ', 'ਠੇਕਾ', 'ଠିକା',
      ],
      labels: {
        'en': 'Contracts & Services', 'hi': 'अनुबंध और सेवाएं', 'te': 'ఒప్పందాలు & సేవలు',
        'ta': 'ஒப்பந்தங்கள் & சேவைகள்', 'kn': 'ಗುತ್ತಿಗೆ & ಸೇವೆಗಳು', 'bn': 'চুক্তি ও সেবা',
        'mr': 'करार व सेवा', 'gu': 'કરાર અને સેવાઓ', 'ml': 'കരാർ & സേവനങ്ങൾ',
        'pa': 'ਠੇਕੇ ਅਤੇ ਸੇਵਾਵਾਂ', 'or': 'ଠିକା ଓ ସେବା',
      },
      routeName: '/contracts',
    ),
    _CommandEntry(
      keywords: [
        'home', 'dashboard',
        'होम', 'హోమ్',
        'முகப்பு', 'ಹೋಮ್', 'হোম', 'होम', 'હોમ', 'ഹോം', 'ਹੋਮ', 'ହୋମ',
      ],
      labels: {
        'en': 'Home', 'hi': 'होम', 'te': 'హోమ్',
        'ta': 'முகப்பு', 'kn': 'ಹೋಮ್', 'bn': 'হোম',
        'mr': 'होम', 'gu': 'હોમ', 'ml': 'ഹോം',
        'pa': 'ਹੋਮ', 'or': 'ହୋମ',
      },
      routeName: '/home',
    ),
  ];

  /// Parse a voice command and return a matched result, or null if no match.
  static VoiceCommandResult? parseCommand(String text, String languageCode) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return null;

    // Try exact multi-word matches first (longer keywords first)
    final sortedCommands = List<_CommandEntry>.from(_commands)
      ..sort((a, b) {
        final aMax = a.keywords.map((k) => k.length).reduce((a, b) => a > b ? a : b);
        final bMax = b.keywords.map((k) => k.length).reduce((a, b) => a > b ? a : b);
        return bMax.compareTo(aMax);
      });

    for (final cmd in sortedCommands) {
      for (final keyword in cmd.keywords) {
        if (lower.contains(keyword.toLowerCase())) {
          final label = cmd.labels[languageCode] ?? cmd.labels['en']!;
          return VoiceCommandResult(
            screen: cmd.builder != null ? cmd.builder!() : null,
            routeName: cmd.routeName,
            screenLabel: label,
          );
        }
      }
    }

    return null;
  }

  /// Get a "navigating to" message in the profile language
  static String getNavigatingMessage(String screenLabel, String languageCode) {
    final templates = {
      'en': 'Opening $screenLabel',
      'hi': '$screenLabel खोल रहे हैं',
      'te': '$screenLabel తెరుస్తున్నాము',
      'ta': '$screenLabel திறக்கிறோம்',
      'kn': '$screenLabel ತೆರೆಯುತ್ತಿದ್ದೇವೆ',
      'bn': '$screenLabel খোলা হচ্ছে',
      'mr': '$screenLabel उघडत आहे',
      'gu': '$screenLabel ખોલી રહ્યા છીએ',
      'ml': '$screenLabel തുറക്കുന്നു',
      'pa': '$screenLabel ਖੋਲ ਰਹੇ ਹਾਂ',
      'or': '$screenLabel ଖୋଲୁଛୁ',
    };
    return templates[languageCode] ?? templates['en']!;
  }

  /// Get a "didn't understand" message in the profile language
  static String getNotUnderstoodMessage(String languageCode) {
    final messages = {
      'en': 'Sorry, I didn\'t understand. Please try again.',
      'hi': 'समझ नहीं आया। कृपया फिर से बोलें।',
      'te': 'అర్థం కాలేదు. దయచేసి మళ్ళీ చెప్పండి.',
      'ta': 'புரியவில்லை. தயவுசெய்து மீண்டும் சொல்லுங்கள்.',
      'kn': 'ಅರ್ಥವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಹೇಳಿ.',
      'bn': 'বুঝতে পারিনি। অনুগ্রহ করে আবার বলুন।',
      'mr': 'समजले नाही. कृपया पुन्हा सांगा.',
      'gu': 'સમજ ન આવ્યું. કૃપા કરીને ફરી કહો.',
      'ml': 'മനസ്സിലായില്ല. ദയവായി വീണ്ടും പറയൂ.',
      'pa': 'ਸਮਝ ਨਹੀਂ ਆਇਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਬੋਲੋ।',
      'or': 'ବୁଝିପାରିଲି ନାହିଁ। ଦୟାକରି ପୁନର୍ବାର କୁହନ୍ତୁ।',
    };
    return messages[languageCode] ?? messages['en']!;
  }

  /// Get a "listening" message in the profile language
  static String getListeningMessage(String languageCode) {
    final messages = {
      'en': 'Listening...', 'hi': 'सुन रहा हूँ...', 'te': 'వింటున్నాను...',
      'ta': 'கேட்கிறேன்...', 'kn': 'ಕೇಳುತ್ತಿದ್ದೇನೆ...', 'bn': 'শুনছি...',
      'mr': 'ऐकतो आहे...', 'gu': 'સાંભળી રહ્યા છીએ...', 'ml': 'കേൾക്കുന്നു...',
      'pa': 'ਸੁਣ ਰਿਹਾ ਹਾਂ...', 'or': 'ଶୁଣୁଛି...',
    };
    return messages[languageCode] ?? messages['en']!;
  }
}

class _CommandEntry {
  final List<String> keywords;
  final Map<String, String> labels;
  final Widget Function()? builder;
  final String? routeName;

  _CommandEntry({
    required this.keywords,
    required this.labels,
    this.builder,
    this.routeName,
  });
}
