import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/providers/splash_provider.dart';
import 'package:nilewing/utils/styles.dart';

import '../screens/home_screen.dart';
// Assuming you have the styles from previous response

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(splashProvider);

    // Navigate to HomeScreen after a delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.navigateAfterDelay(context);
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF38BDF8),
              Color(0xFFFFFFFF),
              Color(0xFF64748B),
            ], // Approx from-sky-400 via-white to-slate-900
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            Positioned(
              top: 64,
              left: 24,
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              bottom: 96,
              right: 32,
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height / 2,
              left: MediaQuery.of(context).size.width / 6,
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const SizedBox.expand(),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with glow effect
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppStyles.radius),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/nilewing_logo.png', // Replace with your logo path
                      width: 64,
                      height: 64,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Brand name
                  Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF64748B),
                            Color(0xFF38BDF8),
                            Color(0xFF64748B),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'NILE WING',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 4,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tagline
                  Column(
                    children: [
                      const Text(
                        'Connect During Layovers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Turn waiting time into meaningful connections with fellow travelers',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Loading indicator
                  Column(
                    children: [
                      Container(
                        width: 64,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const LinearProgressIndicator(
                          value: null,
                          color: Color(0xFF38BDF8),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Loading your journey...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Airplane animation
            Positioned(
              top: MediaQuery.of(context).size.height / 5,
              right: 16,
              child: AnimatedOpacity(
                opacity: 0.2,
                duration: const Duration(milliseconds: 500),
                child: BounceAnimation(
                  child: Icon(Icons.flight, size: 48, color: Colors.grey[700]),
                ),
              ),
            ),

            // Tap hint
            Positioned(
              bottom: 32,
              left: MediaQuery.of(context).size.width / 2,
              child: const Text(
                'Tap anywhere to continue',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Bounce Animation Widget
class BounceAnimation extends StatefulWidget {
  final Widget child;

  const BounceAnimation({super.key, required this.child});

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: widget.child);
      },
    );
  }
}
