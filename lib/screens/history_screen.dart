import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';
import '../widgets/voice_wrapper.dart';
import '../l10n/generated/app_localizations.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key}); 

  @override
  Widget build(BuildContext context) {
    final Box historyBox = Hive.box('historyBox');

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.predictionHistory),
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.predictionHistory,
        textToRead: historyBox.isEmpty
            ? "You have no prediction history yet."
            : "You have ${historyBox.length} past predictions. You can review them here.",
        child: ValueListenableBuilder(
        valueListenable: historyBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No predictions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final dynamic rawItem = box.getAt(index);

              // 🔒 Safety check
              if (rawItem is! Map) return const SizedBox();

              final String imagePath = rawItem['imagePath'] ?? '';
              final String disease = rawItem['disease'] ?? 'Unknown';
              final double confidence =
                  (rawItem['confidence'] as num?)?.toDouble() ?? 0.0;
              final String date = _formatDate(rawItem['date']);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.defaultBorderRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _buildImage(imagePath),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              disease,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Confidence: ${confidence.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 13,
                                color: confidence > 80 ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
    );
  }

  /// 🕒 Safe date formatter
  String _formatDate(dynamic rawDate) {
    try {
      final DateTime dt = DateTime.parse(rawDate.toString());
      return "${dt.day.toString().padLeft(2, '0')}-"
          "${dt.month.toString().padLeft(2, '0')}-"
          "${dt.year} "
          "${dt.hour.toString().padLeft(2, '0')}:"
          "${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }

  /// 🖼️ Safe image loader
  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        width: 70, height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8)
        ),
        child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey)
      );
    }

    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        width: 70, height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8)
        ),
        child: const Icon(Icons.broken_image, size: 30, color: Colors.grey)
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
      ),
    );
  }
}
