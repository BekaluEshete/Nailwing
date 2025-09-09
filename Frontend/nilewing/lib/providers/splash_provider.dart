import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/splash_viewmodel.dart';

final splashProvider = Provider<SplashViewModel>((ref) => SplashViewModel());
