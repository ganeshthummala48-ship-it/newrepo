import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import '../widgets/voice_wrapper.dart';
import '../l10n/generated/app_localizations.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Product> _allProducts = [
    // Fertilizers
    Product(
      id: 'f1',
      name: 'Urea Fertilizer',
      category: 'Fertilizer',
      price: 266,
      unit: '45kg Bag',
      description: 'High-quality Urea fertilizer providing essential nitrogen for robust plant growth.',
      imageIcon: Icons.grass_rounded,
      imageUrl: 'assets/products/urea.png',
    ),
    Product(
      id: 'f2',
      name: 'DAP Fertilizer',
      category: 'Fertilizer',
      price: 1350,
      unit: '50kg Bag',
      description: 'Diammonium Phosphate, excellent for early root development and crop establishment.',
      imageIcon: Icons.agriculture_rounded,
      imageUrl: 'assets/products/dap.png',
    ),
    Product(
      id: 'f3',
      name: 'Organic Manure',
      category: 'Fertilizer',
      price: 800,
      unit: '50kg Bag',
      description: '100% organic compost and manure to enrich soil fertility naturally.',
      imageIcon: Icons.eco_rounded,
    ),
    // Seeds
    Product(
      id: 's1',
      name: 'Hybrid Rice Seeds',
      category: 'Seed',
      price: 450,
      unit: '5kg Bag',
      description: 'High-yielding hybrid rice seeds resistant to common pests.',
      imageIcon: Icons.spa_rounded,
      imageUrl: 'assets/products/rice_seeds.png',
    ),
    Product(
      id: 's2',
      name: 'Wheat Seeds (Premium)',
      category: 'Seed',
      price: 320,
      unit: '10kg Bag',
      description: 'Top-grade wheat seeds ensuring a bountiful and healthy harvest.',
      imageIcon: Icons.looks_rounded,
      imageUrl: 'assets/products/wheat_seeds.png',
    ),
    Product(
      id: 's3',
      name: 'Maize Seeds',
      category: 'Seed',
      price: 280,
      unit: '5kg Bag',
      description: 'Fast-growing maize seeds suited for various climates.',
      imageIcon: Icons.park_rounded,
    ),
    // Pesticides
    Product(
      id: 'p1',
      name: 'Neem Oil Pesticide',
      category: 'Pesticide',
      price: 450,
      unit: '1 Liter',
      description: 'Organic neem oil for safe and effective pest control.',
      imageIcon: Icons.water_drop_rounded,
      imageUrl: 'assets/products/neem_oil.png',
    ),
    Product(
      id: 'p2',
      name: 'Chlorpyrifos 20% EC',
      category: 'Pesticide',
      price: 350,
      unit: '500 ml',
      description: 'Broad-spectrum insecticide for targeted agricultural use.',
      imageIcon: Icons.pest_control_rounded,
      imageUrl: 'assets/products/chlorpyrifos.png',
    ),
    Product(
      id: 'p3',
      name: 'Fungicide (Mancozeb)',
      category: 'Pesticide',
      price: 220,
      unit: '500g Pack',
      description: 'Effective against a wide range of fungal diseases in crops.',
      imageIcon: Icons.coronavirus_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bookSupplies),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Fertilizers'),
            Tab(text: 'Seeds'),
            Tab(text: 'Pesticides'),
          ],
        ),
      ),
      body: VoiceWrapper(
        screenTitle: 'Book Supplies',
        textToRead: "You are in the Book Supplies screen. Currently viewing ${_tabController.index == 0 ? 'Fertilizers' : _tabController.index == 1 ? 'Seeds' : 'Pesticides'}. Select items to add to your cart.",
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildProductGrid('Fertilizer'),
            _buildProductGrid('Seed'),
            _buildProductGrid('Pesticide'),
          ],
        ),
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.itemCount == 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            backgroundColor: AppConstants.primaryColor,
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text(
              'View Cart (${cart.itemCount})',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(String category) {
    final products = _allProducts.where((p) => p.category == category).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            );
          },
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: Hero(
                      tag: product.id,
                      child: product.imageUrl != null
                          ? Image.asset(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              product.imageIcon,
                              size: 60,
                              color: AppConstants.primaryColor,
                            ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          '₹${product.price}',
                          style: const TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'per ${product.unit}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Provider.of<CartProvider>(
                                context,
                                listen: false,
                              ).addItem(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to cart'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Text(
                              'Add',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

