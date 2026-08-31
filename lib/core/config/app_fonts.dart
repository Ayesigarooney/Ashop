import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central font configuration for Ashop.
///
/// Typography choices for traders & shop owners:
///
/// HEADING  →  Plus Jakarta Sans
///   Modern geometric sans-serif, extremely crisp and clean.
///   Excellent weight range (400–800) for visual hierarchy and premium feel.
///   Used in state-of-the-art SaaS dashboards and enterprise interfaces.
///   Numbers and uppercase text are beautifully proportioned.
///
/// BODY     →  Inter
///   The industry standard for user interfaces and dashboards.
///   Highly legible at small sizes on shop counters or mobile displays.
///   Provides superb numeric scanning and is horizontally compact,
///   which directly prevents text layout overflows.
///
/// SIZE SCALE (optimized for quick scanning):
///   xs   10 — badges, timestamps, captions
///   sm   12 — secondary labels, subtitles
///   md   14 — body text, list items, form fields
///   lg   16 — section headers, card titles
///   xl   20 — screen titles, key values
///   2xl  24 — large amounts, stat values
///   3xl  32 — hero revenue figures
class AppFonts {
  AppFonts._();

  // ── Heading font (Plus Jakarta Sans) ───────────────────────────────────────

  /// Screen titles, card headings, button labels, section labels.
  static TextStyle heading({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing ?? _headingSpacing(fontSize),
    height: height,
  );

  // ── Body & Number font (Inter) ─────────────────────────────────────────────

  /// Body text, descriptions, list subtitles, form hints.
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height ?? 1.45,
  );

  /// Numeric values — Inter with clean legibility and compact width.
  /// Use for prices, quantities, totals.
  static TextStyle number({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) => GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: -0.3,
    height: 1.1,
  );

  // ── Convenience shorthands ─────────────────────────────────────────────────

  /// App bar / screen title
  static TextStyle get appBarTitle =>
      heading(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3);

  /// Section header (e.g. "Quick Actions", "Recent Sales")
  static TextStyle get sectionTitle =>
      heading(fontSize: 15, fontWeight: FontWeight.w700);

  /// Card / tile primary label
  static TextStyle get cardTitle =>
      heading(fontSize: 14, fontWeight: FontWeight.w700);

  /// Small label (category badge, tab label)
  static TextStyle get label =>
      heading(fontSize: 12, fontWeight: FontWeight.w700);

  /// Tiny label (badge, timestamp caption)
  static TextStyle get caption =>
      body(fontSize: 10, fontWeight: FontWeight.w500);

  /// Standard body paragraph
  static TextStyle get bodyMd => body(fontSize: 14);

  /// Small body (subtitles, secondary info)
  static TextStyle get bodySm => body(fontSize: 12);

  /// Extra-small body (timestamps, hints)
  static TextStyle get bodyXs => body(fontSize: 11);

  /// Hero revenue / large price display
  static TextStyle get heroNumber =>
      number(fontSize: 30, fontWeight: FontWeight.w800);

  /// Medium price / stat value
  static TextStyle get statNumber =>
      number(fontSize: 18, fontWeight: FontWeight.w800);

  /// Small inline price
  static TextStyle get priceSmall =>
      number(fontSize: 13, fontWeight: FontWeight.w700);

  // ── Theme text theme ───────────────────────────────────────────────────────

  static TextTheme buildTextTheme(Color primary, Color secondary) => TextTheme(
    displayLarge: heading(
      fontSize: 57,
      fontWeight: FontWeight.w800,
      color: primary,
    ),
    displayMedium: heading(
      fontSize: 45,
      fontWeight: FontWeight.w700,
      color: primary,
    ),
    displaySmall: heading(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: primary,
    ),
    headlineLarge: heading(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: primary,
    ),
    headlineMedium: heading(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: primary,
    ),
    headlineSmall: heading(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: primary,
    ),
    titleLarge: heading(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: primary,
    ),
    titleMedium: heading(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    titleSmall: heading(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    bodyLarge: body(fontSize: 16, color: primary, height: 1.5),
    bodyMedium: body(fontSize: 14, color: primary, height: 1.5),
    bodySmall: body(fontSize: 12, color: secondary, height: 1.5),
    labelLarge: heading(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    labelMedium: body(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: secondary,
    ),
    labelSmall: body(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: secondary,
    ),
  );

  // ── Internal helpers ───────────────────────────────────────────────────────

  static double _headingSpacing(double size) {
    if (size >= 28) return -0.5;
    if (size >= 20) return -0.3;
    if (size >= 16) return -0.2;
    return 0.0;
  }
}
