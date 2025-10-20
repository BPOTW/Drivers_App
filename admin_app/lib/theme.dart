import 'package:flutter/material.dart';

final ThemeData darkTealTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: const Color(0xFF121212),
  primaryColor: Colors.tealAccent,
  colorScheme: const ColorScheme.dark(primary: Colors.tealAccent),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    elevation: 0,
  ),
  cardColor: const Color(0xFF1E1E1E),
);
