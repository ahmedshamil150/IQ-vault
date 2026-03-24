import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'screens/home_screen.dart';
import 'screens/splash_loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      final directory = await getApplicationSupportDirectory();
      final path = '${directory.path}/iq_vault_data';
      final iqDir = Directory(path);
      if (!await iqDir.exists()) {
        await iqDir.create(recursive: true);
      }
      await Hive.initFlutter(path);
      await Hive.openBox('iqVaultBox').timeout(const Duration(seconds: 10));
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
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
