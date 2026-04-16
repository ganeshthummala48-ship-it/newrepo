import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/constants.dart';
import '../widgets/voice_wrapper.dart';

class LabourScreen extends StatefulWidget {
  const LabourScreen({super.key});

  @override
  State<LabourScreen> createState() => _LabourScreenState();
}

class _LabourScreenState extends State<LabourScreen> {
  List<dynamic> _labour = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLabour();
  }

  Future<void> _fetchLabour() async {
    setState(() => _loading = true);
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/listings?type=labour&lang=$lang'));
      if (response.statusCode == 200) {
        setState(() {
          _labour = jsonDecode(response.body)['items'];
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.dialerError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(title: Text(l10n.labourCoordination)),
      body: VoiceWrapper(
        screenTitle: 'Labour',
        textToRead: _loading 
            ? "Looking for available labour groups." 
            : (_labour.isEmpty 
                ? "No labour groups found in your area." 
                : "Found ${_labour.length} labour groups. " + 
                  _labour.map((l) => "${l['title']} charging ${l['price']}.").join(". ")),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _labour.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.noLabour))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _labour.length,
                    itemBuilder: (context, index) {
                    final group = _labour[index];
                    final contact = group['contact'] ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                                  child: const Icon(Icons.groups_rounded, size: 30, color: AppConstants.primaryColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(group['title'] ?? 'Labour Group', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('${group['price'] ?? 'Price not set'}', style: TextStyle(color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            const SizedBox(height: 12),
                            if (contact.isNotEmpty)
                              InkWell(
                                onTap: () => _makeCall(contact),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.phone, color: Colors.green.shade700, size: 22),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(AppLocalizations.of(context)!.tapToCall, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            Text(contact, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green.shade400),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showNegotiationDialog(context, group),
                                icon: const Icon(Icons.handshake),
                                label: Text(AppLocalizations.of(context)!.negotiateOffer),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
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

  void _showNegotiationDialog(BuildContext context, dynamic group) {
    final TextEditingController _offerController = TextEditingController();
    final TextEditingController _notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${group['title']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rate: ${group['price']}'),
            const SizedBox(height: 16),
            TextField(
              controller: _offerController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.yourOffer + ' (₹/day)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.notes),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitNegotiation(context, group, _offerController.text, _notesController.text);
            },
            child: Text(AppLocalizations.of(context)!.sendRequest),
          ),
        ],
      ),
    );
  }

  Future<void> _submitNegotiation(BuildContext context, dynamic group, String offer, String notes) async {
    final box = Hive.box('profileBox');
    final farmerName = box.get('name', defaultValue: 'Farmer');

    try {
      await http.post(
        Uri.parse('${AppConstants.baseUrl}/create_inquiry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'farmer_name': farmerName,
          'contractor_name': group['contractor_name'],
          'listing_id': group['id'],
          'offer_amount': '₹$offer',
          'message': notes,
        }),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestSent)));
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}
