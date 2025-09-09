import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async operations
  runApp(const ProviderScope(child: MyApp()));
}
