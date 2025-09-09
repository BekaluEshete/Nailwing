import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/styles.dart';
import 'screens/splash_screen.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  Future<ThemeMode> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'system';
    return theme == 'dark'
        ? ThemeMode.dark
        : theme == 'light'
        ? ThemeMode.light
        : ThemeMode.system;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return FutureBuilder<ThemeMode>(
      future: _loadThemeMode(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          ref.read(themeModeProvider.notifier).state =
              snapshot.data ?? ThemeMode.system;
          return MaterialApp(
            title: 'Nilewing',
            theme: AppStyles.lightTheme,
            darkTheme: AppStyles.darkTheme,
            themeMode: themeMode,
            home: const SplashScreen(), // Start with SplashScreen
          );
        }
        return const SizedBox.shrink(); // Placeholder while loading
      },
    );
  }
}
