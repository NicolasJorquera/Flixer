import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark = ThemeData(
    useMaterial3: false,
    primaryColor: Colors.black,
    iconTheme: const IconThemeData(size: 30),
    textTheme: TextTheme(
      titleLarge: GoogleFonts.oswald(
        fontSize: 30,
        fontStyle: FontStyle.italic,
      ),
      displayLarge: GoogleFonts.roboto(
        fontSize: 25,
        color: Colors.white,
      ),
      displayMedium: GoogleFonts.roboto(
        fontSize: 20,
        color: Colors.white,
      ),
      displaySmall: GoogleFonts.roboto(
        fontSize: 15,
        color: Colors.white,
      ),
    ),
    colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color.fromRGBO(180, 0, 0, 1),
        onPrimary: Colors.white,
        secondary: Color.fromARGB(255, 150, 150, 150),
        onSecondary: Colors.white,
        error: Color.fromARGB(255, 180, 180, 0),
        onError: Colors.white,
        background: Colors.black,
        onBackground: Colors.white,
        surface: Color.fromARGB(255, 100, 100, 100),
        onSurface: Color.fromARGB(255, 150, 150, 150),
        onSurfaceVariant: Colors.white,
        surfaceTint: Color.fromARGB(255, 50, 50, 50)),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
    ),
  );

  static ThemeData light = ThemeData(
    useMaterial3: false,
    primaryColor: Colors.black,
    iconTheme: const IconThemeData(size: 30),
    textTheme: TextTheme(
      titleLarge: GoogleFonts.oswald(
        fontSize: 30,
        fontStyle: FontStyle.italic,
      ),
      displayLarge: GoogleFonts.roboto(
        fontSize: 30,
        color: Colors.black,
      ),
      displayMedium: GoogleFonts.roboto(
        fontSize: 20,
        color: Colors.black,
      ),
      displaySmall: GoogleFonts.roboto(
        fontSize: 15,
        color: Colors.black,
      ),
    ),
    colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color.fromRGBO(180, 0, 0, 1),
        onPrimary: Colors.white,
        secondary: Color.fromARGB(255, 150, 150, 150),
        onSecondary: Colors.white,
        error: Color.fromARGB(255, 180, 180, 0),
        onError: Colors.white,
        background: Colors.white,
        onBackground: Colors.black,
        surface: Color.fromARGB(255, 150, 150, 150),
        onSurface: Color.fromARGB(255, 200, 200, 200),
        onSurfaceVariant: Colors.white,
        surfaceTint: Colors.white),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
    ),
  );
}
