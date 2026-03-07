import 'package:flutter/material.dart';
import '../widgets/home_card.dart';
import '../utils/constants.dart';
import 'crop_screen.dart';
import 'market_screen.dart';
import 'disease_screen.dart';
import 'assistant_screen.dart';
import 'history_screen.dart';
import 'yield_profit_screen.dart';
import 'schemes_screen.dart';
import 'risk_alerts_screen.dart';
import 'farm_map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: const Text(
                'FarmerAI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppConstants.primaryGradient,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        Icons.agriculture,
                        size: 200,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 24.0, top: 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, Farmer! 👋",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "What would you like to do today?",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
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
          SliverPadding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildListDelegate([
                HomeCard(
                  title: 'Crop\nRecommendation',
                  icon: Icons.grass_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CropScreen()),
                  ),
                ),
                HomeCard(
                  title: 'Market\nPrices',
                  icon: Icons.trending_up_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MarketScreen()),
                  ),
                ),
                HomeCard(
                  title: 'Disease\nDetection',
                  icon: Icons.pest_control_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DiseaseScreen()),
                  ),
                ),
                HomeCard(
                  title: 'Prediction\nHistory',
                  icon: Icons.history_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                HomeCard(
                  title: 'Ask\nFarmerAI',
                  icon: Icons.auto_awesome_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AIAssistantScreen(),
                    ),
                  ),
                ),
                HomeCard(
                  title: 'Yield &\nProfit',
                  icon: Icons.monetization_on_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YieldProfitScreen(),
                    ),
                  ),
                ),
                HomeCard(
                  title: 'Govt\nSchemes',
                  icon: Icons.account_balance_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SchemesScreen()),
                  ),
                ),
                HomeCard(
                  title: 'Risk\nAlerts',
                  icon: Icons.warning_amber_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RiskAlertsScreen()),
                  ),
                ),
                HomeCard(
                  title: 'Farm\nMap',
                  icon: Icons.map_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FarmMapScreen()),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
