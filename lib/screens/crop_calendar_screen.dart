import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/constants.dart';
import '../services/ai_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/voice_wrapper.dart';

class CropCalendarScreen extends StatefulWidget {
  final bool isEmbedded;
  const CropCalendarScreen({super.key, this.isEmbedded = false});

  @override
  State<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends State<CropCalendarScreen> {
  late TextEditingController _cropController;
  late TextEditingController _stateController;

  bool _loading = false;
  String? _calendar;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('profileBox');
    _cropController = TextEditingController(
      text: box.get('crop', defaultValue: 'Cotton'),
    );
    _stateController = TextEditingController(
      text: box.get('state', defaultValue: 'Telangana'),
    );
  }

  @override
  void dispose() {
    _cropController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _generateCalendar() async {
    setState(() {
      _loading = true;
      _calendar = null;
    });

    final prompt =
        '''
You are an expert Indian agricultural planner.

Create a detailed month-by-month crop calendar for **${_cropController.text}** farming in **${_stateController.text}**, India.

Format the response in Markdown. For each month use this structure:

## [Month Name]
- **Activity**: [what to do]
- **Tips**: [specific advice]
- **Watch out**: [pests/diseases/weather risks]

Cover all 12 months. Be concise and practical. Use Indian farming context (Kharif/Rabi/Zaid seasons).
''';

    try {
      final lang = Localizations.localeOf(context).languageCode;
      final result = await AIService.getAIResponse(prompt, language: lang);
      setState(() => _calendar = result);
    } catch (e) {
      setState(
        () => _calendar =
            '**Error generating calendar.** Please check your connection.',
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: widget.isEmbedded ? null : AppBar(title: Text(AppLocalizations.of(context)!.cropCalendarTitle)),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.cropCalendar,
        textToRead: _loading 
            ? "Generating your personalized farming calendar." 
            : (_calendar == null 
                ? "Get a personalized 12-month farming calendar for ${_cropController.text} in ${_stateController.text}." 
                : "Your crop calendar for ${_cropController.text} is ready. " + _calendar!.replaceAll('*', '').substring(0, _calendar!.length > 500 ? 500 : _calendar!.length)),
        child: Column(
          children: [
          // ── Input bar ──
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cropController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.primaryCrop,
                      prefixIcon: Icon(
                        Icons.grass_rounded,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.state,
                      prefixIcon: Icon(Icons.map_outlined, color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _loading ? null : _generateCalendar,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 20),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.searching,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _calendar == null
                ? _buildEmptyState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: MarkdownBody(
                        data: _calendar!,
                        styleSheet: MarkdownStyleSheet(
                          h2: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          p: const TextStyle(fontSize: 14, height: 1.5),
                          listBullet: const TextStyle(fontSize: 14),
                          strong: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 80,
              color: Colors.green.shade200,
            ),
            const SizedBox(height: 20),
            const Text(
              'Get a personalized 12-month farming calendar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Set your crop and state above, then tap ✨ to generate your plan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateCalendar,
              icon: const Icon(Icons.auto_awesome),
              label: Text(AppLocalizations.of(context)!.generateCalendar),
            ),
          ],
        ),
      ),
    );
  }
}
