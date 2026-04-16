import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../widgets/ai_recommendation_card.dart';
import 'fertilizer_map_screen.dart';
import 'machinery_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/voice_wrapper.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedType = 'All';
  List<dynamic> _contractors = [];
  List<dynamic> _myInquiries = [];
  Map<String, dynamic>? _aiRecommendation;
  String? _recommendationCrop;
  bool _isLoading = true;

  final List<String> _types = ['All', 'Machinery', 'Labour', 'Fertilizers', 'Irrigation', 'Logistics'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchContractors();
    _fetchMyInquiries();
  }

  Future<void> _fetchMyInquiries() async {
    final box = Hive.box('profileBox');
    final name = box.get('name');
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/inquiries?user=$name&role=farmer&lang=$lang'));
      if (response.statusCode == 200) {
        setState(() {
          _myInquiries = jsonDecode(response.body)['inquiries'];
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _fetchContractors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final typeQuery = _selectedType == 'All' ? '' : '?type=${_selectedType.toLowerCase()}';
      final joinChar = typeQuery.contains('?') ? '&' : '?';
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/listings${typeQuery}${joinChar}lang=$lang'));
      if (response.statusCode == 200) {
        setState(() {
          final items = jsonDecode(response.body)['items'] as List<dynamic>;
          _contractors = items.reversed.toList();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.appName),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.browseServices, icon: const Icon(Icons.search)),
            Tab(text: l10n.myRequests, icon: const Icon(Icons.history)),
          ],
        ),
      ),
      body: VoiceWrapper(
        screenTitle: 'Contracts',
        textToRead: _tabController.index == 0
            ? "${l10n.browseServices}. Found ${_contractors.length} services."
            : "${l10n.myRequests}. You have ${_myInquiries.length} active requests.",
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBrowseTab(),
            _buildMyRequestsTab(),
          ],
        ),
      ),
      floatingActionButton: (_selectedType == 'Fertilizers' || _contractors.any((l) => l['type'] == 'fertilizers'))
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FertilizerMapScreen(initialListings: _contractors.where((l) => l['type'] == 'fertilizers').toList())),
              ),
              label: Text(l10n.locateFertilizer),
              icon: const Icon(Icons.map_outlined),
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildBrowseTab() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildFilterBar(),
        if (_selectedType == 'Fertilizers') ...[
          if (_aiRecommendation == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _showAIAdviceDialog,
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.getAiFertilizerAdvice),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade800,
                ),
              ),
            )
          else
            AIRecommendationCard(
              crop: _recommendationCrop ?? 'General',
              recommendation: _aiRecommendation!,
            ),
        ],
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _contractors.isEmpty
                   ? Center(child: Text(l10n.noContractorsFound))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _contractors.length,
                      itemBuilder: (context, index) {
                        final c = _contractors[index];
                        return _buildContractorCard(c);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMyRequestsTab() {
    final l10n = AppLocalizations.of(context)!;
     if (_myInquiries.isEmpty) return Center(child: Text(l10n.noRequestsYet));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myInquiries.length,
      itemBuilder: (context, index) {
         final req = _myInquiries[index];
         final status = req['status'].toString().toUpperCase();
         final color = status == 'ACCEPTED' ? Colors.green : (status == 'REJECTED' ? Colors.red : Colors.amber);
         
         return Card(
           child: ListTile(
             leading: CircleAvatar(backgroundColor: color, child: const Icon(Icons.request_quote, color: Colors.white)),
             title: Text('Offer: ${req['offer_amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
             subtitle: Text('To: ${req['contractor_name']} • Status: $status'),
             trailing: const Icon(Icons.chevron_right),
           ),
         );
      },
    );
  }

  Widget _buildFilterBar() {
    final l10n = AppLocalizations.of(context)!;
    final localizedTypes = {
      'All': l10n.all,
      'Machinery': l10n.machinerySupport,
      'Labour': l10n.labourCoordination,
      'Fertilizers': l10n.fertilizers,
      'Irrigation': l10n.irrigation,
      'Logistics': l10n.logistics,
    };
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _types.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(localizedTypes[type] ?? type),
              selected: isSelected,
              onSelected: (val) {
                if (type == 'Machinery') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MachineryScreen()),
                  );
                  return; // Don't change selected state or fetch, let user return to Contracts if they want
                }
                setState(() => _selectedType = type);
                _fetchContractors();
              },
              selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppConstants.primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContractorCard(dynamic c) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                  child: Text(c['contractor_name'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                       Text('${c['contractor_name']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)), 
                    ],
                  ),
                ),
                if (c['price'] != null && c['price'].isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(c['price'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
              ],
            ),
            const Divider(height: 24),
            if (c['extra_fields'] != null && (c['extra_fields'] as Map).isNotEmpty) ...[
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: (c['extra_fields'] as Map).entries.map((e) {
                  final key = e.key.toString().toLowerCase();
                  final localizedKey = key == 'stock' ? l10n.stock : (key == 'composition' ? l10n.composition : (key == 'model' ? l10n.model : (key == 'hp' ? l10n.hp : key.toUpperCase())));
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                    child: Text('$localizedKey: ${e.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            InkWell(
              onTap: () {
                final contact = c['contact'] ?? '';
                if (contact.isNotEmpty) {
                  launchUrl(Uri.parse('tel:$contact'));
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: AppConstants.primaryColor),
                    const SizedBox(width: 8),
                    Text(c['contact'] ?? 'No contact info',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: (c['contact'] != null && c['contact'].toString().isNotEmpty)
                              ? Colors.green.shade700
                              : Colors.grey,
                          decoration: (c['contact'] != null && c['contact'].toString().isNotEmpty)
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        )),
                    if (c['contact'] != null && c['contact'].toString().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('Tap to call', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
             Text(c['description'] ?? l10n.noDescription, style: TextStyle(color: Colors.grey.shade700)),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showContactDialog(c),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                     child: Text(l10n.sendOfferNegotiate),
                  ),
                ),
                if (c['type'] == 'fertilizers') ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 45,
                    child: IconButton.filled(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FertilizerMapScreen(initialListings: [c])),
                      ),
                      icon: const Icon(Icons.location_on),
                      style: IconButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                      tooltip: 'View on map',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(dynamic c) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController offerController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
         title: Text(l10n.messageContractor(c['contractor_name'])),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(l10n.discussing(c['title'])),
              const SizedBox(height: 16),
              TextField(
                controller: offerController,
                keyboardType: TextInputType.number,
                 decoration: InputDecoration(labelText: l10n.yourPriceOffer, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                 decoration: InputDecoration(labelText: l10n.messageSpecialReq, border: const OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final box = Hive.box('profileBox');
              final farmerName = box.get('name', defaultValue: 'Farmer');
              
              final response = await http.post(
                Uri.parse('${AppConstants.baseUrl}/create_inquiry'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'farmer_name': farmerName,
                  'contractor_name': c['contractor_name'],
                  'listing_id': c['id'] ?? 0, 
                  'offer_amount': '₹${offerController.text}',
                  'message': messageController.text,
                }),
              );
              
              if (mounted && response.statusCode == 200) {
                Navigator.pop(context);
                _fetchMyInquiries();
                _tabController.animateTo(1); // Switch to "My Requests" tab
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.offerSentToContractor)));
              }
            },
             child: Text(l10n.sendOffer),
          ),
        ],
      ),
    );
  }

  void _showAIAdviceDialog() {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController cropController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
         title: Text(l10n.aiFertilizerExpert),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text(l10n.enterCropForAdvice),
            const SizedBox(height: 12),
            TextField(
              controller: cropController,
              decoration: InputDecoration(
                 hintText: l10n.cropHintExample,
                 border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchAIRecommendation(cropController.text);
            },
             child: Text(l10n.getAdvice),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAIRecommendation(String crop) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/recommendations/fertilizer?crop=$crop'));
      if (response.statusCode == 200) {
        setState(() {
          _aiRecommendation = jsonDecode(response.body);
          _recommendationCrop = crop;
        });
      }
    } catch (e) {
      print('AI Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
