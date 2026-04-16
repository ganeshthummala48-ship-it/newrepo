import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/constants.dart';
import '../services/risk_service.dart';
import '../services/ai_service.dart';
import '../services/cache_service.dart';
import '../services/notification_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/voice_wrapper.dart';

class RiskAlertsScreen extends StatefulWidget {
  const RiskAlertsScreen({super.key});

  @override
  State<RiskAlertsScreen> createState() => _RiskAlertsScreenState();
}

class _RiskAlertsScreenState extends State<RiskAlertsScreen> {
  final TextEditingController _cropController = TextEditingController(
    text: 'Cotton',
  );
  final TextEditingController _manualLocationController = TextEditingController(
    text: 'Nagpur',
  );

  // Location mode
  bool _useGps = true;

  // Location state
  double? _lat;
  double? _lon;
  String _locationName = '';
  bool _locationLoading = false;

  // Data state
  bool _dataLoading = false;
  Map<String, dynamic>? _weatherData;
  List<dynamic> _disasters = [];
  Map<String, dynamic>? _pollenData;

  // AI state
  bool _aiLoading = false;
  String? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    // Auto-detect GPS on open
    _autoDetectLocation();
  }

  @override
  void dispose() {
    _manualLocationController.dispose();
    _cropController.dispose();
    super.dispose();
  }

  // ─── LOCATION ─────────────────────────────────────────────────────────────
  Future<void> _autoDetectLocation() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showSnack(
          'Location permission denied. Enable GPS to get automatic alerts.',
        );
        setState(() => _locationLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lat = position.latitude;
      _lon = position.longitude;

      final placemarks = await placemarkFromCoordinates(_lat!, _lon!);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _locationName =
            '${p.locality ?? p.subAdministrativeArea ?? ''}, ${p.administrativeArea ?? ''}';
      }

      setState(() => _locationLoading = false);
      await _fetchRiskData();
    } catch (e) {
      _showSnack('Could not detect location: $e');
      setState(() => _locationLoading = false);
    }
  }

  // ─── RESOLVE MANUAL LOCATION ──────────────────────────────────────────────
  Future<bool> _resolveManualLocation() async {
    final city = _manualLocationController.text.trim();
    if (city.isEmpty) {
      _showSnack('Please enter a location name.');
      return false;
    }
    try {
      final locs = await locationFromAddress(city);
      if (locs.isEmpty) {
        _showSnack('Could not find location: $city');
        return false;
      }
      _lat = locs.first.latitude;
      _lon = locs.first.longitude;
      _locationName = city;
      return true;
    } catch (e) {
      _showSnack('Geocoding error: $e');
      return false;
    }
  }

  // ─── FETCH AMBEE DATA ─────────────────────────────────────────────────────
  Future<void> _fetchRiskData() async {
    // Resolve location depending on mode
    if (!_useGps) {
      setState(() => _locationLoading = true);
      final ok = await _resolveManualLocation();
      setState(() => _locationLoading = false);
      if (!ok) return;
    } else if (_lat == null || _lon == null) {
      _showSnack('GPS location not available. Switch to Manual or enable GPS.');
      return;
    }

    setState(() {
      _dataLoading = true;
      _aiAnalysis = null;
    });

    final cacheKey = 'risk_${_lat}_$_lon';
    if (CacheService.isFresh(cacheKey)) {
      final cached = CacheService.load(cacheKey) as Map?;
      if (cached != null) {
        setState(() {
          _weatherData = cached['weather'];
          _disasters = cached['disasters'] ?? [];
          _pollenData = cached['pollen'];
          _aiAnalysis = cached['ai'];
          _dataLoading = false;
        });
        return;
      }
    }

    final results = await Future.wait([
      RiskService.getCurrentWeatherByCoords(lat: _lat!, lon: _lon!),
      RiskService.getSevereWeatherAlerts(lat: _lat!, lon: _lon!),
      RiskService.getPollenData(lat: _lat!, lon: _lon!),
    ]);

    setState(() {
      _weatherData = results[0] as Map<String, dynamic>?;
      _disasters = results[1] as List<dynamic>;
      _pollenData = results[2] as Map<String, dynamic>?;
      _dataLoading = false;
    });

    await _runAiAnalysis();
  }

  // ─── AI ANALYSIS ─────────────────────────────────────────────────────────
  Future<void> _runAiAnalysis() async {
    setState(() => _aiLoading = true);

    final crop = _cropController.text.trim();
    final weatherCtx = RiskService.buildWeatherContext(_weatherData);
    final disasterCtx = _disasters.isEmpty
        ? 'No active severe weather events.'
        : _disasters
              .map(
                (d) =>
                    '- ${d['event'] ?? d['type'] ?? 'Alert'}: ${d['description'] ?? ''}',
              )
              .join('\n');

    String pollenCtx = '';
    if (_pollenData != null) {
      try {
        final d = (_pollenData!['data'] as List?)?.first ?? _pollenData!;
        pollenCtx =
            'Pollen risk: tree=${d['Count']?['tree_pollen'] ?? 'N/A'}, grass=${d['Count']?['grass_pollen'] ?? 'N/A'}, weed=${d['Count']?['weed_pollen'] ?? 'N/A'}';
      } catch (_) {}
    }

    final prompt =
        '''
You are an expert agricultural advisor helping a farmer understand risks.

Farmer location: $_locationName (GPS: ${_lat?.toStringAsFixed(4)}, ${_lon?.toStringAsFixed(4)})
Crop: $crop

Live Environmental Data (Ambee API):
$weatherCtx
${pollenCtx.isNotEmpty ? pollenCtx : ''}

Severe Weather / Disaster Alerts:
$disasterCtx

Provide a clear risk assessment with:
1. **Risk Level**: (Low / Medium / High / Critical)
2. **Key Risks**: bullet list specific to $crop
3. **Immediate Actions**: what to do today
4. **Next 7 Days**: preventive measures

Keep the language simple and farmer-friendly.
''';

    final lang = Localizations.localeOf(context).languageCode;
    try {
      final response = await AIService.getAIResponse(prompt, language: lang);
      setState(() => _aiAnalysis = response);

      // Save to cache
      final cacheKey = 'risk_${_lat}_$_lon';
      CacheService.save(cacheKey, {
        'weather': _weatherData,
        'disasters': _disasters,
        'pollen': _pollenData,
        'ai': _aiAnalysis,
      });

      // Check and fire notification for High/Critical risk
      NotificationService.checkAndNotify(
        aiAnalysis: _aiAnalysis!,
        location: _locationName.isNotEmpty ? _locationName : 'your farm',
        crop: crop,
      );
    } catch (e) {
      setState(
        () => _aiAnalysis =
            '**AI analysis unavailable.** Please check your internet connection.',
      );
    }

    setState(() => _aiLoading = false);
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    String voiceContent = AppLocalizations.of(context)!.riskAlerts + ". ";
    if (_dataLoading) {
      voiceContent += "Analyzing environmental risks for ${_cropController.text}.";
    } else if (_aiAnalysis != null) {
      voiceContent += "Risk assessment for ${_cropController.text} in ${_locationName}. " + _aiAnalysis!.replaceAll('*', '');
    } else {
      voiceContent += "Enter your crop and location to get a personalized risk assessment.";
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.riskAlerts),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_locationLoading || _dataLoading || _aiLoading)
                ? null
                : _fetchRiskData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.riskAlerts,
        textToRead: voiceContent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            _buildLocationCard(),
            const SizedBox(height: 16),
            _buildCropInput(),
            const SizedBox(height: 16),
            if (_dataLoading)
              _buildLoadingCard('Fetching real-time data from Ambee...'),
            if (!_dataLoading &&
                (_weatherData != null || _disasters.isNotEmpty))
              ..._buildDataCards(),
            if (_aiLoading)
              _buildLoadingCard('FarmerAI is analyzing your risks...'),
            if (!_aiLoading && _aiAnalysis != null) ...[
              const SizedBox(height: 4),
              _buildAiCard(),
            ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── LOCATION CARD ────────────────────────────────────────────────────────
  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mode toggle ──
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.locationMode,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              // GPS pill
              GestureDetector(
                onTap: () {
                  setState(() => _useGps = true);
                  _autoDetectLocation();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _useGps ? Colors.white : Colors.white24,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    'GPS',
                    style: TextStyle(
                      color: _useGps ? Colors.green : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              // Manual pill
              GestureDetector(
                onTap: () => setState(() => _useGps = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: !_useGps ? Colors.white : Colors.white24,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Manual',
                    style: TextStyle(
                      color: !_useGps ? Colors.green : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Content ──
          if (_useGps)
            _locationLoading
                ? Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)!.detectingLocation,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _locationName.isNotEmpty
                                  ? _locationName
                                  : 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (_lat != null)
                              Text(
                                'GPS: ${_lat!.toStringAsFixed(4)}, ${_lon!.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                        ),
                        onPressed: _autoDetectLocation,
                        tooltip: 'Re-detect',
                      ),
                    ],
                  )
          else
            // Manual city input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualLocationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter city / district...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                    ),
                    onSubmitted: (_) => _fetchRiskData(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── CROP INPUT ───────────────────────────────────────────────────────────
  Widget _buildCropInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.grass_rounded, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _cropController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.cropType,
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _fetchRiskData(),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: (_dataLoading || _locationLoading)
                ? null
                : _fetchRiskData,
            icon: const Icon(Icons.search, size: 18),
            label: Text(AppLocalizations.of(context)!.analyze),
          ),
        ],
      ),
    );
  }

  // ─── LOADING CARD ─────────────────────────────────────────────────────────
  Widget _buildLoadingCard(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ─── DATA CARDS ───────────────────────────────────────────────────────────
  List<Widget> _buildDataCards() {
    final cards = <Widget>[];

    if (_weatherData != null) {
      cards.add(_buildWeatherCard());
      cards.add(const SizedBox(height: 12));
    }

    if (_disasters.isNotEmpty) {
      cards.add(_buildDisastersCard());
      cards.add(const SizedBox(height: 12));
    } else {
      cards.add(_buildNoDisasterCard());
      cards.add(const SizedBox(height: 12));
    }

    if (_pollenData != null) {
      cards.add(_buildPollenCard());
      cards.add(const SizedBox(height: 12));
    }

    return cards;
  }

  Widget _buildWeatherCard() {
    final data = _weatherData?['data'] ?? _weatherData ?? {};
    final temp = data['temperature'] ?? data['temp'] ?? '--';
    final humidity = data['humidity'] ?? '--';
    final windSpeed = data['windSpeed'] ?? data['wind_speed'] ?? '--';
    final summary = data['summary'] ?? data['description'] ?? 'N/A';
    final precip = data['precipIntensity'] ?? data['precipitation'] ?? '--';

    return _infoCard(
      icon: Icons.cloud_outlined,
      iconColor: Colors.blue,
      title: AppLocalizations.of(context)!.liveWeather,
      subtitle: 'Ambee API • GPS-based',
      children: [
        _dataChip(Icons.thermostat, '$temp°C', 'Temp'),
        _dataChip(Icons.water_drop, '$humidity%', 'Humidity'),
        _dataChip(Icons.air, '$windSpeed km/h', 'Wind'),
        _dataChip(Icons.umbrella, '$precip mm', 'Rain'),
        _dataChip(Icons.wb_cloudy, '$summary', 'Conditions'),
      ],
    );
  }

  Widget _buildDisastersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                '${_disasters.length} Active Alert${_disasters.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._disasters.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, color: Colors.red, size: 8),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${d['event'] ?? d['type'] ?? 'Alert'}: ${d['description'] ?? ''}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDisasterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.noActiveAlerts,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollenCard() {
    final d = (_pollenData!['data'] as List?)?.first ?? _pollenData!;
    final tree = d['Count']?['tree_pollen'] ?? d['tree_pollen'] ?? '--';
    final grass = d['Count']?['grass_pollen'] ?? d['grass_pollen'] ?? '--';
    final weed = d['Count']?['weed_pollen'] ?? d['weed_pollen'] ?? '--';

    return _infoCard(
      icon: Icons.eco_outlined,
      iconColor: Colors.orange,
      title: AppLocalizations.of(context)!.pollenPestRisk,
      subtitle: 'Ambee API • GPS-based',
      children: [
        _dataChip(Icons.park, '$tree', 'Tree'),
        _dataChip(Icons.grass, '$grass', 'Grass'),
        _dataChip(Icons.spa, '$weed', 'Weed'),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: iconColor.withOpacity(0.15),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Wrap(spacing: 10, runSpacing: 8, children: children),
        ],
      ),
    );
  }

  Widget _dataChip(IconData icon, String value, String label) {
    return Chip(
      avatar: Icon(icon, size: 14, color: Colors.grey.shade700),
      label: Text('$label: $value', style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ─── AI CARD ─────────────────────────────────────────────────────────────
  Widget _buildAiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.riskAnalysis,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          MarkdownBody(
            data: _aiAnalysis!,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 14, height: 1.5),
              h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              listBullet: const TextStyle(fontSize: 14),
              strong: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _aiLoading ? null : _runAiAnalysis,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh Analysis'),
            ),
          ),
        ],
      ),
    );
  }
}
