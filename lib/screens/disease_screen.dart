import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:hive/hive.dart';

import 'package:farmer_ai/screens/disease_result_screen.dart';
import 'package:farmer_ai/screens/history_screen.dart';
import 'package:farmer_ai/screens/disease_gallery_screen.dart';
import '../widgets/voice_wrapper.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class DiseaseScreen extends StatefulWidget {
  final bool isEmbedded;
  const DiseaseScreen({super.key, this.isEmbedded = false});

  @override
  State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen>
    with SingleTickerProviderStateMixin {
  File? imageFile;
  bool loading = false;
  int activeMode = 0; // 0: Disease Detection, 1: Fruit Ripeness, 2: Deep Weed

  final ImagePicker _picker = ImagePicker();

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  // 📸 Pick image
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  // 🔍 Analyze image based on selected activeMode
  Future<void> analyzeImage() async {
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or capture an image first')),
      );
      return;
    }

    setState(() => loading = true);
    final lang =
        Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;

    try {
      if (activeMode == 0) {
        await _analyzeDisease(lang);
      } else if (activeMode == 1) {
        await _analyzeFruit(lang);
      } else if (activeMode == 2) {
        await _analyzeWeed(lang);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("API ERROR: $e");
      String errorMessage =
          'Failed to connect to server. Please check your network connection.';
      if (e is SocketException) {
        errorMessage = 'Network Timeout: Could not connect to AI backend.';
      } else if (e is FormatException) {
        errorMessage = 'Invalid response format received from server.';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // 🍃 Mode 0: Disease Detection
  Future<void> _analyzeDisease(String lang) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/detect-disease');
    final request = http.MultipartRequest('POST', uri);
    request.headers['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    request.fields['lang'] = lang;
    request.files.add(await http.MultipartFile.fromPath('file', imageFile!.path));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final data = jsonDecode(body);
      final disease = data['disease'] ?? 'Unknown Disease';
      final recommendation =
          data['recommendation'] ?? 'No recommendation available.';
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
      final treatment = data['treatment'];
      final aiExplanation = data['ai_explanation'];

      final box = Hive.box('historyBox');
      box.add({
        'imagePath': imageFile!.path,
        'disease': disease,
        'confidence': confidence,
        'date': DateTime.now().toString(),
        'treatment': treatment,
        'mode': 'Disease Detection',
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiseaseResultScreen(
            disease: disease,
            confidence: confidence,
            recommendation: recommendation,
            treatment: treatment,
            aiExplanation: aiExplanation,
          ),
        ),
      );
    } else {
      throw Exception("Server status ${streamedResponse.statusCode}");
    }
  }

  // 🍎 Mode 1: Fruit Ripeness & Classification
  Future<void> _analyzeFruit(String lang) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/classify-fruit');
    final request = http.MultipartRequest('POST', uri);
    request.headers['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    request.fields['lang'] = lang;
    request.files.add(await http.MultipartFile.fromPath('file', imageFile!.path));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final data = jsonDecode(body);
      if (data['error'] != null) {
        throw Exception(data['error']);
      }
      final fruitName = data['fruit'] ?? 'Unknown Fruit';
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
      final aiInfo = data['ai_info'] ?? 'Fruit classified successfully.';

      final box = Hive.box('historyBox');
      box.add({
        'imagePath': imageFile!.path,
        'disease': 'Fruit: $fruitName',
        'confidence': confidence,
        'date': DateTime.now().toString(),
        'mode': 'Fruit Classification',
      });

      if (!mounted) return;
      _showFruitResultSheet(fruitName, confidence, aiInfo);
    } else {
      throw Exception("Server status ${streamedResponse.statusCode}");
    }
  }

  // 🌿 Mode 2: Deep Weed Species Detection
  Future<void> _analyzeWeed(String lang) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/detect-weed');
    final request = http.MultipartRequest('POST', uri);
    request.headers['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    request.fields['lang'] = lang;
    request.files.add(await http.MultipartFile.fromPath('file', imageFile!.path));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final data = jsonDecode(body);
      if (data['error'] != null) {
        throw Exception(data['error']);
      }
      final weedName = data['weed'] ?? 'Unknown Weed Species';
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
      final controlAdvice = data['control_advice'] ?? 'No advice available.';

      final box = Hive.box('historyBox');
      box.add({
        'imagePath': imageFile!.path,
        'disease': 'Weed: $weedName',
        'confidence': confidence,
        'date': DateTime.now().toString(),
        'mode': 'Weed Detection',
      });

      if (!mounted) return;
      _showWeedResultSheet(weedName, confidence, controlAdvice);
    } else {
      throw Exception("Server status ${streamedResponse.statusCode}");
    }
  }

  // 🍎 Bottom Sheet for Fruit Classification
  void _showFruitResultSheet(String fruitName, double confidence, String aiInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.apple_rounded,
                      color: Colors.deepOrange, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fruitName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fruits-360 AI Model Diagnosis',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${confidence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (confidence / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  confidence > 80 ? Colors.green : Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // AI Info Card (Cohere Specialized Key)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.amber.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: Colors.deepOrange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Nutritional & Quality Insights',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    aiInfo,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade900,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌿 Bottom Sheet for Deep Weed Detection
  void _showWeedResultSheet(
      String weedName, double confidence, String controlAdvice) {
    bool isNegative = weedName.contains("Negative") || weedName.contains("No Weed");
    Color themeColor = isNegative ? Colors.green : Colors.red;
    IconData themeIcon = isNegative ? Icons.check_circle_rounded : Icons.warning_amber_rounded;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(themeIcon, color: themeColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weedName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'DeepWeeds AI Species Model',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isNegative ? 'Low Risk' : 'Invasive Species',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confidence Match',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                Text(
                  '${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: themeColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (confidence / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            ),
            const SizedBox(height: 24),
            // Control Advice Card (Cohere Specialized Key)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor.withValues(alpha: 0.08),
                    themeColor.withValues(alpha: 0.03)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: themeColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: themeColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Farmland Control & Management',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controlAdvice,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade900,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧱 UI
  @override
  Widget build(BuildContext context) {
    String voiceContent =
        "${AppLocalizations.of(context)!.diseaseDetection}. Mode: ${activeMode == 0 ? 'Plant Disease' : activeMode == 1 ? 'Fruit Ripeness' : 'Weed Detection'}. ${AppLocalizations.of(context)!.uploadLeafHint}";

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(AppLocalizations.of(context)!.diseaseDetection),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  tooltip: AppLocalizations.of(context)!.predictionHistory,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                ),
              ],
            ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.diseaseDetection,
        textToRead: voiceContent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              // 🎛️ Mode Selector Cards
              _buildModeSelector(),

              const SizedBox(height: 20),

              // Mode Description Banner
              _buildModeHeaderBanner(),

              const SizedBox(height: 20),

              // 📸 Scanner / Image Container with Micro-Animations
              _buildImageScannerBox(),

              const SizedBox(height: 24),

              // Camera & Gallery Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.primaryColor,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                              color: AppConstants.primaryColor, width: 1.5),
                        ),
                      ),
                      onPressed:
                          loading ? null : () => pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: Text(AppLocalizations.of(context)!.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.primaryColor,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                              color: AppConstants.primaryColor, width: 1.5),
                        ),
                      ),
                      onPressed:
                          loading ? null : () => pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: Text(AppLocalizations.of(context)!.gallery),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 🚀 Analyze Button with Dynamic Text
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: (imageFile == null || loading)
                          ? [Colors.grey.shade400, Colors.grey.shade500]
                          : [Colors.green.shade600, Colors.teal.shade700],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: (imageFile != null && !loading)
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed:
                        (imageFile == null || loading) ? null : analyzeImage,
                    child: loading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'AI Model Analyzing...',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : Text(
                            activeMode == 0
                                ? AppLocalizations.of(context)!.analyzeLeaf
                                : activeMode == 1
                                    ? 'Classify Fruit & Ripeness'
                                    : 'Detect Weed Species',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🌟 Dynamic Feature Showcase Card
              _buildFeatureCard(),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // 📖 Browse Diseases Guide Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiseaseGalleryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_rounded),
                  label: Text(AppLocalizations.of(context)!.browseGuide),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                    side: const BorderSide(color: AppConstants.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppConstants.defaultBorderRadius,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎛️ Mode Selector Cards Component
  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _buildModeTab(0, 'Disease', Icons.eco_rounded, Colors.green),
          _buildModeTab(1, 'Fruit', Icons.apple_rounded, Colors.orange),
          _buildModeTab(2, 'Weed', Icons.grass_rounded, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildModeTab(
      int index, String title, IconData icon, Color activeColor) {
    final bool isSelected = activeMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!loading) {
            setState(() {
              activeMode = index;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 💡 Mode Header Banner
  Widget _buildModeHeaderBanner() {
    String title = activeMode == 0
        ? "Plant Disease AI Diagnosis"
        : activeMode == 1
            ? "Fruit Ripeness & Classification"
            : "Deep Weed Species Detection";

    String subtitle = activeMode == 0
        ? "Upload leaf photo for 38 disease diagnoses across 14 crop types."
        : activeMode == 1
            ? "Upload fruit or vegetable photo to classify variety & get nutritional overview."
            : "Upload farmland vegetation photo to identify 9 weed species & control advice.";

    IconData icon = activeMode == 0
        ? Icons.coronavirus_rounded
        : activeMode == 1
            ? Icons.bakery_dining_rounded
            : Icons.spa_rounded;

    MaterialColor badgeColor = activeMode == 0
        ? Colors.green
        : activeMode == 1
            ? Colors.orange
            : Colors.teal;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey<int>(activeMode),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [badgeColor.withValues(alpha: 0.12), badgeColor.withValues(alpha: 0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: badgeColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: badgeColor.shade900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📸 Scanner Box with Animated Laser Line
  Widget _buildImageScannerBox() {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: AppConstants.defaultBorderRadius,
        border: Border.all(
          color: imageFile != null
              ? AppConstants.primaryColor
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: AppConstants.defaultBorderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: imageFile != null
                  ? Image.file(imageFile!, fit: BoxFit.cover)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          activeMode == 0
                              ? Icons.add_a_photo_rounded
                              : activeMode == 1
                                  ? Icons.apple_rounded
                                  : Icons.grass_rounded,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          activeMode == 0
                              ? AppLocalizations.of(context)!.selectImageHint
                              : activeMode == 1
                                  ? "Select or capture fruit image"
                                  : "Select or capture weed image",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
            ),

            // Pulsating Laser Scan Animation when analyzing
            if (loading)
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Dark Overlay
                      Container(color: Colors.black.withValues(alpha: 0.35)),
                      // Moving Laser Bar
                      Positioned(
                        top: _scanAnimation.value * 240,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.lightGreenAccent,
                                Colors.greenAccent,
                                Colors.transparent
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withValues(alpha: 0.8),
                                blurRadius: 12,
                                spreadRadius: 3,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // 🌟 Feature Showcase Component Card
  Widget _buildFeatureCard() {
    String headline = activeMode == 0
        ? '14 Crops & 38 Diseases Supported'
        : activeMode == 1
            ? '131 Fruits & Vegetables Supported'
            : '9 Farmland Weed Species Supported';

    String details = activeMode == 0
        ? 'AI model detects plant health & pathology for Tomato, Potato, Corn, Grape, Apple, Citrus, Pepper, Peach, Strawberry, Cherry, Soybean, Squash, Blueberry, and Raspberry.'
        : activeMode == 1
            ? 'Fruits-360 ResNet50 classifier identifies apples, bananas, citrus, berries, mangoes, grapes, tomatoes, and vegetables with instant nutritional overview.'
            : 'DeepWeeds MobileNetV2 classifier detects Chinee Apple, Lantana, Parkinsonia, Parthenium, Prickly Acacia, Rubber Vine, Siam Weed, Snake Weed & Negative control.';

    IconData badgeIcon = activeMode == 0
        ? Icons.verified_rounded
        : activeMode == 1
            ? Icons.eco_rounded
            : Icons.shield_rounded;

    Color badgeColor = activeMode == 0
        ? Colors.green.shade700
        : activeMode == 1
            ? Colors.orange.shade700
            : Colors.teal.shade700;

    return Card(
      elevation: 0,
      color: badgeColor.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(badgeIcon, color: badgeColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  headline,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              details,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade800, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
