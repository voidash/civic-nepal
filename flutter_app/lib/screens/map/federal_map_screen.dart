import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../l10n/app_localizations.dart';
import '../../models/constituency.dart';
import '../../providers/constituencies_provider.dart';
import '../../services/svg_path_parser.dart';
import '../../widgets/home_title.dart';

part 'federal_map_screen.g.dart';

/// Selected constituency provider for federal map
@riverpod
class SelectedFederalConstituency extends _$SelectedFederalConstituency {
  @override
  String? build() => null;

  void setConstituency(String? name) {
    state = name;
  }

  void clear() {
    state = null;
  }
}

/// Federal constituency map screen using nepal_constituencies.svg
class FederalMapScreen extends ConsumerStatefulWidget {
  const FederalMapScreen({super.key});

  @override
  ConsumerState<FederalMapScreen> createState() => _FederalMapScreenState();
}

class _FederalMapScreenState extends ConsumerState<FederalMapScreen> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedConstituency = ref.watch(selectedFederalConstituencyProvider);
    final constituenciesAsync = ref.watch(constituenciesProvider);
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: selectedConstituency == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedConstituency != null) {
          ref.read(selectedFederalConstituencyProvider.notifier).clear();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: HomeTitle(child: Text(l10n.constituencyMap)),
          actions: [
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              tooltip: l10n.resetZoom,
              onPressed: () {
                _transformationController.value = Matrix4.identity();
              },
            ),
          ],
        ),
        body: constituenciesAsync.when(
          data: (data) => Row(
            children: [
              // Map area
              Expanded(
                child: Stack(
                  children: [
                    _buildInteractiveMap(data),
                    if (selectedConstituency != null)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _ConstituencyInfoChip(name: selectedConstituency),
                      ),
                  ],
                ),
              ),
              // Side panel for selected constituency
              if (selectedConstituency != null)
                _buildCandidatesPanel(data, selectedConstituency),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
        ),
      ),
    );
  }

  Widget _buildInteractiveMap(ConstituencyData data) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      constrained: false,
      child: SizedBox(
        width: 1200,
        height: 700,
        child: _ConstituencyMapWidget(
          data: data,
          onConstituencyTap: (name) {
            if (name.isEmpty) {
              ref.read(selectedFederalConstituencyProvider.notifier).clear();
            } else {
              ref.read(selectedFederalConstituencyProvider.notifier).setConstituency(name);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCandidatesPanel(ConstituencyData data, String constituencyName) {
    // Find the constituency
    Constituency? constituency;
    for (final districts in data.districts.values) {
      for (final c in districts) {
        if (c.name == constituencyName) {
          constituency = c;
          break;
        }
      }
      if (constituency != null) break;
    }

    final l10n = AppLocalizations.of(context);

    return Container(
      width: 350,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        constituencyName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (constituency != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${constituency.district} • Province ${constituency.province}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          '${constituency.candidates.length} ${l10n.candidates}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      ref.read(selectedFederalConstituencyProvider.notifier).clear(),
                ),
              ],
            ),
          ),
          // Candidates list
          Expanded(
            child: constituency == null || constituency.candidates.isEmpty
                ? Center(child: Text(l10n.noCandidatesFound))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: constituency.candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = constituency!.candidates[index];
                      return _CandidateCard(candidate: candidate);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Interactive constituency map widget
class _ConstituencyMapWidget extends StatefulWidget {
  final ConstituencyData data;
  final void Function(String name) onConstituencyTap;

  const _ConstituencyMapWidget({
    required this.data,
    required this.onConstituencyTap,
  });

  @override
  State<_ConstituencyMapWidget> createState() => _ConstituencyMapWidgetState();
}

class _ConstituencyMapWidgetState extends State<_ConstituencyMapWidget> {
  final SvgPathParser _pathParser = SvgPathParser();
  final GlobalKey _mapKey = GlobalKey();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSvgPaths();
  }

  Future<void> _loadSvgPaths() async {
    await _pathParser.loadSvg('assets/data/election/nepal_constituencies.svg');
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/data/election/nepal_constituencies.svg',
          key: _mapKey,
          width: 1200,
          height: 700,
          fit: BoxFit.contain,
        ),
        Positioned.fill(
          child: GestureDetector(
            onTapUp: _isLoading ? null : _handleTap,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        if (_isLoading)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  void _handleTap(TapUpDetails details) {
    final renderBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;

    final svgPoint = _pathParser.screenToSvg(localPosition, size);
    final pathId = _pathParser.hitTest(svgPoint);

    if (pathId != null) {
      // Convert path ID to constituency name
      final constituencyName = _findConstituencyName(pathId);
      if (constituencyName != null) {
        widget.onConstituencyTap(constituencyName);
      }
    } else {
      widget.onConstituencyTap('');
    }
  }

  String? _findConstituencyName(String pathId) {
    // Path IDs are like "kathmandu-1", "jhapa-2", etc.
    // Find matching constituency in data
    for (final districts in widget.data.districts.values) {
      for (final c in districts) {
        final normalizedName = c.name.toLowerCase().replaceAll(' ', '-');
        if (normalizedName == pathId || c.svgPathId == pathId) {
          return c.name;
        }
      }
    }
    // Try to format it as a proper name
    return _formatConstituencyName(pathId);
  }

  String _formatConstituencyName(String id) {
    // Convert "kathmandu-1" to "Kathmandu-1"
    final parts = id.split('-');
    if (parts.isEmpty) return id;

    final district = parts[0].split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    if (parts.length > 1) {
      return '$district-${parts.last}';
    }
    return district;
  }
}

class _ConstituencyInfoChip extends StatelessWidget {
  final String name;

  const _ConstituencyInfoChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.how_to_vote, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text(name, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Candidate candidate;

  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildAvatar(context),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (candidate.partySymbol.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CachedNetworkImage(
                            imageUrl: candidate.partySymbol,
                            width: 20,
                            height: 20,
                            errorWidget: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          candidate.party,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (candidate.votes > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.how_to_vote, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${candidate.votes} votes',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final fallback = CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        candidate.name.isNotEmpty ? candidate.name[0] : '?',
        style: TextStyle(
          fontSize: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    if (candidate.imageUrl.isEmpty || candidate.imageUrl.contains('placeholder')) {
      return fallback;
    }

    return CachedNetworkImage(
      imageUrl: candidate.imageUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 24,
        backgroundImage: imageProvider,
      ),
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
