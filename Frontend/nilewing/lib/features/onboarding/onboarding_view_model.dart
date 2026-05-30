import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import 'dart:ui';

final onboardingViewModelProvider =
    StateNotifierProvider<OnboardingViewModel, OnboardingState>((ref) {
      return OnboardingViewModel();
    });

class OnboardingState {
  final int currentPage;
  final PageController pageController;
  final List<Map<String, dynamic>> screens;

  OnboardingState({
    required this.currentPage,
    required this.pageController,
    required this.screens,
  });

  OnboardingState copyWith({
    int? currentPage,
    PageController? pageController,
    List<Map<String, dynamic>>? screens,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      pageController: pageController ?? this.pageController,
      screens: screens ?? this.screens,
    );
  }
}

class OnboardingViewModel extends StateNotifier<OnboardingState> {
  OnboardingViewModel()
    : super(
        OnboardingState(
          currentPage: 0,
          pageController: PageController(),
          screens: [
            {
              'title': 'Meet People While Travelling',
              'description':
                  'Connect with fellow travelers during layovers and flights. Share experiences and make new friends on your journey.',
              'illustration': _buildFirstIllustration(),
            },
            {
              'title': 'Real Time Location Matching',
              'description':
                  'Get matched with travelers at your current airport or destination. Find people with similar interests nearby.',
              'illustration': _buildSecondIllustration(),
            },
            {
              'title': 'Chat and Explore Together',
              'description':
                  'Start conversations, share travel tips, and plan activities together. Make your layover time more enjoyable and productive.',
              'illustration': _buildThirdIllustration(),
            },
          ],
        ),
      );

  static Widget _buildFirstIllustration() {
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Glow
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.blue.shade100.withOpacity(0.5), Colors.transparent],
                ),
              ),
            ),
          ),

          // Main Airplane Icon
          Center(
            child: TweenAnimationBuilder(
              duration: const Duration(seconds: 2),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Transform.translate(
                  offset: Offset(0, 5 * (1 - value)),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/images/nilewing_logo.jpeg',
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating Avatars
          Positioned(
            top: 40,
            left: 20,
            child: _buildFloatingAvatar(Icons.person, Colors.orange.shade400),
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: _buildFloatingAvatar(Icons.person_3, Colors.purple.shade400),
          ),
          Positioned(
            top: 140,
            left: 40,
            child: _buildFloatingAvatar(Icons.person_2, Colors.green.shade400),
          ),
        ],
      ),
    );
  }

  static Widget _buildFloatingAvatar(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  static Widget _buildSecondIllustration() {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Effect
          ...List.generate(3, (index) {
            return TweenAnimationBuilder(
              duration: Duration(seconds: 2 + index),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Container(
                  width: 100 + (value * 100),
                  height: 100 + (value * 100),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.shade400.withOpacity(1 - value),
                      width: 2,
                    ),
                  ),
                );
              },
            );
          }),

          // Center Location Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          // Small Map Markers
          Positioned(
            top: 20,
            right: 40,
            child: Icon(Icons.location_on_outlined, size: 24, color: Colors.blue.shade300),
          ),
          Positioned(
            bottom: 40,
            left: 30,
            child: Icon(Icons.location_on_outlined, size: 28, color: Colors.cyan.shade300),
          ),
        ],
      ),
    );
  }

  static Widget _buildThirdIllustration() {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Chat Bubbles Layout
          Positioned(
            top: 10,
            left: 20,
            child: _buildChatBubble("Hey! 👋", true),
          ),
          Positioned(
            top: 80,
            right: 10,
            child: _buildChatBubble("Ready to explore?", false),
          ),
          Positioned(
            bottom: 30,
            left: 40,
            child: _buildChatBubble("Let's go! ✈️", true),
          ),

          // Connection Line
          CustomPaint(
            size: const Size(200, 150),
            painter: ConnectionLinePainter(),
          ),
        ],
      ),
    );
  }

  static Widget _buildChatBubble(String text, bool isLeft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isLeft ? Colors.white : Colors.blue.shade600,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isLeft ? 0 : 16),
          bottomRight: Radius.circular(isLeft ? 16 : 0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isLeft ? Colors.blue.shade900 : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  void onPageChanged(int index) {
    state = state.copyWith(currentPage: index);
  }

  void nextPage() {
    if (state.currentPage < state.screens.length - 1) {
      state.pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void prevPage() {
    if (state.currentPage > 0) {
      state.pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void complete(BuildContext context) async {
    await TokenStorage().saveHasSeenOnboarding(true);
    if (context.mounted) {
      context.go('/registration');
    }
  }

  @override
  void dispose() {
    state.pageController.dispose();
    super.dispose();
  }
}

class ConnectionLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade200.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.2);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5,
      size.width * 0.8,
      size.height * 0.4,
    );

    // Draw dashed path
    for (double i = 0; i < 1.0; i += 0.1) {
      final p1 = _getPathPoint(path, i);
      final p2 = _getPathPoint(path, i + 0.05);
      canvas.drawLine(p1, p2, paint);
    }
  }

  Offset _getPathPoint(Path path, double t) {
    final metrics = path.computeMetrics().first;
    return metrics.getExtractForPercent(t).getBounds().center;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension on PathMetric {
  Path getExtractForPercent(double percent) {
    return extractPath(0, length * percent);
  }
}
