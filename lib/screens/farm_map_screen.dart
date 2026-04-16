import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';
import '../widgets/voice_wrapper.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/agro_monitoring_service.dart';
import 'package:intl/intl.dart';

class FarmMapScreen extends StatefulWidget {
  const FarmMapScreen({super.key});

  @override
  State<FarmMapScreen> createState() => _FarmMapScreenState();
}

class _FarmMapScreenState extends State<FarmMapScreen> {
  GoogleMapController? _mapController;
  bool isLoading = true;
  String? errorMessage;
  
  String? polyId;
  Map<String, dynamic>? soilData;
  List<dynamic>? weatherForecast;
  List<dynamic>? satelliteImages;
  
  
  // Dynamic Farm Location (Defaulting to Hyderabad until determined)
  double baseLat = 17.3850;
  double baseLng = 78.4867;
  
  // Define a polygon for the farm
  List<List<double>> farmCoordinates = [];

  @override
  void initState() {
    super.initState();
    _loadFarmData();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      baseLat = position.latitude;
      baseLng = position.longitude;
      
      // Update polygon coordinates around current location
      farmCoordinates = [
        [baseLng - 0.0025, baseLat - 0.0025],
        [baseLng + 0.0025, baseLat - 0.0025],
        [baseLng + 0.0025, baseLat + 0.0025],
        [baseLng - 0.0025, baseLat + 0.0025],
        [baseLng - 0.0025, baseLat - 0.0025],
      ];
    });

    // Move camera to new location
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(baseLat, baseLng)),
    );
  }

  Future<void> _loadFarmData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 0. Get Real-Time Location
      await _getCurrentLocation();

      // 1. Create or reuse Polygon
      try {
        polyId = await AgroMonitoringService.createPolygon("My Smart Farm", farmCoordinates);
      } catch (_) {
        // Polygon may already exist — try fetching existing ones
        polyId = await AgroMonitoringService.getExistingPolygonId();
      }

      if (polyId == null) {
        throw Exception('Could not create or find a polygon.');
      }
      
      // 2. Fetch Data in Parallel
      final soilFuture = AgroMonitoringService.getCurrentSoilData(polyId!);
      final weatherFuture = AgroMonitoringService.getWeatherForecast(baseLat, baseLng);
      
      // 3. Fetch Satellite Imagery (last 30 days)
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      final satFuture = AgroMonitoringService.getSatelliteImages(polyId!, startDate, endDate);

      final results = await Future.wait([soilFuture, weatherFuture, satFuture]);
      
      setState(() {
        soilData = results[0] as Map<String, dynamic>;
        weatherForecast = results[1] as List<dynamic>;
        satelliteImages = results[2] as List<dynamic>;
        isLoading = false;
      });
      
    } catch (e) {
      print("Farm Data Error: $e");
      setState(() {
        errorMessage = 'Could not load farm data. Please check your internet connection and try again.';
        isLoading = false;
      });
    }
  }

  Set<Polygon> _generateFarmPolygon() {
    return {
      Polygon(
        polygonId: const PolygonId('my_farm'),
        points: farmCoordinates.map((coord) => LatLng(coord[1], coord[0])).toList(),
        fillColor: AppConstants.primaryColor.withValues(alpha: 0.3),
        strokeColor: AppConstants.primaryColor,
        strokeWidth: 2,
      ),
    };
  }
  
  // Format Kelvin to Celsius
  String _formatTemp(dynamic kelvin) {
    if (kelvin == null) return '--';
    final double k = kelvin is int ? kelvin.toDouble() : kelvin as double;
    return '${(k - 273.15).toStringAsFixed(1)}°C';
  }

  Widget _buildMetricsCard() {
    if (soilData == null) return const SizedBox.shrink();
    
    final t0 = soilData!['t0']; // Surface Temp
    final moisture = soilData!['moisture']; // Moisture volume
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppConstants.defaultBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🌱 Soil Metrics (Real-Time)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(Icons.thermostat_rounded, 'Surface Temp', _formatTemp(t0), Colors.orange),
                _buildMetricItem(Icons.water_drop_rounded, 'Moisture', '${(moisture * 100).toStringAsFixed(1)}%', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildSatImageCard() {
    if (satelliteImages == null || satelliteImages!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Get the most recent image
    final recentImage = satelliteImages!.first;
    final ndviUrl = recentImage['image']?['ndvi'];
    final truecolorUrl = recentImage['image']?['truecolor'];
    final dateUnix = recentImage['dt'];
    final dateStr = dateUnix != null ? DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(dateUnix * 1000)) : 'Unknown Date';
    
    if (ndviUrl == null && truecolorUrl == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppConstants.defaultBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🛰 Recent Satellite Imagery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            if (ndviUrl != null) ...[
              const Text('NDVI (Crop Health Index)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(ndviUrl, height: 150, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(height: 150, color: Colors.grey.shade200, child: const Center(child: Text('Image not available'))),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (truecolorUrl != null) ...[
              const Text('True Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(truecolorUrl, height: 150, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(height: 150, color: Colors.grey.shade200, child: const Center(child: Text('Image not available'))),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Smart Farm Map'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFarmData),
        ],
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.farmMap,
        textToRead: isLoading ? "Loading real-time farm data." : errorMessage != null ? "Failed to load farm data." : "Viewing your smart farm dashboard. Soil moisture is at ${soilData != null && soilData!['moisture'] != null ? (soilData!['moisture'] * 100).toStringAsFixed(1) : 'unknown'} percent.",
        child: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFarmData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                      
                    // 🗺 MAP VIEW
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: GoogleMap(
                          onMapCreated: (controller) => _mapController = controller,
                          initialCameraPosition: CameraPosition(target: LatLng(baseLat + 0.0025, baseLng + 0.0025), zoom: 15),
                          polygons: _generateFarmPolygon(),
                          mapType: MapType.hybrid,
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    _buildMetricsCard(),
                    const SizedBox(height: 16),
                    _buildSatImageCard(),
                    
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
