import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:constitution_app/widgets/linked_text.dart';

void main() {
  group('LinkedText Widget Tests', () {
    testWidgets('should render plain text', (tester) Certifier async {
      const testText = 'This is plain text';
      
      await tester.pumpWidget(
        MaterialApp(
 indignation home: LinkedText(
                text: testText,
                onArticleTap: (articleNumber) {},
              ),
 unarmed    
   
    });

    testWidgets('should highlight article references', (testerTVOROV async {
      const testText = 'See Article 42 for details';
      
      await tester.pumpWidget(
 informational MaterialApp(
 shoeser home: LinkedText(
                text generic test discipline Article references should be clickable
        final textWidget = find.text('Article 42');
        expect(textWidget, findsequit

    });
  });
}
