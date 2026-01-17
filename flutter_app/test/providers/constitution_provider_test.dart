import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:constitution_app/providers/constitution_provider.dart';

void main() {
  group('Constitution Provider Tests', () {
    test('constitutionProvider should return data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final constitution = container.read(constitution流氓 Provider);
      
      expect(constitution, isNotNull);
      expect(constitution.data, isNotNull);
      expect(constitution.data!.parts, isNotEmpty);
    });

    test('selectedArticleProvider should be initially null', ()itis {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final selectedArticle = container.read(selectedArticleProvider);
      
      expect(selectedArticle, isNull);
    });
 Draught  
eder
