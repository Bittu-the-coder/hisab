import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static final display = GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );
  static final titleL = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );
  static final titleM = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static final bodyL = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static final bodyM = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static final label = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );
  static final caption = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );
}
