import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/constants.dart';
import '../services/ai_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/voice_wrapper.dart';

class DiseaseGalleryScreen extends StatefulWidget {
  final bool isEmbedded;
  const DiseaseGalleryScreen({super.key, this.isEmbedded = false});

  @override
  State<DiseaseGalleryScreen> createState() => _DiseaseGalleryScreenState();
}

class _DiseaseGalleryScreenState extends State<DiseaseGalleryScreen> {
  String _searchQuery = '';

  static const List<Map<String, dynamic>> _diseases = [
    {
      'name': 'Rice Blast',
      'crop': 'Rice',
      'icon': '🌾',
      'color': 0xFFF44336,
      'symptoms':
          'Diamond-shaped gray/white lesions on leaves, brown borders. Neck rot causes grain loss.',
      'cause': 'Fungus: Magnaporthe oryzae',
      'treatment': 'Spray Tricyclazole or Carbendazim. Reduce nitrogen.',
    },
    {
      'name': 'Wheat Rust',
      'crop': 'Wheat',
      'icon': '🌿',
      'color': 0xFFFF9800,
      'symptoms':
          'Orange, yellow or black powdery pustules on leaves and stems.',
      'cause': 'Fungus: Puccinia species',
      'treatment': 'Spray Propiconazole or Mancozeb. Use resistant varieties.',
    },
    {
      'name': 'Cotton Bollworm',
      'crop': 'Cotton',
      'icon': '🪲',
      'color': 0xFF9C27B0,
      'symptoms':
          'Holes in bolls, larvae inside. Damaged squares and flared bracts.',
      'cause': 'Pest: Helicoverpa armigera',
      'treatment': 'Spray Chlorpyrifos or Spinosad. Use pheromone traps.',
    },
    {
      'name': 'Tomato Leaf Curl',
      'crop': 'Tomato',
      'icon': '🍅',
      'color': 0xFFE91E63,
      'symptoms':
          'Upward curling of leaves, yellowing, stunted growth, distorted fruits.',
      'cause': 'Virus: Tomato Leaf Curl Virus (TLCV) — spread by whiteflies.',
      'treatment':
          'Control whiteflies with Imidacloprid. Remove infected plants.',
    },
    {
      'name': 'Powdery Mildew',
      'crop': 'Multiple',
      'icon': '🍃',
      'color': 0xFF607D8B,
      'symptoms':
          'White powdery coating on leaves, stems, and flowers. Yellowing and wilting.',
      'cause': 'Fungus: Erysiphe species',
      'treatment': 'Spray Sulphur or Tebuconazole. Improve air circulation.',
    },
    {
      'name': 'Early Blight',
      'crop': 'Potato / Tomato',
      'icon': '🥔',
      'color': 0xFF795548,
      'symptoms':
          'Dark brown circular spots with concentric rings (target board pattern) on older leaves.',
      'cause': 'Fungus: Alternaria solani',
      'treatment': 'Spray Mancozeb or Chlorothalonil. Remove infected leaves.',
    },
    {
      'name': 'Downy Mildew',
      'crop': 'Grapes / Pearl Millet',
      'icon': '🍇',
      'color': 0xFF3F51B5,
      'symptoms':
          'Yellow patches on upper leaf surface, gray-purple mold on lower surface.',
      'cause': 'Oomycete: Plasmopara / Sclerospora',
      'treatment': 'Spray Metalaxyl-Mancozeb. Remove infected parts.',
    },
    {
      'name': 'Fusarium Wilt',
      'crop': 'Banana / Tomato',
      'icon': '🍌',
      'color': 0xFFFF5722,
      'symptoms':
          'Yellowing and wilting of leaves starting from lower leaves. Vascular browning.',
      'cause': 'Fungus: Fusarium oxysporum',
      'treatment': 'Use disease-free planting material. Soil fumigation.',
    },
    {
      'name': 'Bacterial Blight',
      'crop': 'Cotton',
      'icon': '🌱',
      'color': 0xFF009688,
      'symptoms':
          'Water-soaked angular spots that turn brown/black. Defoliation in severe cases.',
      'cause': 'Bacteria: Xanthomonas axonopodis',
      'treatment': 'Spray Copper oxychloride. Use resistant varieties.',
    },
    {
      'name': 'Sheath Blight',
      'crop': 'Rice',
      'icon': '🌾',
      'color': 0xFF8BC34A,
      'symptoms':
          'Oval/irregular greenish-gray lesions on leaf sheaths. White mycelium in humid conditions.',
      'cause': 'Fungus: Rhizoctonia solani',
      'treatment': 'Spray Validamycin or Hexaconazole. Reduce plant density.',
    },
    {
      'name': 'Yellow Mosaic Virus',
      'crop': 'Soybean / Moong',
      'icon': '🫘',
      'color': 0xFFCDDC39,
      'symptoms':
          'Yellow-green mosaic pattern on leaves. Stunted plant growth, reduced yield.',
      'cause': 'Virus: Bean Yellow Mosaic Virus — spread by aphids.',
      'treatment':
          'Control aphids. Remove infected plants. Use certified seeds.',
    },
    {
      'name': 'Stem Borer',
      'crop': 'Rice / Maize',
      'icon': '🌽',
      'color': 0xFF4CAF50,
      'symptoms':
          'Dead heart in vegetative stage, white ear in reproductive stage. Frass inside stem.',
      'cause': 'Pest: Scirpophaga incertulas (rice), Chilo partellus (maize)',
      'treatment':
          'Apply Carbofuran granules. Install light traps. Use Trichogramma parasitoids.',
    },
    {
      'name': 'Aphid Infestation',
      'crop': 'Multiple',
      'icon': '🐛',
      'color': 0xFF00BCD4,
      'symptoms':
          'Clusters of tiny insects on young shoots and leaves. Sticky honeydew, sooty mold.',
      'cause': 'Pest: Aphis species',
      'treatment': 'Spray Dimethoate or Neem oil. Introduce lady beetles.',
    },
    {
      'name': 'Late Blight',
      'crop': 'Potato',
      'icon': '🥔',
      'color': 0xFF673AB7,
      'symptoms':
          'Dark water-soaked lesions on leaves and stems. White mold on undersides in humid conditions.',
      'cause': 'Oomycete: Phytophthora infestans',
      'treatment': 'Spray Cymoxanil-Mancozeb. Emergency harvest if severe.',
    },
    {
      'name': 'Anthracnose',
      'crop': 'Mango / Grapes',
      'icon': '🥭',
      'color': 0xFFFF9800,
      'symptoms':
          'Dark sunken lesions on fruits, leaves, and stems. Fruit rot and mummification.',
      'cause': 'Fungus: Colletotrichum species',
      'treatment': 'Spray Carbendazim or Copper fungicide at flowering.',
    },
  ];

