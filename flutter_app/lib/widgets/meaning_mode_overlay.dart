import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/meaning_mode_provider.dart';
import '../services/dictionary_service.dart';

/// Overlay widget that shows meaning mode tooltip when a word is selected
class MeaningModeOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const MeaningModeOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MeaningModeOverlay> createState() => _MeaningModeOverlayState();
}

class _MeaningModeOverlayState extends ConsumerState<MeaningModeOverlay> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _key = GlobalKey();
  bool _initialized = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showMeaningTooltip(DictionaryLookupResult result) {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _MeaningTooltip(
        result: result,
        onDismiss: () {
          ref.read(currentLookupProvider.notifier).clear();
          _removeOverlay();
        },
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    // Initialize dictionary on first build
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dictionaryInitializedProvider.notifier).ensureInitialized();
      });
    }

    // Listen to lookup results - must be in build method for ConsumerStatefulWidget
    ref.listen<DictionaryLookupResult?>(currentLookupProvider, (previous, next) {
      if (next != null && ref.read(meaningModeEnabledProvider)) {
        _showMeaningTooltip(next);
      } else {
        _removeOverlay();
      }
    });

    return Container(
      key: _key,
      child: widget.child,
    );
  }
}

/// Tooltip widget showing dictionary lookup results
class _MeaningTooltip extends StatelessWidget {
  final DictionaryLookupResult result;
  final VoidCallback onDismiss;

  const _MeaningTooltip({
    required this.result,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with dismiss button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.translate,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  Text(
                    result.found ? 'Translation' : 'Not Found',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(height: 16),
              // Word queried
              Text(
                result.queriedWord,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              // Translations
              if (result.found)
                Text(
                  result.formattedTranslations,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                )
              else
                Text(
                  'No translation found for this word.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable text widget with meaning mode support
class MeaningModeText extends ConsumerStatefulWidget {
  final String text;
  final String language; // 'en' or 'np'
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  const MeaningModeText({
    super.key,
    required this.text,
    required this.language,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  @override
  ConsumerState<MeaningModeText> createState() => _MeaningModeTextState();
}

class _MeaningModeTextState extends ConsumerState<MeaningModeText> {
  final GlobalKey _textKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final meaningModeEnabled = ref.watch(meaningModeEnabledProvider);

    return GestureDetector(
      onLongPressStart: meaningModeEnabled ? _handleLongPress : null,
      child: SelectableText(
        key: _textKey,
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
      ),
    );
  }

  void _handleLongPress(LongPressStartDetails details) {
    // Get the selected text from the SelectableText
    // Since Flutter doesn't provide direct access to selected text,
    // we'll show a dialog for manual word input or use a different approach

    // For now, show a dialog to enter the word to look up
    _showWordLookupDialog();
  }

  void _showWordLookupDialog() {
    final controller = TextEditingController();
    final isNepali = widget.language == 'np';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNepali ? 'Lookup Nepali Word' : 'Lookup English Word'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isNepali ? 'Enter Nepali word' : 'Enter English word',
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              ref.read(currentLookupProvider.notifier).lookupWord(
                    value.trim(),
                    fromNepali: isNepali,
                  );
              context.pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final word = controller.text.trim();
              if (word.isNotEmpty) {
                ref.read(currentLookupProvider.notifier).lookupWord(
                      word,
                      fromNepali: isNepali,
                    );
                context.pop();
              }
            },
            child: const Text('Lookup'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Meaning mode toggle button for use in app bar
class MeaningModeToggleButton extends ConsumerWidget {
  const MeaningModeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(meaningModeEnabledProvider);

    return IconButton(
      icon: Icon(enabled ? Icons.translate : Icons.translate_outlined),
      tooltip: enabled ? 'Meaning Mode On' : 'Meaning Mode Off',
      color: enabled ? Theme.of(context).colorScheme.primary : null,
      onPressed: () {
        ref.read(meaningModeEnabledProvider.notifier).toggle();
        // Clear any existing lookup when toggling
        ref.read(currentLookupProvider.notifier).clear();
      },
    );
  }
}
