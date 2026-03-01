import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'web_nav_bar.dart';

/// Shell widget that provides persistent [WebNavBar] on desktop screens.
///
/// On screens wider than [_desktopBreakpoint], the [WebNavBar] is shown above
/// the child route. On narrow screens (mobile), the child is returned directly.
class DesktopNavShell extends StatelessWidget {
  final Widget child;

  const DesktopNavShell({required this.child, super.key});

  static const double _desktopBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= _desktopBreakpoint;

    if (!isDesktop) return child;

    final location = GoRouterState.of(context).uri.path;

    return Material(
      child: Column(
        children: [
          WebNavBar(currentRoute: location),
          Expanded(child: child),
        ],
      ),
    );
  }
}
