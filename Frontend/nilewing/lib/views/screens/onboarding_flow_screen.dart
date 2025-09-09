import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/providers/onboarding_flow_provider.dart';
import 'package:nilewing/utils/styles.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(onboardingProvider);
    final currentScreen = viewModel.currentScreen;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF1F5F9),
              Color(0xFFECFEFF),
              Color(0xFFBFDBFE),
            ], // Approx from-slate-50 via-cyan-50 to-blue-50
          ),
        ),
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: index == currentScreen ? 32.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      color: index == currentScreen
                          ? AppStyles.primary
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  );
                }),
              ),
            ),

            // Main Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 32.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration
                    Container(
                      margin: const EdgeInsets.only(bottom: 24.0),
                      height: 192.0,
                      child: _buildIllustration(currentScreen),
                    ),

                    // Title and Description
                    Column(
                      children: [
                        Text(
                          viewModel.screens[currentScreen]['title'],
                          style: AppStyles.h2.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          viewModel.screens[currentScreen]['description'],
                          style: AppStyles.p.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onBackground.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (currentScreen < 2)
                    ElevatedButton(
                      onPressed: viewModel.nextScreen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.primary,
                        foregroundColor: AppStyles.primaryForeground,
                        minimumSize: const Size(double.infinity, 48.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radius),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Continue'),
                          SizedBox(width: 8.0),
                          Icon(Icons.chevron_right, size: 20.0),
                        ],
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => viewModel.completeOnboarding(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.primary,
                        foregroundColor: AppStyles.primaryForeground,
                        minimumSize: const Size(double.infinity, 48.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radius),
                        ),
                      ),
                      child: const Text('Get Started'),
                    ),
                  const SizedBox(height: 12.0),
                  TextButton(
                    onPressed: () => viewModel.completeOnboarding(context),
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  if (currentScreen > 0)
                    TextButton(
                      onPressed: viewModel.prevScreen,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.chevron_left, size: 20.0),
                          SizedBox(width: 4.0),
                          Text(
                            'Back',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(int screenIndex) {
    switch (screenIndex) {
      case 0:
        return _buildFirstScreenIllustration();
      case 1:
        return _buildSecondScreenIllustration();
      case 2:
        return _buildThirdScreenIllustration();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFirstScreenIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Airplane
        Positioned(
          top: 16.0,
          child: Transform.rotate(
            angle: 0.785, // 45 degrees in radians
            child: Icon(Icons.flight, size: 48.0, color: AppStyles.primary),
          ),
        ),
        // People talking (left)
        Positioned(
          bottom: 32.0,
          left: 16.0,
          child: Row(
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3B82F6),
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.people,
                  size: 20.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    width: 48.0,
                    height: 6.0,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 4.0),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    width: 32.0,
                    height: 6.0,
                    color: Colors.grey[200],
                  ),
                ],
              ),
            ],
          ),
        ),
        // People talking (right)
        Positioned(
          bottom: 32.0,
          right: 16.0,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    width: 56.0,
                    height: 6.0,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 4.0),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    width: 40.0,
                    height: 6.0,
                    color: Colors.grey[200],
                  ),
                ],
              ),
              const SizedBox(width: 8.0),
              Container(
                width: 40.0,
                height: 40.0,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF22D3EE), Color(0xFF06B6D4)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF06B6D4),
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.people,
                  size: 20.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Connection lines
        Container(
          width: 96.0,
          height: 96.0,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppStyles.primary.withOpacity(0.3),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(48.0),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondScreenIllustration() {
    return Container(
      width: double.infinity,
      height: 192.0,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFF93C5FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8.0)],
      ),
      child: Stack(
        children: [
          // Grid lines
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: GridView.count(
                crossAxisCount: 4,
                childAspectRatio: 1.0,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  12,
                  (index) => Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Location pins
          Positioned(
            top: 32.0,
            left: 32.0,
            child: _buildLocationPin(
              const Color(0xFFF87171),
              const Duration(milliseconds: 0),
            ),
          ),
          Positioned(
            top: 48.0,
            right: 40.0,
            child: _buildLocationPin(
              const Color(0xFF60A5FA),
              const Duration(milliseconds: 300),
            ),
          ),
          Positioned(
            bottom: 32.0,
            left: 48.0,
            child: _buildLocationPin(
              const Color(0xFF9333EA),
              const Duration(milliseconds: 600),
            ),
          ),
          // Your location
          const Positioned(top: 96.0, left: 144.0, child: _YourLocation()),
          // Connection radius
          const Positioned(top: 96.0, left: 144.0, child: _ConnectionRadius()),
        ],
      ),
    );
  }

  Widget _buildThirdScreenIllustration() {
    return Container(
      width: double.infinity,
      height: 192.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8.0)],
      ),
      child: Stack(
        children: [
          // Header
          Container(
            height: 40.0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20.0,
                      height: 20.0,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      width: 48.0,
                      height: 6.0,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ],
                ),
                const Icon(Icons.message, size: 16.0, color: Colors.white),
              ],
            ),
          ),
          // Chat messages
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildChatMessage(
                  const Color(0xFF60A5FA),
                  Alignment.centerLeft,
                ),
                _buildChatMessage(AppStyles.primary, Alignment.centerRight),
                _buildChatMessage(
                  const Color(0xFF9333EA),
                  Alignment.centerLeft,
                ),
              ],
            ),
          ),
          // Input area
          const Positioned(
            left: 8.0,
            right: 8.0,
            bottom: 8.0,
            child: _ChatInput(),
          ),
          // Activity indicators
          const Positioned(top: -4.0, right: -4.0, child: _ActivityIndicator()),
          // Floating chat bubbles
          const Positioned(
            top: -8.0,
            left: -8.0,
            child: _FloatingBubble(
              const Color(0xFF60A5FA),
              const Duration(milliseconds: 0),
            ),
          ),
          const Positioned(
            bottom: -8.0,
            right: -8.0,
            child: _FloatingBubble(
              const Color(0xFF9333EA),
              const Duration(milliseconds: 500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPin(Color color, Duration delay) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1.0 + (0.1 * value),
            child: Icon(Icons.location_pin, size: 24.0, color: color),
          );
        },
      ),
    );
  }

  Widget _buildChatMessage(Color color, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: alignment == Alignment.centerLeft
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Container(
              width: 56.0,
              height: 6.0,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 4.0),
            Container(
              width: 40.0,
              height: 6.0,
              color: Colors.white.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _YourLocation extends StatelessWidget {
  const _YourLocation();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.0,
      height: 20.0,
      decoration: BoxDecoration(
        color: AppStyles.primary,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4.0)],
      ),
    );
  }
}

class _ConnectionRadius extends StatelessWidget {
  const _ConnectionRadius();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80.0,
      height: 80.0,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppStyles.primary.withOpacity(0.2),
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(40.0),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(width: 64.0, height: 6.0, color: Colors.grey[200]),
          ),
          Container(
            width: 20.0,
            height: 20.0,
            color: AppStyles.primary.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}

class _ActivityIndicator extends StatelessWidget {
  const _ActivityIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.0,
      height: 24.0,
      decoration: const BoxDecoration(
        color: Color(0xFF10B981),
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      child: const Center(
        child: Icon(Icons.circle, size: 8.0, color: Colors.white),
      ),
    );
  }
}

class _FloatingBubble extends StatefulWidget {
  final Color color;
  final Duration delay;

  const _FloatingBubble(this.color, this.delay);

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
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
    _animation =
        Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        )..addListener(() {
          if (mounted) setState(() {});
        });
    Future.delayed(widget.delay, () => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _animation.value,
      child: Container(
        width: 24.0,
        height: 24.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.color.withOpacity(0.6), widget.color],
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 8.0),
          ],
        ),
      ),
    );
  }
}
