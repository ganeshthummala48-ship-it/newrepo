import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/voice_wrapper.dart';
import 'contract_details_screen.dart';
import '../services/notification_polling_service.dart';

class ContractorDashboard extends StatefulWidget {
  const ContractorDashboard({super.key});

  @override
  State<ContractorDashboard> createState() => _ContractorDashboardState();
}

class _ContractorDashboardState extends State<ContractorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _notifications = [];
  List<dynamic> _allListings = [];
  bool _isLoadingListings = true;
  NotificationPollingService? _pollingService;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 8, vsync: this); // Added 1 for Overview
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchNotifications();
    _fetchAllListings();
    // Start background polling for new farmer requests
    final box = Hive.box('profileBox');
    final name = box.get('name', defaultValue: '') as String;
    if (name.isNotEmpty) {
      _pollingService = NotificationPollingService(
        role: 'contractor',
        name: name,
        pollInterval: const Duration(seconds: 30),
      )..start();
    }
  }

  Future<void> _fetchAllListings() async {
    final box = Hive.box('profileBox');
    final name = box.get('name');
    final lang = Localizations.localeOf(context).languageCode;
    setState(() => _isLoadingListings = true);
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}/listings?lang=$lang'));
      if (response.statusCode == 200) {
        final allItems = jsonDecode(response.body)['items'] as List;
        setState(() {
          _allListings =
              allItems.where((i) => i['contractor_name'] == name).toList();
        });
      }
    } catch (e) {
      print('Error fetching listings: $e');
    } finally {
      setState(() => _isLoadingListings = false);
    }
  }

  Future<void> _fetchNotifications() async {
    final box = Hive.box('profileBox');
    final name = box.get('name');
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final response = await http.get(Uri.parse(
          '${AppConstants.baseUrl}/inquiries?user=$name&role=contractor&lang=$lang'));
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
    _pollingService?.stop();
    final box = Hive.box('profileBox');
    await box.put('setup_done', false);
    await box.delete('role');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pollingService?.stop();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text('${l10n.appName} - Contractor',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
              onPressed: () {
                _fetchNotifications();
                _fetchAllListings();
              },
              icon: const Icon(Icons.refresh)),
          IconButton(
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              icon: const Icon(Icons.notifications_active_rounded)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            const Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: l10n.machinery, icon: const Icon(Icons.agriculture)),
            Tab(text: l10n.labour, icon: const Icon(Icons.groups)),
            Tab(text: l10n.fertilizers, icon: const Icon(Icons.science)),
            Tab(text: l10n.logistics, icon: const Icon(Icons.local_shipping)),
            Tab(text: l10n.irrigation, icon: const Icon(Icons.water_drop)),
            Tab(
                text: 'Requests',
                icon: Badge(
                    isLabelVisible: _notifications.isNotEmpty,
                    label: Text('${_notifications.length}'),
                    child: const Icon(Icons.notifications))),
            Tab(text: l10n.settings, icon: const Icon(Icons.settings)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddListingDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.addService),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: VoiceWrapper(
        screenTitle: 'Contractor Dashboard',
        textToRead:
            "Welcome to your contractor dashboard. You have ${_allListings.length} total services and ${_notifications.length} requests.",
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildListingTab('machinery', l10n.machinery),
            _buildListingTab('labour', l10n.labour),
            _buildListingTab('fertilizers', l10n.fertilizers),
            _buildListingTab('logistics', l10n.logistics),
            _buildListingTab('irrigation', l10n.irrigation),
            _buildNotificationsTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoadingListings) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeContracts = _notifications
        .where((n) => n['status'] == 'accepted' || n['status'] == 'active')
        .length;
    final totalRequests = _notifications.length;
    final totalServices = _allListings.length;
    final recentRequests = _notifications.take(3).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchAllListings();
        await _fetchNotifications();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5)) // Replaced withOpacity
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Summary',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryStat(
                        Icons.storefront, '$totalServices', 'My Services'),
                    _buildSummaryStat(Icons.request_quote, '$totalRequests',
                        'Total Requests'),
                    _buildSummaryStat(
                        Icons.handshake, '$activeContracts', 'Active Jobs'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => _tabController.animateTo(6),
                child: const Text('View All'),
              ),
            ],
          ),
          if (recentRequests.isEmpty)
            Card(
              elevation: 0,
              color: Colors.blueGrey.shade50,
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                    child: Text(
                        "No requests right now. Keep your services updated!",
                        style: TextStyle(color: Colors.blueGrey))),
              ),
            )
          else
            ...recentRequests.map((req) => _buildRequestCard(req)),
          const SizedBox(height: 24),
          const Text('My Top Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_allListings.isEmpty)
            Card(
              elevation: 0,
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                    child: Text(
                        "You haven't listed any services yet. Tap + to add one.",
                        style: TextStyle(color: Colors.orange))),
              ),
            )
          else
            ..._allListings.take(3).map((l) => _buildListingCard(l)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(IconData icon, String value, String label) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor:
              Colors.white.withValues(alpha: 0.2), // Replaced withOpacity
          radius: 24,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: Colors.green.shade100, fontSize: 12)),
      ],
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.registerService,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: l10n.browseServices,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: [
                    'machinery',
                    'labour',
                    'fertilizers',
                    'logistics',
                    'irrigation'
                  ]
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: selectedType == 'machinery'
                          ? l10n.machinery
                          : l10n.addService,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    )),
                const SizedBox(height: 12),
                if (selectedType == 'machinery') ...[
                  TextField(
                      controller: extra1Controller,
                      decoration: InputDecoration(
                          labelText: l10n.model,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: extra2Controller,
                      decoration: InputDecoration(
                          labelText: l10n.hp,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                ] else if (selectedType == 'labour') ...[
                  TextField(
                      controller: extra1Controller,
                      decoration: InputDecoration(
                          labelText: l10n.teamSize,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: extra2Controller,
                      decoration: InputDecoration(
                          labelText: l10n.specialty,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                ],
                TextField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                        labelText: l10n.contactNumber,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                        labelText: l10n.priceRate,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                TextField(
                    controller: descController,
                    decoration: InputDecoration(
                        labelText: l10n.description,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                final box = Hive.box('profileBox');
                final name = box.get('name');
                // Inherit contractor's registered location for the listing
                final contractorLat =
                    (box.get('lat') as num?)?.toDouble() ?? 0.0;
                final contractorLng =
                    (box.get('lng') as num?)?.toDouble() ?? 0.0;
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
                    'lat': contractorLat,
                    'lng': contractorLng,
                  }),
                );
                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  _fetchAllListings();
                }
              },
              child: Text(l10n.register),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingTab(String type, String localizedType) {
    if (_isLoadingListings) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = _allListings.where((i) => i['type'] == type).toList();

    if (items.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No $localizedType services added',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Tap the + button to add a service',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildListingCard(items[index]);
      },
    );
  }

  Widget _buildListingCard(dynamic item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppConstants.primaryColor
                          .withValues(alpha: 0.1), // Replaced withOpacity
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.check_circle_outline,
                      color: AppConstants.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(item['price'] ?? 'Price not set',
                          style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () {
                    // Placeholder for edit functionality
                  },
                ),
              ],
            ),
            if (item['description'] != null &&
                item['description'].toString().isNotEmpty) ...[
              const Divider(height: 24),
              Text(item['description'],
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    if (_notifications.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read_outlined,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No active requests',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
          const SizedBox(height: 8),
          Text("You're all caught up!",
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(_notifications[index]);
      },
    );
  }

  Widget _buildRequestCard(dynamic inquiry) {
    final String status = inquiry['status'].toString().toUpperCase();

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;

    switch (inquiry['status']) {
      case 'pending':
        statusColor = Colors.amber;
        statusIcon = Icons.pending_actions;
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.handshake;
        break;
      case 'active':
        statusColor = Colors.teal;
        statusIcon = Icons.play_circle_fill;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: statusColor.withValues(alpha: 0.3),
            width: 1), // Replaced withOpacity
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContractDetailsScreen(
                inquiry: inquiry,
                role: 'contractor',
              ),
            ),
          );
          _fetchNotifications();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(
                          alpha: 0.1), // Replaced withOpacity
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(status,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('ID: #${inquiry['id']}',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(inquiry['farmer_name'][0].toUpperCase(),
                        style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inquiry['farmer_name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Offer: ${inquiry['offer_amount']}',
                            style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              if (inquiry['message'] != null &&
                  inquiry['message'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(inquiry['message'],
                              style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    final box = Hive.box('profileBox');
    final name = box.get('name');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: AppConstants.primaryColor
                        .withValues(alpha: 0.05), // Replaced withOpacity
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16))),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppConstants.primaryColor,
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name ?? 'Contractor',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Professional Account',
                            style: TextStyle(color: Colors.green.shade700)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(8)), // Replaced withOpacity
                    child: const Icon(Icons.star, color: Colors.amber)),
                title: const Text('Specialty / Contract Type',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showSpecialtyDialog(),
              ),
              const Divider(height: 1, indent: 70),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(8)), // Replaced withOpacity
                    child: const Icon(Icons.analytics, color: Colors.blue)),
                title: const Text('Performance Analytics',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon!')));
                },
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
    final specialties = [
      'Machinery',
      'Labour',
      'Fertilizers',
      'Irrigation',
      'Logistics'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.settings,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: specialties
              .map((s) => ListTile(
                    title: Text(s,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.check_circle_outline,
                        color: Colors.grey),
                    onTap: () async {
                      await http.post(
                        Uri.parse(
                            '${AppConstants.baseUrl}/update_profile?name=$name'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'specialty': s}),
                      );
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
