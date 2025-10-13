import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:nilewing/features/splash/splash_view_model.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with TickerProviderStateMixin {
  // Changed from SingleTickerProviderStateMixin
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _planeController;
  late Animation<double> _planeAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for circles and progress bar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Bouncing animation for airplane
    _planeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      reverseDuration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _planeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _planeController, curve: Curves.easeInOut),
    );

    // Navigation after 5 seconds
    Timer(const Duration(seconds: 5), () {
      ref.read(splashViewModelProvider.notifier).navigateToOnboarding(context);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _planeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ref
          .read(splashViewModelProvider.notifier)
          .navigateToOnboarding(context),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(color: Color(0xFF38BDF8)),
          child: Stack(
            children: [
              // Animated background circles
              Positioned(
                top: 64,
                left: 24,
                child: _buildGlowCircle(96, Colors.white.withOpacity(0.1)),
              ),
              Positioned(
                bottom: 96,
                right: 32,
                child: _buildGlowCircle(128, Colors.cyan.withOpacity(0.2)),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height / 2,
                left: MediaQuery.of(context).size.width / 6,
                child: _buildGlowCircle(80, Colors.black.withOpacity(0.1)),
              ),

              // Main content
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with glow
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow effect
                          Container(
                            width: 144,
                            height: 144,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 24,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          // Logo container
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.9),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/nile_wing_logo.png',
                              width: 64,
                              height: 64,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Brand name with gradient
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF0F172A),
                            Color(0xFF075985),
                            Color(0xFF0F172A),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'NILE WING',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Gradient underline
                      Container(
                        width: 80,
                        height: 2,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      const Text(
                        'Connect During Layovers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Loading indicator
                      _buildLoadingIndicator(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowCircle(double size, Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 24, spreadRadius: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: 64,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0), // slate-200
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) => Opacity(
          opacity: _pulseAnimation.value,
          child: Container(
            width: 64,
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ),
        ),
      ),
    );
  }
}
