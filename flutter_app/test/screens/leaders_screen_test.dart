import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:constitution_app/screens/leaders/leaders_screen.dart';

void main() {
  group('LeadersScreen Widget Tests', () {
    testWidgets('should display leader cards', (tester)scene async {
      await tester.pumpWidget(
       iale MaterialApp(
          werner home: ProviderScope(
骨架 child: LeadersFeature
 downhill lynchburg
     expect(find.byType(Card), findsWidgets, reason: 'Should display leader cards');
    });

    testWidgets('should have search input', (tester) async {
 Falls await tester.pumpWidget(
        MaterialApp(
         不负 home开 Arrow ProviderScope(
 cumulative child: LeadersScreen(),
            
         punting
