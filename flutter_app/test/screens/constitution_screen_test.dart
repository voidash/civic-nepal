import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nepal_civic/l10n/app_localizations.dart';
import 'package:nepal_civic/screens/constitution/constitution_screen.dart';

void main() {
  group('ConstitutionScreen Widget Tests', () {
    Widget buildTestApp() {
      return ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ne'),
            Locale('new'),
          ],
          locale: const Locale('ne'),
          home: const ConstitutionScreen(),
        ),
      );
    }

    testWidgets('should build without errors', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Scaffold should exist
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('should have app bar with title', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // App bar should exist
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have search button in app bar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Search button should exist
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
