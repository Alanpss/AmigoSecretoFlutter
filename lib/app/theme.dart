import 'package:flutter/material.dart';

/// Tema visual do aplicativo.
abstract final class AppTheme {
  static const Color _seedColor = Color(0xFF6A4C93);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.standard,
    );
  }
}
