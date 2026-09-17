import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFFF28C28);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
    scaffoldBackgroundColor: const Color(0xFFF6F7F9),
    cardTheme: const CardThemeData(margin: EdgeInsets.zero),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF1B1F24),
    cardTheme: const CardThemeData(
      margin: EdgeInsets.zero,
      color: Color(0xFF2A2F36),
    ),
  );
}
