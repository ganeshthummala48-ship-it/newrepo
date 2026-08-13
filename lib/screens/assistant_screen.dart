import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/voice_service.dart';
import '../widgets/voice_wrapper.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/generated/app_localizations.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> messages = [];
  bool isLoading = false;
  bool isListening = false;
  String selectedLanguage = "English";

  List<String> get languages {
    return [
      "English",
      "Hindi",
      "Telugu",
      "Marathi",
      "Tamil",
      "Bengali",
      "Gujarati",
      "Kannada",
      "Malayalam",
      "Punjabi",
      "Odia"
    ];
  }

  String _getLanguageFromCode(String code) {
    switch (code) {
      case 'te': return "Telugu";
      case 'hi': return "Hindi";
      case 'mr': return "Marathi";
      case 'ta': return "Tamil";
      case 'bn': return "Bengali";
      case 'gu': return "Gujarati";
      case 'kn': return "Kannada";
      case 'ml': return "Malayalam";
      case 'pa': return "Punjabi";
      case 'or': return "Odia";
      default: return "English";
    }
  }

  String _getCodeFromLanguage(String lang) {
     switch (lang) {
      case 'Telugu': return "te";
      case 'Hindi': return "hi";
      case 'Marathi': return "mr";
      case 'Tamil': return "ta";
      case 'Bengali': return "bn";
      case 'Gujarati': return "gu";
      case 'Kannada': return "kn";
      case 'Malayalam': return "ml";
      case 'Punjabi': return "pa";
      case 'Odia': return "or";
      default: return "en";
    }
  }

  @override
  void initState() {
    super.initState();
    VoiceService.init();
  }

  Future<void> _speak(String text) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    await VoiceService.speak(text, localeProvider.locale.languageCode);
  }

  Future<void> _listen() async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    
    // If we're already listening, stop it
    if (isListening || VoiceService.state == VoiceState.listening) {
      setState(() => isListening = false);
      await VoiceService.stopListening();
      return;
    }

    // Stop anything before starting new listen session
    await VoiceService.stop();
    if (!mounted) return;

    setState(() => isListening = true);
    
    final result = await VoiceService.listenForCommand(
      localeProvider.locale.languageCode,
      onPartialResult: (val) {
        if (mounted) setState(() => _controller.text = val);
      },
    );

    if (mounted) {
      setState(() => isListening = false);
      if (result.isNotEmpty) {
        _controller.text = result;
        // Optional: auto-send after voice recognition?
        // sendMessage(); 
      }
    }
  }

  Future<void> sendMessage() async {
    String question = _controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": question});
      isLoading = true;
    });

    _controller.clear();
    scrollToBottom();

    try {
      final answer = await AIService.getAIResponse(
        question,
        language: selectedLanguage,
      );

      setState(() {
        messages.add({"role": "ai", "text": answer});
      });
      
      // Auto-speak AI response if user preferred
       _speak(answer);

    } catch (e) {
      setState(() {
        messages.add({
          "role": "ai",
          "text": "AI Error: ${e.toString().replaceAll("Exception:", "")}",
        });
      });
    }

    setState(() => isLoading = false);
    scrollToBottom();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget buildMessage(Map<String, String> message) {
    bool isUser = message["role"] == "user";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.green.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: message["role"] == "ai"
                      ? MarkdownBody(
                          data: message["text"] ?? "",
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 15, height: 1.4),
                            listBullet: const TextStyle(fontSize: 15),
                          ),
                        )
                      : Text(
                          message["text"] ?? "",
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                ),
                if (!isUser)
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up,
                      size: 20,
                      color: Colors.green,
                    ),
                    onPressed: () => _speak(message["text"] ?? ""),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser)
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.askFarmerAI),
        actions: [
          DropdownButton<String>(
            value: _getLanguageFromCode(Provider.of<LocaleProvider>(context).locale.languageCode),
            icon: const Icon(Icons.language, color: Colors.white),
            underline: Container(),
            dropdownColor: Colors.green,
            onChanged: (String? newValue) {
              if (newValue != null) {
                Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(_getCodeFromLanguage(newValue)));
                setState(() {
                  selectedLanguage = newValue;
                });
              }
            },
            items: languages.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.askFarmerAI,
        textToRead: AppLocalizations.of(context)!.namasteAI + " " + AppLocalizations.of(context)!.askAnything,
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? _buildWelcomeMessage()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) =>
                          buildMessage(messages[index]),
                    ),
            ),
            if (isLoading) _buildLoading(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.eco, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.namasteAI,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.of(context)!.askAnything,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: isListening ? Colors.red : Colors.green,
            ),
            onPressed: _listen,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.askIn(selectedLanguage),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: sendMessage,
          ),
        ],
      ),
    );
  }
}
