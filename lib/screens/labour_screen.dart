import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/constants.dart';
import '../widgets/voice_wrapper.dart';

/// Service types a farmer can filter by
const _kServiceTypes = [
  {'key': '', 'label': 'All Services', 'icon': Icons.grid_view_rounded},
  {'key': 'machinery', 'label': 'Machinery', 'icon': Icons.agriculture},
  {'key': 'labour', 'label': 'Labour', 'icon': Icons.groups},
  {'key': 'fertilizers', 'label': 'Fertilizers', 'icon': Icons.science},
  {'key': 'logistics', 'label': 'Logistics', 'icon': Icons.local_shipping},
  {'key': 'irrigation', 'label': 'Irrigation', 'icon': Icons.water_drop},
];

class LabourScreen extends StatefulWidget {
  const LabourScreen({super.key});

  @override
  State<LabourScreen> createState() => _LabourScreenState();
}

class _LabourScreenState extends State<LabourScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _contractors = [];
  bool _loading = false;
  String _error = '';
  String _selectedType = '';
  double _selectedRadius = 50.0;
  Position? _farmerPosition;
  bool _locationLoading = true;
  String _locationLabel = 'Getting your location…';
  late AnimationController _pulseController;

  // Manual location state
  bool _isAutoLocation = true;
  double? _manualLat;
  double? _manualLng;
  String _manualLocationName = '';
  final TextEditingController _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // ── Location ────────────────────────────────────────────
  Future<void> _initLocation() async {
    setState(() => _locationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationLabel = 'Location services disabled';
          _locationLoading = false;
        });
        _fetchWithFallback();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _locationLabel = 'Location permission denied';
          _locationLoading = false;
        });
        _fetchWithFallback();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 12),
      );
      setState(() {
        _farmerPosition = pos;
        if (_isAutoLocation) {
          _locationLabel =
              '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        }
        _locationLoading = false;
      });
      _fetchNearestContractors();
    } catch (e) {
      setState(() {
        _locationLabel = 'Could not get location';
        _locationLoading = false;
      });
      _fetchWithFallback();
    }
  }

  Future<void> _lookupManualPincode(String pincode) async {
    if (pincode.length != 6) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final response = await http
          .get(
            Uri.parse(
                '${AppConstants.baseUrl}/pincode_lookup?pincode=$pincode'),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
        if (lat != 0.0) {
          setState(() {
            _manualLat = lat;
            _manualLng = lng;
            _manualLocationName = data['city'] != ''
                ? '${data['city']}, ${data['district']}'
                : 'PIN $pincode';
            _locationLabel = 'Manual: $_manualLocationName';
            _error = '';
          });
          _fetchNearestContractors();
        } else {
          setState(() {
            _error = 'Pincode not found. Try e.g. 500001, 500016.';
          });
        }
      }
    } catch (e) {
      setState(() => _error = 'Failed to verify Pincode.');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// If GPS fails, fall back to Hyderabad coordinates (seeded data area)
  void _fetchWithFallback() {
    _farmerPosition = null;
    _fetchNearestContractors(fallbackLat: 17.3850, fallbackLng: 78.4867);
  }

  // ── API call ─────────────────────────────────────────────
  Future<void> _fetchNearestContractors(
      {double? fallbackLat, double? fallbackLng}) async {
    double lat;
    double lng;

    if (_isAutoLocation) {
      if (_farmerPosition == null) {
        lat = fallbackLat ?? 17.3850;
        lng = fallbackLng ?? 78.4867;
      } else {
        lat = _farmerPosition!.latitude;
        lng = _farmerPosition!.longitude;
      }
    } else {
      if (_manualLat == null || _manualLng == null) {
        lat = fallbackLat ?? 17.3850;
        lng = fallbackLng ?? 78.4867;
      } else {
        lat = _manualLat!;
        lng = _manualLng!;
      }
    }

    final lang = Localizations.localeOf(context).languageCode;

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final typeParam = _selectedType.isNotEmpty ? '&type=$_selectedType' : '';
      final url =
          '${AppConstants.baseUrl}/nearest_contractors?lat=$lat&lng=$lng&radius_km=$_selectedRadius&lang=$lang$typeParam';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _contractors = data['contractors'] ?? [];
        });
      } else {
        setState(() => _error = 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Could not reach server. Check connection.');
    } finally {
      setState(() => _loading = false);
    }
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

  // ── Submit negotiation inquiry ────────────────────────────
  Future<void> _submitNegotiation(BuildContext ctx, dynamic contractor,
      dynamic listing, String offer, String notes) async {
    final box = Hive.box('profileBox');
    final farmerName = box.get('name', defaultValue: 'Farmer');
    try {
      await http.post(
        Uri.parse('${AppConstants.baseUrl}/create_inquiry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'farmer_name': farmerName,
          'contractor_name': contractor['name'],
          'listing_id': listing['id'],
          'offer_amount': '₹$offer',
          'message': notes,
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.requestSent),
            backgroundColor: Colors.green.shade700));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // ── UI ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Find Contractors'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Refresh location',
            onPressed: _initLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _fetchNearestContractors(),
          ),
        ],
      ),
      body: VoiceWrapper(
        screenTitle: 'Find Contractors',
        textToRead: _loading
            ? 'Finding nearest contractors…'
            : _contractors.isEmpty
                ? 'No contractors found within $_selectedRadius km.'
                : 'Found ${_contractors.length} contractors near you.',
        child: Column(
          children: [
            _buildHeaderBanner(),
            _buildFilters(),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? _buildLoadingState()
                  : _error.isNotEmpty
                      ? _buildErrorState()
                      : _contractors.isEmpty
                          ? _buildEmptyState()
                          : _buildContractorList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header banner with GPS info & Manual Pincode selection ──
  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Segmented selector: Auto (GPS) vs Manual (PIN)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAutoLocation = true;
                          _locationLabel = _farmerPosition != null
                              ? '${_farmerPosition!.latitude.toStringAsFixed(4)}, ${_farmerPosition!.longitude.toStringAsFixed(4)}'
                              : 'Getting your location…';
                        });
                        _initLocation();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isAutoLocation
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Auto (GPS)',
                          style: TextStyle(
                            color: _isAutoLocation
                                ? const Color(0xFF1B5E20)
                                : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAutoLocation = false;
                          _locationLabel = _manualLocationName.isNotEmpty
                              ? 'Manual: $_manualLocationName'
                              : 'Enter PIN Code';
                        });
                        _fetchNearestContractors();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isAutoLocation
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Manual (PIN)',
                          style: TextStyle(
                            color: !_isAutoLocation
                                ? const Color(0xFF1B5E20)
                                : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Details section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) => Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isAutoLocation
                          ? (_locationLoading
                              ? Colors.orange
                              : _farmerPosition != null
                                  ? Colors.greenAccent
                                  : Colors.red.shade300)
                          : (_manualLat != null
                              ? Colors.greenAccent
                              : Colors.orange),
                      boxShadow: [
                        BoxShadow(
                          color: (_isAutoLocation
                                  ? (_farmerPosition != null
                                      ? Colors.greenAccent
                                      : Colors.orange)
                                  : (_manualLat != null
                                      ? Colors.greenAccent
                                      : Colors.orange))
                              .withValues(alpha: _pulseController.value * 0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _isAutoLocation
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _locationLoading
                                  ? 'Locating you…'
                                  : _farmerPosition != null
                                      ? 'Your location detected'
                                      : 'Using approximate location',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            Text(
                              _locationLabel,
                              style: TextStyle(
                                  color: Colors.green.shade100, fontSize: 11),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _manualLocationName.isNotEmpty
                                        ? 'Searching from:'
                                        : 'Enter 6-digit Pincode:',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  Text(
                                    _manualLocationName.isNotEmpty
                                        ? _manualLocationName
                                        : 'e.g., 500001 (Hyderabad)',
                                    style: TextStyle(
                                        color: Colors.green.shade100,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 110,
                              height: 36,
                              child: TextField(
                                controller: _pincodeController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'PIN Code',
                                  hintStyle: const TextStyle(
                                      color: Colors.white38, fontSize: 12),
                                  counterText: '',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val.length == 6) {
                                    _lookupManualPincode(val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                ),
                if (_isAutoLocation) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_contractors.length} found',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter row (type chips + radius) ─────────────────────
  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // Service type chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _kServiceTypes.length,
              itemBuilder: (context, i) {
                final t = _kServiceTypes[i];
                final selected = _selectedType == t['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(t['icon'] as IconData,
                        size: 16,
                        color: selected
                            ? Colors.white
                            : AppConstants.primaryColor),
                    label: Text(t['label'] as String,
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedType = t['key'] as String);
                      _fetchNearestContractors();
                    },
                    selectedColor: AppConstants.primaryColor,
                    backgroundColor: Colors.grey.shade100,
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    side: BorderSide(
                        color: selected
                            ? AppConstants.primaryColor
                            : Colors.grey.shade300),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Radius slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.radar, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                const Text('Radius:',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _selectedRadius,
                    min: 10,
                    max: 200,
                    divisions: 19,
                    activeColor: AppConstants.primaryColor,
                    label: '${_selectedRadius.toInt()} km',
                    onChanged: (v) => setState(() => _selectedRadius = v),
                    onChangeEnd: (_) => _fetchNearestContractors(),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${_selectedRadius.toInt()} km',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _shimmer(width: 56, height: 56, radius: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmer(width: double.infinity, height: 14),
                      const SizedBox(height: 8),
                      _shimmer(width: 120, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _shimmer(width: double.infinity, height: 44),
          ],
        ),
      ),
    );
  }

  Widget _shimmer(
      {required double width, required double height, double radius = 8}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: Color.lerp(Colors.grey.shade200, Colors.grey.shade100,
              _pulseController.value),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_error,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchNearestContractors,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No contractors within ${_selectedRadius.toInt()} km',
            style: TextStyle(fontSize: 17, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try increasing the search radius or changing the service type',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedRadius = 200.0;
                _selectedType = '';
              });
              _fetchNearestContractors();
            },
            icon: const Icon(Icons.expand_circle_down),
            label: const Text('Expand to 200 km'),
          ),
        ],
      ),
    );
  }

  Widget _buildContractorList() {
    return RefreshIndicator(
      onRefresh: () => _fetchNearestContractors(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: _contractors.length,
        itemBuilder: (context, index) {
          final contractor = _contractors[index];
          return _buildContractorCard(contractor, index);
        },
      ),
    );
  }

  Widget _buildContractorCard(dynamic contractor, int index) {
    final distance = (contractor['distance_km'] as num).toDouble();
    final rating = (contractor['rating'] as num?)?.toDouble() ?? 4.5;
    final ratingsCount = (contractor['ratings_count'] as num?)?.toInt() ?? 0;
    final listings = (contractor['listings'] as List?) ?? [];
    final specialty = contractor['specialty'] ?? '';
    final address = contractor['address'] ?? '';
    final pincode = contractor['pincode'] ?? '';

    // Distance pill colour
    Color distanceColor;
    String distanceLabel;
    if (distance < 5) {
      distanceColor = Colors.green.shade600;
      distanceLabel = 'Very Near';
    } else if (distance < 20) {
      distanceColor = Colors.teal;
      distanceLabel = 'Nearby';
    } else if (distance < 50) {
      distanceColor = Colors.orange;
      distanceLabel = 'Moderate';
    } else {
      distanceColor = Colors.red.shade400;
      distanceLabel = 'Far';
    }

    // Service type icon
    IconData specialtyIcon = Icons.handyman;
    if (specialty.toLowerCase().contains('machinery'))
      specialtyIcon = Icons.agriculture;
    if (specialty.toLowerCase().contains('labour'))
      specialtyIcon = Icons.groups;
    if (specialty.toLowerCase().contains('fertili'))
      specialtyIcon = Icons.science;
    if (specialty.toLowerCase().contains('logistics'))
      specialtyIcon = Icons.local_shipping;
    if (specialty.toLowerCase().contains('irrigation'))
      specialtyIcon = Icons.water_drop;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.green.shade50],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rank badge + avatar
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              AppConstants.primaryColor.withValues(alpha: 0.1),
                          child: Icon(specialtyIcon,
                              size: 28, color: AppConstants.primaryColor),
                        ),
                        Positioned(
                          top: -6,
                          left: -6,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? Colors.amber
                                  : index == 1
                                      ? Colors.grey.shade400
                                      : index == 2
                                          ? Colors.brown.shade300
                                          : AppConstants.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${index + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contractor['name'] ?? 'Contractor',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (specialty.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(specialty,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                          const SizedBox(height: 4),
                          // Star rating
                          Row(
                            children: [
                              ...List.generate(5, (i) {
                                if (i < rating.floor()) {
                                  return const Icon(Icons.star,
                                      size: 14, color: Colors.amber);
                                } else if (i < rating) {
                                  return const Icon(Icons.star_half,
                                      size: 14, color: Colors.amber);
                                } else {
                                  return Icon(Icons.star_border,
                                      size: 14, color: Colors.grey.shade300);
                                }
                              }),
                              const SizedBox(width: 4),
                              Text('${rating.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              if (ratingsCount > 0)
                                Text(' ($ratingsCount)',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Distance pill
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: distanceColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: distanceColor.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.near_me,
                                  size: 14, color: distanceColor),
                              const SizedBox(height: 2),
                              Text('${distance.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: distanceColor,
                                      fontWeight: FontWeight.bold)),
                              Text(distanceLabel,
                                  style: TextStyle(
                                      fontSize: 9, color: distanceColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Address row
                if (address.isNotEmpty || pincode.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              if (address.isNotEmpty) address,
                              if (pincode.isNotEmpty) 'PIN: $pincode'
                            ].join(' • '),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Services offered by this contractor ──────────
          if (listings.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.list_alt, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text('Services Offered',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700)),
                ],
              ),
            ),
            ...listings
                .take(3)
                .map((listing) => _buildListingTile(contractor, listing)),
          ],

          // ── Action buttons ───────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                if ((contractor['phone'] ?? '').isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makeCall(contractor['phone']),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                if ((contractor['phone'] ?? '').isNotEmpty)
                  const SizedBox(width: 10),
                if (listings.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _showRequestDialog(
                          context, contractor, listings.first),
                      icon: const Icon(Icons.handshake, size: 16),
                      label: const Text('Request Service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingTile(dynamic contractor, dynamic listing) {
    final typeIcons = {
      'machinery': Icons.agriculture,
      'labour': Icons.groups,
      'fertilizers': Icons.science,
      'logistics': Icons.local_shipping,
      'irrigation': Icons.water_drop,
    };
    final icon = typeIcons[listing['type']] ?? Icons.miscellaneous_services;

    return InkWell(
      onTap: () => _showRequestDialog(context, contractor, listing),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: AppConstants.primaryColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if ((listing['description'] ?? '').isNotEmpty)
                    Text(listing['description'],
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(listing['price'] ?? '',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                    fontSize: 13)),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showRequestDialog(
      BuildContext context, dynamic contractor, dynamic listing) {
    final offerController = TextEditingController();
    final notesController = TextEditingController();
    // Pre-select listing
    dynamic selectedListing = listing;
    final listings = (contractor['listings'] as List?) ?? [listing];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle + title
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4)
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppConstants.primaryColor
                                .withValues(alpha: 0.1),
                            child: const Icon(Icons.handshake,
                                color: AppConstants.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Request Service',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                Text(contractor['name'] ?? '',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Service picker
                      const Text('Select Service',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ...listings.map((l) {
                        final isSelected = selectedListing['id'] == l['id'];
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedListing = l),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppConstants.primaryColor
                                      .withValues(alpha: 0.08)
                                  : Colors.grey.shade50,
                              border: Border.all(
                                color: isSelected
                                    ? AppConstants.primaryColor
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l['title'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(l['price'] ?? '',
                                          style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle,
                                      color: AppConstants.primaryColor),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      // Offer price
                      TextField(
                        controller: offerController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Your Offer (₹)',
                          hintText: 'Enter your price offer',
                          prefixText: '₹ ',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          helperText:
                              'Listed price: ${selectedListing['price'] ?? 'N/A'}',
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Notes
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Notes / Requirements',
                          hintText:
                              'Describe your farm location, acreage, specific requirements…',
                          prefixIcon: const Icon(Icons.notes),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Distance info card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.near_me,
                                color: Colors.blue.shade700, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${contractor['name']} is ${(contractor['distance_km'] as num).toStringAsFixed(1)} km from your location'
                                '${contractor['address'] != null && (contractor['address'] as String).isNotEmpty ? ' — ${contractor['address']}' : ''}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blue.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _submitNegotiation(
                                context,
                                contractor,
                                selectedListing,
                                offerController.text,
                                notesController.text);
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Send Request',
                              style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
