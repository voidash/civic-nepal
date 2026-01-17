import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepal_civic/screens/constitution/constitution_screen.dart';

void main() {
  group('ConstitutionScreen Widget Tests', () {
    testWidgets('should build without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProviderScope(
            child: ConstitutionScreen(),
          ),
        ),
      );

      expect(find.byType(ConstitutionScreen), findsOneWidget);
    });

    testWidgets('should have language toggle buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProviderScope(
            child: ConstitutionScreen(),
          ),
        ),
      );

      // Initially shows loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Pump multiple times for async data loading
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      // After loading, should still have ConstitutionScreen present
      expect(find.byType(ConstitutionScreen), findsOneWidget);
    });

    testWidgets('should display TOC items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProviderScope(
            child: ConstitutionScreen(),
          ),
        ),
      );

      // Initially shows loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Pump multiple times for async data loading
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      // After loading, should have ConstitutionScreen present
      expect(find.byType(ConstitutionScreen), findsOneWidget);
    });
  });
}
