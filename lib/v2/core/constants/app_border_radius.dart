import 'package:flutter/material.dart';

/// Border radius constants following Spotify design system
class AppBorderRadius {
  AppBorderRadius._();

  static const double minimal = 2;
  static const double subtle = 4;
  static const double standard = 6;
  static const double comfortable = 8;
  static const double medium = 10;
  static const double large = 20;
  static const double pill = 500;
  static const double fullPill = 9999;
  static const double circle = 50;

  static const Radius minimalRadius = Radius.circular(minimal);
  static const Radius subtleRadius = Radius.circular(subtle);
  static const Radius standardRadius = Radius.circular(standard);
  static const Radius comfortableRadius = Radius.circular(comfortable);
  static const Radius mediumRadius = Radius.circular(medium);
  static const Radius largeRadius = Radius.circular(large);
  static const Radius pillRadius = Radius.circular(pill);
  static const Radius fullPillRadius = Radius.circular(fullPill);
  static const Radius circleRadius = Radius.circular(circle);

  static RoundedRectangleBorder minimalShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(minimal),
  );
  static RoundedRectangleBorder subtleShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(subtle),
  );
  static RoundedRectangleBorder standardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(standard),
  );
  static RoundedRectangleBorder comfortableShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(comfortable),
  );
  static RoundedRectangleBorder mediumShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(medium),
  );
  static RoundedRectangleBorder largeShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(large),
  );
  static RoundedRectangleBorder pillShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(pill),
  );
  static RoundedRectangleBorder fullPillShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(fullPill),
  );
  static RoundedRectangleBorder circleShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(circle),
  );
}
