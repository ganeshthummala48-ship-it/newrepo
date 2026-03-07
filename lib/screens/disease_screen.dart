import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'package:hive/hive.dart';

import 'package:farmer_ai/screens/disease_result_screen.dart';
import 'package:farmer_ai/screens/history_screen.dart';

class DiseaseScreen extends StatefulWidget {
  const DiseaseScreen({super.key});

  @override
  State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen> {
  File? imageFile;
  bool loading = false;

  final ImagePicker _picker = ImagePicker();

  // 📸 Pick image
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  // 🔍 Analyze image
  Future<void> analyzeImage() async {
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() => loading = true);
    String disease = 'Unknown Disease';
    String? aiExplanation;
    String recommendation =
        'The image could not be analyzed. Please try again.';
    double confidence = 0.0;
    Map<String, dynamic>? treatment;

    final uri = Uri.parse('${AppConstants.baseUrl}/detect-disease');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile!.path),
      );

      final streamedResponse = await request.send();
      final body = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final data = jsonDecode(body);
        disease = data['disease'] ?? disease;
        recommendation = data['recommendation'] ?? recommendation;
        confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
        treatment = data['treatment'];
        aiExplanation = data['ai_explanation'];
        // ✅ SAVE TO HISTORY ONLY AFTER SUCCESS
        final box = Hive.box('historyBox');
        box.add({
          'imagePath': imageFile!.path,
          'disease': disease,
          'confidence': confidence,
          'date': DateTime.now().toString(),
          'treatment': treatment,
        });

        debugPrint("API RESPONSE: $data");
      } else {
        if (!mounted) return;
        debugPrint("Server error: ${streamedResponse.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server Error: ${streamedResponse.statusCode}'),
          ),
        );
        setState(() => loading = false);
        return;
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("API ERROR: $e");
      String errorMessage =
          'Failed to connect to the server. Please check your connection.';

      if (e is HiveError) {
        errorMessage = 'Database Error: ${e.message}';
      } else if (e is SocketException) {
        errorMessage = 'Network Error: Connection refused or timed out.';
      } else if (e is FormatException) {
        errorMessage = 'Invalid response format from server.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      setState(() => loading = false);
      return;
    }

    setState(() => loading = false);

    if (!mounted) return;
    // ➡️ Navigate to result screen
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
  }

  // 🧱 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Prediction History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Upload a clear picture of the affected crop leaf to detect diseases instantly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),

            // Image Box
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: AppConstants.defaultBorderRadius,
                border: Border.all(
                  color: imageFile != null
                      ? AppConstants.primaryColor
                      : Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: ClipRRect(
                borderRadius: AppConstants.defaultBorderRadius,
                child: imageFile != null
                    ? Image.file(imageFile!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap buttons below to select image',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppConstants.primaryColor,
                      elevation: 0,
                      side: const BorderSide(color: AppConstants.primaryColor),
                    ),
                    onPressed: loading
                        ? null
                        : () => pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppConstants.primaryColor,
                      elevation: 0,
                      side: const BorderSide(color: AppConstants.primaryColor),
                    ),
                    onPressed: loading
                        ? null
                        : () => pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (imageFile == null || loading) ? null : analyzeImage,
                child: loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Analyze Leaf',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
