import 'package:flutter/material.dart';

class AppStyles {
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightForeground = Color(
    0xFF252525,
  ); // Approx OKLCH(0.145 0 0)
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardForeground = Color(0xFF252525);
  static const Color lightPopover = Color(0xFFFFFFFF); // Approx OKLCH(1 0 0)
  static const Color lightPopoverForeground = Color(0xFF252525);
  static const Color primary = Color(0xFF0891B2);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color primaryHover = Color(0xFF0E7490);
  static const Color secondary = Color(0xFF0F172A);
  static const Color secondaryForeground = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentForeground = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFF8FAFC);
  static const Color mutedForeground = Color(0xFF64748B);
  static const Color destructive = Color(0xFFDC2626);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color border = Color(0x260891B2); // RGBA(8, 145, 178, 0.15)
  static const Color input = Colors.transparent;
  static const Color inputBackground = Color(0xFFF8FAFC);
  static const Color switchBackground = Color(0xFFCBD5E1);
  static const Color ring = Color(0xFF0891B2);
  static const List<Color> chartColors = [
    Color(0xFF0891B2),
    Color(0xFF06B6D4),
    Color(0xFF0E7490),
    Color(0xFF155E75),
    Color(0xFF164E63),
  ];
  static const double radius = 8.0; // 0.5rem ≈ 8px

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkForeground = Color(0xFFF8FAFC);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardForeground = Color(0xFFF8FAFC);
  static const Color darkPopover = Color(0xFF1E293B);
  static const Color darkPopoverForeground = Color(0xFFF8FAFC);
  static const Color darkPrimary = Color(0xFF0891B2);
  static const Color darkPrimaryForeground = Color(0xFFFFFFFF);
  static const Color darkPrimaryHover = Color(0xFF06B6D4);
  static const Color darkSecondary = Color(0xFF334155);
  static const Color darkSecondaryForeground = Color(0xFFF8FAFC);
  static const Color darkAccent = Color(0xFF06B6D4);
  static const Color darkAccentForeground = Color(0xFF0F172A);
  static const Color darkMuted = Color(0xFF334155);
  static const Color darkMutedForeground = Color(0xFF94A3B8);
  static const Color darkDestructive = Color(0xFFDC2626);
  static const Color darkDestructiveForeground = Color(0xFFFFFFFF);
  static const Color darkBorder = Color(0x400891B2); // RGBA(8, 145, 178, 0.25)
  static const Color darkInput = Color(0xFF334155);
  static const Color darkInputBackground = Color(0xFF334155);
  static const Color darkRing = Color(0xFF0891B2);

  // Sidebar Colors
  static const Color sidebar = Color(0xFFFCFCFC); // Approx OKLCH(0.985 0 0)
  static const Color sidebarForeground = Color(
    0xFF252525,
  ); // Approx OKLCH(0.145 0 0)
  static const Color sidebarPrimary = Color(0xFF0891B2);
  static const Color sidebarPrimaryForeground = Color(0xFFFFFFFF);
  static const Color sidebarAccent = Color(0xFFF0F9FF);
  static const Color sidebarAccentForeground = Color(0xFF0C4A6E);
  static const Color sidebarBorder = Color(0xFFE2E8F0);
  static const Color sidebarRing = Color(0xFF0891B2);

  // Dark Sidebar Colors
  static const Color darkSidebar = Color(0xFF0F172A);
  static const Color darkSidebarForeground = Color(0xFFF8FAFC);
  static const Color darkSidebarPrimary = Color(0xFF0891B2);
  static const Color darkSidebarPrimaryForeground = Color(0xFFFFFFFF);
  static const Color darkSidebarAccent = Color(0xFF334155);
  static const Color darkSidebarAccentForeground = Color(0xFFF8FAFC);
  static const Color darkSidebarBorder = Color(0xFF334155);
  static const Color darkSidebarRing = Color(0xFF0891B2);

  // Typography
  static const TextStyle h1 = TextStyle(
    fontSize: 24.0, // --text-2xl equivalent
    fontWeight: FontWeight.w500, // --font-weight-medium
    height: 1.5,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 20.0, // --text-xl equivalent
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18.0, // --text-lg equivalent
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static const TextStyle h4 = TextStyle(
    fontSize: 16.0, // --text-base equivalent
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static const TextStyle p = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400, // --font-weight-normal
    height: 1.5,
  );
  static const TextStyle label = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static const TextStyle inputText = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ThemeData
  static ThemeData lightTheme = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: lightBackground,
    textTheme: const TextTheme(
      headlineLarge: h1,
      headlineMedium: h2,
      headlineSmall: h3,
      titleMedium: h4,
      bodyMedium: p,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: inputBackground,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: border),
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: primaryForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
    // Add more theme configurations as needed
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBackground,
    textTheme: const TextTheme(
      headlineLarge: h1,
      headlineMedium: h2,
      headlineSmall: h3,
      titleMedium: h4,
      bodyMedium: p,
    ).apply(bodyColor: darkForeground, displayColor: darkForeground),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: darkInputBackground,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: darkBorder),
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: darkPrimaryForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
    // Add more theme configurations as needed
  );
}
