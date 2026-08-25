import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ── Brand tokens ──────────────────────────────────────────────
const kNavy = Color(0xFF0D1B3E); // Turn360 deep navy (hero/headers)
const kInk = Color(0xFF0F172A); // primary text
const kMuted = Color(0xFF64748B); // secondary text
const kFaint = Color(0xFF94A3B8); // hints
const kLine = Color(0xFFE9EDF3); // hairline borders
const kBg = Color(0xFFF4F6FB); // app background
const kSuccess = Color(0xFF0EA96E);
const kDanger = Color(0xFFE11D48);
const kWarning = Color(0xFFEA580C);

/// Soft, layered card shadow used across the app.
const kCardShadow = [
  BoxShadow(color: Color(0x0A0F172A), blurRadius: 18, offset: Offset(0, 8)),
  BoxShadow(color: Color(0x05000000), blurRadius: 2, offset: Offset(0, 1)),
];

/// A premium 2-stop gradient from navy into the company's brand colour.
LinearGradient brandGradient(Color brand) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [kNavy, Color.lerp(brand, kNavy, 0.15) ?? brand],
    );

/// Semantic colour for an order/return status string.
Color statusColor(String s) {
  final v = s.toLowerCase();
  if (v.contains('deliver') || v.contains('complete') || v.contains('paid') || v.contains('approv')) return kSuccess;
  if (v.contains('cancel') || v.contains('return') || v.contains('reject')) return kDanger;
  if (v.contains('ship')) return const Color(0xFF2563EB);
  if (v.contains('pack') || v.contains('ready') || v.contains('process')) return const Color(0xFF7C3AED);
  if (v.contains('hold') || v.contains('pending') || v.contains('request')) return kWarning;
  return const Color(0xFF64748B);
}

BoxDecoration softCard({double radius = 20}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: kLine),
      boxShadow: kCardShadow,
    );

ThemeData buildTheme(Color brand) {
  final scheme = ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.light).copyWith(
    primary: brand,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: kInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(color: kInk, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: kLine)),
    ),
    dividerTheme: const DividerThemeData(color: kLine, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: kFaint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kLine)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kLine)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: brand, width: 1.6)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brand,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kInk,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: kLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: brand,
      side: const BorderSide(color: kLine),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: brand.withValues(alpha: 0.12),
      height: 66,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((s) =>
          IconThemeData(color: s.contains(WidgetState.selected) ? brand : kFaint)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: s.contains(WidgetState.selected) ? brand : kFaint)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kInk,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

const money = _Money();

class _Money {
  const _Money();
  String call(String symbol, num value) {
    final s = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    final parts = s.split('.');
    final digits = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$symbol$digits${parts.length > 1 ? '.${parts[1]}' : ''}';
  }
}
