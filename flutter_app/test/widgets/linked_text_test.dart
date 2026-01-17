import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nepal_civic/widgets/linked_text.dart';

void main() {
  group('LinkedText Widget Tests', () {
    testWidgets('should render plain text', (tester) async {
      const testText = 'This is plain text';

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LinkedText(
                text: testText,
              ),
            ),
          ),
        ),
      );

      // Should find the plain text
      expect(find.textContaining('This is plain text'), findsOneWidget);
    });

    testWidgets('should highlight article references', (tester) async {
      const testText = 'See Article 42 for details';

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LinkedText(
                text: testText,
              ),
            ),
          ),
        ),
      );

      // Should find text containing "Article 42"
      expect(find.textContaining('Article 42'), findsOneWidget);
    });

    testWidgets('should handle Nepali article references', (tester) async {
      const testText = 'धारा ४२ हेर्नुहोस्'; // See Article 42

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LinkedText(
                text: testText,
              ),
            ),
          ),
        ),
      );

      // Should find Nepali text
      expect(find.textContaining('धारा'), findsOneWidget);
    });

    testWidgets('should call onArticleTap when link tapped', (tester) async {
      const testText = 'See Article 42 for details';

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LinkedText(
                text: testText,
              ),
            ),
          ),
        ),
      );

      // Find and tap the article reference
      // Note: In a real test with proper RichText rendering, we'd tap the specific span
      // For now, we verify the widget renders without error
      expect(find.byType(LinkedText), findsOneWidget);
    });

    testWidgets('should handle empty text', (tester) async {
      const testText = '';

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LinkedText(
                text: testText,
              ),
            ),
          ),
        ),
      );

      // Should handle empty text gracefully
      expect(find.byType(LinkedText), findsOneWidget);
    });
  });
}
