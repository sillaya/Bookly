import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'front/splash.dart';
import 'front/accueil.dart';


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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          tertiary: AppColors.accent,
          surface: AppColors.background,
        ),
        
        scaffoldBackgroundColor: AppColors.background,
        
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: AppColors.primary),
          bodyMedium: TextStyle(color: AppColors.primary),
        ),
      ),
      
      // ---------- ROUTES ----------
      // Define all the screens and their paths
      initialRoute: '/', // starting screen
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const AccueilScreen(),
      },
    );
  }
}