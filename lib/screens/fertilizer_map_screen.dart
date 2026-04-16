import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../widgets/voice_wrapper.dart';

class FertilizerMapScreen extends StatefulWidget {
  final List<dynamic>? initialListings;
  const FertilizerMapScreen({super.key, this.initialListings});

  @override
  State<FertilizerMapScreen> createState() => _FertilizerMapScreenState();
}

class _FertilizerMapScreenState extends State<FertilizerMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  List<dynamic> _shops = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _isLocating = true;
  bool _showMap = true;
  bool _showSearchDropdown = false;
  String _searchQuery = '';
  String _dataSource = ''; // 'google' or 'backend'
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _startInitialization() async {
    await _fetchUserLocation();
    _fetchNearbyShops();
  }

  Future<void> _fetchUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
            _isLocating = false;
          });
        }
      } else {
        // Default to Hyderabad if no permission
        if (mounted) {
          setState(() {
            _currentPosition = const LatLng(17.3850, 78.4867);
            _isLocating = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        setState(() {
          _currentPosition = const LatLng(17.3850, 78.4867);
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _fetchNearbyShops() async {
    if (_currentPosition == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      final apiKey = AppConstants.googleMapsApiKey;

      // Search for fertilizer-related shops using Google Places Nearby Search
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=10000'
        '&keyword=fertilizer|agriculture|seeds|pesticides|farm supply|agri shop'
        '&type=store'
        '&key=$apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List? ?? [];

        if (results.isNotEmpty && mounted) {
          setState(() {
            _dataSource = 'google';
            _shops = results.map((place) {
              final location = place['geometry']?['location'];
              return {
                'place_id': place['place_id'] ?? '',
                'name': place['name'] ?? 'Unknown Shop',
                'vicinity': place['vicinity'] ?? 'No address',
                'lat': location?['lat'] ?? 0.0,
                'lng': location?['lng'] ?? 0.0,
                'rating': place['rating'] ?? 0.0,
                'user_ratings_total': place['user_ratings_total'] ?? 0,
                'is_open': place['opening_hours']?['open_now'] ?? false,
                'types': (place['types'] as List?)?.join(', ') ?? '',
                'icon': place['icon'] ?? '',
              };
            }).toList();
            _isLoading = false;
          });
          _updateMarkers();
        } else {
          // No Google results → fall back to registered backend listings
          await _fetchBackendListings();
        }
      } else {
        // API error → fall back to registered backend listings
        await _fetchBackendListings();
      }
    } catch (e) {
      debugPrint('Places API error: $e');
      // On exception → fall back to registered backend listings
      await _fetchBackendListings();
    }
  }

  Future<void> _fetchBackendListings() async {
    try {
      final lang = 'en'; // default
      final response = await http.get(Uri.parse(
          '${AppConstants.baseUrl}/listings?type=fertilizers&lang=$lang'));
      if (response.statusCode == 200 && mounted) {
        final items = jsonDecode(response.body)['items'] as List? ?? [];
        setState(() {
          _dataSource = 'backend';
          _shops = items.map((shop) {
            return {
              'place_id': shop['id']?.toString() ?? '',
              'name': shop['title'] ?? 'Shop',
              'vicinity': shop['description'] ?? '',
              'lat': shop['lat'] ?? 0.0,
              'lng': shop['lng'] ?? 0.0,
              'rating': 0.0,
              'user_ratings_total': 0,
              'is_open': true,
              'contact': shop['contact'] ?? '',
              'price': shop['price'] ?? '',
              'contractor_name': shop['contractor_name'] ?? '',
              'extra_fields': shop['extra_fields'] ?? {},
            };
          }).toList();
          _isLoading = false;
        });
        _updateMarkers();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Backend listings error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateMarkers() {
    final Set<Marker> newMarkers = {};

    // Add current location marker (blue)
    if (_currentPosition != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You are here'),
      ));
    }

    for (var shop in _shops) {
      final lat = (shop['lat'] is double) ? shop['lat'] : double.tryParse(shop['lat'].toString()) ?? 0.0;
      final lng = (shop['lng'] is double) ? shop['lng'] : double.tryParse(shop['lng'].toString()) ?? 0.0;
      if (lat != 0.0 && lng != 0.0) {
        newMarkers.add(Marker(
          markerId: MarkerId(shop['place_id']?.toString() ?? shop['name']),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: shop['name'],
            snippet: shop['vicinity'],
          ),
          onTap: () => _showShopDetails(shop),
        ));
      }
    }

    if (mounted) {
      setState(() => _markers = newMarkers);
    }
  }

  List<dynamic> get _filteredShops {
    if (_searchQuery.isEmpty) return _shops;
    final q = _searchQuery.toLowerCase();
    return _shops.where((shop) {
      final name = (shop['name'] ?? '').toString().toLowerCase();
      final vicinity = (shop['vicinity'] ?? '').toString().toLowerCase();
      return name.contains(q) || vicinity.contains(q);
    }).toList();
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openInGoogleMaps(double lat, double lng) {
    launchUrl(Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'));
  }

  void _focusOnShop(dynamic shop) {
    final lat = (shop['lat'] is double) ? shop['lat'] : double.tryParse(shop['lat'].toString()) ?? 0.0;
    final lng = (shop['lng'] is double) ? shop['lng'] : double.tryParse(shop['lng'].toString()) ?? 0.0;
    if (lat != 0.0 && lng != 0.0) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.0),
      );
      setState(() {
        _showMap = true;
        _showSearchDropdown = false;
      });
    }
  }

  void _showShopDetails(dynamic shop) {
    final rating = (shop['rating'] is double) ? shop['rating'] : double.tryParse(shop['rating'].toString()) ?? 0.0;
    final ratingsCount = shop['user_ratings_total'] ?? 0;
    final isOpen = shop['is_open'] == true;
    final contact = (shop['contact'] ?? '').toString();
    final price = (shop['price'] ?? '').toString();
    final contractorName = (shop['contractor_name'] ?? '').toString();

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
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Shop header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shop['name'] ?? 'Shop',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(shop['vicinity'] ?? '',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        if (contractorName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('by $contractorName',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  if (price.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(price,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 14)),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Status & Rating row
              Row(
                children: [
                  // Open/Closed badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOpen ? Colors.green.shade200 : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOpen ? Icons.check_circle : Icons.cancel,
                          size: 14,
                          color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOpen ? 'Open Now' : 'Closed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Rating
                  if (rating > 0) ...[
                    Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade600),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      ' ($ratingsCount reviews)',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Contact section (for backend-sourced shops)
              if (contact.isNotEmpty) ...[
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
                              const Text('Tap to Call',
                                  style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(contact,
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green.shade400),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Action Buttons
              Row(
                children: [
                  if (contact.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makeCall(contact),
                        icon: const Icon(Icons.call_rounded),
                        label: const Text('Call Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
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
                        final lat = (shop['lat'] is double) ? shop['lat'] : double.tryParse(shop['lat'].toString()) ?? 0.0;
                        final lng = (shop['lng'] is double) ? shop['lng'] : double.tryParse(shop['lng'].toString()) ?? 0.0;
                        _openInGoogleMaps(lat, lng);
                      },
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: contact.isNotEmpty ? Colors.blue.shade600 : Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.location_on_rounded, color: Colors.blue.shade700),
                      onPressed: () {
                        Navigator.pop(context);
                        _focusOnShop(shop);
                      },
                      tooltip: 'View on Map',
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

  @override
  Widget build(BuildContext context) {
    final filteredShops = _filteredShops;
    final shopCount = _shops.length;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: _showSearchDropdown
          ? _buildSearchField()
          : const Text('Fertilizer Shops', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(_showSearchDropdown ? Icons.close : Icons.search_rounded),
            tooltip: 'Search Shops',
            onPressed: () {
              setState(() {
                _showSearchDropdown = !_showSearchDropdown;
                if (!_showSearchDropdown) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          // Map/List toggle
          IconButton(
            icon: Icon(_showMap ? Icons.view_list_rounded : Icons.map_rounded),
            tooltip: _showMap ? 'List View' : 'Map View',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          if (shopCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$shopCount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          if (_isLocating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: VoiceWrapper(
        screenTitle: 'Fertilizer Shops',
        textToRead: _isLoading
            ? "Searching for nearby fertilizer shops."
            : "Found $shopCount fertilizer and agriculture shops near you.",
        child: Stack(
          children: [
            _isLoading
                ? _buildLoadingState()
                : _shops.isEmpty
                    ? _buildEmptyState()
                    : _showMap
                        ? _buildMapWithList(filteredShops)
                        : _buildFullList(filteredShops),
            // Dropdown overlay
            if (_showSearchDropdown && _searchQuery.isNotEmpty && filteredShops.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 4,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredShops.length,
                      itemBuilder: (ctx, i) {
                        final shop = filteredShops[i];
                        final isOpen = shop['is_open'] == true;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade50,
                            child: Icon(Icons.storefront_rounded, color: Colors.green.shade700, size: 20),
                          ),
                          title: Text(shop['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(shop['vicinity'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(isOpen ? 'Open' : 'Closed', style: TextStyle(fontSize: 10, color: isOpen ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                          ),
                          onTap: () {
                            _focusOnShop(shop);
                            _showShopDetails(shop);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      autofocus: true,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Search fertilizer shops...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
        border: InputBorder.none,
        prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
      ),
      cursorColor: Colors.white,
      onChanged: (val) => setState(() => _searchQuery = val),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppConstants.primaryColor),
          const SizedBox(height: 20),
          Text('Searching nearby fertilizer shops...', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Using your GPS location', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No fertilizer shops found nearby', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Try expanding your search area', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchNearbyShops();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWithList(List<dynamic> shops) {
    return Column(
      children: [
        // Map section
        SizedBox(
          height: 300,
          child: Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_currentPosition != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentPosition!, 13.5),
                    );
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: _currentPosition ?? const LatLng(17.3850, 78.4867),
                  zoom: 13.5,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
              // GPS Re-center button
              Positioned(
                bottom: 12,
                right: 12,
                child: FloatingActionButton.small(
                  heroTag: 'gps_btn',
                  onPressed: () {
                    if (_currentPosition != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentPosition!, 13.5),
                      );
                    }
                  },
                  backgroundColor: Colors.white,
                  elevation: 3,
                  child: const Icon(Icons.gps_fixed, color: AppConstants.primaryColor, size: 20),
                ),
              ),
              // Refresh button
              Positioned(
                bottom: 12,
                left: 12,
                child: FloatingActionButton.small(
                  heroTag: 'refresh_btn',
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _fetchNearbyShops();
                  },
                  backgroundColor: Colors.white,
                  elevation: 3,
                  child: const Icon(Icons.refresh, color: AppConstants.primaryColor, size: 20),
                ),
              ),
            ],
          ),
        ),
        // Section header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.storefront_rounded, color: Colors.green.shade700, size: 18),
              ),
              const SizedBox(width: 10),
              Text(_dataSource == 'backend' ? 'Registered Shops' : 'Nearby Shops', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text('${shops.length} found', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        // List section
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: shops.length,
            itemBuilder: (context, index) => _buildShopCard(shops[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildFullList(List<dynamic> shops) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: shops.length,
      itemBuilder: (context, index) => _buildShopCard(shops[index]),
    );
  }

  Widget _buildShopCard(dynamic shop) {
    final rating = (shop['rating'] is double) ? shop['rating'] : double.tryParse(shop['rating'].toString()) ?? 0.0;
    final ratingsCount = shop['user_ratings_total'] ?? 0;
    final isOpen = shop['is_open'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: InkWell(
        onTap: () => _showShopDetails(shop),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade300, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              // Shop details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(shop['name'] ?? 'Shop',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        // Open/Closed
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(shop['vicinity'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 6),
                    // Rating + Actions row
                    Row(
                      children: [
                        if (rating > 0) ...[
                          Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                          const SizedBox(width: 2),
                          Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(' ($ratingsCount)', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ],
                        const Spacer(),
                        // Directions button
                        InkWell(
                          onTap: () {
                            final lat = (shop['lat'] is double) ? shop['lat'] : double.tryParse(shop['lat'].toString()) ?? 0.0;
                            final lng = (shop['lng'] is double) ? shop['lng'] : double.tryParse(shop['lng'].toString()) ?? 0.0;
                            _openInGoogleMaps(lat, lng);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions_rounded, size: 14, color: Colors.blue.shade700),
                                const SizedBox(width: 4),
                                Text('Directions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Map pin
                        InkWell(
                          onTap: () => _focusOnShop(shop),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.location_on_rounded, size: 16, color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
