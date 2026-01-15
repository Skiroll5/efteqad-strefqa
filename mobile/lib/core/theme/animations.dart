import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);
  static const Duration fastDuration = Duration(milliseconds: 200);

  // Stagger delays
  static const Duration staggerLow = Duration(milliseconds: 50);
  static const Duration staggerMedium = Duration(milliseconds: 100);

  // Common Curves
  static const Curve defaultCurve = Curves.easeOutQuart;
  static const Curve bounceCurve = Curves.easeOutBack;

  // Global extensions or helpers can go here
  static List<Effect> entryAnimation({double delay = 0}) {
    return [
      FadeEffect(
        duration: defaultDuration,
        curve: defaultCurve,
        delay: Duration(milliseconds: (delay * 1000).toInt()),
      ),
      SlideEffect(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
        duration: defaultDuration,
        curve: defaultCurve,
        delay: Duration(milliseconds: (delay * 1000).toInt()),
      ),
    ];
  }
}
