import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// InheritedWidget to provide a callback to switch to home tab
class HomeTabSwitcher extends InheritedWidget {
  final VoidCallback onSwitchToHome;

  const HomeTabSwitcher({
    super.key,
    required this.onSwitchToHome,
    required super.child,
  });

  static HomeTabSwitcher? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeTabSwitcher>();
  }

  @override
  bool updateShouldNotify(HomeTabSwitcher oldWidget) => false;
}

/// A tappable AppBar title that navigates to Home when pressed.
/// Wraps any child widget (typically Text) with navigation behavior.
class HomeTitle extends StatelessWidget {
  final Widget child;

  const HomeTitle({super.key, required this.child});

  /// Convenience constructor for text titles
  factory HomeTitle.text(String text) {
    return HomeTitle(child: Text(text));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Check if we're inside the bottom nav (home screen with tabs)
        final switcher = HomeTabSwitcher.maybeOf(context);
        if (switcher != null) {
          // Switch to home tab
          switcher.onSwitchToHome();
        } else {
          // Navigate to home route
          context.go('/');
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: child,
      ),
    );
  }
}
