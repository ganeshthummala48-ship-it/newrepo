import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FarmMapScreen extends StatefulWidget {
  const FarmMapScreen({super.key});

  @override
  State<FarmMapScreen> createState() => _FarmMapScreenState();
}

class _FarmMapScreenState extends State<FarmMapScreen> {
  String selectedLayer = 'Soil Fertility';

  final List<String> layers = [
    'Soil Fertility',
    'Irrigation Zones',
    'Crop Health',
  ];

  Color _getZoneColor(int index) {
    if (selectedLayer == 'Soil Fertility') {
      return [
        Colors.brown.shade800,
        Colors.brown.shade600,
        Colors.brown.shade400,
        Colors.brown.shade300,
      ][index % 4];
    } else if (selectedLayer == 'Irrigation Zones') {
      return [
        Colors.blue.shade800,
        Colors.blue.shade600,
        Colors.blue.shade400,
        Colors.blue.shade200,
      ][index % 4];
    } else {
      return [
        Colors.green.shade800,
        Colors.green.shade600,
        Colors.lightGreen.shade400,
        Colors.yellow.shade600,
      ][index % 4];
    }
  }

  String _getZoneLabel(int index) {
    if (selectedLayer == 'Soil Fertility') {
      return ['High NPK', 'Medium NPK', 'Low Nitrogen', 'Optimal'][index % 4];
    } else if (selectedLayer == 'Irrigation Zones') {
      return ['Well Irrigated', 'Moderate', 'Needs Water', 'Dry Zone'][index %
          4];
    } else {
      return ['Healthy', 'Vigorous', 'Mild Stress', 'Pest Risk'][index % 4];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(title: const Text('Smart Farm Map')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: layers
                    .map(
                      (layer) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(layer),
                          selected: selectedLayer == layer,
                          onSelected: (selected) {
                            if (selected) setState(() => selectedLayer = layer);
                          },
                          selectedColor: AppConstants.primaryColor.withValues(
                            alpha: 0.2,
                          ),
                          labelStyle: TextStyle(
                            color: selectedLayer == layer
                                ? AppConstants.primaryColor
                                : Colors.black87,
                            fontWeight: selectedLayer == layer
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  color: Colors.grey.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Tooltip(
                        message: 'Zone ${index + 1}: ${_getZoneLabel(index)}',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _getZoneColor(index),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getZoneLabel(index),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap on zones to view detailed metrics. Map simulated for demonstration.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
