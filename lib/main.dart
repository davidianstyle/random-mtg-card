import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/app_provider.dart';
import 'providers/card_provider.dart';
import 'screens/card_display_screen.dart';
import 'services/config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize configuration first
  await ConfigService.initialize();
  
  // Initialize window manager for desktop platforms
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    
    // Configure window based on platform
    await _configureWindow();
  }
  
  runApp(const MTGCardDisplayApp());
}

Future<void> _configureWindow() async {
  final config = ConfigService.instance.config;
  final displayConfig = config['display'] as Map<String, dynamic>;
  
  // Default window size (can be overridden by config)
  Size windowSize = const Size(600, 1024);
  
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
      minimumSize: const Size(400, 600),
      maximumSize: const Size(800, 1200),
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