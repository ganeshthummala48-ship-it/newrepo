import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/voice_wrapper.dart';

class ContractorDashboard extends StatefulWidget {
  const ContractorDashboard({super.key});

  @override
  State<ContractorDashboard> createState() => _ContractorDashboardState();
}

class _ContractorDashboardState extends State<ContractorDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final box = Hive.box('profileBox');
    final name = box.get('name');
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/inquiries?user=$name&role=contractor&lang=$lang'));
      if (response.statusCode == 200) {
        setState(() {
          _notifications = jsonDecode(response.body)['inquiries'];
        });
      }
    } catch (e) {
      print('Error fetching inquiries: $e');
    }
  }

  void _logout() async {
    final box = Hive.box('profileBox');
    await box.put('setup_done', false);
    await box.delete('role');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.appName} - ${l10n.myProfile}'),
        actions: [
          IconButton(onPressed: _fetchNotifications, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.machinery, icon: const Icon(Icons.agriculture)),
            Tab(text: l10n.labour, icon: const Icon(Icons.groups)),
            Tab(text: l10n.fertilizers, icon: const Icon(Icons.science)),
            Tab(text: l10n.logistics, icon: const Icon(Icons.local_shipping)),
            Tab(text: l10n.irrigation, icon: const Icon(Icons.water_drop)),
            Tab(text: l10n.requests, icon: const Icon(Icons.notifications)),
            Tab(text: l10n.settings, icon: const Icon(Icons.settings)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddListingDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.addService),
      ),
      body: VoiceWrapper(
        screenTitle: 'Contractor Dashboard',
        textToRead: "Welcome to your contractor dashboard. Currently in ${_tabController.index == 0 ? 'Machinery' : _tabController.index == 1 ? 'Labour' : _tabController.index == 2 ? 'Fertilizers' : _tabController.index == 3 ? 'Requests' : 'Settings'}. You have ${_notifications.length} requests.",
        child: TabBarView(
          controller: _tabController,
          children: [
          _buildListingTab('machinery'),
          _buildListingTab('labour'),
          _buildListingTab('fertilizers'),
          _buildListingTab('logistics'),
          _buildListingTab('irrigation'),
          _buildNotificationsTab(),
          _buildSettingsTab(),
          ],
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
    final extra1Controller = TextEditingController(); 
    final extra2Controller = TextEditingController(); 
    String selectedType = 'machinery';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.registerService),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['machinery', 'labour', 'fertilizers', 'logistics', 'irrigation']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                  decoration: InputDecoration(labelText: l10n.browseServices),
                ),
                TextField(controller: titleController, decoration: InputDecoration(labelText: selectedType == 'machinery' ? l10n.machinery : l10n.addService)),
                if (selectedType == 'machinery') ...[
                  TextField(controller: extra1Controller, decoration: InputDecoration(labelText: l10n.model)),
                  TextField(controller: extra2Controller, decoration: InputDecoration(labelText: l10n.hp)),
                ] else if (selectedType == 'labour') ...[
                   TextField(controller: extra1Controller, decoration: InputDecoration(labelText: l10n.teamSize)),
                   TextField(controller: extra2Controller, decoration: InputDecoration(labelText: l10n.specialty)),
                ],
                 TextField(controller: contactController, decoration: InputDecoration(labelText: l10n.contactNumber)),
                 TextField(controller: priceController, decoration: InputDecoration(labelText: l10n.priceRate)),
                 TextField(controller: descController, decoration: InputDecoration(labelText: l10n.description), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                final box = Hive.box('profileBox');
                final name = box.get('name');
                final extraFields = {};
                if (selectedType == 'machinery') {
                   extraFields['model'] = extra1Controller.text;
                   extraFields['hp'] = extra2Controller.text;
                } else if (selectedType == 'labour') {
                   extraFields['team_size'] = extra1Controller.text;
                   extraFields['specialty'] = extra1Controller.text;
                }
                final response = await http.post(
                  Uri.parse('${AppConstants.baseUrl}/add_listing'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'contractor_name': name,
                    'type': selectedType,
                    'title': titleController.text,
                    'contact': contactController.text,
                    'description': descController.text,
                    'price': priceController.text,
                    'extra_fields': extraFields,
                  }),
                );
                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: Text(l10n.register),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingTab(String type) {
    final box = Hive.box('profileBox');
    final name = box.get('name');
    final lang = Localizations.localeOf(context).languageCode;
    return FutureBuilder(
      future: http.get(Uri.parse('${AppConstants.baseUrl}/listings?type=$type&lang=$lang')),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final allItems = jsonDecode(snapshot.data!.body)['items'];
        // Filter only own items for the dashboard
        final items = (allItems as List).where((i) => i['contractor_name'] == name).toList();
        
        if (items.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.all)); // Using 'all' as a placeholder for empty
        
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppConstants.primaryColor),
                title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item['price'] ?? 'Price not set'),
                trailing: const Icon(Icons.edit, size: 20),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_notifications.isEmpty) return Center(child: Text(l10n.requests));
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final inquiry = _notifications[index];
        final bool isPending = inquiry['status'] == 'pending';
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text('${l10n.offer}: ${inquiry['offer_amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${l10n.from}: ${inquiry['farmer_name']} • ${l10n.statusLabel}: ${inquiry['status'].toString().toUpperCase()}'),
            leading: CircleAvatar(
              backgroundColor: isPending ? Colors.amber : (inquiry['status'] == 'accepted' ? Colors.green : Colors.red),
              child: const Icon(Icons.request_quote, color: Colors.white),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Message: ${inquiry['message']}'),
                    const SizedBox(height: 16),
                    if (isPending)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _respondToInquiry(inquiry['id'], 'rejected'),
                            child: Text(l10n.reject, style: const TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _respondToInquiry(inquiry['id'], 'accepted'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            child: Text(l10n.acceptOffer),
                          ),
                        ],
                      )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _respondToInquiry(int id, String status) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/respond_inquiry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'inquiry_id': id, 'status': status}),
      );
      if (response.statusCode == 200) {
        _fetchNotifications();
      }
    } catch (e) {
      print('Error responding to inquiry: $e');
    }
  }

  Widget _buildSettingsTab() {
    final box = Hive.box('profileBox');
    final name = box.get('name');
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: AppConstants.primaryColor),
                title: Text(name ?? 'Contractor'),
                subtitle: Text(AppLocalizations.of(context)!.myProfile),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text('Specialty / Contract Type'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showSpecialtyDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSpecialtyDialog() {
    final box = Hive.box('profileBox');
    final name = box.get('name');
    final specialties = ['Machinery', 'Labour', 'Fertilizers', 'Irrigation', 'Logistics'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.settings),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: specialties.map((s) => ListTile(
            title: Text(s),
            onTap: () async {
              await http.post(
                Uri.parse('${AppConstants.baseUrl}/update_profile?name=$name'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'specialty': s}),
              );
              Navigator.pop(context);
              setState(() {});
            },
          )).toList(),
        ),
      ),
    );
  }
}
