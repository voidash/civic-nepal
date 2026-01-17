/// Test helper utilities for Flutter constitution app tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a widget with MaterialApp and ProviderScope for testing
Widget buildTestWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: child,
    ),
  );
}

/// Creates a test pump wrapper for widget testing
/// Usage: await tester.pumpWidget(buildTestWidget(MyWidget()));
///
/// Example:
/// ```dart
/// testWidgets('should display text', (tester) async {
///   await tester.pumpWidget(buildTestWidget(const Text('Hello')));
///   expect(find.text('Hello'), findsOneWidget);
/// });
/// ```
Widget testableWidget(Widget child) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: MaterialApp(
      home: ProviderScope(
        child: child,
      ),
    ),
  );
}

/// Provides a ProviderContainer for testing providers
/// Remember to dispose the container in tearDown
ProviderContainer createProviderContainer() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}
