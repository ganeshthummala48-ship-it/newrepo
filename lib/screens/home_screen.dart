import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/home_card.dart';
import '../utils/constants.dart';
import 'market_screen.dart';
import 'crop_health_screen.dart';
import 'booking_screen.dart';
import 'assistant_screen.dart';
import 'yield_profit_screen.dart';
import 'schemes_screen.dart';
import 'risk_alerts_screen.dart';
import 'farm_map_screen.dart';
import 'profile_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'community_screen.dart';
import 'crop_screen.dart';
import '../widgets/voice_wrapper.dart';
import '../services/notification_polling_service.dart';
import '../widgets/home/wave_painter.dart';
import '../widgets/home/weather_hero_card.dart';
import '../widgets/home/live_stats_ticker.dart';
import '../widgets/home/activity_feed_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NotificationPollingService? _pollingService;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('profileBox');
    final name = box.get('name', defaultValue: '') as String;
    if (name.isNotEmpty) {
      _pollingService = NotificationPollingService(
        role: 'farmer',
        name: name,
        pollInterval: const Duration(seconds: 30),
      )..start();
    }
  }

  @override
  void dispose() {
    _pollingService?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final box = Hive.box('profileBox');
    final farmerName = box.get('name', defaultValue: '') as String;
    final greeting =
        farmerName.isNotEmpty ? l10n.hello(farmerName) : l10n.helloFarmer;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: VoiceWrapper(
        screenTitle: l10n.homeDashboard,
        textToRead: '$greeting. ${l10n.whatsToday}. '
            '${l10n.cropHealth}, ${l10n.diseaseDetection}. '
            '${l10n.contractsAndServices}, ${l10n.contractsSubtitle}. '
            '${l10n.marketPrices}, ${l10n.realTimeRates}. '
            '${l10n.myBookings}. '
            '${l10n.yieldAndProfit}, ${l10n.revenueEstimates}. '
            '${l10n.farmMap}, ${l10n.satelliteMonitoring}. '
            '${l10n.govtSchemes}, ${l10n.financialSupport}. '
            '${l10n.askFarmerAI}, ${l10n.expertChat}. '
            '${l10n.riskAlerts}, ${l10n.weatherWarnings}. '
            '${l10n.farmersCommunity}, ${l10n.localDiscussions}.',
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 280.0,
              floating: false,
              pinned: true,
              backgroundColor: AppConstants.primaryColor,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.groups_rounded, color: Colors.white),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CommunityScreen())),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_active_rounded,
                      color: Colors.white),
                  onPressed: () {
                    // Navigate to real-time unified notifications
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen())),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                title: const Text(
                  'AgriNova',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                background: AnimatedWaveBackground(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  child: Stack(
                    children: [
                      // Decorative elements
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Icon(
                          Icons.eco_rounded,
                          size: 250,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: 40,
                        child: Icon(
                          Icons.wb_sunny_rounded,
                          size: 150,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 24.0, right: 24.0, top: 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.whatsToday,
                                style: TextStyle(
                                  color: Colors.green.shade100,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Weather overview glassmorphism card
                              WeatherHeroCard(
                                location: 'Local Farm',
                                temperature: '32°C',
                                description: 'Sunny, optimal for harvesting.',
                                icon: Icons.wb_sunny_rounded,
                                onTap: () {}, // Can link to weather details later
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ), // Container
                ), // AnimatedWaveBackground
              ), // FlexibleSpaceBar
            ), // SliverAppBar

            // Live Stats Ticker and Activity Feed
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const LiveStatsTicker(
                    items: [
                      'Market: Tomato prices increased by ₹5/kg today.',
                      'Weather Alert: Clear skies expected for the next 48 hours.',
                      'New government subsidy for drip irrigation available.',
                    ],
                  ),
                  const SizedBox(height: 16),
                  ActivityFeedSection(
                    title: 'Community & Alerts',
                    onSeeAll: () {},
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Grid content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildListDelegate([
                  HomeCard(
                    title: l10n.cropHealth,
                    subtitle: l10n.diseaseDetection,
                    icon: Icons.health_and_safety_rounded,
                    baseColor: Colors.red.shade600,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CropHealthScreen()),
                    ),
                  ),
                  HomeCard(
                    title: l10n.riskAlerts,
                    subtitle: l10n.weatherWarnings,
                    icon: Icons.warning_amber_rounded,
                    baseColor: Colors.deepOrange.shade500,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RiskAlertsScreen()),
                    ),
                  ),
                  HomeCard(
                    title: l10n.govtSchemes,
                    subtitle: l10n.financialSupport,
                    icon: Icons.account_balance_rounded,
                    baseColor: Colors.indigo.shade500,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SchemesScreen()),
                    ),
                  ),
                  HomeCard(
                    title: l10n.yieldAndProfit,
                    subtitle: l10n.revenueEstimates,
                    icon: Icons.monetization_on_rounded,
                    baseColor: Colors.amber.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const YieldProfitScreen(),
                      ),
                    ),
                  ),
                  HomeCard(
                    title: l10n.marketPrices,
                    subtitle: l10n.realTimeRates,
                    icon: Icons.show_chart_rounded,
                    baseColor: Colors.purple.shade600,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MarketScreen()),
                    ),
                  ),
                  HomeCard(
                    title: l10n.askFarmerAI,
                    subtitle: l10n.expertChat,
                    icon: Icons.auto_awesome_rounded,
                    baseColor: Colors.orange.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AIAssistantScreen(),
                      ),
                    ),
                  ),
                  HomeCard(
                    title: l10n.farmMap,
                    subtitle: l10n.satelliteMonitoring,
                    icon: Icons.map_rounded,
                    baseColor: Colors.teal.shade500,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FarmMapScreen()),
                    ),
                  ),
                  HomeCard(
                    title: l10n.myBookings,
                    subtitle: l10n.myBookingsSubtitle,
                    icon: Icons.receipt_long_rounded,
                    baseColor: Colors.cyan.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BookingScreen(farmerName: farmerName)),
                    ),
                  ),
                  HomeCard(
                    title: l10n.contractsAndServices,
                    subtitle: l10n.contractsSubtitle,
                    icon: Icons.handshake_rounded,
                    baseColor: Colors.blue.shade700,
                    onTap: () => Navigator.pushNamed(context, '/contracts'),
                  ),
                  HomeCard(
                    title: l10n.cropRecommendation,
                    subtitle: l10n.topCrops,
                    icon: Icons.psychology_rounded,
                    baseColor: Colors.lightGreen.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CropScreen()),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
