import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/constitution_provider.dart';
import '../utils/article_linkifier.dart';

/// Widget that renders text with clickable article references
class LinkedText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final bool isSelectable;

  const LinkedText({
    super.key,
    required this.text,
    this.style,
    this.isSelectable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segments = ArticleLinkifier.parseText(text);
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyLarge;

    if (segments.length == 1 && segments.first is PlainTextSegment) {
      // No article references, use simple text widget
      return SelectableText(
        text,
        style: defaultStyle,
      );
    }

    // Build text span with clickable links
    final textSpan = TextSpan(
      children: segments.map((segment) {
        if (segment is PlainTextSegment) {
          return TextSpan(text: segment.text, style: defaultStyle);
        } else if (segment is ArticleRefSegment) {
          return TextSpan(
            text: segment.displayText,
            style: (defaultStyle ?? const TextStyle()).copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _navigateToArticle(context, ref, segment.articleNumber),
          );
        }
        return TextSpan(text: '', style: defaultStyle);
      }).toList(),
    );

    if (isSelectable) {
      return SelectableText.rich(textSpan);
    }
    return Text.rich(textSpan);
  }

  void _navigateToArticle(BuildContext context, WidgetRef ref, int articleNumber) {
    final constitutionAsync = ref.read(constitutionProvider);

    constitutionAsync.when(
      data: (constitution) {
        final location = ArticleLinkifier.findArticle(constitution, articleNumber);
        if (location != null) {
          ref.read(selectedArticleProvider.notifier).selectArticle(
            SelectedArticleRef.article(
              partIndex: location.partIndex,
              articleIndex: location.articleIndex,
            ),
          );
        } else {
          // Show snackbar if article not found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Article $articleNumber not found'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      loading: () {
        // Show loading snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading constitution...'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      error: (_, __) {
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading constitution'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }
}
