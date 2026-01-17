import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/constitution_provider.dart';
import '../../models/constitution.dart';
import '../../widgets/meaning_mode_overlay.dart';
import '../../widgets/linked_text.dart';

/// Constitution screen with TOC and content
class ConstitutionScreen extends ConsumerWidget {
  const ConstitutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final constitutionAsync = ref.watch(constitutionProvider);
    final selectedArticle = ref.watch(selectedArticleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Constitution of Nepal'),
        actions: [
          const MeaningModeToggleButton(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ArticleSearchDelegate(ref),
              );
            },
          ),
        ],
      ),
      body: MeaningModeOverlay(
        child: constitutionAsync.when(
          data: (constitution) {
            return Row(
            children: [
              // TOC Sidebar
              SizedBox(
                width: 300,
                child: _buildTOC(context, ref, constitution),
              ),
              const VerticalDivider(width: 1),
              // Main Content Area
              Expanded(
                child: _buildContentArea(context, ref, constitution, selectedArticle),
              ),
            ],
          );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildTOC(BuildContext context, WidgetRef ref, ConstitutionData constitution) {
    final selectedArticle = ref.watch(selectedArticleProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: constitution.parts.length + 1, // +1 for preamble
      itemBuilder: (context, index) {
        if (index == 0) {
          // Preamble
          final isSelected = _isPreambleSelected(selectedArticle);
          return ListTile(
            title: const Text('Preamble'),
            subtitle: const Text('प्रस्तावना'),
            selected: isSelected,
            tileColor: isSelected ? Theme.of(context).highlightColor : null,
            onTap: () {
              ref.read(selectedArticleProvider.notifier).selectPreamble();
            },
          );
        }
        final partIndex = index - 1;
        final part = constitution.parts[partIndex];
        return ExpansionTile(
          title: Text(_getPartTitle(part)),
          subtitle: part.title.np.isNotEmpty ? Text(part.title.np) : null,
          children: part.articles.asMap().entries.map((entry) {
            final articleIndex = entry.key;
            final article = entry.value;
            // Check if selected article matches this article
            final isSelected = _isArticleSelected(selectedArticle, partIndex, articleIndex);

            return ListTile(
              title: Text(_getArticleTitle(article)),
              subtitle: (article.title.np?.isNotEmpty ?? false) ? Text(article.title.np!) : null,
              selected: isSelected,
              tileColor: isSelected ? Theme.of(context).highlightColor : null,
              onTap: () {
                ref.read(selectedArticleProvider.notifier).selectArticle(
                  SelectedArticleRef.article(
                    partIndex: partIndex,
                    articleIndex: articleIndex,
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildContentArea(
    BuildContext context,
    WidgetRef ref,
    ConstitutionData constitution,
    SelectedArticleRef? selectedArticle,
  ) {
    if (selectedArticle == null) {
      return _buildWelcome(context, ref);
    }

    return selectedArticle.when(
      preamble: () => _buildPreamble(context, ref, constitution.preamble),
      article: (partIndex, articleIndex) {
        final article = constitution.parts[partIndex].articles[articleIndex];
        return _buildArticle(context, ref, article);
      },
    );
  }

  Widget _buildWelcome(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select an article to view',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Or tap the preamble to begin',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreamble(BuildContext context, WidgetRef ref, Preamble preamble) {
    final languageMode = ref.watch(languageModeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preamble',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'प्रस्तावना',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _buildLanguageToggle(context, ref),
              const SizedBox(width: 8),
              _buildViewModeToggle(context, ref),
            ],
          ),
          const SizedBox(height: 24),
          if (languageMode == 'both' || languageMode == 'english')
            _buildPreambleText(context, preamble.en, 'English'),
          if (languageMode == 'both') const SizedBox(height: 24),
          if (languageMode == 'both' || languageMode == 'nepali')
            _buildPreambleText(context, preamble.np, 'नेपाली'),
        ],
      ),
    );
  }

  Widget _buildPreambleText(BuildContext context, String text, String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        LinkedText(
          text: text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.8,
            fontSize: language == 'नेपाली' ? 18 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildArticle(BuildContext context, WidgetRef ref, Article article) {
    final languageMode = ref.watch(languageModeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.number,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (article.title.en?.isNotEmpty ?? false)
                      Text(
                        article.title.en!,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    if (article.title.np?.isNotEmpty ?? false)
                      Text(
                        article.title.np!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              _buildLanguageToggle(context, ref),
              const SizedBox(width: 8),
              _buildViewModeToggle(context, ref),
            ],
          ),
          const SizedBox(height: 24),
          // Render content based on language mode
          if (languageMode == 'both' || languageMode == 'english')
            _buildContentItems(context, article.content.en, 'English'),
          if (languageMode == 'both') const SizedBox(height: 24),
          if (languageMode == 'both' || languageMode == 'nepali')
            _buildContentItems(context, article.content.np, 'नेपाली'),
        ],
      ),
    );
  }

  Widget _buildContentItems(BuildContext context, List<ContentItem> items, String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _buildContentItem(context, item, language)),
      ],
    );
  }

  Widget _buildContentItem(BuildContext context, ContentItem item, String language) {
    final isNepali = language == 'नेपाली';
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      height: 1.8,
      fontSize: isNepali ? 18 : 16,
    );

    if (item.type == 'subsection' && item.identifier != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.identifier!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (item.text != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: LinkedText(text: item.text!, style: textStyle),
              ),
            if (item.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: item.items.map((subItem) {
                    return _buildContentItem(context, subItem, language);
                  }).toList(),
                ),
              ),
          ],
        ),
      );
    }

    // Regular text item
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LinkedText(text: item.text ?? '', style: textStyle),
    );
  }

  Widget _buildLanguageToggle(BuildContext context, WidgetRef ref) {
    final languageMode = ref.watch(languageModeProvider);

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'both',
          label: Text('Both'),
        ),
        ButtonSegment(
          value: 'nepali',
          label: Text('नेपाली'),
        ),
        ButtonSegment(
          value: 'english',
          label: Text('English'),
        ),
      ],
      selected: {languageMode},
      onSelectionChanged: (Set<String> selection) {
        ref.read(languageModeProvider.notifier).setLanguage(selection.first);
      },
    );
  }

  Widget _buildViewModeToggle(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'paragraph',
          label: Text('Paragraph'),
          icon: Icon(Icons.view_agenda),
        ),
        ButtonSegment(
          value: 'sentence',
          label: Text('Sentence'),
          icon: Icon(Icons.format_list_bulleted),
        ),
      ],
      selected: {viewMode},
      onSelectionChanged: (Set<String> selection) {
        ref.read(viewModeProvider.notifier).setMode(selection.first);
      },
    );
  }

  String _getPartTitle(Part part) {
    if (part.title.en.isNotEmpty) return part.title.en;
    return 'Part ${part.number}';
  }

  String _getArticleTitle(Article article) {
    if (article.title.en?.isNotEmpty ?? false) return '${article.number} ${article.title.en}';
    return article.number;
  }
}

