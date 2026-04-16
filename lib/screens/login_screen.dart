import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/voice_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        final role = data['role'];
        final phone = data['phone'] ?? '';
        final box = Hive.box('profileBox');
        await box.put('name', _nameController.text);
        await box.put('role', role);
        await box.put('phone', phone);
        await box.put('setup_done', true);

        if (role == 'contractor') {
          Navigator.pushReplacementNamed(context, '/contractor');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? l10n.loginFailed)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorConnecting}: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('FarmerAI'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: localeProvider.locale.languageCode,
              dropdownColor: AppConstants.primaryColor,
              iconEnabledColor: Colors.white,
              underline: const SizedBox(),
              items: ['en', 'te', 'hi', 'mr', 'ta', 'bn', 'gu', 'kn', 'ml', 'pa', 'or']
                  .map((l) => DropdownMenuItem(
                        value: l,
                        child: Text(_getLanguageName(l), style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  localeProvider.setLocale(Locale(v));
                  setState(() {});
                }
              },
            ),
          ),
        ],
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.login,
        textToRead: "Welcome to FarmerAI. Please login to continue. You can talk to the AI assistant once you are logged in.",
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Image.asset(AppConstants.appLogo, height: 120),
              const SizedBox(height: 16),
              Text(
                l10n.welcome,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
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
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(l10n.login),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text(l10n.noAccount),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
