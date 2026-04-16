import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../services/ai_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/cache_service.dart';
import '../widgets/voice_wrapper.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  final TextEditingController _stateController = TextEditingController(
    text: 'Maharashtra',
  );
  final TextEditingController _cropController = TextEditingController(
    text: 'Cotton',
  );
  final TextEditingController _landSizeController = TextEditingController(
    text: '2.0',
  );

  bool _locationLoading = false;
  bool _loading = false;
  String? _detectedState;
  String? _schemesResult;
  List<String> _translatedStates = [];
  String? _lastTranslatedLang;

  // Popular Indian states quick-select
  final List<String> _popularStates = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  @override
  void initState() {
    super.initState();
    _autoDetectState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Provider.of<LocaleProvider>(context).locale.languageCode;
    if (lang != _lastTranslatedLang) {
      _translateStates(lang);
    }
  }

  Future<void> _translateStates(String lang) async {
    _lastTranslatedLang = lang;
    if (lang == 'en') {
      setState(() {
        _translatedStates = List.from(_popularStates);
      });
      return;
    }

    final cacheKey = 'translated_states_$lang';
    if (CacheService.isFresh(cacheKey)) {
      final cached = CacheService.load(cacheKey);
      if (cached != null) {
        setState(() {
          _translatedStates = List<String>.from(jsonDecode(cached));
        });
        return;
      }
    }

    try {
      final prompt = "Translate the following Indian state names to ${AppConstants.langNames[lang] ?? lang}. "
          "Respond ONLY with a JSON array of strings in the same order. "
          "States: ${_popularStates.join(', ')}";
      
      final response = await AIService.getAIResponse(prompt, language: lang);
      // Clean potential markdown
      final cleanJson = response.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> translated = jsonDecode(cleanJson);
      
      setState(() {
        _translatedStates = translated.cast<String>();
      });
      CacheService.save(cacheKey, jsonEncode(_translatedStates));
    } catch (e) {
      debugPrint("Error translating states: $e");
      setState(() {
        _translatedStates = List.from(_popularStates);
      });
    }
  }

  @override
  void dispose() {
    _stateController.dispose();
    _cropController.dispose();
    _landSizeController.dispose();
    super.dispose();
  }

  // ─── AUTO DETECT STATE VIA GPS ───────────────────────────────────────────
  Future<void> _autoDetectState() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _locationLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final state = placemarks.first.administrativeArea ?? '';
        if (state.isNotEmpty) {
          setState(() {
            _detectedState = state;
            _stateController.text = state;
          });
        }
      }
    } catch (e) {
      // Silently fail — user can type state manually
    }
    setState(() => _locationLoading = false);
  }

  // ─── FETCH SCHEMES ───────────────────────────────────────────────────────
  Future<void> _findSchemes() async {
    final state = _stateController.text.trim();
    final crop = _cropController.text.trim();
    final landSize = double.tryParse(_landSizeController.text) ?? 1.0;
    
    // Fetch user profile language
    final lang = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;

    final cacheKey = 'schemes_${state}_${crop}_$lang';

    // Check Cache
    if (CacheService.isFresh(cacheKey)) {
      final cached = CacheService.load(cacheKey);
      if (cached != null) {
        setState(() => _schemesResult = cached);
        return;
      }
    }

    setState(() {
      _loading = true;
      _schemesResult = null;
    });

    // Try backend first
    bool backendSuccess = false;
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/recommend-schemes');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'state': state,
              'crop': crop,
              'land_size': landSize,
              'lang': lang,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (res.statusCode == 200) {
        setState(() => _schemesResult = jsonDecode(res.body)['schemes']);
        backendSuccess = true;
      }
    } catch (_) {
      // Backend unreachable — use AI directly
    }

    // Fallback: call Cohere AI directly when backend is offline
    if (!backendSuccess) {
      try {
        final prompt =
            'You are an expert on Indian government agricultural schemes.\n\n'
            'A farmer in $state grows $crop on $landSize hectares.\n\n'
            'List the top 5 most relevant central and state government schemes. '
            'For each scheme include: **Scheme Name**, what it offers, who is eligible, how to apply.\n'
            'Format in clear Markdown. Include PM-KISAN, PMFBY and $state-specific schemes.';
        final response = await AIService.getAIResponse(prompt, language: lang);
        setState(() => _schemesResult = response);
      } catch (e) {
        _showSnack('Could not fetch schemes: $e');
      }
    }

    if (_schemesResult != null) {
      CacheService.save(cacheKey, _schemesResult);
    }

    setState(() => _loading = false);
  }

  void _showSnack(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    String voiceContent = AppLocalizations.of(context)!.govtSchemes + ". ";
    if (_loading) {
      voiceContent += "Searching for schemes.";
    } else if (_schemesResult != null) {
      voiceContent += "Found schemes for ${_stateController.text}. " + _schemesResult!.replaceAll('*', '');
    } else {
      voiceContent += "Enter your state and crop to find relevant government schemes.";
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.govtSchemes),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _locationLoading ? null : _autoDetectState,
            tooltip: 'Detect my state',
          ),
        ],
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.governmentSchemes,
        textToRead: voiceContent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ── Banner ──
            _buildBanner(),
            const SizedBox(height: 20),
            // ── Form ──
            _buildForm(),
            const SizedBox(height: 16),
            // ── Quick state chips ──
            _buildStateChips(),
            const SizedBox(height: 20),
            // ── Button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading ? null : _findSchemes,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_loading ? AppLocalizations.of(context)!.searching : AppLocalizations.of(context)!.findSchemes),
              ),
            ),
            const SizedBox(height: 20),
            // ── Results ──
            if (_schemesResult != null) _buildResults(),
          ],
        ),
      ),
    ),
    );
  }

  // ─── BANNER ──────────────────────────────────────────────────────────────
  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.governmentSchemes,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _locationLoading
                      ? AppLocalizations.of(context)!.detectingState
                      : _detectedState != null
                      ? '📍 ${AppLocalizations.of(context)!.autoDetected(_detectedState!)}'
                      : AppLocalizations.of(context)!.subsidiesForFarmers,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (_locationLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }

  // ─── FORM ─────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _stateController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.state,
              prefixIcon: const Icon(Icons.map_outlined, color: Colors.indigo),
              suffixIcon: _locationLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.indigo),
                      onPressed: _autoDetectState,
                      tooltip: 'Use my location',
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cropController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.cropType,
              prefixIcon: Icon(Icons.grass_rounded, color: Colors.green),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _landSizeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.landSize,
              prefixIcon: Icon(Icons.straighten, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  // ─── QUICK STATE CHIPS ────────────────────────────────────────────────────
  Widget _buildStateChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quickSelectState,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: Iterable<int>.generate(_popularStates.length).map((index) {
            final stateEn = _popularStates[index];
            final stateDisplay = (_translatedStates.length > index) ? _translatedStates[index] : stateEn;
            final isSelected = _stateController.text == stateEn || _stateController.text == stateDisplay;
            return GestureDetector(
              onTap: () => setState(() => _stateController.text = stateEn),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.indigo : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.indigo : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  stateDisplay,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── RESULTS ─────────────────────────────────────────────────────────────
  Widget _buildResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.schemesFor(_stateController.text, _cropController.text),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          MarkdownBody(
            data: _schemesResult!,
            onTapLink: (text, href, title) async {
              if (href != null) {
                String urlStr = href.trim();
                if (!urlStr.startsWith('http')) {
                  urlStr = 'https://$urlStr';
                }
                final uri = Uri.tryParse(urlStr);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  _showSnack('Could not launch $urlStr');
                }
              }
            },
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 14, height: 1.6),
              h2: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
              listBullet: const TextStyle(fontSize: 14),
              strong: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Info footer
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.kvkInfo,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
