import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/voice_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  final bool isOnboarding;
  const ProfileScreen({super.key, this.isOnboarding = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _landController = TextEditingController(text: '2.0');

  String _selectedState = 'Telangana';
  String _selectedCrop = 'Cotton';

  final List<String> _states = [
    'Andhra Pradesh',
    'Bihar',
    'Gujarat',
    'Haryana',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Tamil Nadu',
    'Telangana',
    'Uttar Pradesh',
    'West Bengal',
  ];

  final List<String> _crops = [
    'Cotton',
    'Maize',
    'Rice',
    'Wheat',
    'Sugarcane',
    'Groundnut',
    'Soybean',
    'Sunflower',
    'Tomato',
    'Onion',
    'Potato',
    'Banana',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    final box = Hive.box('profileBox');
    _nameController.text = box.get('name', defaultValue: '');
    _selectedState = box.get('state', defaultValue: 'Telangana');
    _selectedCrop = box.get('crop', defaultValue: 'Cotton');
    _landController.text = box.get('land_size', defaultValue: '2.0');
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'te': return 'తెలుగు (Telugu)';
      case 'hi': return 'हिन्दी (Hindi)';
      case 'mr': return 'मराठी (Marathi)';
      case 'ta': return 'தமிழ் (Tamil)';
      case 'bn': return 'বাংলা (Bengali)';
      case 'gu': return 'ગુજરાતી (Gujarati)';
      case 'kn': return 'ಕನ್ನಡ (Kannada)';
      case 'ml': return 'മലയാളം (Malayalam)';
      case 'pa': return 'ਪੰਜਾਬੀ (Punjabi)';
      case 'or': return 'ଓଡ଼ିଆ (Odia)';
      default: return 'English';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final box = Hive.box('profileBox');
    await box.put('name', _nameController.text.trim());
    await box.put('state', _selectedState);
    await box.put('crop', _selectedCrop);
    await box.put('land_size', _landController.text.trim());
    await box.put('setup_done', true);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (widget.isOnboarding) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
      Navigator.pop(context);
    }
  }

  Future<void> _logout() async {
    final box = Hive.box('profileBox');
    await box.put('setup_done', false);
    await box.delete('role');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout? your profile data will be kept but you will need to re-verify.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    String voiceContent = "${widget.isOnboarding ? l10n.welcome : l10n.myProfile}. " +
        "Language is set to ${_getLanguageName(localeProvider.locale.languageCode)}. " +
        "Name is ${_nameController.text.isEmpty ? 'not set' : _nameController.text}. " +
        "Profile settings help FarmerAI provide better recommendations.";

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.myProfile,
        textToRead: voiceContent,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const SizedBox(height: 24),
                // ── Header ──
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppConstants.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.isOnboarding ? l10n.welcome : l10n.myProfile,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isOnboarding
                            ? l10n.welcomeSubtitle
                            : l10n.updateProfile,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Language ──
                _sectionLabel(l10n.language),
                DropdownButtonFormField<String>(
                  value: localeProvider.locale.languageCode,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.language),
                  ),
                  items: ['en', 'te', 'hi', 'mr', 'ta', 'bn', 'gu', 'kn', 'ml', 'pa', 'or']
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(_getLanguageName(l)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      localeProvider.setLocale(Locale(v));
                    }
                  },
                ),
                const SizedBox(height: 20),

                // ── Name ──
                _sectionLabel(l10n.yourName),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: l10n.enterName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.nameError
                      : null,
                ),
                const SizedBox(height: 20),

                // ── State ──
                _sectionLabel(l10n.yourState),
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: _states
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedState = v!),
                ),
                const SizedBox(height: 20),

                // ── Main Crop ──
                _sectionLabel(l10n.primaryCrop),
                DropdownButtonFormField<String>(
                  value: _selectedCrop,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.grass_rounded),
                  ),
                  items: _crops
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCrop = v!),
                ),
                const SizedBox(height: 20),

                // ── Land Size ──
                _sectionLabel(l10n.landSize),
                TextFormField(
                  controller: _landController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 2.5',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Save Button ──
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      widget.isOnboarding
                          ? l10n.letsGetStarted
                          : l10n.saveProfile,
                    ),
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!widget.isOnboarding) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Center(child: Text(l10n.cancel)),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout_rounded, color: Colors.red),
                      label: const Text(
                        'Logout from App',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}
