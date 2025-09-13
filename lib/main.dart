import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:g_weather_forecast/firebase_options.dart';
import 'package:g_weather_forecast/presentations/main/main_menu.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'G-Weather-Forecast',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF5372F0),
          onPrimary: Colors.white,
          secondary: Color(0xFFE3F2FD),
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface: Color(0xFF6C757D),
          onSurface: Colors.white,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.rubikTextTheme(textTheme),
      ),
      home: const MainMenu(),
    );
  }
}