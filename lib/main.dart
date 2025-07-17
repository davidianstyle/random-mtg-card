import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/app_provider.dart';
import 'providers/card_provider.dart';
import 'screens/card_display_screen.dart';
import 'services/config_service.dart';
import 'services/service_locator.dart';
import 'services/cache_service.dart';
import 'services/scryfall_service.dart';
import 'utils/logger.dart';
import 'utils/performance_monitor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize enhanced services
    await _initializeEnhancedServices();

    // Initialize window manager for desktop platforms
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await windowManager.ensureInitialized();
      await _configureWindow();
    }

    Logger.instance.info('Application initialized successfully');
    runApp(const MTGCardDisplayApp());
  } catch (e, stackTrace) {
    // Fallback error handling if logger isn't initialized
    debugPrint('Fatal error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');

    // Show error dialog or fallback UI
    runApp(ErrorApp(error: e.toString()));
  }
}

Future<void> _initializeEnhancedServices() async {
  // Initialize logger first
  await Logger.initialize(
    minLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
    enableFileLogging: true,
    enableConsoleLogging: true,
  );

  Logger.instance.info('Starting application initialization');

  // Initialize configuration service first
  await ConfigService.initialize();

  // Initialize service locator and register services
  await ServiceConfig.setupDependencies();

  // Initialize cache service
  final cacheService = await CacheService.create();
  ServiceLocator.instance.registerSingleton<CacheService>(cacheService);

  // Initialize Scryfall service
  final scryfallService = ScryfallService.instance;
  await scryfallService.initialize();
  ServiceLocator.instance.registerSingleton<ScryfallService>(scryfallService);

  // Enable performance monitoring
  PerformanceMonitor.instance.enable();

  Logger.instance.info('Enhanced services initialized successfully');
}

// Error app for initialization failures
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTG Card Display - Error',
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.red[900],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Application Failed to Start',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  error,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    exit(0);
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _configureWindow() async {
  final config = ConfigService.instance.config;
  final displayConfig = config['display'] as Map<String, dynamic>;

  // Default window size optimized for MTG card aspect ratio (can be overridden by config)
  // MTG cards are ~2.5" x 3.5" (ratio ~0.714:1), adjusted for UI elements
  Size windowSize = const Size(700, 900);

  // Platform-specific window configuration
  if (Platform.isLinux) {
    // Linux (Raspberry Pi) - Full-screen kiosk mode
    WindowOptions windowOptions = WindowOptions(
      size: windowSize,
      center: true,
      backgroundColor: Colors.black,
      skipTaskbar: displayConfig['fullscreen'] == true,
      titleBarStyle: TitleBarStyle.hidden,
      fullScreen: displayConfig['fullscreen'] == true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (displayConfig['fullscreen'] == true) {
        await windowManager.setFullScreen(true);
        await windowManager.setAlwaysOnTop(true);
        await windowManager.setSkipTaskbar(true);
      }
      await windowManager.focus();
    });
  } else if (Platform.isWindows || Platform.isMacOS) {
    // Windows/MacOS - Windowed mode with option for fullscreen
    WindowOptions windowOptions = WindowOptions(
      size: windowSize,
      center: true,
      backgroundColor: Colors.black,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      minimumSize: const Size(500, 650),  // Maintains card-friendly aspect ratio
      maximumSize: const Size(900, 1100), // Allows larger size while keeping proportions
      title: 'MTG Card Display',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();

      // Optional fullscreen on desktop (can be toggled with F11)
      if (displayConfig['fullscreen'] == true) {
        await windowManager.setFullScreen(true);
      }
    });
  }
}

class MTGCardDisplayApp extends StatelessWidget {
  const MTGCardDisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
      ],
      child: MaterialApp(
        title: 'MTG Card Display',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          primarySwatch: Colors.blue,
        ),
        home: const CardDisplayScreen(),
        builder: (context, child) {
          // Platform-specific UI configuration
          if (Platform.isLinux) {
            // Linux (Pi) - Lock to portrait, hide system UI
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
          } else {
            // Windows/MacOS - Allow orientation changes, show system UI
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          }

          return child ?? Container();
        },
      ),
    );
  }
}
