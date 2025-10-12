import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/home/view/home_view';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async operations
  runApp(const ProviderScope(child: MyApp()));
}
