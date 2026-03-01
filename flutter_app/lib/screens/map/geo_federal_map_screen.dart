import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/geo_districts_provider.dart';
import '../../providers/constituencies_provider.dart';
import '../../providers/leaders_provider.dart';
import '../../models/constituency.dart';
import '../../widgets/home_title.dart';
import '../../widgets/source_attribution.dart';

/// Province colors for constituencies
const _provinceColors = [
  Color(0xFFE57373), // Province 1 - Red
  Color(0xFF64B5F6), // Province 2 - Blue
  Color(0xFF81C784), // Province 3 - Green
  Color(0xFFFFD54F), // Province 4 - Yellow
  Color(0xFFBA68C8), // Province 5 - Purple
  Color(0xFF4DB6AC), // Province 6 - Teal
  Color(0xFFFF8A65), // Province 7 - Orange
];

/// Lightweight Federal Constituency Map using simplified JSON
class GeoFederalMapScreen extends ConsumerStatefulWidget {
  const GeoFederalMapScreen({super.key});

  @override
  ConsumerState<GeoFederalMapScreen> createState() => _GeoFederalMapScreenState();
}

class _GeoFederalMapScreenState extends ConsumerState<GeoFederalMapScreen> {
  final TransformationController _transformationController = TransformationController();
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
    final constituenciesAsync = ref.watch(geoConstituenciesProvider);
    final electionDataAsync = ref.watch(constituenciesProvider);
    final selectedConstituency = ref.watch(selectedGeoConstituencyProvider);
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: selectedConstituency == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedConstituency != null) {
          ref.read(selectedGeoConstituencyProvider.notifier).clear();
        }
      },
      child: Scaffold(
        bottomNavigationBar: const SourceAttribution.election(),
        appBar: AppBar(
          title: HomeTitle(child: Text(l10n.constituencyMap)),
          actions: [
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              tooltip: l10n.resetZoom,
              onPressed: () => _transformationController.value = Matrix4.identity(),
            ),
          ],
        ),
        body: constituenciesAsync.when(
          data: (data) => _buildMapContent(
            data,
            electionDataAsync,
            selectedConstituency,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  // Canvas size — aspect ratio should roughly match the data viewBox for uniform scaling
  static const _canvasWidth = 1200.0;
  static const _canvasHeight = 680.0;

  Widget _buildMapContent(
    GeoConstituenciesData data,
    AsyncValue<ConstituencyData> electionDataAsync,
    GeoConstituency? selectedConstituency,
  ) {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final isWideScreen = outerConstraints.maxWidth > 700;

        return Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Center the map initially
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_transformationController.value == Matrix4.identity()) {
                      final dx = (constraints.maxWidth - _canvasWidth) / 2;
                      final dy = (constraints.maxHeight - _canvasHeight) / 2;
                      if (dx > 0 || dy > 0) {
                        _transformationController.value = Matrix4.identity()
                          ..setTranslationRaw(dx.clamp(0, double.infinity), dy.clamp(0, double.infinity), 0);
                      }
                    }
                  });
                  return Stack(
                    children: [
                      InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 15.0,
                        constrained: false,
                        child: SizedBox(
                          width: _canvasWidth,
                          height: _canvasHeight,
                          child: GestureDetector(
                            onTapUp: (details) => _handleTap(details, data, isWideScreen, electionDataAsync),
                            child: CustomPaint(
                              size: const Size(_canvasWidth, _canvasHeight),
                              painter: _ConstituencyMapPainter(
                                data: data,
                                electionData: electionDataAsync.valueOrNull,
                                selectedConstituency: selectedConstituency,
                                currentZoom: _currentZoom,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (selectedConstituency != null)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: _ConstituencyInfoChip(constituency: selectedConstituency),
                        ),
                      // Map data attribution
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Geographic data © OpenStreetMap contributors',
                            style: TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Side panel only on wide screens
            if (isWideScreen && selectedConstituency != null)
              _buildCandidatesPanel(electionDataAsync, selectedConstituency),
          ],
        );
      },
    );
  }

  void _handleTap(
    TapUpDetails details,
    GeoConstituenciesData data,
    bool isWideScreen,
    AsyncValue<ConstituencyData> electionDataAsync,
  ) {
    final canvasPos = details.localPosition;
    final viewBox = data.viewBox;

    // Convert canvas position to viewBox coordinates (uniform scaling inverse)
    final scaleX = _canvasWidth / viewBox[2];
    final scaleY = _canvasHeight / viewBox[3];
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final offsetX = (_canvasWidth - viewBox[2] * scale) / 2;
    final offsetY = (_canvasHeight - viewBox[3] * scale) / 2;
    final vbX = (canvasPos.dx - offsetX) / scale + viewBox[0];
    final vbY = (canvasPos.dy - offsetY) / scale + viewBox[1];

    // Find which constituency was tapped using point-in-polygon
    for (final constituency in data.constituencies) {
      if (_isPointInPolygon(vbX, vbY, constituency.path)) {
        ref.read(selectedGeoConstituencyProvider.notifier).select(constituency);

        // On mobile, show bottom sheet instead of side panel
        if (!isWideScreen) {
          _showCandidatesBottomSheet(constituency, electionDataAsync);
        }
        return;
      }
    }

    ref.read(selectedGeoConstituencyProvider.notifier).clear();
  }

  void _showCandidatesBottomSheet(
    GeoConstituency geoConstituency,
    AsyncValue<ConstituencyData> electionDataAsync,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return electionDataAsync.when(
            data: (data) {
              // Find matching constituency in election data
              Constituency? constituency;
              for (final districts in data.districts.values) {
                for (final c in districts) {
                  if (c.name.toLowerCase() == geoConstituency.name.toLowerCase() ||
                      c.svgPathId == geoConstituency.id) {
                    constituency = c;
                    break;
                  }
                }
                if (constituency != null) break;
              }

              return _CandidatesPanelContent(
                constituency: constituency,
                geoConstituency: geoConstituency,
                scrollController: scrollController,
                onClose: () {
                  Navigator.pop(context);
                  ref.read(selectedGeoConstituencyProvider.notifier).clear();
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
        },
      ),
    ).whenComplete(() {
      ref.read(selectedGeoConstituencyProvider.notifier).clear();
    });
  }

  bool _isPointInPolygon(double x, double y, List<List<double>> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i][0], yi = polygon[i][1];
      final xj = polygon[j][0], yj = polygon[j][1];

      if (((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  Widget _buildCandidatesPanel(
    AsyncValue<ConstituencyData> electionDataAsync,
    GeoConstituency selectedConstituency,
  ) {
    return electionDataAsync.when(
      data: (data) {
        // Find matching constituency in election data
        Constituency? constituency;
        for (final districts in data.districts.values) {
          for (final c in districts) {
            if (c.name.toLowerCase() == selectedConstituency.name.toLowerCase() ||
                c.svgPathId == selectedConstituency.id) {
              constituency = c;
              break;
            }
          }
          if (constituency != null) break;
        }

        return _CandidatesPanel(
          constituency: constituency,
          geoConstituency: selectedConstituency,
          onClose: () => ref.read(selectedGeoConstituencyProvider.notifier).clear(),
        );
      },
      loading: () => const SizedBox(
        width: 350,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => SizedBox(
        width: 350,
        child: Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Custom painter for constituency map
class _ConstituencyMapPainter extends CustomPainter {
  final GeoConstituenciesData data;
  final ConstituencyData? electionData;
  final GeoConstituency? selectedConstituency;
  final double currentZoom;

  _ConstituencyMapPainter({
    required this.data,
    required this.electionData,
    required this.selectedConstituency,
    required this.currentZoom,
  });

  int _getProvince(String district) {
    if (electionData == null) return 0;

    for (final entry in electionData!.districts.entries) {
      for (final c in entry.value) {
        if (c.district.toLowerCase() == district.toLowerCase()) {
          return c.province;
        }
      }
    }
    return 0;
  }

  Color _getProvinceColor(int province) {
    if (province < 1 || province > 7) return Colors.grey;
    return _provinceColors[province - 1];
  }

  Offset _viewBoxToCanvas(double x, double y, Size size) {
    final viewBox = data.viewBox;
    // Use uniform scaling to avoid distortion
    final scaleX = size.width / viewBox[2];
    final scaleY = size.height / viewBox[3];
    final scale = scaleX < scaleY ? scaleX : scaleY;
    // Center the content within the canvas
    final offsetX = (size.width - viewBox[2] * scale) / 2;
    final offsetY = (size.height - viewBox[3] * scale) / 2;
    final canvasX = (x - viewBox[0]) * scale + offsetX;
    final canvasY = (y - viewBox[1]) * scale + offsetY;
    return Offset(canvasX, canvasY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw disputed territory first (so it's behind constituencies)
    _drawDisputedTerritory(canvas, size);

    // Draw all constituencies
    for (final constituency in data.constituencies) {
      final isSelected = selectedConstituency?.id == constituency.id;
      final province = _getProvince(constituency.district);
      final baseColor = _getProvinceColor(province);

      final fillPaint = Paint()
        ..color = isSelected ? baseColor : baseColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = isSelected ? Colors.black : Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 0.5
        ..strokeJoin = StrokeJoin.round;

      _drawPolygon(canvas, size, constituency.path, fillPaint, borderPaint);
    }

    // Draw constituency labels
    _drawLabels(canvas, size);
  }

  void _drawDisputedTerritory(Canvas canvas, Size size) {
    final disputed = data.disputedTerritory;
    if (disputed == null || disputed.path.isEmpty) return;

    // Fill with a distinct color to show it's Nepal's claimed territory
    final fillPaint = Paint()
      ..color = const Color(0xFFFFCDD2) // Light red to indicate disputed
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFD32F2F) // Red border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    _drawPolygon(canvas, size, disputed.path, fillPaint, borderPaint);

    // Draw label for disputed territory at higher zoom
    if (currentZoom >= 2) {
      final offset = _viewBoxToCanvas(
        disputed.centroid[0],
        disputed.centroid[1],
        size,
      );

      final textStyle = ui.TextStyle(
        color: const Color(0xFFB71C1C),
        fontSize: 7 / currentZoom.clamp(1.0, 2.5),
        fontWeight: FontWeight.w600,
      );

      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 2,
      ))
        ..pushStyle(textStyle)
        ..addText(disputed.name);

      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 100));

      canvas.drawParagraph(
        paragraph,
        Offset(offset.dx - paragraph.width / 2, offset.dy - paragraph.height / 2),
      );
    }
  }

  void _drawPolygon(
    Canvas canvas,
    Size size,
    List<List<double>> points,
    Paint fillPaint,
    Paint borderPaint,
  ) {
    if (points.length < 3) return;

    final path = Path();
    bool first = true;

    for (final point in points) {
      final offset = _viewBoxToCanvas(point[0], point[1], size);
      if (first) {
        path.moveTo(offset.dx, offset.dy);
        first = false;
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  double _calculatePolygonArea(List<List<double>> path) {
    // Shoelace formula for polygon area
    if (path.length < 3) return 0;
    double area = 0;
    int j = path.length - 1;
    for (int i = 0; i < path.length; i++) {
      area += (path[j][0] + path[i][0]) * (path[j][1] - path[i][1]);
      j = i;
    }
    return (area / 2).abs();
  }

  void _drawLabels(Canvas canvas, Size size) {
    final fontSize = 9 / currentZoom.clamp(1.0, 3.0);
    final textStyle = ui.TextStyle(
      color: Colors.black87,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );

    // Calculate minimum area threshold based on zoom
    // At zoom 1, only show labels for large constituencies
    // At higher zoom, show all labels
    final minArea = currentZoom > 2 ? 0 : 50 / (currentZoom * currentZoom * currentZoom);

    // Track placed label positions to avoid overlap
    final placedLabels = <Rect>[];

    for (final constituency in data.constituencies) {
      // Calculate constituency area
      final area = _calculatePolygonArea(constituency.path);
      if (area < minArea) continue;

      final offset = _viewBoxToCanvas(
        constituency.centroid[0],
        constituency.centroid[1],
        size,
      );

      // Skip if label center would be outside canvas bounds (with margin)
      const margin = 20.0;
      if (offset.dx < margin || offset.dx > size.width - margin ||
          offset.dy < margin || offset.dy > size.height - margin) {
        continue;
      }

      // Format label - just show number for small areas, full name for large
      final label = constituency.number > 0
          ? (area > 100 ? '${constituency.district.split(' ').first}-${constituency.number}' : '${constituency.number}')
          : constituency.district;

      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 1,
      ))
        ..pushStyle(textStyle)
        ..addText(label);

      final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 70));

      // Calculate label bounds
      final labelRect = Rect.fromCenter(
        center: offset,
        width: paragraph.width + 4,
        height: paragraph.height + 2,
      );

      // Check for overlap with already placed labels (skip at high zoom)
      if (currentZoom < 3) {
        bool overlaps = false;
        for (final placed in placedLabels) {
          if (labelRect.overlaps(placed)) {
            overlaps = true;
            break;
          }
        }
        if (overlaps) continue;
      }

      // Draw label and record position
      placedLabels.add(labelRect);
      canvas.drawParagraph(
        paragraph,
        Offset(offset.dx - paragraph.width / 2, offset.dy - paragraph.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConstituencyMapPainter oldDelegate) {
    return selectedConstituency != oldDelegate.selectedConstituency ||
        currentZoom != oldDelegate.currentZoom;
  }
}

class _ConstituencyInfoChip extends StatelessWidget {
  final GeoConstituency constituency;

  const _ConstituencyInfoChip({required this.constituency});

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
            Text(constituency.name, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _CandidatesPanel extends ConsumerWidget {
  final Constituency? constituency;
  final GeoConstituency geoConstituency;
  final VoidCallback onClose;

  const _CandidatesPanel({
    required this.constituency,
    required this.geoConstituency,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final showVotes = ref.watch(showVotesProvider);

    return Container(
      width: 350,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        geoConstituency.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (constituency != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${constituency!.district} • Province ${constituency!.province}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          '${constituency!.candidates.length} ${l10n.candidates}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
          // Candidates list
          Expanded(
            child: constituency == null || constituency!.candidates.isEmpty
                ? Center(child: Text(l10n.noCandidatesFound))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: constituency!.candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = constituency!.candidates[index];
                      return _CandidateCard(candidate: candidate, showVotes: showVotes);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Shared content widget for candidates panel (used in both side panel and bottom sheet)
class _CandidatesPanelContent extends ConsumerWidget {
  final Constituency? constituency;
  final GeoConstituency geoConstituency;
  final ScrollController? scrollController;
  final VoidCallback onClose;

  const _CandidatesPanelContent({
    required this.constituency,
    required this.geoConstituency,
    required this.onClose,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final showVotes = ref.watch(showVotesProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        geoConstituency.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (constituency != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${constituency!.district} • Province ${constituency!.province}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          '${constituency!.candidates.length} ${l10n.candidates}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
          // Candidates list
          Expanded(
            child: constituency == null || constituency!.candidates.isEmpty
                ? Center(child: Text(l10n.noCandidatesFound))
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: constituency!.candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = constituency!.candidates[index];
                      return _CandidateCard(candidate: candidate, showVotes: showVotes);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends ConsumerWidget {
  final Candidate candidate;
  final bool showVotes;

  const _CandidateCard({required this.candidate, required this.showVotes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadersAsync = ref.watch(leadersProvider);
    final l10n = AppLocalizations.of(context);

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
        onTap: hasLeaderProfile ? () => context.push('/leaders/${matchingLeader.id}') : null,
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
                    Text(candidate.name, style: Theme.of(context).textTheme.titleMedium),
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
        style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );

    if (candidate.imageUrl.isEmpty || candidate.imageUrl.contains('placeholder')) {
      return fallback;
    }

    return CachedNetworkImage(
      imageUrl: candidate.imageUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(radius: 24, backgroundImage: imageProvider),
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
