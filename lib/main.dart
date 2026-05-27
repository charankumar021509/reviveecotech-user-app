import 'dart:ui';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'package:revive_eco_tech_app/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:easy_localization/easy_localization.dart';
// --- Global Constants ---
const kPrimaryColor = Color(0xFF013856);
const kAccentColor = Color(0xFFa7cd47);
const kCreamColor = Color(0xFFfcf3e2);

// ─────────────────────────────────────────────────────────────
// Debug Logger (Only runs in Debug Mode)
// ─────────────────────────────────────────────────────────────
Future<void> logFirebaseProjectInfo() async {
  final app = Firebase.app();
  final options = app.options;

  // print('------------------ FIREBASE CONFIG CHECK ------------------');
  // print('Project ID:       ${options.projectId}');
  // print('App ID:           ${options.appId}');
  // print('Storage Bucket:   ${options.storageBucket}');
  // print('------------------------------------------------------------');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 100;
PaintingBinding.instance.imageCache.maximumSizeBytes =
    1024 * 1024 * 200;
await EasyLocalization.ensureInitialized();
  // ✅ 1. Set System UI (Transparent Status Bar)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Dark icons for cream bg
    systemNavigationBarColor: Colors.white, // Bottom nav bar color
  ));

  // ✅ 2. Lock Orientation (Optional, prevents layout breaking)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ✅ 3. Secure Logging (Only in Debug)
    if (kDebugMode) {
      await logFirebaseProjectInfo();
    }

    // ✅ 4. Initialize App Check
    // Note: If running on Emulator, switch androidProvider to AndroidProvider.debug
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );

  } catch (e) {
    debugPrint("⚠️ Firebase Initialization Failed: $e");
  }

  runApp(

  EasyLocalization(

    supportedLocales: const [

      Locale('en'),
      Locale('hi'),
      Locale('te'),
    ],

    path: 'assets/translations',

    fallbackLocale:
        const Locale('en'),

    child: ReviveApp(),
  ),
);

}

// ✅ 5. Centralized App Widget
class ReviveApp extends StatelessWidget {
  ReviveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates:
    context.localizationDelegates,

supportedLocales:
    context.supportedLocales,

locale:
    context.locale,
      title: 'Revive Eco',
      debugShowCheckedModeBanner: false,

      // ✅ 6. GLOBAL THEME ENGINE
      // This ensures your Font and Colors apply to LaunchPage & Login too!
      theme: ThemeData(
        fontFamily: 'RedHatDisplay', // Make sure this is in pubspec.yaml
        useMaterial3: true,
        // This prevents Material widgets from firing their own vibrations,
        // allowing your GlobalHapticWrapper to handle everything cleanly.
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: kCreamColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          secondary: kAccentColor,
          surface: kCreamColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: kCreamColor,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kAccentColor,
            foregroundColor: kPrimaryColor,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),

      home: const AuthWrapper(),
    );
  }
}