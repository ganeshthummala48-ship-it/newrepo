import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import 'crop_recommendation_screen.dart';
import '../widgets/voice_wrapper.dart';

class CropScreen extends StatefulWidget {
  final bool isEmbedded;
  const CropScreen({super.key, this.isEmbedded = false});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  String selectedSoil = 'Black';
  String selectedSeason = 'Kharif';
  String selectedRainfall = 'Medium';

  bool loading = false;

  final soils = ['Black', 'Alluvial', 'Loamy', 'Clay', 'Sandy'];
  final seasons = ['Kharif', 'Rabi', 'Zaid'];
  final rainfalls = ['Low', 'Medium', 'High'];

  Future<void> getRecommendation() async {
    setState(() => loading = true);

    final uri = Uri.parse('${AppConstants.baseUrl}/recommend-crop');

    try {
      final lang = Localizations.localeOf(context).languageCode;
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'soil': selectedSoil,
          'season': selectedSeason,
          'rainfall': selectedRainfall,
          'lang': lang,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CropRecommendationScreen(
              data: data['top_crops'],
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Failed to connect to the server. Please check your connection.')),
      );
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: widget.isEmbedded ? null : AppBar(
        title: Text(AppLocalizations.of(context)!.cropRecommendation),
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.cropRecommendation,
        textToRead: AppLocalizations.of(context)!.farmDetails + ". Enter your soil type, season and rainfall to get the best crop recommendations.",
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
              child: Text(
                AppLocalizations.of(context)!.farmDetails,
                style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppConstants.defaultBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Row(
                    children: [
                      Icon(Icons.landscape_rounded, color: AppConstants.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Farm Conditions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  _buildDropdownRow(
                    label: AppLocalizations.of(context)!.soilType,
                    icon: Icons.grass_rounded,
                    value: selectedSoil,
                    items: soils,
                    onChanged: (val) => setState(() => selectedSoil = val!),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildDropdownRow(
                    label: AppLocalizations.of(context)!.season,
                    icon: Icons.wb_sunny_rounded,
                    value: selectedSeason,
                    items: seasons,
                    onChanged: (val) => setState(() => selectedSeason = val!),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildDropdownRow(
                    label: AppLocalizations.of(context)!.rainfallLevel,
                    icon: Icons.water_drop_rounded,
                    value: selectedRainfall,
                    items: rainfalls,
                    onChanged: (val) => setState(() => selectedRainfall = val!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: loading ? null : getRecommendation,
                icon: loading 
                    ? const SizedBox() 
                    : const Icon(Icons.auto_awesome_rounded),
                label: loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.getRecommendation,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppConstants.primaryColor),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.primaryColor),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}

