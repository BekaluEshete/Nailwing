import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final onboardingViewModelProvider = ChangeNotifierProvider<OnboardingViewModel>(
  (ref) => OnboardingViewModel(),
);

class OnboardingViewModel extends ChangeNotifier {
  final PageController pageController = PageController();
  int currentPage = 0;

  final List<Map<String, dynamic>> screens = [
    {
      "title": "Meet People While Travelling",
      "description":
          "Connect with fellow travelers during layovers and flights. Share experiences and make new friends on your journey.",
      "illustration": Icon(
        Icons.people_alt_rounded,
        size: 100,
        color: Color(0xFF0891B2),
      ),
    },
    {
      "title": "Real Time Location Matching",
      "description":
          "Get matched with travelers at your current airport or destination. Find people with similar interests nearby.",
      "illustration": Icon(
        Icons.location_on_rounded,
        size: 100,
        color: Color(0xFF0891B2),
      ),
    },
    {
      "title": "Chat and Explore Together",
      "description":
          "Start conversations, share travel tips, and plan activities together. Make your layover time enjoyable.",
      "illustration": Icon(
        Icons.chat_bubble_outline_rounded,
        size: 100,
        color: Color(0xFF0891B2),
      ),
    },
  ];

  void onPageChanged(int index) {
    currentPage = index;
    notifyListeners();
  }

  void nextPage() {
    if (currentPage < screens.length - 1) {
      currentPage++;
      pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void prevPage() {
    if (currentPage > 0) {
      currentPage--;
      pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void complete(BuildContext context) {
    context.go('/home');
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
