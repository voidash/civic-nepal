import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/constitution_provider.dart';
import '../../models/constitution.dart';
import '../../models/know_your_rights.dart';
import '../../widgets/linked_text.dart';
import '../../widgets/home_title.dart';

/// Constitution screen with TOC and content
class ConstitutionScreen extends ConsumerWidget {
  const ConstitutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final constitutionAsync = ref.watch(constitutionProvider);
    final selectedArticle = ref.watch(selectedArticleProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 800;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: isWideScreen ? null : Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: HomeTitle(child: Text(l10n.knowYourRights)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ArticleSearchDelegate(ref, l10n),
              );
            },
          ),
        ],
      ),
      // Disable edge swipe to prevent accidental opening
      drawerEdgeDragWidth: 0,
      drawer: isWideScreen ? null : constitutionAsync.whenOrNull(
        data: (constitution) => Drawer(
          child: SafeArea(
            child: _buildTOC(context, ref, constitution, closeDrawer: true),
          ),
        ),
      ),
      body: constitutionAsync.when(
        data: (constitution) {
          if (isWideScreen) {
            return Row(
              children: [
                // TOC Sidebar for wide screens
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
          } else {
            // Full width content on mobile
            return _buildContentArea(context, ref, constitution, selectedArticle);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildTOC(BuildContext context, WidgetRef ref, ConstitutionData constitution, {bool closeDrawer = false}) {
    final selectedArticle = ref.watch(selectedArticleProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: constitution.parts.length + 2, // +1 for preamble, +1 for Know Your Rights
      itemBuilder: (context, index) {
        if (index == 0) {
          // Know Your Rights
          final isSelected = selectedArticle == null;
          final l10n = AppLocalizations.of(context);
          return ListTile(
            leading: Icon(
              Icons.gavel,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(l10n.knowYourRights),
            subtitle: const Text('आफ्नो हक जान्नुहोस्'),
            selected: isSelected,
            tileColor: isSelected ? Theme.of(context).highlightColor : null,
            onTap: () {
              ref.read(selectedArticleProvider.notifier).clear();
              if (closeDrawer) Navigator.of(context).pop();
            },
          );
        }
        if (index == 1) {
          // Preamble
          final isSelected = _isPreambleSelected(selectedArticle);
          final l10n = AppLocalizations.of(context);
          return ListTile(
            title: Text(l10n.preamble),
            subtitle: const Text('प्रस्तावना'),
            selected: isSelected,
            tileColor: isSelected ? Theme.of(context).highlightColor : null,
            onTap: () {
              ref.read(selectedArticleProvider.notifier).selectPreamble();
              if (closeDrawer) Navigator.of(context).pop();
            },
          );
        }
        final partIndex = index - 2;
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
                if (closeDrawer) Navigator.of(context).pop();
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
      part: (partIndex) {
        final part = constitution.parts[partIndex];
        return _buildPart(context, ref, part, partIndex);
      },
    );
  }

  Widget _buildWelcome(BuildContext context, WidgetRef ref) {
    final rightsAsync = ref.watch(knowYourRightsProvider);

    return rightsAsync.when(
      data: (rights) => _buildKnowYourRights(context, ref, rights),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading rights: $e')),
    );
  }

  Widget _buildKnowYourRights(BuildContext context, WidgetRef ref, KnowYourRightsData rights) {
    final l10n = AppLocalizations.of(context);
    final localeCode = l10n.locale.code;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            l10n.knowYourRights,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Disclaimer
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3D2E00) : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF6B5000) : Colors.amber.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rights.disclaimer.forLocale(localeCode),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Categories
          ...rights.categories.map((category) =>
            _buildCategoryCard(context, ref, category, localeCode),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, WidgetRef ref, RightsCategory category, String localeCode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(_getIconData(category.icon), color: Theme.of(context).colorScheme.primary),
        title: Text(
          category.title.forLocale(localeCode),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          category.subtitle.forLocale(localeCode),
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        children: category.rights.map((right) =>
          _buildRightItem(context, ref, right, localeCode),
        ).toList(),
      ),
    );
  }

  Widget _buildRightItem(BuildContext context, WidgetRef ref, RightItem right, String localeCode) {
    return InkWell(
      onTap: () {
        // Navigate to the referenced article
        ref.read(selectedArticleProvider.notifier).selectArticle(
          SelectedArticleRef.article(
            partIndex: right.articleRef.partIndex,
            articleIndex: right.articleRef.articleIndex,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Situation
            Builder(builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Row(
                children: [
                  Icon(Icons.help_outline, size: 16,
                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      right.situation.forLocale(localeCode),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),

            // Your Right
            Text(
              right.yourRight.forLocale(localeCode),
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),

            // Practical Tip
            Builder(builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B3D1B) : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16,
                      color: isDark ? Colors.green.shade300 : Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        right.tip.forLocale(localeCode),
                        style: TextStyle(fontSize: 13,
                          color: isDark ? Colors.green.shade200 : Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),

            // Link to article and complaint filing
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.article_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Article ${right.articleRef.articleNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return GestureDetector(
                      onTap: () => context.push('/tools/gov-services?category=complaints'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gavel, size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            l10n.fileComplaint,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shield':
        return Icons.shield;
      case 'work':
        return Icons.work;
      case 'woman':
        return Icons.woman;
      case 'home':
        return Icons.home;
      case 'house':
        return Icons.house;
      case 'campaign':
        return Icons.campaign;
      case 'info':
        return Icons.info;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'child_care':
        return Icons.child_care;
      case 'diversity_3':
        return Icons.diversity_3;
      case 'elderly':
        return Icons.elderly;
      case 'park':
        return Icons.park;
      case 'restaurant':
        return Icons.restaurant;
      case 'lock':
        return Icons.lock;
      default:
        return Icons.gavel;
    }
  }

  Widget _buildPreamble(BuildContext context, WidgetRef ref, Preamble preamble) {
    final languageMode = ref.watch(languageModeProvider);
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.preamble,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'प्रस्तावना',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildLanguageToggle(context, ref),
                  _buildViewModeToggle(context, ref),
                ],
              ),
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

  Widget _buildPart(BuildContext context, WidgetRef ref, Part part, int partIndex) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Part header
          Text(
            'Part ${part.number}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            part.title.en,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (part.title.np.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              part.title.np,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Articles in this part
          Text(
            l10n.articles,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // List all articles
          ...part.articles.asMap().entries.map((entry) {
            final articleIndex = entry.key;
            final article = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  '${article.number}${article.title.en != null ? ' - ${article.title.en}' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: article.title.np != null
                    ? Text(article.title.np!)
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(selectedArticleProvider.notifier).selectArticle(
                    SelectedArticleRef.article(
                      partIndex: partIndex,
                      articleIndex: articleIndex,
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildArticle(BuildContext context, WidgetRef ref, Article article) {
    final languageMode = ref.watch(languageModeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildLanguageToggle(context, ref),
                  _buildViewModeToggle(context, ref),
                ],
              ),
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
  final AppLocalizations l10n;

  ArticleSearchDelegate(this.ref, this.l10n);

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
          return Center(child: Text(l10n.searchArticles));
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
          return Center(child: Text(l10n.noResults(query)));
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
    part: (_) => false,
    orElse: () => false,
  ) ?? false;
}

/// Helper to check if article is selected
bool _isArticleSelected(SelectedArticleRef? selectedArticle, int partIndex, int articleIndex) {
  return selectedArticle?.maybeWhen(
    preamble: () => false,
    article: (p, a) => p == partIndex && a == articleIndex,
    part: (_) => false,
    orElse: () => false,
  ) ?? false;
}

/// Helper to check if part is selected
bool _isPartSelected(SelectedArticleRef? selectedArticle, int partIndex) {
  return selectedArticle?.maybeWhen(
    preamble: () => false,
    article: (_, __) => false,
    part: (p) => p == partIndex,
    orElse: () => false,
  ) ?? false;
}
