import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  final TextEditingController _stateController = TextEditingController(
    text: 'Maharashtra',
  );
  final TextEditingController _cropController = TextEditingController(
    text: 'Cotton',
  );
  final TextEditingController _landSizeController = TextEditingController(
    text: '2.0',
  );

  bool loading = false;
  String? schemesResult;

  Future<void> findSchemes() async {
    setState(() => loading = true);
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/recommend-schemes');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'state': _stateController.text.trim(),
          'crop': _cropController.text.trim(),
          'land_size': double.tryParse(_landSizeController.text) ?? 1.0,
        }),
      );

      if (res.statusCode == 200) {
        setState(() {
          schemesResult = jsonDecode(res.body)['schemes'];
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${res.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to connect')));
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(title: const Text('Govt Schemes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State (e.g., Maharashtra)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _cropController,
                    decoration: const InputDecoration(labelText: 'Crop Type'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _landSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Land Size (Hectares)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : findSchemes,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Find Schemes'),
              ),
            ),
            const SizedBox(height: 20),
            if (schemesResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  schemesResult!,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
