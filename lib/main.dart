import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'screens/home_screen.dart';
import 'screens/splash_loading_screen.dart';

import 'services/currency_service.dart';
import 'services/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      // Ensure the splash screen is visible for at least 2.5 seconds for premium feel
      final results = await Future.wait([
        _performInitialization(),
        Future.delayed(const Duration(milliseconds: 2500)),
      ]);

      if (results[0] == true) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<bool> _performInitialization() async {
    final directory = await getApplicationSupportDirectory();
    final path = '${directory.path}/iq_vault_data';
    final iqDir = Directory(path);
    if (!await iqDir.exists()) {
      await iqDir.create(recursive: true);
    }
    await Hive.initFlutter(path);
    final box = await Hive.openBox('iqVaultBox').timeout(const Duration(seconds: 10));

    if (!box.containsKey('isDarkMode')) {
      await box.put('isDarkMode', false);
    }

    if (!box.containsKey('tester_bonus_1000')) {
      final currentCurrency = box.get(
        'user_currency',
        defaultValue: CurrencyService.initialCurrency,
      ) as int;
      await box.put(
        'user_currency',
        currentCurrency + CurrencyService.testerBonus,
      );
      await box.put('tester_bonus_1000', true);
    }

    if (box.containsKey('tester_bonus_100k')) {
      await box.delete('tester_bonus_100k');
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _error != null ? _buildErrorScreen() : _buildLoadingScreen(),
      );
    }

    final box = Hive.box('iqVaultBox');

    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['isDarkMode']),
      builder: (context, Box box, _) {
        final isDarkMode = box.get('isDarkMode', defaultValue: false);

        return MaterialApp(
          title: 'IQ Vault',
          debugShowCheckedModeBanner: false,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              primary: Colors.indigo,
              secondary: Colors.indigoAccent,
              surface: const Color(0xFFF8FAFF),
              brightness: Brightness.light,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: Colors.indigo,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
              iconTheme: IconThemeData(color: Colors.indigo),
            ),
            fontFamily:
                'Outfit', // Assuming user might have this or default to sans
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              primary: Colors.indigoAccent,
              secondary: Colors.indigo,
              surface: const Color(0xFF111315),
              brightness: Brightness.dark,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: const Color(0xFF1A1C1E),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const SplashLoadingScreen();
  }

  Widget _buildErrorScreen() {
    return Scaffold(body: Center(child: Text('Error: $_error')));
  }
}
