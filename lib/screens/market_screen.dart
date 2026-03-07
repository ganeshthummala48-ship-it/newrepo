import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  bool loading = true;
  List<Map<String, dynamic>> marketData = [];
  Map<String, dynamic>? weatherData;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final prices = await ApiService.fetchMarketPrices(
        state: 'Telangana',
        district: 'Hyderabad',
        commodity: 'Rice',
      );

      final weather = await ApiService.fetchWeather('Hyderabad');

      if (!mounted) return;

      setState(() {
        marketData = List<Map<String, dynamic>>.from(prices);
        weatherData = weather;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tempKelvin = weatherData?['main']?['temp'];
    final tempCelsius = tempKelvin != null
        ? (tempKelvin - 273.15).toStringAsFixed(1)
        : '--';

    final weatherDescription =
        weatherData?['weather']?[0]?['description']?.toString().toUpperCase() ??
            'WEATHER DATA';

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Market Prices & Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                loading = true;
              });
              loadData();
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 🌦 WEATHER CARD
                  if (weatherData != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppConstants.primaryGradient,
                        borderRadius: AppConstants.defaultBorderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
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
                                weatherDescription,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$tempCelsius °C',
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
                    ),

                  const SizedBox(height: 24),

                  // 📊 MARKET PRICES HEADER
                  const Text(
                    'Today’s Market Prices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 📉 EMPTY STATE
                  if (marketData.isEmpty)
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppConstants.defaultBorderRadius,
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.query_stats_rounded, size: 48, color: Colors.grey),
                            SizedBox(height: 12, width: double.infinity),
                            Text(
                              'Market price data will be displayed once government API authorization is completed.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // 📈 MARKET LIST
                    ...marketData.map(
                      (item) => Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppConstants.defaultBorderRadius,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                            child: const Icon(Icons.storefront_rounded, color: AppConstants.primaryColor),
                          ),
                          title: Text(
                            item['commodity'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Market: ${item['market'] ?? ''}\n'
                              'Date: ${item['arrival_date'] ?? ''}',
                              style: const TextStyle(height: 1.4),
                            ),
                          ),
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
                              const Text('per quintal', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
}
