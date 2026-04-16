import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/constants.dart';
import 'disease_screen.dart';
import 'disease_gallery_screen.dart';

class CropHealthScreen extends StatelessWidget {
  const CropHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: const Text('Crop Health', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: const Icon(Icons.document_scanner_rounded),
                text: l10n.diseaseDetection,
              ),
              Tab(
                icon: const Icon(Icons.menu_book_rounded),
                text: l10n.diseaseGuide,
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DiseaseScreen(isEmbedded: true),
            DiseaseGalleryScreen(isEmbedded: true),
          ],
        ),
      ),
    );
  }
}