/// Search delegate for articles
class ArticleSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  ArticleSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final constitutionAsync = ref.watch(constitutionProvider);

    return constitutionAsync.when(
      data: (constitution) {
        if (query.isEmpty) {
          return const Center(child: Text('Search for articles...'));
        }

        final results = <SearchResult>[];

        // Search through all articles
        for (int i = 0; i < constitution.parts.length; i++) {
          final part = constitution.parts[i];
          for (int j = 0; j < part.articles.length; j++) {
            final article = part.articles[j];
            final titleEn = (article.title.en ?? '').toLowerCase();
            final titleNp = (article.title.np ?? '').toLowerCase();
            final searchQuery = query.toLowerCase();

            if (titleEn.contains(searchQuery) || titleNp.contains(searchQuery)) {
              results.add(SearchResult(
                partIndex: i,
                articleIndex: j,
                article: article,
              ));
            }
          }
        }

        if (results.isEmpty) {
          return Center(child: Text('No results for "$query"'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              title: Text('${result.article.number} ${result.article.title.en ?? ''}'),
              subtitle: (result.article.title.np?.isNotEmpty ?? false)
                  ? Text(result.article.title.np!)
                  : null,
              onTap: () {
                ref.read(selectedArticleProvider.notifier).selectArticle(
                  SelectedArticleRef.article(
                    partIndex: result.partIndex,
                    articleIndex: result.articleIndex,
                  ),
                );
                close(context, '');
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class SearchResult {
  final int partIndex;
  final int articleIndex;
  final Article article;

  SearchResult({
    required this.partIndex,
    required this.articleIndex,
    required this.article,
  });
}

/// Helper to check if preamble is selected
bool _isPreambleSelected(SelectedArticleRef? selectedArticle) {
  return selectedArticle?.maybeWhen(
    preamble: () => true,
    article: (_, __) => false,
    orElse: () => false,
  ) ?? false;
}

/// Helper to check if article is selected
bool _isArticleSelected(SelectedArticleRef? selectedArticle, int partIndex, int articleIndex) {
  return selectedArticle?.maybeWhen(
    preamble: () => false,
    article: (p, a) => p == partIndex && a == articleIndex,
    orElse: () => false,
  ) ?? false;
}
