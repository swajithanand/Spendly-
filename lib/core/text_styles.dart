import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  // Serif display — replaces Instrument Serif
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 40,
        height: 1.04,
        letterSpacing: -0.4,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
      );

  static TextStyle get displayLargeItalic => GoogleFonts.playfairDisplay(
        fontSize: 40,
        height: 1.04,
        letterSpacing: -0.4,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: AppColors.ink2,
      );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
        fontSize: 28,
        height: 1.1,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
      );

  static TextStyle get displayMediumItalic => GoogleFonts.playfairDisplay(
        fontSize: 28,
        height: 1.1,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: AppColors.ink2,
      );

  // Numeric display (tabular)
  static TextStyle get numericHero => GoogleFonts.playfairDisplay(
        fontSize: 44,
        height: 1.05,
        letterSpacing: -0.44,
        fontWeight: FontWeight.w400,
        color: AppColors.onInkStrong,
        fontFeatures: [const FontFeature.tabularFigures()],
      );

  static TextStyle get numericLarge => GoogleFonts.playfairDisplay(
        fontSize: 30,
        height: 1.0,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        fontFeatures: [const FontFeature.tabularFigures()],
      );

  static TextStyle get numericMedium => GoogleFonts.playfairDisplay(
        fontSize: 34,
        height: 1.0,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        fontFeatures: [const FontFeature.tabularFigures()],
      );

  static TextStyle get numericSmall => GoogleFonts.playfairDisplay(
        fontSize: 28,
        height: 1.0,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        fontFeatures: [const FontFeature.tabularFigures()],
      );

  static TextStyle get amountSheet => GoogleFonts.playfairDisplay(
        fontSize: 56,
        height: 1.05,
        letterSpacing: -0.84,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        fontFeatures: [const FontFeature.tabularFigures()],
      );

  // Sans-serif body — replaces Geist
  static TextStyle get body => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
      );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      );

  static TextStyle get bodySemiBold => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      );

  static TextStyle get bodySmallMedium => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.muted,
      );

  static TextStyle get caption => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.muted,
        letterSpacing: 0.24,
      );

  static TextStyle get eyebrow => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.muted,
        letterSpacing: 1.54,
      );

  static TextStyle get keypad => GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        fontFeatures: [const FontFeature.tabularFigures()],
      );

  static TextStyle get button => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.075,
        color: AppColors.onInk,
      );
}
