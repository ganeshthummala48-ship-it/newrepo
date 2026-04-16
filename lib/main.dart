import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/contractor_dashboard.dart';
import 'screens/contracts_screen.dart';
import 'screens/machinery_screen.dart';
import 'utils/constants.dart';
import 'services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/locale_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/community_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📦 Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('historyBox');
  await Hive.openBox('profileBox');
  await Hive.openBox('cacheBox');

  // 🔔 Initialize local notifications
  await NotificationService.init();

  runApp(const FarmerAIApp());
}

class FarmerAIApp extends StatelessWidget {
  const FarmerAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('profileBox');
    final bool profileDone = box.get('setup_done', defaultValue: false);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'FarmerAI',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('te'), // Telugu
              Locale('hi'), // Hindi
              Locale('mr'), // Marathi
              Locale('ta'), // Tamil
              Locale('bn'), // Bengali
              Locale('gu'), // Gujarati
              Locale('kn'), // Kannada
              Locale('ml'), // Malayalam
              Locale('pa'), // Punjabi
              Locale('or'), // Odia
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppConstants.primaryColor,
                surface: AppConstants.backgroundColor,
              ),
              textTheme: GoogleFonts.outfitTextTheme(ThemeData().textTheme),
              appBarTheme: AppBarTheme(
                centerTitle: true,
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                titleTextStyle: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppConstants.defaultBorderRadius,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  elevation: 2,
                  textStyle: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: AppConstants.defaultBorderRadius,
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppConstants.defaultBorderRadius,
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppConstants.defaultBorderRadius,
                  borderSide: const BorderSide(
                    color: AppConstants.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              cardTheme: CardThemeData(
                color: AppConstants.cardColor,
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.defaultBorderRadius,
                ),
              ),
            ),
            routes: {
              '/home': (_) => const HomeScreen(),
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegistrationScreen(),
              '/contractor': (_) => const ContractorDashboard(),
              '/contracts': (_) => const ContractsScreen(),
              '/machinery': (_) => const MachineryScreen(),
            },
            home: profileDone
                ? (box.get('role') == 'contractor'
                    ? const ContractorDashboard()
                    : const HomeScreen())
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
