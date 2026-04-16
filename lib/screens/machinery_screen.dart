import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/constants.dart';
import '../widgets/voice_wrapper.dart';

class MachineryScreen extends StatefulWidget {
  const MachineryScreen({super.key});

  @override
  State<MachineryScreen> createState() => _MachineryScreenState();
}

class _MachineryScreenState extends State<MachineryScreen> {
  List<dynamic> _machinery = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.apps_rounded},
    {'label': 'Tractor', 'icon': Icons.agriculture},
    {'label': 'Harvester', 'icon': Icons.grass_rounded},
    {'label': 'Plough', 'icon': Icons.landscape_rounded},
    {'label': 'Sprayer', 'icon': Icons.water_drop_rounded},
    {'label': 'Transport', 'icon': Icons.local_shipping_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMachinery();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMachinery() async {
    setState(() => _loading = true);
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/listings?type=machinery&lang=$lang'));
      if (response.statusCode == 200) {
        setState(() {
          final items = jsonDecode(response.body)['items'] as List<dynamic>;
          _machinery = items.reversed.toList();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredMachinery {
    var list = _machinery;
    if (_selectedCategory != 'All') {
      list = list.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final cat = _selectedCategory.toLowerCase();
        return title.contains(cat);
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final desc = (item['description'] ?? '').toString().toLowerCase();
        final contractor = (item['contractor_name'] ?? '').toString().toLowerCase();
        return title.contains(q) || desc.contains(q) || contractor.contains(q);
      }).toList();
    }
    return list;
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.dialerError)),
        );
      }
    }
  }

  IconData _getMachineIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('tractor')) return Icons.agriculture;
    if (t.contains('harvest')) return Icons.grass_rounded;
    if (t.contains('plough') || t.contains('plow')) return Icons.landscape_rounded;
    if (t.contains('spray')) return Icons.water_drop_rounded;
    if (t.contains('transport') || t.contains('truck')) return Icons.local_shipping_rounded;
    if (t.contains('seeder') || t.contains('drill')) return Icons.scatter_plot_rounded;
    return Icons.construction_rounded;
  }

  Color _getMachineColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('tractor')) return Colors.green;
    if (t.contains('harvest')) return Colors.amber.shade700;
    if (t.contains('plough') || t.contains('plow')) return Colors.brown;
    if (t.contains('spray')) return Colors.blue;
    if (t.contains('transport') || t.contains('truck')) return Colors.deepOrange;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filteredMachinery;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(l10n.machinerySupport, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMachinery,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: VoiceWrapper(
        screenTitle: l10n.machinerySupport,
        textToRead: _loading
            ? "Searching for farming machinery for rent."
            : (_machinery.isEmpty
                ? "No machinery listings found."
                : "Found ${_machinery.length} machines available for rent."),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Search bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    color: Colors.white,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchMachinery,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),

                  // Category chips
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.white,
                    child: SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _categories.length,
                        itemBuilder: (ctx, i) {
                          final cat = _categories[i];
                          final isSelected = _selectedCategory == cat['label'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Icon(cat['icon'] as IconData, size: 18,
                                  color: isSelected ? Colors.white : Colors.green.shade700),
                              label: Text(cat['label'] as String),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedCategory = cat['label']  as String),
                              selectedColor: Colors.green,
                              backgroundColor: Colors.green.shade50,
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isSelected ? Colors.white : Colors.green.shade800,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              side: BorderSide.none,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Results header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Text(l10n.machinesAvailable(filtered.length),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade700)),
                        const Spacer(),
                        if (_selectedCategory != 'All')
                          GestureDetector(
                            onTap: () => setState(() => _selectedCategory = 'All'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close, size: 14, color: Colors.red.shade700),
                                  const SizedBox(width: 4),
                                  Text(l10n.clearFilter, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Machinery list
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.agriculture, size: 60, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(l10n.noMachinery, style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                                const SizedBox(height: 8),
                                Text(l10n.tryDifferentFilter,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchMachinery,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) => _buildMachineryCard(filtered[index], l10n),
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMachineryCard(dynamic item, AppLocalizations l10n) {
    final title = item['title'] ?? 'Machine';
    final price = item['price'] ?? l10n.contactForPrice;
    final contact = item['contact'] ?? '';
    final contractor = item['contractor_name'] ?? 'Unknown';
    final description = item['description'] ?? '';
    final extra = item['extra_fields'] as Map? ?? {};
    final color = _getMachineColor(title);
    final icon = _getMachineIcon(title);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1,
      child: InkWell(
        onTap: () => _showMachineDetails(item, l10n),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Machine icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.7), color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  // Title and contractor
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(child: Text(contractor, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Price badge
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(price, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),

              // Description
              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],

              // Extra fields as chips
              if (extra.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: extra.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${e.key}: ${e.value}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                    );
                  }).toList(),
                ),
              ],

              const Divider(height: 24),

              // Bottom action row
              Row(
                children: [
                  // Contact
                  if (contact.isNotEmpty)
                    Expanded(
                      child: InkWell(
                        onTap: () => _makeCall(contact),
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            Icon(Icons.phone_rounded, size: 18, color: Colors.green.shade700),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(contact,
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700,
                                      fontSize: 13, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Call button
                  if (contact.isNotEmpty)
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () => _makeCall(contact),
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: Text(l10n.callText, style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Negotiate button
                  SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: () => _showNegotiationDialog(context, item),
                      icon: const Icon(Icons.handshake_rounded, size: 16),
                      label: Text(l10n.negotiate, style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: color.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMachineDetails(dynamic item, AppLocalizations l10n) {
    final title = item['title'] ?? 'Machine';
    final price = item['price'] ?? 'Contact for price';
    final contact = item['contact'] ?? '';
    final contractor = item['contractor_name'] ?? 'Unknown';
    final description = item['description'] ?? '';
    final extra = item['extra_fields'] as Map? ?? {};
    final color = _getMachineColor(title);
    final icon = _getMachineIcon(title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('by $contractor', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Price badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text(price, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                ),
              ),
              const SizedBox(height: 16),
              // Description
              if (description.isNotEmpty) ...[
                Text(description, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4)),
                const SizedBox(height: 16),
              ],
              // Extra specs
              if (extra.isNotEmpty) ...[
                Text(l10n.specifications, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                ...extra.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: color),
                      const SizedBox(width: 8),
                      Text('${e.key}:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 6),
                      Text('${e.value}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
              ],
              // Action buttons
              Row(
                children: [
                  if (contact.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makeCall(contact),
                        icon: const Icon(Icons.call_rounded),
                        label: Text('Call $contact'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  if (contact.isNotEmpty) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showNegotiationDialog(context, item);
                      },
                      icon: const Icon(Icons.handshake_rounded),
                      label: Text(l10n.negotiate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showNegotiationDialog(BuildContext context, dynamic item) {
    final TextEditingController offerController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${l10n.negotiate} for ${item['title']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('${l10n.listedPrice}: ${item['price']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: offerController,
              decoration: InputDecoration(
                labelText: '${l10n.yourOffer} (₹)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: l10n.notes,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.note_alt_outlined),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitNegotiation(context, item, offerController.text, notesController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.submitOffer),
          ),
        ],
      ),
    );
  }

  Future<void> _submitNegotiation(BuildContext context, dynamic item, String offer, String notes) async {
    final box = Hive.box('profileBox');
    final farmerName = box.get('name', defaultValue: 'Farmer');

    try {
      await http.post(
        Uri.parse('${AppConstants.baseUrl}/create_inquiry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'farmer_name': farmerName,
          'contractor_name': item['contractor_name'],
          'listing_id': item['id'],
          'offer_amount': '₹$offer',
          'message': notes,
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.offerSent)),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Widget? _buildBottomBar() {
    final box = Hive.box('profileBox');
    final role = box.get('role', defaultValue: 'farmer');
    if (role != 'farmer') return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _showAddListingDialog,
          icon: const Icon(Icons.add_business_rounded),
          label: const Text("List Machinery for Rent", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  void _showAddListingDialog() {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final contactController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final modelController = TextEditingController();
    final hpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("List Machinery for Rent"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Machine Name (e.g. Mahindra Arjun 605)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: InputDecoration(
                  labelText: "Model Year",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hpController,
                decoration: InputDecoration(
                  labelText: "Horsepower (HP)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                decoration: InputDecoration(
                  labelText: l10n.contactNumber,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: "Rent Content (e.g. ₹800/hr)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: l10n.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final box = Hive.box('profileBox');
              final name = box.get('name');
              final extraFields = {
                'model': modelController.text,
                'hp': hpController.text,
              };

              try {
                final response = await http.post(
                  Uri.parse('${AppConstants.baseUrl}/add_listing'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'contractor_name': name,
                    'type': 'machinery',
                    'title': titleController.text,
                    'contact': contactController.text,
                    'description': descController.text,
                    'price': priceController.text,
                    'extra_fields': extraFields,
                  }),
                );
                if (response.statusCode == 200 && mounted) {
                  Navigator.pop(context);
                  _fetchMachinery();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Your machine is now listed for rent!")),
                  );
                }
              } catch (e) {
                debugPrint('Error: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("List Machine"),
          ),
        ],
      ),
    );
  }
}
