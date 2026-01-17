import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:constitution_app/screens/leaders/leaders_screen.dart';

void main() {
  group('LeadersScreen Widget Tests', () {
    testWidgets('should build without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: LeadersScreen(),
          ),
        ),
      );

      expect(find.byType(LeadersScreen), findsOneWidget);
    });

    testWidgets('should display leader cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: LeadersScreen(),
          ),
        ),
      );

      // Wait for async data loading
      await tester.pumpAndSettle();

      // Should have cards for leaders
      final cards = find.byType(Card);
      expect(cards, findsWidgets, reason: 'Should display leader cards');
    });

    testWidgets('should have search input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: LeadersScreen(),
          ),
        ),
      );

      // Wait for async data loading
      await tester.pumpAndSettle();

      // Should have a search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget, reason: 'Should have search input');
    });

    testWidgets('should have filter buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: LeadersScreen(),
          ),
        ),
      );

      // Wait for async data loading
      await tester.pumpAndSettle();

      // Should have filter buttons (party, district)
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsWidgets, reason: 'Should have filter buttons');
    });
  });
}
