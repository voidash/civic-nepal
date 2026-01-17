import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/constitution_provider.dart';
import '../../models/constitution.dart';

part 'constitution_screen.g.dart';

/// Constitution screen with TOC and content
class ConstitutionScreen extends ConsumerWidget {
  const ConstitutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final constitutionAsync = ref.watch(constitutionProvider);
    final languageMode = ref.watch(languageModeProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Constitution of Nepal'),
        actions: [
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
      body: constitutionAsync.when(
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
                child: _buildContentArea(context, constitution),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildTOC(BuildContext context, WidgetRef ref, Constitution constitution) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: constitution.parts.length + 1, // +1 for preamble
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            title: const Text('Preamble'),
            subtitle: const Text('प्रस्तावना'),
            onTap: () {
              // Navigate to preamble
            },
          );
        }
        final part = constitution.parts[index - 1];
        return ExpansionTile(
          title: Text(part.title ?? 'Part ${part.id}'),
          subtitle: Text(part.titleNp ?? ''),
          children: part.articles.map((article) {
            return ListTile(
              title: Text(article.title ?? 'Article ${article.id}'),
              subtitle: Text(article.titleNp ?? ''),
              onTap: () {
                // Navigate to article
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildContentArea(BuildContext context, Constitution constitution) {
    return const Center(
      child: Text('Select an article to view'),
    );
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
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox.shrink();
  }
}
