import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/voice_wrapper.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  bool loading = true;
  List<Map<String, dynamic>> marketData = [];
  Map<String, dynamic>? weatherData;
  String? errorMessage;

  String selectedState = 'Uttar Pradesh';
  String selectedCommodity = 'Potato';
  String? selectedDistrict;
  List<String> districts = [];

  final List<String> states = [
    'Telangana',
    'Andhra Pradesh',
    'Maharashtra',
    'Karnataka',
    'Tamil Nadu',
    'Punjab',
    'Uttar Pradesh',
  ];

  final List<String> commodities = [
    'Cotton',
    'Maize',
    'Groundnut',
    'Paddy',
    'Onion',
    'Tomato',
    'Potato',
    'Rice',
    'Wheat',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize districts list so the dropdown isn't empty on first build
    districts = ['All Districts'];
    selectedDistrict = 'All Districts';
    
    loadDistricts(selectedState).then((_) {
      loadData();
    });
  }

  Future<void> loadDistricts(String state) async {
    try {
      print('MarketScreen: Loading districts for $state...');
      final districtList = await ApiService.fetchDistricts(state);
      if (!mounted) return;
      setState(() {
        districts = ['All Districts', ...districtList];
        selectedDistrict = 'All Districts';
        print('MarketScreen: Districts loaded: ${districts.length} items');
      });
    } catch (e) {
      print('MarketScreen: Error loading districts: $e');
      if (!mounted) return;
      setState(() {
        districts = ['All Districts'];
        selectedDistrict = 'All Districts';
      });
    }
  }

  Future<void> loadData() async {
    print('MarketScreen: loadData started (District: $selectedDistrict, Commodity: $selectedCommodity)');
    setState(() {
      loading = true;
      errorMessage = null;
      marketData = [];
    });

    try {
      double? lat;
      double? lon;

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          );
          lat = position.latitude;
          lon = position.longitude;
          print('MarketScreen: Location obtained ($lat, $lon)');
        }
      } catch (e) {
        print('MarketScreen: Location error: $e');
      }

      final districtParam = selectedDistrict == 'All Districts' ? null : selectedDistrict;
      print('MarketScreen: Fetching prices for $selectedState, $districtParam, $selectedCommodity');

      final prices = await ApiService.fetchMarketPrices(
        state: selectedState,
        district: districtParam,
        commodity: selectedCommodity,
        lat: lat,
        lon: lon,
      );

      print('MarketScreen: Received ${prices.length} records');

      Map<String, dynamic>? weather;
      try {
        final weatherCity = (districtParam != null && districtParam.isNotEmpty) 
            ? districtParam 
            : selectedState;
        print('MarketScreen: Fetching weather for $weatherCity');
        weather = await ApiService.fetchWeather(weatherCity);
      } catch (e) {
        print('MarketScreen: Weather fetch failed (non-fatal): $e');
      }

      if (!mounted) return;

      setState(() {
        marketData = List<Map<String, dynamic>>.from(prices);
        weatherData = weather;
        loading = false;
      });
    } catch (e) {
      print('MarketScreen: Error in loadData: $e');
      String errorMsg = e.toString();
      if (errorMsg.contains('502') || errorMsg.contains('503')) {
        errorMsg = "The government Mandi API is currently undergoing maintenance (Error 502/503). Please try again later.";
      }

      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = errorMsg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Returns the market item with the highest modal_price (recommended)
  Map<String, dynamic>? get _recommendedMarket {
    if (marketData.isEmpty) return null;
    return marketData.reduce((a, b) {
      final aPrice = double.tryParse(a['modal_price']?.toString() ?? '0') ?? 0;
      final bPrice = double.tryParse(b['modal_price']?.toString() ?? '0') ?? 0;
      return aPrice >= bPrice ? a : b;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tempKelvin = weatherData?['main']?['temp'];
    final tempCelsius = tempKelvin != null
        ? (tempKelvin - 273.15).toStringAsFixed(1)
        : '--';

    final weatherDescription =
        weatherData?['weather']?[0]?['description']?.toString().toUpperCase() ??
        'WEATHER INFO';

    final recommended = _recommendedMarket;

    String voiceContent = AppLocalizations.of(context)!.realTimeMarket + ". ";
    if (loading) {
      voiceContent += "Loading market prices.";
    } else if (errorMessage != null) {
      voiceContent += errorMessage!;
    } else if (marketData.isEmpty) {
      voiceContent += "No market prices found for $selectedCommodity.";
    } else {
      voiceContent += "Found ${marketData.length} records. ";
      if (recommended != null) {
        voiceContent += "Best price is ₹ ${recommended['modal_price']} in ${recommended['market']} market.";
      }
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.realTimeMarket),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: loadData,
          ),
        ],
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.marketPrices,
        textToRead: voiceContent,
        child: Column(
          children: [
          // 🔍 SEARCH FILTERS
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                _buildDropdown(AppLocalizations.of(context)!.state, selectedState, states, (val) {
                  setState(() => selectedState = val!);
                  loadDistricts(selectedState);
                }),
                const SizedBox(height: 10),
                _buildDropdown(
                  'District/Place',
                  selectedDistrict ?? 'All Districts',
                  districts.isEmpty ? ['All Districts'] : districts,
                  (val) {
                    setState(() => selectedDistrict = val);
                  },
                  hint: 'Select District',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        'Commodity',
                        selectedCommodity,
                        commodities,
                        (val) {
                          setState(() => selectedCommodity = val!);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onPressed: loadData,
                      icon: const Icon(Icons.search, color: Colors.white),
                      label: Text(
                        AppLocalizations.of(context)!.search,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🌦 WEATHER CARD
                          if (weatherData != null)
                            _buildWeatherCard(weatherDescription, tempCelsius),

                          const SizedBox(height: 16),

                          // ⭐ RECOMMENDED PRICE BANNER
                          if (recommended != null) ...[
                            _buildRecommendedBanner(recommended),
                            const SizedBox(height: 16),
                          ],

                          // 📊 MARKET PRICES HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Prices for $selectedCommodity',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (selectedDistrict != null)
                                Chip(
                                  avatar: const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: AppConstants.primaryColor,
                                  ),
                                  label: Text(
                                    selectedDistrict!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                  backgroundColor: AppConstants.primaryColor
                                      .withOpacity(0.1),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (marketData.isEmpty)
                            _buildEmptyState()
                          else
                            ...marketData.map(
                              (item) => _buildMarketCard(
                                item,
                                isRecommended:
                                    item == recommended && marketData.length > 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged, {
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      hint: hint != null ? Text(hint) : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        prefixIcon: label == 'District/Place'
            ? const Icon(Icons.location_on_outlined)
            : null,
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildWeatherCard(String desc, String temp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: AppConstants.defaultBorderRadius,
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_queue_rounded, size: 48, color: Colors.white),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$temp °C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedBanner(Map<String, dynamic> item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: AppConstants.defaultBorderRadius,
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.bestPrice,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sell at ${item['market'] ?? 'N/A'} for the highest price in ${selectedDistrict ?? selectedState}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          Text(
            '₹ ${item['modal_price'] ?? '--'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketCard(
    Map<String, dynamic> item, {
    bool isRecommended = false,
  }) {
    final distance = item['distance_km'];

    return Card(
      elevation: isRecommended ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.defaultBorderRadius,
        side: isRecommended
            ? const BorderSide(color: Colors.amber, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isRecommended
              ? Colors.amber.withOpacity(0.15)
              : AppConstants.primaryColor.withOpacity(0.1),
          child: Icon(
            isRecommended ? Icons.star_rounded : Icons.storefront_rounded,
            color: isRecommended ? Colors.amber : AppConstants.primaryColor,
          ),
        ),
        title: Text(
          item['commodity'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Market: ${item['market'] ?? ''}'),
            Text('District: ${item['district'] ?? ''}'),
            if (distance != null)
              Text(
                'Distance: ${distance} km',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            Text('Date: ${item['arrival_date'] ?? ''}'),
          ],
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹ ${item['modal_price'] ?? ''}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
            const Text(
              'per quintal',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage != null && (errorMessage!.contains('502') || errorMessage!.contains('503'))
                  ? 'The Mandi API (data.gov.in) is temporarily down for maintenance. This is an external issue.'
                  : 'Try a nearby district or check the spelling.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
