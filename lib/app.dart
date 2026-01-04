import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'front/splash.dart';

/// ===========================================
/// APP CONFIGURATION
/// ===========================================
/// This file sets up:
/// - The MaterialApp (root of our Flutter app)
/// - Theme (colors, text styles)
/// - Routes (navigation between screens)
/// ===========================================

class BooklyApp extends StatelessWidget {
  const BooklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ---------- APP INFO ----------
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false, // removes debug banner
      
      // ---------- THEME ----------
      theme: ThemeData(
        // Use Material 3 design
        useMaterial3: true,
        
        // Color scheme based on our branding
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          tertiary: AppColors.accent,
          surface: AppColors.background,
        ),
        
        // Default background color
        scaffoldBackgroundColor: AppColors.background,
      ),
      
      // ---------- ROUTES ----------
      // Define all the screens and their paths
      initialRoute: '/', // starting screen
      routes: {
        '/': (context) => const SplashScreen(),
        // TODO: Add more routes as we create screens
        // '/onboarding': (context) => const OnboardingScreen(),
        // '/home': (context) => const HomeScreen(),
        // '/search': (context) => const SearchScreen(),
        // '/library': (context) => const LibraryScreen(),
        // '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}