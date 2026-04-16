import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/voice_wrapper.dart';

class DiseaseResultScreen extends StatelessWidget {
  final String disease;
  final double confidence;
  final String recommendation;
  final Map<String, dynamic>? treatment;
  final String? aiExplanation;

  const DiseaseResultScreen({
    super.key,
    required this.disease,
    required this.confidence,
    required this.recommendation,
    this.treatment,
    this.aiExplanation,
  });

  Color _confidenceColor(double value) {
    if (value >= 80) return Colors.green;
    if (value >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildLottie(String disease) {
    if (disease.toLowerCase().contains('healthy')) {
      return Lottie.asset('assets/lottie/healthy.json', height: 180);
    } else if (disease.toLowerCase().contains('unknown')) {
      return Lottie.asset('assets/lottie/unknown.json', height: 180);
    } else {
      return Lottie.asset('assets/lottie/disease.json', height: 180);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showTreatment =
        treatment != null && !disease.toLowerCase().contains('healthy');

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.analysisResult),
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.analysisResult,
        textToRead: "${AppLocalizations.of(context)!.analysisResult}. "
            "${AppLocalizations.of(context)!.detectedDisease}: $disease, "
            "${AppLocalizations.of(context)!.predictionConfidence}: ${confidence.toStringAsFixed(1)}%. "
            "${AppLocalizations.of(context)!.recommendedAction}: $recommendation. "
            "${showTreatment ? '${AppLocalizations.of(context)!.treatmentPlan}: ${treatment!['pesticide']}, ${treatment!['organic']}, precaution: ${treatment!['precaution']}. ' : ''}"
            "${aiExplanation != null && aiExplanation!.isNotEmpty ? '${AppLocalizations.of(context)!.aiAdvice}: $aiExplanation' : ''}",
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: AppConstants.defaultBorderRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.cropDiseasePrediction,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(child: _buildLottie(disease)),
                    const SizedBox(height: 24),
                    
                    Text(
                       AppLocalizations.of(context)!.detectedDisease,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      disease,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    Text(
                       AppLocalizations.of(context)!.predictionConfidence,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: confidence / 100,
                              color: _confidenceColor(confidence),
                              backgroundColor: Colors.grey.shade200,
                              minHeight: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${confidence.toStringAsFixed(2)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _confidenceColor(confidence),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Text(
                       AppLocalizations.of(context)!.recommendedAction,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recommendation,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

            if (showTreatment) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.defaultBorderRadius,
                  side: BorderSide(color: Colors.green.shade100, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medical_services_rounded, color: AppConstants.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                             AppLocalizations.of(context)!.treatmentPlan,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTreatmentRow("💊 Chemical", treatment!['pesticide']),
                      const SizedBox(height: 8),
                      _buildTreatmentRow("📏 Dosage", treatment!['dosage']),
                      const SizedBox(height: 8),
                      _buildTreatmentRow("🌱 Organic", treatment!['organic']),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Precaution: ${treatment!['precaution']}",
                                style: const TextStyle(color: Colors.black87, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (aiExplanation != null && aiExplanation!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.defaultBorderRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.smart_toy_rounded, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                             AppLocalizations.of(context)!.aiAdvice,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      MarkdownBody(
                        data: aiExplanation!,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                 AppLocalizations.of(context)!.aiNotes,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add_a_photo_rounded),
                label: Text(AppLocalizations.of(context)!.analyzeAnother),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTreatmentRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black54)),
        ),
      ],
    );
  }
}
