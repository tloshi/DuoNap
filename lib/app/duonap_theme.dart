import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/duonap_baby.dart';

class DuoNapColors {
  const DuoNapColors._();

  static const Color ground = Color(0xFF0B0C1A);
  static const Color glow = Color(0xFF1B1D3D);
  static const Color surface = Color(0xFF15172B);
  static const Color raised = Color(0xFF1D2040);
  static const Color highlight = Color(0xFF23264A);
  static const Color text = Color(0xFFF4F2FF);
  static const Color muted = Color(0xFFA3A6C8);
  static const Color first = Color(0xFFF6BE7A);
  static const Color second = Color(0xFF7C9FF0);

  /// Bottom sheet, from the "D · Dialogu" mockup.
  static const Color sheet = Color(0xFF1A1C38);
  static const Color sheetBorder = Color(0xFF2A2D52);
  static const Color handle = Color(0xFF4A4E7A);

  /// Wells inside a sheet or card: steppers, the baby selector, text fields.
  static const Color inset = Color(0xFF101226);

  /// Unselected labels that still need to read clearly.
  static const Color soft = Color(0xFFC9CBE0);

  /// Night view ground, darker than the day.
  static const Color night = Color(0xFF070812);

  static Color ofBaby(DuoNapBabyId id) {
    return id == DuoNapBabyId.first ? first : second;
  }
}

class DuoNapTheme {
  const DuoNapTheme._();

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: DuoNapColors.ground,
      colorScheme: const ColorScheme.dark(
        primary: DuoNapColors.text,
        surface: DuoNapColors.surface,
      ),
    );
    final textTheme = GoogleFonts.soraTextTheme(base.textTheme).apply(
      bodyColor: DuoNapColors.text,
      displayColor: DuoNapColors.text,
    );
    return base.copyWith(textTheme: textTheme);
  }
}
