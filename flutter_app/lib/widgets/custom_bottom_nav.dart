import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom bottom navigation bar: Calendar (left), Home (center), IPO (right)
class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    required this.currentIndex,
    super.key,
  });

  /// 0 = Calendar, 1 = Home, 2 = IPO
  final int currentIndex;

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (index == 1) {
      // Going to Home
      context.go('/home');
    } else if (currentIndex == 1) {
      // Coming from Home - push
      final routes = ['/calendar', '/home', '/ipo'];
      context.push(routes[index]);
    } else {
      // Switching between Calendar and IPO - replace
      final routes = ['/calendar', '/home', '/ipo'];
      context.pushReplacement(routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onTap(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'पात्रो',
        ),
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.trending_up_outlined),
          selectedIcon: Icon(Icons.trending_up),
          label: 'IPO',
        ),
      ],
    );
  }
}
