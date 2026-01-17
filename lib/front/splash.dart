import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<double> _taglineScaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOutBack),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _taglineFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    ));
    _taglineScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
    ));

    _controller.forward();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Future.delayed(AppDurations.splashWait, () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = _flipAnimation.value * math.pi;

            final isFlipped = _flipAnimation.value > 0.5;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) 
                    ..rotateY(angle),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isFlipped ? AppColors.background : AppColors.primary.withValues(alpha: 0.1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(isFlipped ? math.pi : 0),
                        child: Image.asset(
                          'images/logo.png',
                          width: 180,
                          height: 180,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Opacity(
                  opacity: _taglineFadeAnimation.value,
                  child: Transform.scale(
                    scale: _taglineScaleAnimation.value,
                    child: Text(
                      AppStrings.tagline,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}