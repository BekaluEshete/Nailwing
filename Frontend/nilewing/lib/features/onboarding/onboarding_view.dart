import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/features/onboarding/onboarding_view_model.dart';

class OnboardingView extends ConsumerWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final notifier = ref.read(onboardingViewModelProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFf8fafc), // slate-50
              Color(0xFFecfeff), // cyan-50
              Color(0xFFf0f9ff), // blue-50
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    state.screens.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: index == state.currentPage ? 32 : 8,
                      decoration: BoxDecoration(
                        color: index == state.currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: PageView.builder(
                  controller: state.pageController,
                  onPageChanged: notifier.onPageChanged,
                  itemCount: state.screens.length,
                  itemBuilder: (context, index) {
                    final screen = state.screens[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Illustration
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: screen['illustration'] as Widget,
                          ),

                          // Content
                          const SizedBox(height: 24),
                          Text(
                            screen['title'] as String,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                  color: Colors.grey.shade900,
                                  height: 1.3,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              screen['description'] as String,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    height: 1.5,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Main action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (state.currentPage < state.screens.length - 1) {
                            notifier.nextPage();
                          } else {
                            notifier.complete(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              state.currentPage < state.screens.length - 1
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFF007AFF), // Primary blue
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Colors.blue.shade200.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              state.currentPage < state.screens.length - 1
                                  ? 'Continue'
                                  : 'Get Started',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (state.currentPage <
                                state.screens.length - 1) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, size: 20),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Skip button (only show on first two screens)
                    if (state.currentPage < state.screens.length - 1)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => notifier.complete(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Skip for now",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    // Back button (only show when not on first screen)
                    if (state.currentPage > 0) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => notifier.prevPage(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_left, size: 20),
                        label: const Text(
                          "Back",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
