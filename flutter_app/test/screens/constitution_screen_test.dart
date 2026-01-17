import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:constitution_app/screens/constitution/constitution_screen.dart';

void main() {
  group('ConstitutionScreen Widget Tests', () {
    testWidgets('should build without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: ConstitutionScreen(),
          ),
        ),
      );

      expect(find.byType(ConstitutionScreen), findsOneWidget);
    });

    testWidgets('should have language toggle buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: ConstitutionScreen(),
          ),
        ),
      );

      // Wait for async data loading
      await tester.pumpAndSettle();

      // Look for language toggle segments
      final languageToggle = find.byType(SegmentedButton<String>);
      // May have multiple SegmentedButtons (language and view mode)
      expect(languageToggle, findsWidgets);
    });

    testWidgets('should display TOC items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: ConstitutionScreen(),
          ),
        ),
      );

      // Wait for async data loading
      await tester.pumpAndSettle();

      // Should have a ListView or similar for TOC
      final listView = find.byType(ListView);
      expect(listView, findsWidgets);
    });
  });
}
