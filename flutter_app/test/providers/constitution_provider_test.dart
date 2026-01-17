import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nepal_civic/providers/constitution_provider.dart';
import 'package:nepal_civic/models/constitution.dart';

void main() {
  // Initialize Flutter binding for asset loading
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Constitution Provider Tests', () {
    test('constitutionProvider should return data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final constitution = await container.read(constitutionProvider.future);

      expect(constitution, isNotNull);
      expect(constitution.parts, isNotEmpty);
    });

    test('constitutionProvider should have 35 parts', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final constitution = await container.read(constitutionProvider.future);

      expect(constitution.parts.length, greaterThanOrEqualTo(35));
    });

    test('constitutionProvider should have at least 300 articles', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final constitution = await container.read(constitutionProvider.future);

      int totalArticles = constitution.parts.fold(
        0,
        (sum, part) => sum + part.articles.length,
      );
      expect(totalArticles, greaterThanOrEqualTo(300));
    });

    test('selectedArticleProvider should default to preamble', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selectedArticle = container.read(selectedArticleProvider);

      expect(selectedArticle, equals(const SelectedArticleRef.preamble()));
    });

    test('selectedArticleProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final testRef = SelectedArticleRef.article(partIndex: 1, articleIndex: 1);
      container.read(selectedArticleProvider.notifier).state = testRef;

      final selectedArticle = container.read(selectedArticleProvider);
      expect(selectedArticle, equals(testRef));
    });

    test('selectedArticleRef equality', () {
      final ref1 = SelectedArticleRef.article(partIndex: 1, articleIndex: 1);
      final ref2 = SelectedArticleRef.article(partIndex: 1, articleIndex: 1);
      final ref3 = SelectedArticleRef.article(partIndex: 1, articleIndex: 2);
      final ref4 = const SelectedArticleRef.preamble();

      expect(ref1, equals(ref2));
      expect(ref1, isNot(equals(ref3)));
      expect(ref1, isNot(equals(ref4)));
    });
  });
}