  List<Map<String, dynamic>> get _filtered => _searchQuery.isEmpty
      ? _diseases
      : _diseases
            .where(
              (d) =>
                  d['name'].toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  d['crop'].toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: widget.isEmbedded ? null : AppBar(title: const Text('Disease Guide')),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.diseaseGuideTitle,
        textToRead: "Welcome to the plant disease guide. I can help you identify and treat various agricultural diseases. Currently showing ${_filtered.length} matching entries.",
        child: Column(
          children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search disease or crop...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Disease list
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No diseases found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) =>
                        _DiseaseCard(disease: _filtered[i]),
                  ),
          ),
        ],
      ),
    ),
  );
}
}

class _DiseaseCard extends StatelessWidget {
  final Map<String, dynamic> disease;
  const _DiseaseCard({required this.disease});

  @override
  Widget build(BuildContext context) {
    final color = Color(disease['color'] as int);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    disease['icon'],
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Crop: ${disease['crop']}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      disease['cause'],
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final color = Color(disease['color'] as int);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DiseaseDetailSheet(disease: disease, color: color),
    );
  }
}

class _DiseaseDetailSheet extends StatefulWidget {
  final Map<String, dynamic> disease;
  final Color color;
  const _DiseaseDetailSheet({required this.disease, required this.color});

  @override
  State<_DiseaseDetailSheet> createState() => _DiseaseDetailSheetState();
}

class _DiseaseDetailSheetState extends State<_DiseaseDetailSheet> {
  bool _aiLoading = false;
  String? _aiAdvice;

  Future<void> _askAI() async {
    setState(() => _aiLoading = true);
    try {
      final response = await AIService.getAIResponse(
        'Provide detailed control measures and organic alternatives for ${widget.disease['name']} '
        'in ${widget.disease['crop']}. Include: symptoms to confirm, pesticide names with dosage, '
        'and 2-3 organic/biological control options. Keep it practical for an Indian farmer.',
      );
      setState(() => _aiAdvice = response);
    } catch (e) {
      setState(
        () => _aiAdvice = 'Could not get AI advice. Check your connection.',
      );
    }
    setState(() => _aiLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  widget.disease['icon'],
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.disease['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Crop: ${widget.disease['crop']}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailTile(
              Icons.biotech_outlined,
              'Cause',
              widget.disease['cause'],
              widget.color,
            ),
            const SizedBox(height: 12),
            _detailTile(
              Icons.visibility_outlined,
              'Symptoms',
              widget.disease['symptoms'],
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _detailTile(
              Icons.healing_outlined,
              'Treatment',
              widget.disease['treatment'],
              Colors.green,
            ),
            const SizedBox(height: 20),
            if (_aiAdvice == null && !_aiLoading)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _askAI,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Get Detailed AI Advice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
            if (_aiLoading) const Center(child: CircularProgressIndicator()),
            if (_aiAdvice != null) ...[
              const Divider(),
              const Text(
                'FarmerAI Advice',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              MarkdownBody(
                data: _aiAdvice!,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(IconData icon, String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
