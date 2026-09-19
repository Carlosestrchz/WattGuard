import 'package:flutter/material.dart';

class AppTheme {
  // ── Paleta principal (del mockup Figma) ─────────────────────────────────
  static const Color primary      = Color(0xFF2563EB); // Azul principal
  static const Color primaryDark  = Color(0xFF1D4ED8); // Azul oscuro (header)
  static const Color primaryLight = Color(0xFF3B82F6); // Azul claro

  static const Color background   = Color(0xFFF1F5F9); // Fondo general
  static const Color surface      = Color(0xFFFFFFFF); // Cards / superficies
  static const Color border       = Color(0xFFE2E8F0); // Bordes sutiles

  static const Color textPrimary   = Color(0xFF1E293B); // Texto principal
  static const Color textSecondary = Color(0xFF64748B); // Texto secundario

  static const Color success  = Color(0xFF22C55E); // Verde (activo)
  static const Color warning  = Color(0xFFF59E0B); // Ámbar (advertencia)
  static const Color error    = Color(0xFFEF4444); // Rojo (error / salir)
  static const Color inactive = Color(0xFF94A3B8); // Gris inactivo

  // Colores cíclicos para identificar nodos visualmente
  static const List<Color> nodeColors = [
    Color(0xFF2563EB), // azul
    Color(0xFF22C55E), // verde
    Color(0xFF8B5CF6), // violeta
    Color(0xFFF59E0B), // ámbar
    Color(0xFFEF4444), // rojo
  ];

  static Color nodeColor(int index) => nodeColors[index % nodeColors.length];

  // ── Tema ────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: primaryLight,
          surface: surface,
          error: error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 1),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          elevation: 8,
          shadowColor: Colors.black12,
          indicatorColor: primary.withAlpha(20),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 11, color: primary, fontWeight: FontWeight.w600);
            }
            return const TextStyle(fontSize: 11, color: textSecondary);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primary, size: 22);
            }
            return const IconThemeData(color: textSecondary, size: 22);
          }),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return Colors.white;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primary;
            return inactive;
          }),
        ),
        dividerTheme: const DividerThemeData(color: border, thickness: 1),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: inactive),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: textPrimary,
          contentTextStyle:
              const TextStyle(color: Colors.white, fontSize: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: primary.withAlpha(15),
          labelStyle:
              const TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
      );
}
