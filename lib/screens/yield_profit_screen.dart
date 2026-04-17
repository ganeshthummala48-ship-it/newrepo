import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/api_service.dart';
import '../widgets/voice_wrapper.dart';

class YieldProfitScreen extends StatefulWidget {
  const YieldProfitScreen({super.key});

  @override
  State<YieldProfitScreen> createState() => _YieldProfitScreenState();
}

class _YieldProfitScreenState extends State<YieldProfitScreen> {
  String selectedCrop = 'Rice';
  List<String> commodities = ['Rice', 'Wheat', 'Maize', 'Cotton', 'Sugarcane', 'Tomato', 'Potato'];

  String selectedSoil = 'Black';
  String selectedRainfall = 'Medium';

  final soils = ['Black', 'Alluvial', 'Loamy', 'Clay', 'Sandy'];
  final rainfalls = ['Low', 'Medium', 'High'];

  bool loading = false;
  Map<String, dynamic>? yieldData;
  Map<String, dynamic>? profitData;

  Future<void> calculate() async {
    setState(() => loading = true);

    try {
      // 1. Get Yield Prediction
      final yieldUri = Uri.parse('${AppConstants.baseUrl}/predict-yield');
      final lang = Localizations.localeOf(context).languageCode;
      final yieldRes = await http.post(
        yieldUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'crop': selectedCrop,
          'soil': selectedSoil,
          'rainfall': selectedRainfall,
          'land_size': double.tryParse(_landSizeController.text) ?? 1.0,
          'lang': lang,
        }),
      );

      if (yieldRes.statusCode == 200) {
        yieldData = jsonDecode(yieldRes.body);

        // 2. Get Profit Prediction based on Yield
        final profitUri = Uri.parse('${AppConstants.baseUrl}/calculate-profit');
        final profitRes = await http.post(
          profitUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'crop': selectedCrop,
            'yield_amount': yieldData!['expected_yield'],
            'market_price': double.tryParse(_priceController.text) ?? 0,
            'cost': double.tryParse(_costController.text) ?? 0,
          }),
        );

        if (profitRes.statusCode == 200) {
          profitData = jsonDecode(profitRes.body);
        } else {
          final errorBody = jsonDecode(profitRes.body);
          throw Exception(errorBody['detail'] ?? 'Profit calculation failed');
        }
      } else {
        final errorBody = jsonDecode(yieldRes.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.serverError}: ${errorBody['detail'] ?? yieldRes.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${AppLocalizations.of(context)!.connectionError}: $e")));
      }
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    loadCommodities();
  }

  Future<void> loadCommodities() async {
    try {
      final list = await ApiService.fetchCommodities();
      if (list.isNotEmpty && mounted) {
        setState(() {
          commodities = list;
          if (!commodities.contains(selectedCrop)) {
            selectedCrop = commodities.contains('Rice') ? 'Rice' : commodities.first;
          }
        });
      }
    } catch (e) {
      print('YieldProfitScreen: Error loading commodities: $e');
    }
  }

  final TextEditingController _landSizeController = TextEditingController(text: '1.0');
  final TextEditingController _priceController = TextEditingController(text: '30000');
  final TextEditingController _costController = TextEditingController(text: '15000');

  @override
  Widget build(BuildContext context) {
    String voiceContent = AppLocalizations.of(context)!.yieldPredictor + ". ";
    if (loading) {
      voiceContent += "Calculating your expected yield and profit.";
    } else if (yieldData != null && profitData != null) {
      voiceContent += "Expected yield is ${yieldData!['expected_yield'] ?? 'unknown'} tons. " +
          "Predicted profit is ${profitData!['profit'] ?? 'unknown'} rupees. " +
          (yieldData!['explanation'] ?? 'Calculations based on area and soil.').replaceAll('*', '');
    } else {
      voiceContent += "Enter your crop, land size and costs to predict your profit.";
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.yieldPredictor)),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.yieldPredictor,
        textToRead: voiceContent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
            _buildInputForm(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : calculate,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(AppLocalizations.of(context)!.calculate),
              ),
            ),
            const SizedBox(height: 20),
            if (yieldData != null && profitData != null) _buildResultCard(),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: commodities.contains(selectedCrop) ? selectedCrop : null,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.cropType,
              prefixIcon: const Icon(Icons.grass_rounded),
            ),
            items: commodities
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => selectedCrop = v!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedSoil,
            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.soilType),
            items: soils
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => selectedSoil = v!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedRainfall,
            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.rainfallLevel),
            items: rainfalls
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => selectedRainfall = v!),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _landSizeController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.landSize,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Expected Market Price per Ton',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _costController,
            decoration: const InputDecoration(
              labelText: 'Total Cultivation Cost',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    bool isProfitable = profitData!['profit'] > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expected Yield: ${yieldData!['expected_yield'] ?? '--'} ${yieldData!['unit'] ?? ''}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'AI Analysis: ${yieldData!['explanation'] ?? 'Analysis not available.'}',
            style: const TextStyle(color: Colors.grey),
          ),
          const Divider(height: 30),
          Text(
            'Revenue: ₹${profitData!['revenue']}',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Profit/Loss: ₹${profitData!['profit']}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isProfitable ? Colors.green : Colors.red,
            ),
          ),
          Text(
            'ROI: ${profitData!['roi_percentage']}%',
            style: TextStyle(color: isProfitable ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }
}
