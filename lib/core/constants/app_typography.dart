import 'package:flutter/material.dart';

/// The application typography contract from the Stitch design source.
class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Arimo';

  static const TextStyle headlineLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle instructionBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle bodyPassage = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 25.6 / 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle timerTabular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.02,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle labelMeta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle labelBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w400,
  );

  // Generated component aliases used by the screen references.
  static const TextStyle displayLg = headlineLg;
  static const TextStyle displaySm = headlineLg;
  static const TextStyle headingMd = headlineMd;
  static const TextStyle headingSm = instructionBold;
  static const TextStyle bodyLg = bodyPassage;
  static const TextStyle bodyMd = bodyRegular;
  static const TextStyle bodyMdBold = bodyBold;
  static const TextStyle bodySm = labelMeta;
  static const TextStyle monoSm = timerTabular;
}
