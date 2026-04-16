import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/constants.dart';
import 'crop_screen.dart';
import 'crop_calendar_screen.dart';

class CropInsightScreen extends StatelessWidget {
  const CropInsightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: const Text('Crop Insights', style: TextStyle(fontWeight: FontWeight.bold)),
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
                icon: const Icon(Icons.grass_rounded),
                text: l10n.cropRecommendation,
              ),
              Tab(
                icon: const Icon(Icons.calendar_month_rounded),
                text: l10n.cropCalendar,
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CropScreen(isEmbedded: true),
            CropCalendarScreen(isEmbedded: true),
          ],
        ),
      ),
    );
  }
}
