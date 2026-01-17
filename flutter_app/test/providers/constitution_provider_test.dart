import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:constitution_app/providers/constitution_provider.dart';

void main() {
  group('Constitution Provider Tests', () {
    test('constitutionProvider should return data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final constitution = await container.read(constitutionProvider.future);

      expect(constitution, isNotNull);
      expect(constitution.data, isNotNull);
      expect(constitution.data!.parts, isNotEmpty);
    });

    test('constitutionProvider should have 35 parts', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final constitution = await container.read(constitutionProvider.future);

      expect(constitution.data!.parts.length, greaterThanOrEqualTo(35));
    });

    test('constitutionProvider should have at least 300 articles', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final constitution = await container.read(constitutionProvider.future);

      int totalArticles = constitution.data!.parts.fold(
        0,
        (sum, part) => sum + (part.articles?.length ?? 0),
      );
      expect(totalArticles, greaterThanOrEqualTo(300));
    });

    test('selectedArticleProvider should be initially null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selectedArticle = container.read(selectedArticleProvider);

      expect(selectedArticle, isNull);
    });

    test('selectedArticleProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const testRef = SelectedArticleRef.article(1, 1);
      container.read(selectedArticleProvider.notifier).state = testRef;

      final selectedArticle = container.read(selectedArticleProvider);
      expect(selectedArticle, equals(testRef));
    });

    test('selectedArticleRef equality', () {
      const ref1 = SelectedArticleRef.article(1, 1);
      const ref2 = SelectedArticleRef.article(1, 1);
      const ref3 = SelectedArticleRef.article(1, 2);
      const ref4 = SelectedArticleRef.preamble();

      expect(ref1, equals(ref2));
      expect(ref1, isNot(equals(ref3)));
      expect(ref1, isNot(equals(ref4)));
    });
  });
}
