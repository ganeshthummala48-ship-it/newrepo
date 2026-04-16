import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/voice_wrapper.dart';
import '../l10n/generated/app_localizations.dart';

class CropRecommendationScreen extends StatefulWidget {
  final List<dynamic>? data;
  
  const CropRecommendationScreen({super.key, this.data});

  @override
  State<CropRecommendationScreen> createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen>
    with SingleTickerProviderStateMixin {
  
  late List<Map<String, dynamic>> predictions;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    predictions = widget.data != null 
        ? List<Map<String, dynamic>>.from(widget.data!) 
        : [];
        
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String cropImage(String crop) {
    return 'assets/crops/${crop.toLowerCase()}.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Top Recommended Crops'),
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.cropRecommendation,
        textToRead: predictions.isEmpty 
            ? "No recommendations found." 
            : "Found ${predictions.length} recommended crops. " + 
              predictions.map((p) => "${p['crop']} with ${p['confidence'].toStringAsFixed(0)} percent confidence.").join(". "),
        child: predictions.isEmpty 
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grass_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('No recommendations found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        )
      : SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Text(
                    "Here are the best crops suited for your farm's conditions:",
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 12),
                ...predictions.map(_cropCard),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cropCard(Map<String, dynamic> item) {
    final crop = item['crop'];
    final confidence = item['confidence'];
    final rank = item['rank'];
    final desc = item['description'];

    // Define medal colors based on rank
    Color rankColor = AppConstants.primaryColor;
    if (rank == 1) rankColor = Colors.amber.shade600;
    if (rank == 2) rankColor = Colors.grey.shade500;
    if (rank == 3) rankColor = Colors.brown.shade400;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: AppConstants.defaultBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: rankColor.withValues(alpha: 0.1),
                     shape: BoxShape.circle,
                   ),
                   child: Icon(Icons.emoji_events_rounded, color: rankColor),
                 ),
                 const SizedBox(width: 12),
                 Text(
                     "Rank $rank - $crop",
                     style: TextStyle(
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                       color: rankColor,
                      ),
                  ),
               ],
             ),
              const SizedBox(height: 16),
              ClipRRect(
                  borderRadius: AppConstants.defaultBorderRadius,
                  child: Image.asset(
                    cropImage(crop),
                     width: double.infinity,
                     height: 160,
                     fit: BoxFit.cover,
                     errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 160,
                          color: Colors.grey.shade100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.grass_rounded, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text(crop, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                     },
                   ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Match Confidence:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(
                    "${confidence.toStringAsFixed(1)}%",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                    value: confidence / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    color: rankColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  desc ?? '',
                  style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
