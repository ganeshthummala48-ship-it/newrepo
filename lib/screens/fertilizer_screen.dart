import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/voice_wrapper.dart';

class FertilizerScreen extends StatelessWidget {
  const FertilizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    // Mock data for fertilizers
    final List<Map<String, dynamic>> fertilizers = [
      {'name': 'Urea', 'price': '₹300/bag', 'brand': 'IFFCO', 'rating': 4.5},
      {'name': 'DAP', 'price': '₹1200/bag', 'brand': 'Coral', 'rating': 4.7},
      {'name': 'Potash', 'price': '₹800/bag', 'brand': 'FarmPro', 'rating': 4.3},
    ];

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.fertilizerSupport)),
      body: VoiceWrapper(
        screenTitle: 'Fertilizers',
        textToRead: "Found ${fertilizers.length} fertilizers. " + 
          fertilizers.map((f) => "${f['name']} from ${f['brand']} priced at ${f['price']}.").join(". "),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fertilizers.length,
          itemBuilder: (context, index) {
            final item = fertilizers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.blue.shade50.withValues(alpha: 0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                          child: const Icon(Icons.science, size: 30, color: AppConstants.primaryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(item['brand'], style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Text(item['price'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor, fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, size: 18, color: Colors.amber),
                            Text(' ${item['rating']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () => _submitBooking(context, item),
                          child: Text(AppLocalizations.of(context)!.bookNow),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitBooking(BuildContext context, Map<String, dynamic> item) async {
    final box = Hive.box('profileBox');
    final farmerName = box.get('name', defaultValue: 'Farmer');

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.processingBooking)));

    try {
      // Notify contractor (using the same endpoint)
      await http.post(
        Uri.parse('${AppConstants.baseUrl}/notify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': 'Booking for Fertilizer: ${item['name']} - ${item['price']}',
          'farmer_name': farmerName,
        }),
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.bookingConfirmed),
            content: Text('Your booking for ${item['name']} has been sent to the corporation. They will contact you shortly.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.ok))],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.serverError}: $e')));
      }
    }
  }
}
