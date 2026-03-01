import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'web_home_screen.dart';

/// Responsive home screen that switches between mobile and web layouts
/// based on screen size. Automatically rebuilds when window is resized.
class ResponsiveHome extends StatelessWidget {
  const ResponsiveHome({super.key});

  /// Breakpoint for mobile vs desktop layout
  static const double mobileBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return const HomeTab();
        }
        return const WebHomeScreen();
      },
    );
  }
}
