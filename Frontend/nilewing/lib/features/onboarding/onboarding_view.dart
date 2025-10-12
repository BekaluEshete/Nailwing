import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/features/onboarding/onboarding_view_model.dart';

class OnboardingView extends ConsumerWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(onboardingViewModelProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFE0F2FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    viewModel.screens.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: index == viewModel.currentPage ? 24 : 8,
                      decoration: BoxDecoration(
                        color: index == viewModel.currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: PageView.builder(
                  controller: viewModel.pageController,
                  onPageChanged: (index) => ref
                      .read(onboardingViewModelProvider.notifier)
                      .onPageChanged(index),
                  itemCount: viewModel.screens.length,
                  itemBuilder: (context, index) {
                    final screen = viewModel.screens[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Illustration placeholder
                          SizedBox(
                            height: 220,
                            child: screen['illustration'] as Widget,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            screen['title'] as String,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            screen['description'] as String,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Main Button
                    ElevatedButton(
                      onPressed: () {
                        if (viewModel.currentPage <
                            viewModel.screens.length - 1) {
                          ref
                              .read(onboardingViewModelProvider.notifier)
                              .nextPage();
                        } else {
                          ref
                              .read(onboardingViewModelProvider.notifier)
                              .complete(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        viewModel.currentPage < viewModel.screens.length - 1
                            ? 'Continue'
                            : 'Get Started',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Skip
                    TextButton(
                      onPressed: () => ref
                          .read(onboardingViewModelProvider.notifier)
                          .complete(context),
                      child: const Text("Skip for now"),
                    ),

                    // Back
                    if (viewModel.currentPage > 0)
                      TextButton.icon(
                        onPressed: () => ref
                            .read(onboardingViewModelProvider.notifier)
                            .prevPage(),
                        icon: const Icon(Icons.chevron_left),
                        label: const Text("Back"),
                      ),
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
