import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'notification_service.dart';

/// ─── NotificationPollingService ───────────────────────────────────────────
///
/// Polls the backend every [pollInterval] seconds to detect:
///
///  For FARMERS:
///   • Inquiry status changes (e.g. contractor accepted / rejected)
///
///  For CONTRACTORS:
///   • New inquiries (farmer sent a new request)
///
///  For BOTH roles:
///   • New listings posted on the platform (new contractor services)
///
/// Usage:
///   final svc = NotificationPollingService(role: 'farmer', name: 'Ramu');
///   svc.start();
///   // ... later, when widget disposes:
///   svc.stop();
/// ──────────────────────────────────────────────────────────────────────────
class NotificationPollingService {
  final String role; // 'farmer' or 'contractor'
  final String name;
  final Duration pollInterval;

  Timer? _timer;
  bool _isRunning = false;

  // ── Cached state to detect changes ──────────────────────────────────────
  // Maps inquiry_id → last known status (for farmers)
  final Map<int, String> _lastInquiryStatus = {};
  // Last known total listing count (for new-listing alerts)
  int _lastListingCount = -1;
  // Last known total inquiry count for the contractor
  int _lastInquiryCount = -1;

  NotificationPollingService({
    required this.role,
    required this.name,
    this.pollInterval = const Duration(seconds: 30),
  });

  /// Start the polling loop.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    // Run once immediately, then on the timer
    _poll();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
    debugPrint('🔔 NotificationPollingService started for $role: $name');
  }

  /// Stop the polling loop.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    debugPrint('🔕 NotificationPollingService stopped for $role: $name');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE POLLING LOGIC
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _poll() async {
    try {
      if (role == 'farmer') {
        await _pollFarmerInquiries();
      } else if (role == 'contractor') {
        await _pollContractorInquiries();
      }
      await _pollNewListings();
    } catch (e) {
      debugPrint('⚠️ Polling error: $e');
    }
  }

  // ── FARMER: watch for status changes on their own inquiries ──────────────
  Future<void> _pollFarmerInquiries() async {
    final response = await http
        .get(
          Uri.parse(
              '${AppConstants.baseUrl}/inquiries?user=$name&role=farmer&lang=en'),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return;

    final list = (jsonDecode(response.body)['inquiries'] as List? ?? []);

    for (final inquiry in list) {
      final id = inquiry['id'] as int;
      final status = inquiry['status'] as String;
      final contractorName =
          inquiry['contractor_name'] as String? ?? 'Contractor';
      final offerAmount = inquiry['offer_amount'] as String? ?? '';

      if (!_lastInquiryStatus.containsKey(id)) {
        // First time we see this inquiry – seed the state, don't notify
        _lastInquiryStatus[id] = status;
        continue;
      }

      final previousStatus = _lastInquiryStatus[id];
      if (previousStatus != status) {
        _lastInquiryStatus[id] = status;
        await _notifyFarmerStatusChange(
            id, status, contractorName, offerAmount);
      }
    }
  }

  Future<void> _notifyFarmerStatusChange(
    int inquiryId,
    String newStatus,
    String contractorName,
    String offerAmount,
  ) async {
    String title;
    String body;

    switch (newStatus) {
      case 'accepted':
        title = '✅ Offer Accepted!';
        body =
            '$contractorName accepted your offer of $offerAmount. Tap to view details.';
        break;
      case 'rejected':
        title = '❌ Offer Rejected';
        body = '$contractorName declined your offer. Tap to send a new one.';
        break;
      case 'active':
        title = '🚜 Work Started!';
        body =
            '$contractorName has started the job. Track progress in My Requests.';
        break;
      case 'completed':
        title = '🎉 Job Completed!';
        body =
            'Your job with $contractorName is done. Please rate the experience.';
        break;
      case 'counter':
        title = '💬 Counter-Offer Received';
        body =
            '$contractorName sent a counter-offer for $offerAmount. Review it now.';
        break;
      default:
        title = '📋 Request Updated';
        body =
            'Your request #$inquiryId status changed to ${newStatus.toUpperCase()}.';
    }

    await NotificationService.showContractNotification(
      id: 300 + inquiryId,
      title: title,
      body: body,
    );
  }

  // ── CONTRACTOR: watch for new incoming inquiries ──────────────────────────
  Future<void> _pollContractorInquiries() async {
    final response = await http
        .get(
          Uri.parse(
              '${AppConstants.baseUrl}/inquiries?user=$name&role=contractor&lang=en'),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return;

    final list = (jsonDecode(response.body)['inquiries'] as List? ?? []);
    final count = list.length;

    if (_lastInquiryCount == -1) {
      // First poll – seed state
      _lastInquiryCount = count;
      return;
    }

    if (count > _lastInquiryCount) {
      final newCount = count - _lastInquiryCount;
      _lastInquiryCount = count;

      // Get the newest inquiry details
      final newest = list.isNotEmpty ? list.last : null;
      final farmerName =
          newest != null ? (newest['farmer_name'] ?? 'A farmer') : 'A farmer';
      final offerAmount = newest != null ? (newest['offer_amount'] ?? '') : '';

      await NotificationService.showContractNotification(
        id: 400,
        title: '📩 New Request Received!',
        body: newCount == 1
            ? '$farmerName sent you an offer of $offerAmount.'
            : '$newCount new requests are waiting for your response.',
      );
    } else {
      _lastInquiryCount = count;
    }
  }

  // ── BOTH ROLES: watch for brand new listings posted ─────────────────────
  Future<void> _pollNewListings() async {
    final response = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/listings?lang=en'),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return;

    final items = (jsonDecode(response.body)['items'] as List? ?? []);
    final count = items.length;

    if (_lastListingCount == -1) {
      // Seed on first poll
      _lastListingCount = count;
      return;
    }

    if (count > _lastListingCount) {
      final newCount = count - _lastListingCount;
      _lastListingCount = count;

      // Identify what type of new listing was added
      final latest = items.isNotEmpty ? items.last : null;
      final listingTitle = latest?['title'] ?? 'New Service';
      final contractorName = latest?['contractor_name'] ?? 'A contractor';
      final listingType =
          (latest?['type'] ?? 'service').toString().capitalizeFirst;

      await NotificationService.showNewListingNotification(
        id: 500,
        title: '🆕 New $listingType Available!',
        body: newCount == 1
            ? '$contractorName just posted: "$listingTitle". Tap to explore.'
            : '$newCount new services have been added. Browse now!',
      );
    } else {
      _lastListingCount = count;
    }
  }
}

extension _StringCapFirst on String {
  String get capitalizeFirst =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}
