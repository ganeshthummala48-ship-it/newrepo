import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/voice_wrapper.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedRole = 'farmer';
  bool _isLoading = false;

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

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'password': _passwordController.text,
          'phone': _phoneController.text,
          'role': _selectedRole,
          'language': Provider.of<LocaleProvider>(context, listen: false).locale.languageCode,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.registrationSuccess)),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? l10n.registrationFailed)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.register)),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.register,
        textToRead: "Create your account to join the FarmerAI community. Enter your name, password, phone number and select your role.",
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
            const Icon(Icons.person_add, size: 64, color: AppConstants.primaryColor),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.username, prefixIcon: const Icon(Icons.person)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: l10n.password, prefixIcon: const Icon(Icons.lock)),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                prefixIcon: const Icon(Icons.phone),
                hintText: l10n.phoneHint,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: localeProvider.locale.languageCode,
              decoration: InputDecoration(
                labelText: l10n.preferredLanguage,
                prefixIcon: const Icon(Icons.language),
                border: const OutlineInputBorder(),
              ),
              items: ['en', 'te', 'hi', 'mr', 'ta', 'bn', 'gu', 'kn', 'ml', 'pa', 'or'].map((l) {
                return DropdownMenuItem(value: l, child: Text(_getLanguageName(l)));
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  localeProvider.setLocale(Locale(v));
                }
              },
            ),
            const SizedBox(height: 24),
            Text(l10n.selectRole, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedRole = 'farmer'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedRole == 'farmer' ? AppConstants.primaryColor : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _selectedRole == 'farmer' ? AppConstants.primaryColor.withValues(alpha: 0.05) : Colors.white,
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.agriculture, color: _selectedRole == 'farmer' ? AppConstants.primaryColor : Colors.grey),
                          const SizedBox(height: 4),
                          Text(l10n.farmer, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedRole = 'contractor'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedRole == 'contractor' ? AppConstants.primaryColor : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _selectedRole == 'contractor' ? AppConstants.primaryColor.withValues(alpha: 0.05) : Colors.white,
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.business, color: _selectedRole == 'contractor' ? AppConstants.primaryColor : Colors.grey),
                          const SizedBox(height: 4),
                          Text(l10n.contractor, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: Text(l10n.register),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
