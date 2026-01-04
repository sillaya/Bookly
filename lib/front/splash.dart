import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// ===========================================
/// SPLASH SCREEN
/// ===========================================
/// This is the first screen users see when
/// opening the app. It shows:
/// - The Bookly logo (animated fade + scale)
/// - The tagline (animated fade)
/// 
/// After 3 seconds, it navigates to the next screen.
/// ===========================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  
  // Animation controller manages our animations
  late AnimationController _controller;
  
  // Two animations: one for fade (opacity), one for scale (size)
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize the animation controller
    // Duration: how long the animation takes
    _controller = AnimationController(
      vsync: this, // prevents animations when screen is not visible
      duration: AppDurations.splashAnimation,
    );

    // Fade animation: goes from 0 (invisible) to 1 (fully visible)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn, // starts slow, ends fast
    ));

    // Scale animation: goes from 0.8 (80% size) to 1.0 (full size)
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // slight bounce at the end
    ));

    // Start the animation
    _controller.forward();

    // After 3 seconds, navigate to next screen
    //_navigateToNextScreen();
  }

  /// Waits for splash duration, then navigates to next screen
  void _navigateToNextScreen() {
    Future.delayed(AppDurations.splashWait, () {
      // TODO: Navigate to onboarding or home screen
      // For now, we'll just print a message
      // Later we'll replace this with actual navigation
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  @override
  void dispose() {
    // Always dispose controllers to free memory
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color from our branding
      backgroundColor: AppColors.background,
      
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          // The content that gets animated
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ---------- LOGO ----------
              Image.asset(
                'images/logo.jpg',
                width: 200,
                height: 200,
              ),
              
              const SizedBox(height: 20),
              
              // ---------- TAGLINE ----------
              Text(
                AppStrings.tagline,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}