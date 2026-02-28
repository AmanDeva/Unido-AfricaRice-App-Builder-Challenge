import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized before calling SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  // Check if the user has already onboarded
  final prefs = await SharedPreferences.getInstance();
  final bool hasOnboarded = prefs.getBool('hasOnboarded') ?? false;

  runApp(RiceQualityApp(hasOnboarded: hasOnboarded));
}

class RiceQualityApp extends StatelessWidget {
  final bool hasOnboarded;

  const RiceQualityApp({super.key, required this.hasOnboarded});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Rice Scan',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      // If they onboarded, go to Home. Otherwise, go to Onboarding.
      home: hasOnboarded ? const HomeScreen() : const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
