import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/dahabi_theme.dart';
import 'screens/dashboard_screen.dart';
import 'services/data_provider.dart';
import 'services/logger_service.dart';
import 'l10n/app_localizations.dart';

// Simple locale provider
class LocaleProvider extends ChangeNotifier {
  Locale _locale;
  LocaleProvider(this._locale);
  
  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', locale.languageCode);
  }
}

late LocaleProvider localeProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved language
  final prefs = await SharedPreferences.getInstance();
  final String? savedLang = prefs.getString('selected_language');
  localeProvider = LocaleProvider(Locale(savedLang ?? 'ar', ''));

  await LoggerService().init();
  LoggerService().log('>>> APP STARTING <<<');
  DataProvider().init();
  
  runApp(
    ListenableBuilder(
      listenable: localeProvider,
      builder: (context, _) => const DahabiApp(),
    ),
  );
}

class DahabiApp extends StatelessWidget {
  const DahabiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dahabi',
      debugShowCheckedModeBanner: false,
      theme: DahabiTheme.themeData,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('ar', ''), // Arabic
        Locale('fr', ''), // French
      ],
      home: DashboardScreen(),
    );
  }
}
