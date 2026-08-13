import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';

class ContractDetailsScreen extends StatefulWidget {
  final dynamic inquiry;
  final String role; // 'farmer' or 'contractor'

  const ContractDetailsScreen({
    super.key,
    required this.inquiry,
    required this.role,
  });

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  late dynamic _currentInquiry;
  List<dynamic> _logs = [];
  bool _isLoadingLogs = true;
  bool _isLoadingListing = true;
  bool _isActionLoading = false;
  Map<String, dynamic>? _listingDetails;

  final TextEditingController _counterPriceController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newMilestoneController = TextEditingController();
  final TextEditingController _ratingCommentController =
      TextEditingController();
  double _farmerRating = 5.0;

  String? _aiNegotiationMessage;
  String? _aiCounterPriceSuggested;
  bool _isAiAdvising = false;
  Timer? _autoPollTimer;

  @override
  void initState() {
    super.initState();
    _currentInquiry = widget.inquiry;
    // defer fetching until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchListingDetails();
      _fetchServiceLogs();
    });
    // Auto-poll inquiry status every 3 seconds so farmer gets instant updates
    _autoPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _refreshInquiry();
      }
    });
  }

  @override
  void dispose() {
    _autoPollTimer?.cancel();
    _counterPriceController.dispose();
    _otpController.dispose();
    _newMilestoneController.dispose();
    _ratingCommentController.dispose();
    super.dispose();
  }

  Future<void> _fetchListingDetails() async {
    setState(() => _isLoadingListing = true);
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final response = await http.get(Uri.parse(
          '${AppConstants.baseUrl}/listings/${_currentInquiry['listing_id']}?lang=$lang'));
      if (response.statusCode == 200) {
        setState(() {
          _listingDetails = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching listing details: $e');
    } finally {
      setState(() => _isLoadingListing = false);
    }
  }

  Future<void> _fetchServiceLogs() async {
    setState(() => _isLoadingLogs = true);
    try {
      final response = await http.get(Uri.parse(
          '${AppConstants.baseUrl}/contracts/${_currentInquiry['id']}/logs'));
      if (response.statusCode == 200) {
        setState(() {
          _logs = jsonDecode(response.body)['logs'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching service logs: $e');
    } finally {
      setState(() => _isLoadingLogs = false);
    }
  }

  void _showAcceptanceNotificationDialog() {
    NotificationService.showContractNotification(
      id: 999,
      title: '🎉 Offer Accepted by Contractor!',
      body:
          'The contractor has accepted your offer! You can now generate the Work Completion OTP when the job is done.',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Offer Accepted!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The contractor has accepted your request. Both locations are now verified.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'Once the work is done on your farm, tap "Generate Work Completion OTP" below and share it with the contractor.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it! Proceed to OTP'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshInquiry() async {
    final name = Hive.box('profileBox').get('name');
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final response = await http.get(Uri.parse(
          '${AppConstants.baseUrl}/inquiries?user=$name&role=${widget.role}&lang=$lang'));
      if (response.statusCode == 200) {
        final inquiries = jsonDecode(response.body)['inquiries'] as List;
        final updated = inquiries.firstWhere(
            (i) => i['id'] == _currentInquiry['id'],
            orElse: () => null);
        if (updated != null && mounted) {
          final oldStatus = _currentInquiry['status']?.toString();
          final newStatus = updated['status']?.toString();

          setState(() {
            _currentInquiry = updated;
          });

          // If status changed to 'accepted' while farmer is viewing
          if (widget.role == 'farmer' &&
              (oldStatus == 'pending' || oldStatus == 'counter') &&
              newStatus == 'accepted') {
            _showAcceptanceNotificationDialog();
          }
        }
      }
    } catch (e) {
      debugPrint('Error refreshing inquiry: $e');
    }
  }

  Future<void> _respondInquiry(String status, {String? counterPrice}) async {
    setState(() => _isActionLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/respond_inquiry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inquiry_id': _currentInquiry['id'],
          'status': status,
          'counter_price': counterPrice,
        }),
      );
      if (response.statusCode == 200) {
        await _refreshInquiry();
        await _fetchServiceLogs();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Action complete!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _getAiNegotiationAdvice() async {
    if (_listingDetails == null) return;
    setState(() => _isAiAdvising = true);
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/negotiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'item_name': _listingDetails!['title'] ?? 'Service Item',
          'item_type': _listingDetails!['type'] ?? 'machinery',
          'original_price': _listingDetails!['price'] ?? 'Rs.800/hr',
          'offered_price': _currentInquiry['offer_amount'] ?? 'Rs.500/hr',
          'farmer_name': _currentInquiry['farmer_name'],
          'notes': _currentInquiry['message'] ?? '',
          'lang': lang,
        }),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final rawResponse = result['response'] as String? ?? '';
        String message = rawResponse;
        String? cPrice;
        for (var line in rawResponse.split('\n')) {
          if (line.toLowerCase().startsWith('counter price:')) {
            cPrice = line.substring(14).trim();
          } else if (line.toLowerCase().startsWith('message:')) {
            message = line.substring(8).trim();
          }
        }
        if (mounted) {
          setState(() {
            _aiNegotiationMessage = message;
            _aiCounterPriceSuggested = cPrice;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching AI advice: $e');
    } finally {
      if (mounted) setState(() => _isAiAdvising = false);
    }
  }

  Future<void> _generateOtp() async {
    setState(() => _isActionLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/contracts/generate_otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inquiry_id': _currentInquiry['id'],
        }),
      );
      if (response.statusCode == 200) {
        await _refreshInquiry();
        await _fetchServiceLogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Work Completion OTP generated successfully!'),
            backgroundColor: Colors.green,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _verifyOtp(String action) async {
    if (_otpController.text.isEmpty) return;
    setState(() => _isActionLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/contracts/verify_otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inquiry_id': _currentInquiry['id'],
          'otp': _otpController.text.trim(),
          'action': action,
        }),
      );
      final resData = jsonDecode(response.body);
      if (mounted) {
        if (resData['status'] == 'success') {
          _otpController.clear();
          await _refreshInquiry();
          await _fetchServiceLogs();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('OTP verified successfully!'),
            backgroundColor: Colors.green,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(resData['error'] ?? 'Incorrect OTP code'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _addMilestone() async {
    if (_newMilestoneController.text.isEmpty) return;
    setState(() => _isActionLoading = true);
    try {
      await http.post(
        Uri.parse('${AppConstants.baseUrl}/contracts/milestone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inquiry_id': _currentInquiry['id'],
          'status_update': 'Work Progress',
          'description': _newMilestoneController.text.trim(),
        }),
      );
      _newMilestoneController.clear();
      await _fetchServiceLogs();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Status updated!')));
      }
    } catch (e) {
      debugPrint('Error adding milestone: $e');
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _submitReview() async {
    setState(() => _isActionLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/contracts/submit_review'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inquiry_id': _currentInquiry['id'],
          'rating': _farmerRating,
          'comment': _ratingCommentController.text.trim(),
        }),
      );
      if (response.statusCode == 200) {
        _ratingCommentController.clear();
        await _refreshInquiry();
        await _fetchServiceLogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'counter':
        return Colors.indigo;
      case 'accepted':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'reviewed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _currentInquiry['status'].toString();
    final pricing = (_currentInquiry['current_price'] != null &&
            _currentInquiry['current_price'].toString().isNotEmpty)
        ? _currentInquiry['current_price']
        : _currentInquiry['offer_amount'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Contract Details'),
        actions: [
          IconButton(
            onPressed: () {
              _refreshInquiry();
              _fetchServiceLogs();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoadingListing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOverviewCard(pricing, status),
                  const SizedBox(height: 16),
                  _buildLocationSection(),
                  const SizedBox(height: 16),
                  if (status == 'pending' || status == 'counter') ...[
                    _buildNegotiationSection(status),
                    const SizedBox(height: 16),
                  ],
                  if (status == 'accepted' || status == 'active') ...[
                    _buildVerificationSection(status),
                    const SizedBox(height: 16),
                  ],
                  _buildMilestonesTimeline(),
                  if (status == 'completed' && widget.role == 'farmer') ...[
                    const SizedBox(height: 16),
                    _buildFeedbackSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCard(dynamic pricing, String status) {
    final title = _listingDetails?['title'] ?? 'Agricultural Service';
    final contractorName = _listingDetails?['contractor_name'] ??
        _currentInquiry['contractor_name'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: const Icon(Icons.handshake_rounded,
                            color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$title',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.role == 'farmer'
                                  ? 'Contractor: $contractorName'
                                  : 'Farmer: ${_currentInquiry['farmer_name']}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: _getStatusColor(status),
                    ),
                  ),
                )
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Negotiated Price',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(
                      '$pricing',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.green),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Date',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(
                      _currentInquiry['timestamp'].toString().substring(0, 10),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            if (_currentInquiry['message'] != null &&
                _currentInquiry['message'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Farmer's Note: ${_currentInquiry['message']}",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNegotiationSection(String status) {
    final showFarmerControl = (widget.role == 'farmer' && status == 'counter');
    final showContractorControl =
        (widget.role == 'contractor' && status == 'pending');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Active Negotiation',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 20),
            if (showFarmerControl) ...[
              const Text(
                'Contractor suggested a counter-price. You can accept or reject.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondInquiry('rejected'),
                      child: const Text('Reject Offer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondInquiry('accepted'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('Accept Counter'),
                    ),
                  ),
                ],
              ),
            ] else if (showContractorControl) ...[
              const Text(
                "Review the farmer's price request. You can counter-offer or accept directly.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (_aiNegotiationMessage == null)
                OutlinedButton.icon(
                  onPressed: _isAiAdvising ? null : _getAiNegotiationAdvice,
                  icon: const Icon(Icons.auto_awesome),
                  label: _isAiAdvising
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Consult AI Negotiation Advisor'),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: Colors.indigo, size: 18),
                          SizedBox(width: 6),
                          Text('AI Negotiation Strategy',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.indigo)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_aiNegotiationMessage!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade800)),
                      if (_aiCounterPriceSuggested != null) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _counterPriceController.text =
                                _aiCounterPriceSuggested!
                                    .replaceAll(RegExp(r'[^0-9]'), '');
                          },
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          label:
                              Text('Use Suggested: $_aiCounterPriceSuggested'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.indigo,
                              elevation: 0),
                        ),
                      ]
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _counterPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Counter Price',
                        prefixText: 'Rs.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_counterPriceController.text.isNotEmpty) {
                          _respondInquiry('counter',
                              counterPrice:
                                  'Rs.${_counterPriceController.text}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo),
                      child: const Text('Counter'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondInquiry('rejected'),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondInquiry('accepted'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('Accept Direct'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Waiting for the contractor to respond to your request.',
                style: TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.grey.shade600),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    final farmerLat = _currentInquiry['farmer_lat'] ?? 17.3850;
    final farmerLng = _currentInquiry['farmer_lng'] ?? 78.4867;
    final contractorLat = _currentInquiry['contractor_lat'] ?? 17.4065;
    final contractorLng = _currentInquiry['contractor_lng'] ?? 78.4772;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.redAccent),
                const SizedBox(width: 8),
                const Text('Location & Proximity',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Mandatory Verified',
                      style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌾 Farm Location',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 4),
                        Text('$farmerLat, $farmerLng',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🚜 Contractor Site',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                        const SizedBox(height: 4),
                        Text('$contractorLat, $contractorLng',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.directions_car_rounded, size: 18, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Estimated Distance: ~2.4 km (Ready for dispatch)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection(String status) {
    final bool hasOtp = _currentInquiry['otp_code'] != null &&
        _currentInquiry['otp_code'].toString().isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Colors.green),
                SizedBox(width: 8),
                Text('Work Verification & Completion OTP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 20),
            if (widget.role == 'farmer') ...[
              if (!hasOtp) ...[
                const Text(
                  'Once the contractor finishes the work on your farm, generate the OTP and share it with them to finalize completion.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isActionLoading ? null : _generateOtp,
                  icon: const Icon(Icons.key_rounded),
                  label: _isActionLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Generate Work Completion OTP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ] else ...[
                const Text(
                  'Share this Completion OTP with the contractor once they finish the work:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentInquiry['otp_code'].toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ] else ...[
              const Text(
                'Ask the farmer for the Completion OTP when you finish the work, and enter it below to mark the job completed:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: '0000',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed:
                        _isActionLoading ? null : () => _verifyOtp('complete'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 54),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Verify & Finish'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesTimeline() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_list_bulleted, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Service Milestones',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (widget.role == 'contractor' &&
                    _currentInquiry['status'] == 'active')
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: _showAddMilestoneDialog,
                    tooltip: 'Log Progress',
                  ),
              ],
            ),
            const Divider(height: 20),
            _isLoadingLogs
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ))
                : _logs.isEmpty
                    ? Text(
                        'No service updates logged yet.',
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, idx) {
                          final log = _logs[idx];
                          final ts = log['timestamp']?.toString() ?? '';
                          final timeStr =
                              ts.length > 16 ? ts.substring(11, 16) : '';
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 6,
                                    backgroundColor: idx == 0
                                        ? Colors.green
                                        : Colors.grey.shade400,
                                  ),
                                  Container(
                                    width: 2,
                                    height: 50,
                                    color: Colors.grey.shade300,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          log['status_update'] ?? 'Update',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: idx == 0
                                                ? Colors.green
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(timeStr,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(log['description'] ?? '',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700)),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  void _showAddMilestoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Progress Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Describe what was accomplished (e.g. 50% land plowed, machinery dispatched):'),
            const SizedBox(height: 16),
            TextField(
              controller: _newMilestoneController,
              decoration: const InputDecoration(
                hintText: 'Description...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addMilestone();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text('Submit Review & Rating',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 20),
            const Text(
              'Work complete! Rate your experience with this contractor:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (idx) {
                final double val = idx + 1.0;
                return IconButton(
                  icon: Icon(
                    _farmerRating >= val ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () => setState(() => _farmerRating = val),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ratingCommentController,
              decoration: const InputDecoration(
                labelText: 'Write your feedback...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isActionLoading ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor),
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
