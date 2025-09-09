import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/viewmodels/onboarding_flow_viewmodel.dart';

final onboardingProvider = Provider<OnboardingViewModel>(
  (ref) => OnboardingViewModel(),
);
