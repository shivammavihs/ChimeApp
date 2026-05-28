import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// InheritedWidget for responsive scaling based on a standard 375x812 layout
// ---------------------------------------------------------------------------
class ResponsiveScale extends InheritedWidget {
  final double scaleX;
  final double scaleY;
  final double scaleFactor;

  const ResponsiveScale({
    super.key,
    required this.scaleX,
    required this.scaleY,
    required this.scaleFactor,
    required super.child,
  });

  static ResponsiveScale of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<ResponsiveScale>();
    assert(result != null, 'No ResponsiveScale found in context');
    return result!;
  }

  // Horizontal scaling for width/paddings
  double w(double value) => value * scaleX;

  // Vertical scaling for height/margins/gaps
  double h(double value) => value * scaleY;

  // Font/General size scaling
  double sp(double value) => value * scaleFactor;

  @override
  bool updateShouldNotify(ResponsiveScale oldWidget) {
    return oldWidget.scaleX != scaleX ||
        oldWidget.scaleY != scaleY ||
        oldWidget.scaleFactor != scaleFactor;
  }
}
