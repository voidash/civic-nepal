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
import '../../providers/leaders_provider.dart';
import 'package:go_router/go_router.dart';

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
  double _currentZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onZoomChanged);
  }

  void _onZoomChanged() {
    final zoom = _transformationController.value.getMaxScaleOnAxis();
    if (zoom != _currentZoom) {
      setState(() => _currentZoom = zoom);
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onZoomChanged);
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
          data: (data) {
            final svgParserAsync = ref.watch(federalConstituenciesSvgProvider);
            return svgParserAsync.when(
              data: (svgParser) => Row(
              children: [
                // Map area
                Expanded(
                  child: Stack(
                    children: [
                      _buildInteractiveMap(data, svgParser),
                    if (selectedConstituency != null)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _ConstituencyInfoChip(name: selectedConstituency),
                      ),
                    // Zoom hint at bottom - only show when no constituency selected
                    if (selectedConstituency == null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    l10n.zoomHint,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
        ),
      ),
    );
  }

  Widget _buildInteractiveMap(ConstituencyData data, SvgPathParser svgParser) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 15.0,
      constrained: false,
      child: SizedBox(
        width: 1200,
        height: 700,
        child: _ConstituencyMapWidget(
          data: data,
          svgParser: svgParser,
          currentZoom: _currentZoom,
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
  final SvgPathParser svgParser;
  final double currentZoom;
  final void Function(String name) onConstituencyTap;

  const _ConstituencyMapWidget({
    required this.data,
    required this.svgParser,
    required this.currentZoom,
    required this.onConstituencyTap,
  });

  @override
  State<_ConstituencyMapWidget> createState() => _ConstituencyMapWidgetState();
}

class _ConstituencyMapWidgetState extends State<_ConstituencyMapWidget> {
  final GlobalKey _mapKey = GlobalKey();
  Map<String, Size> _textSizes = {};
  bool _textSizesComputed = false;

  // Fixed map size - must match parent SizedBox in _buildInteractiveMap
  static const _mapSize = Size(1200, 700);

  SvgPathParser get _pathParser => widget.svgParser;

  @override
  void initState() {
    super.initState();
    _precomputeTextSizes();
  }

  void _precomputeTextSizes() {
    if (_textSizesComputed) return;

    const textStyle = TextStyle(fontSize: 8, fontWeight: FontWeight.bold);
    final textSizes = <String, Size>{};

    for (final id in _pathParser.districtIds) {
      if (id.startsWith('path')) continue;

      final label = _formatConstituencyName(id);
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textSizes[id] = Size(textPainter.width, textPainter.height);
    }

    _textSizes = textSizes;
    _textSizesComputed = true;
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get actual constraints and ensure consistent sizing
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use actual available size, constrained to our max
        final actualSize = Size(
          constraints.maxWidth.clamp(0, _mapSize.width),
          constraints.maxHeight.clamp(0, _mapSize.height),
        );

        return SizedBox(
          width: actualSize.width,
          height: actualSize.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SvgPicture.asset(
                'assets/data/election/nepal_constituencies.svg',
                key: _mapKey,
                width: actualSize.width,
                height: actualSize.height,
                fit: BoxFit.contain,
                alignment: Alignment.topLeft,
              ),
              // Constituency labels
              ..._buildConstituencyLabels(actualSize),
              Positioned.fill(
                child: GestureDetector(
                  onTapUp: (details) => _handleTap(details, actualSize),
                  behavior: HitTestBehavior.translucent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildConstituencyLabels(Size mapSize) {
    final labels = <Widget>[];
    final pathCenters = _pathParser.pathCenters;
    final zoom = widget.currentZoom;

    const baseFontSize = 12.0;

    // Calculate scale to match SvgPicture's BoxFit.contain behavior
    final svgWidth = _pathParser.svgWidth;
    final svgHeight = _pathParser.svgHeight;
    final scaleX = mapSize.width / svgWidth;
    final scaleY = mapSize.height / svgHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // No offset needed since we use Alignment.topLeft on SvgPicture

    for (final entry in pathCenters.entries) {
      final id = entry.key;
      final svgCenter = entry.value;

      if (id.startsWith('path')) continue;

      final label = _formatConstituencyName(id);
      final textSize = _textSizes[id];
      final clearance = _pathParser.getLabelClearance(id) ?? 0;

      // Check if text fits at current zoom - use smaller threshold to show more labels
      if (textSize != null) {
        final effectiveClearance = clearance * scale * zoom;
        if (effectiveClearance < textSize.width / 4) {
          continue;
        }
      }

      // Transform SVG coordinates to screen coordinates (scale only, no offset)
      final screenX = svgCenter.dx * scale;
      final screenY = svgCenter.dy * scale;

      // Scale font size inversely with zoom to keep labels readable but not overwhelming
      final adjustedFontSize = baseFontSize / zoom;
      final adjustedHalfWidth = (textSize?.width ?? 20) / 2 / zoom;
      final adjustedHalfHeight = (textSize?.height ?? 6) / 2 / zoom;

      labels.add(Positioned(
        left: screenX - adjustedHalfWidth,
        top: screenY - adjustedHalfHeight,
        child: IgnorePointer(
          child: Text(
            label,
            style: TextStyle(
              fontSize: adjustedFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              shadows: const [
                Shadow(color: Colors.white, blurRadius: 2),
                Shadow(color: Colors.white, blurRadius: 3),
              ],
            ),
          ),
        ),
      ));
    }

    return labels;
  }

  void _handleTap(TapUpDetails details, Size mapSize) {
    final renderBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Convert screen to SVG coordinates (matching topLeft alignment)
    final svgWidth = _pathParser.svgWidth;
    final svgHeight = _pathParser.svgHeight;
    final scaleX = mapSize.width / svgWidth;
    final scaleY = mapSize.height / svgHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final svgPoint = Offset(
      localPosition.dx / scale,
      localPosition.dy / scale,
    );
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

class _CandidateCard extends ConsumerWidget {
  final Candidate candidate;

  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadersAsync = ref.watch(leadersProvider);
    final showVotes = ref.watch(showVotesProvider);
    final l10n = AppLocalizations.of(context);

    // Check if this candidate exists in leaders data (match by name since IDs differ between sources)
    final matchingLeader = leadersAsync.maybeWhen(
      data: (data) {
        for (final leader in data.leaders) {
          if (leader.name.toLowerCase() == candidate.name.toLowerCase()) {
            return leader;
          }
        }
        return null;
      },
      orElse: () => null,
    );
    final hasLeaderProfile = matchingLeader != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: hasLeaderProfile
            ? () => context.push('/leaders/${matchingLeader.id}')
            : null,
        borderRadius: BorderRadius.circular(12),
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
                    if (showVotes && candidate.votes > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.how_to_vote, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${candidate.votes} ${l10n.votes}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Show arrow if leader profile exists
              if (hasLeaderProfile)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
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

