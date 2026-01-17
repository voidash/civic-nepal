import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constitution/constitution_screen.dart';
import '../leaders/leaders_screen.dart';
import '../map/district_map_screen.dart';
import '../settings/settings_screen.dart';

part 'home_screen.g.dart';

/// Home screen with bottom navigation
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(_currentTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          ConstitutionTab(),
          LeadersTab(),
          MapTab(),
          SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(_currentTabProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Constitution',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Leaders',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

@riverpod
class _CurrentTab extends _$CurrentTab {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

// Tab widgets
class ConstitutionTab extends StatelessWidget {
  const ConstitutionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConstitutionScreen();
  }
}

class LeadersTab extends StatelessWidget {
  const LeadersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const LeadersScreen();
  }
}

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const DistrictMapScreen();
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}
