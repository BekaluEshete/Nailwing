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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _planeController;
  late Animation<double> _planeAnimation;
  Timer? _navigationTimer;
  bool _isDisposed = false;

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
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _planeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _planeController, curve: Curves.easeInOut),
    );

    // Navigation after 5 seconds
    _navigationTimer = Timer(const Duration(seconds: 5), () {
      if (!_isDisposed) {
        _navigateToOnboarding();
      }
    });
  }

  void _navigateToOnboarding() {
    if (!_isDisposed) {
      ref.read(splashViewModelProvider.notifier).navigateToOnboarding(context);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pulseController.dispose();
    _planeController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _navigationTimer?.cancel();
        _navigateToOnboarding();
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF38BDF8), // sky-400
                Colors.white,
                Color(0xFF0F172A), // slate-900
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Animated background elements
              _buildBackgroundElements(),

              // Main content
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with enhanced styling
                      _buildLogoSection(),
                      const SizedBox(height: 24),

                      // Brand name
                      _buildBrandName(),
                      const SizedBox(height: 24),

                      // Tagline
                      _buildTaglineSection(),
                      const SizedBox(height: 32),

                      // Loading indicator
                      _buildLoadingIndicator(),
                    ],
                  ),
                ),
              ),

              // Airplane animation
              _buildAirplaneAnimation(),

              // Tap hint
              _buildTapHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Top left circle
          Positioned(
            top: 64,
            left: 24,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Opacity(
                opacity: 0.7,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 32,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom right circle
          Positioned(
            bottom: 96,
            right: 32,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Opacity(
                opacity: 0.7,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7DD3FC).withOpacity(0.2), // sky-300
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7DD3FC).withOpacity(0.2),
                        blurRadius: 48,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Middle left circle
          Positioned(
            top: MediaQuery.of(context).size.height / 2,
            left: MediaQuery.of(context).size.width / 6,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Opacity(
                opacity: 0.7,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFF0F172A,
                    ).withOpacity(0.1), // slate-900
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.1),
                        blurRadius: 24,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect behind logo
        Container(
          width: 144,
          height: 144,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.3),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 32,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        // Logo container
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.9),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: _buildNileWingLogo()),
        ),
      ],
    );
  }

  Widget _buildNileWingLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF0EA5E9), // sky-500
            Color(0xFF0369A1), // sky-700
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.flight, color: Colors.white, size: 32),
    );
  }

  Widget _buildBrandName() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF0F172A), // slate-900
              Color(0xFF075985), // sky-700
              Color(0xFF0F172A), // slate-900
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: const Text(
            'NILE WING',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.0,
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
              colors: [
                Color(0xFF38BDF8), // sky-400
                Color(0xFF0EA5E9), // sky-500
              ],
            ),
            borderRadius: BorderRadius.all(Radius.circular(1)),
          ),
        ),
      ],
    );
  }

  Widget _buildTaglineSection() {
    return Column(
      children: [
        Text(
          'Connect During Layovers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B), // slate-800
            letterSpacing: 0.8,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Turn waiting time into meaningful connections with fellow travelers',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF475569), // slate-600
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 2,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0), // slate-200
            borderRadius: BorderRadius.circular(1),
          ),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Container(
              width: 64,
              height: 2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF38BDF8), // sky-400
                    Color(0xFF0EA5E9), // sky-500
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) => Opacity(
            opacity: _pulseAnimation.value.clamp(0.5, 1.0),
            child: Text(
              'Loading your journey...',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF64748B), // slate-500
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAirplaneAnimation() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.2,
      right: 16,
      child: AnimatedBuilder(
        animation: _planeController,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _planeAnimation.value),
          child: Opacity(
            opacity: 0.2,
            child: Container(
              width: 48,
              height: 48,
              child: const Icon(
                Icons.flight,
                color: Color(0xFF374151), // slate-700
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTapHint() {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) => Opacity(
          opacity: _pulseAnimation.value.clamp(0.5, 1.0),
          child: const Text(
            'Tap anywhere to continue',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8), // slate-400
            ),
          ),
        ),
      ),
    );
  }
}
