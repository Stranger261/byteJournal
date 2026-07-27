import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens, shared by both light and dark themes via ThemeExtension
/// so widgets can read `Theme.of(context).extension<DevlogColors>()!`.
class DevlogColors extends ThemeExtension<DevlogColors> {
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color secondary;
  final Color muted;
  final Color border;
  final Color accent;
  final Color accentText;
  final Color accentSoft;
  final Color danger;
  final Color success;

  const DevlogColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.secondary,
    required this.muted,
    required this.border,
    required this.accent,
    required this.accentText,
    required this.accentSoft,
    required this.danger,
    required this.success,
  });

  static const light = DevlogColors(
    bg: Color(0xFFF5F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0F1F4),
    text: Color(0xFF14171A),
    secondary: Color(0xFF5B6470),
    muted: Color(0xFF8A93A0),
    border: Color(0xFFE1E4E9),
    accent: Color(0xFF375DFB),
    accentText: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFEAEFFF),
    danger: Color(0xFFD8443C),
    success: Color(0xFF1E8E5A),
  );

  static const dark = DevlogColors(
    bg: Color(0xFF0D1117),
    surface: Color(0xFF151A21),
    surfaceAlt: Color(0xFF1B222B),
    text: Color(0xFFE6E9EE),
    secondary: Color(0xFF94A0AD),
    muted: Color(0xFF5F6975),
    border: Color(0xFF262C35),
    accent: Color(0xFF7C97FF),
    accentText: Color(0xFF0D1117),
    accentSoft: Color(0xFF1C2338),
    danger: Color(0xFFF0776E),
    success: Color(0xFF3DDC84),
  );

  @override
  DevlogColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? text,
    Color? secondary,
    Color? muted,
    Color? border,
    Color? accent,
    Color? accentText,
    Color? accentSoft,
    Color? danger,
    Color? success,
  }) {
    return DevlogColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      text: text ?? this.text,
      secondary: secondary ?? this.secondary,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      accentSoft: accentSoft ?? this.accentSoft,
      danger: danger ?? this.danger,
      success: success ?? this.success,
    );
  }

  @override
  DevlogColors lerp(ThemeExtension<DevlogColors>? other, double t) {
    if (other is! DevlogColors) return this;
    return DevlogColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      text: Color.lerp(text, other.text, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

/// Terminal/dev-editor mono face, used sparingly for the brand mark,
/// timestamps, commit hashes and gutter numbers.
TextStyle devlogMono(BuildContext context, {double size = 11, Color? color}) {
  final c = color ?? Theme.of(context).extension<DevlogColors>()!.muted;
  return GoogleFonts.jetBrainsMono(fontSize: size, color: c);
}

ThemeData buildDevlogTheme(DevlogColors c, Brightness brightness) {
  final base = GoogleFonts.interTextTheme();
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: c.bg,
    textTheme: base.apply(bodyColor: c.text, displayColor: c.text),
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.accentText,
      secondary: c.accent,
      onSecondary: c.accentText,
      error: c.danger,
      onError: c.accentText,
      surface: c.surface,
      onSurface: c.text,
    ),
    extensions: [c],
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.text,
      contentTextStyle: TextStyle(color: c.bg, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.accent, width: 1.4),
      ),
      hintStyle: TextStyle(color: c.muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.accentText,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
