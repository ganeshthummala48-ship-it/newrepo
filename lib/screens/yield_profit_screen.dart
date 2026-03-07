import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class YieldProfitScreen extends StatefulWidget {
  const YieldProfitScreen({super.key});

  @override
  State<YieldProfitScreen> createState() => _YieldProfitScreenState();
}

class _YieldProfitScreenState extends State<YieldProfitScreen> {
  final TextEditingController _cropController = TextEditingController(
    text: 'Rice',
  );
  final TextEditingController _landSizeController = TextEditingController(
    text: '1.0',
  );
  final TextEditingController _priceController = TextEditingController(
    text: '30000',
  );
  final TextEditingController _costController = TextEditingController(
    text: '15000',
  );

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
      final yieldRes = await http.post(
        yieldUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'crop': _cropController.text.trim(),
          'soil': selectedSoil,
          'rainfall': selectedRainfall,
          'land_size': double.tryParse(_landSizeController.text) ?? 1.0,
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
            'crop': _cropController.text.trim(),
            'yield_amount': yieldData!['expected_yield'],
            'market_price': double.tryParse(_priceController.text) ?? 0,
            'cost': double.tryParse(_costController.text) ?? 0,
          }),
        );

        if (profitRes.statusCode == 200) {
          profitData = jsonDecode(profitRes.body);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${yieldRes.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to connect')));
      }
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(title: const Text('Yield & Profit Predictor')),
      body: SingleChildScrollView(
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
                    : const Text('Calculate'),
              ),
            ),
            const SizedBox(height: 20),
            if (yieldData != null && profitData != null) _buildResultCard(),
          ],
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
          TextField(
            controller: _cropController,
            decoration: const InputDecoration(
              labelText: 'Crop Type (e.g., Rice)',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedSoil,
            decoration: const InputDecoration(labelText: 'Soil Type'),
            items: soils
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => selectedSoil = v!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedRainfall,
            decoration: const InputDecoration(labelText: 'Rainfall'),
            items: rainfalls
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => selectedRainfall = v!),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _landSizeController,
            decoration: const InputDecoration(
              labelText: 'Land Size (Hectares)',
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
            'Expected Yield: ${yieldData!['expected_yield']} ${yieldData!['unit']}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'AI Analysis: ${yieldData!['explanation']}',
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
