import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/geo_districts_provider.dart';
import '../../widgets/home_title.dart';
import '../../widgets/source_attribution.dart';
import 'local_body_screen.dart'; // For election data models

/// Local body type colors
Color _getTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'mahanagarpalika':
    case 'metropolitan':
      return Colors.purple;
    case 'upamahanagarpalika':
    case 'sub-metropolitan':
      return Colors.indigo;
    case 'nagarpalika':
    case 'municipality':
      return Colors.blue;
    case 'gaunpalika':
    case 'rural-municipality':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

String _getTypeLabel(String type, AppLocalizations l10n) {
  switch (type.toLowerCase()) {
    case 'mahanagarpalika':
      return 'Metropolitan';
    case 'upamahanagarpalika':
      return 'Sub-Metropolitan';
    case 'nagarpalika':
      return 'Municipality';
    case 'gaunpalika':
      return 'Rural Municipality';
    default:
      return type;
  }
}

/// GeoJSON-based Local Body Screen
class GeoLocalBodyScreen extends ConsumerStatefulWidget {
  final String districtName;

  const GeoLocalBodyScreen({super.key, required this.districtName});

  @override
  ConsumerState<GeoLocalBodyScreen> createState() => _GeoLocalBodyScreenState();
}

class _GeoLocalBodyScreenState extends ConsumerState<GeoLocalBodyScreen> {
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
    final geoDataAsync = ref.watch(geoLocalUnitsProvider(widget.districtName));
    final electionDataAsync = ref.watch(localElectionResultsProvider);
    final selectedUnit = ref.watch(selectedGeoLocalUnitProvider);
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: selectedUnit == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedUnit != null) {
          ref.read(selectedGeoLocalUnitProvider.notifier).clear();
        }
      },
      child: Scaffold(
        bottomNavigationBar: const SourceAttribution(
          sourceName: 'National Geoportal Nepal',
          sourceUrl: 'https://nationalgeoportal.gov.np',
        ),
        appBar: AppBar(
          title: HomeTitle(child: Text(widget.districtName)),
          actions: [
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              tooltip: l10n.resetZoom,
              onPressed: () => _transformationController.value = Matrix4.identity(),
            ),
          ],
        ),
        body: geoDataAsync.when(
          data: (geoData) {
            if (geoData.localUnits.isEmpty) {
              return _buildListFallback(electionDataAsync);
            }
            return _buildMapContent(geoData, electionDataAsync, selectedUnit);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => _buildListFallback(electionDataAsync),
        ),
      ),
    );
  }

  Widget _buildListFallback(AsyncValue<LocalElectionData> electionDataAsync) {
    return electionDataAsync.when(
      data: (data) {
        final localBodies = data.localBodies
            .where((lb) => lb.district.toLowerCase() == widget.districtName.toLowerCase())
            .toList();

        if (localBodies.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context).noDataAvailable),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: localBodies.length,
          itemBuilder: (context, index) {
            final lb = localBodies[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getTypeColor(lb.type),
                  child: Icon(
                    lb.type.contains('metropolitan') ? Icons.location_city : Icons.business,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(lb.name),
                subtitle: Text(lb.nameNp),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLocalBodyDetails(lb),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildMapContent(
    GeoLocalUnitsData geoData,
    AsyncValue<LocalElectionData> electionDataAsync,
    GeoLocalUnit? selectedUnit,
  ) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 10.0,
                constrained: false,
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: GestureDetector(
                    onTapUp: (details) => _handleTap(details, geoData.localUnits),
                    child: CustomPaint(
                      size: const Size(800, 600),
                      painter: _GeoLocalBodyMapPainter(
                        localUnits: geoData.localUnits,
                        selectedUnit: selectedUnit,
                        currentZoom: _currentZoom,
                      ),
                    ),
                  ),
                ),
              ),
              if (selectedUnit != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: _LocalUnitInfoChip(unit: selectedUnit),
                ),
            ],
          ),
        ),
        // Side panel for selected local body
        if (selectedUnit != null)
          _buildOfficialsPanel(electionDataAsync, selectedUnit),
      ],
    );
  }

  void _handleTap(TapUpDetails details, List<GeoLocalUnit> localUnits) {
    // localPosition is already in canvas coordinates (0 to width/height)
    // because GestureDetector is inside the InteractiveViewer's child
    final canvasPos = details.localPosition;

    // Calculate bounds from the local units
    double minLon = double.infinity, maxLon = double.negativeInfinity;
    double minLat = double.infinity, maxLat = double.negativeInfinity;

    for (final unit in localUnits) {
      for (final ring in unit.rings) {
        for (final point in ring) {
          if (point[0] < minLon) minLon = point[0];
          if (point[0] > maxLon) maxLon = point[0];
          if (point[1] < minLat) minLat = point[1];
          if (point[1] > maxLat) maxLat = point[1];
        }
      }
    }

    // Add padding
    final lonPadding = (maxLon - minLon) * 0.05;
    final latPadding = (maxLat - minLat) * 0.05;
    minLon -= lonPadding;
    maxLon += lonPadding;
    minLat -= latPadding;
    maxLat += latPadding;

    const width = 800.0;
    const height = 600.0;

    final lon = minLon + (canvasPos.dx / width) * (maxLon - minLon);
    final lat = maxLat - (canvasPos.dy / height) * (maxLat - minLat);

    // Find which local unit was tapped
    for (final unit in localUnits) {
      if (_isPointInLocalUnit(lon, lat, unit)) {
        ref.read(selectedGeoLocalUnitProvider.notifier).select(unit);
        return;
      }
    }

    ref.read(selectedGeoLocalUnitProvider.notifier).clear();
  }

  bool _isPointInLocalUnit(double lon, double lat, GeoLocalUnit unit) {
    for (final ring in unit.rings) {
      if (_isPointInPolygon(lon, lat, ring)) {
        return true;
      }
    }
    return false;
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

  Widget _buildOfficialsPanel(AsyncValue<LocalElectionData> electionDataAsync, GeoLocalUnit selectedUnit) {
    return electionDataAsync.when(
      data: (data) {
        // Find matching local body from election data
        final localBody = data.localBodies.firstWhere(
          (lb) => lb.name.toLowerCase() == selectedUnit.name.toLowerCase() ||
              lb.nameNp == selectedUnit.name,
          orElse: () => LocalBodyResult(
            id: '',
            locId: '',
            name: selectedUnit.name,
            nameNp: '',
            district: widget.districtName,
            province: 0,
            type: selectedUnit.type,
            officials: [],
          ),
        );

        return _OfficialsPanel(
          localBody: localBody,
          geoUnit: selectedUnit,
          onClose: () => ref.read(selectedGeoLocalUnitProvider.notifier).clear(),
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

  void _showLocalBodyDetails(LocalBodyResult lb) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _OfficialsBottomSheet(
          localBody: lb,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

/// Custom painter for GeoJSON local body map
class _GeoLocalBodyMapPainter extends CustomPainter {
  final List<GeoLocalUnit> localUnits;
  final GeoLocalUnit? selectedUnit;
  final double currentZoom;

  late final double minLon, maxLon, minLat, maxLat;

  _GeoLocalBodyMapPainter({
    required this.localUnits,
    required this.selectedUnit,
    required this.currentZoom,
  }) {
    _calculateBounds();
  }

  void _calculateBounds() {
    double minLonTemp = double.infinity, maxLonTemp = double.negativeInfinity;
    double minLatTemp = double.infinity, maxLatTemp = double.negativeInfinity;

    for (final unit in localUnits) {
      for (final ring in unit.rings) {
        for (final point in ring) {
          if (point[0] < minLonTemp) minLonTemp = point[0];
          if (point[0] > maxLonTemp) maxLonTemp = point[0];
          if (point[1] < minLatTemp) minLatTemp = point[1];
          if (point[1] > maxLatTemp) maxLatTemp = point[1];
        }
      }
    }

    // Add padding
    final lonPadding = (maxLonTemp - minLonTemp) * 0.05;
    final latPadding = (maxLatTemp - minLatTemp) * 0.05;

    minLon = minLonTemp - lonPadding;
    maxLon = maxLonTemp + lonPadding;
    minLat = minLatTemp - latPadding;
    maxLat = maxLatTemp + latPadding;
  }

  Offset _latLonToCanvas(double lat, double lon, Size size) {
    final x = (lon - minLon) / (maxLon - minLon) * size.width;
    final y = (maxLat - lat) / (maxLat - minLat) * size.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw each local unit
    for (final unit in localUnits) {
      final isSelected = selectedUnit?.name == unit.name;
      final baseColor = _getTypeColor(unit.type);

      final fillPaint = Paint()
        ..color = isSelected ? baseColor : baseColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = isSelected ? Colors.black : Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 0.8
        ..strokeJoin = StrokeJoin.round;

      _drawLocalUnit(canvas, size, unit, fillPaint, borderPaint);
    }

    // Always draw labels for local bodies
    _drawLabels(canvas, size);
  }

  void _drawLocalUnit(Canvas canvas, Size size, GeoLocalUnit unit, Paint fillPaint, Paint borderPaint) {
    for (final ring in unit.rings) {
      if (ring.length < 3) continue;

      final path = Path();
      bool first = true;
      for (final point in ring) {
        final offset = _latLonToCanvas(point[1], point[0], size);
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
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textStyle = ui.TextStyle(
      color: Colors.black87,
      fontSize: 14 / currentZoom.clamp(1.0, 3.0),
      fontWeight: FontWeight.w600,
    );

    for (final unit in localUnits) {
      final (lon, lat) = unit.centroid;
      final offset = _latLonToCanvas(lat, lon, size);

      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 2,
      ))
        ..pushStyle(textStyle)
        ..addText(unit.name);

      final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 80));
      canvas.drawParagraph(
        paragraph,
        Offset(offset.dx - paragraph.width / 2, offset.dy - paragraph.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GeoLocalBodyMapPainter oldDelegate) {
    return selectedUnit != oldDelegate.selectedUnit ||
        currentZoom != oldDelegate.currentZoom;
  }
}

/// Local unit info chip
class _LocalUnitInfoChip extends StatelessWidget {
  final GeoLocalUnit unit;

  const _LocalUnitInfoChip({required this.unit});

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(unit.type);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_city, size: 16, color: color),
            const SizedBox(width: 8),
            Text(unit.name, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

/// Officials panel
class _OfficialsPanel extends StatelessWidget {
  final LocalBodyResult localBody;
  final GeoLocalUnit geoUnit;
  final VoidCallback onClose;

  const _OfficialsPanel({
    required this.localBody,
    required this.geoUnit,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _getTypeColor(geoUnit.type);

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
                        localBody.name.isNotEmpty ? localBody.name : geoUnit.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (localBody.nameNp.isNotEmpty)
                        Text(
                          localBody.nameNp,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getTypeLabel(geoUnit.type, l10n),
                          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
          // Officials list
          Expanded(
            child: localBody.officials.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noCandidatesFound,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: localBody.officials.length,
                    itemBuilder: (context, index) {
                      final official = localBody.officials[index];
                      return _OfficialCard(official: official);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Officials bottom sheet (for list fallback)
class _OfficialsBottomSheet extends StatelessWidget {
  final LocalBodyResult localBody;
  final ScrollController scrollController;

  const _OfficialsBottomSheet({
    required this.localBody,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(localBody.name, style: Theme.of(context).textTheme.titleLarge),
              if (localBody.nameNp.isNotEmpty)
                Text(
                  localBody.nameNp,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: localBody.officials.isEmpty
              ? Center(child: Text(l10n.noCandidatesFound))
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: localBody.officials.length,
                  itemBuilder: (context, index) {
                    final official = localBody.officials[index];
                    return _OfficialCard(official: official);
                  },
                ),
        ),
      ],
    );
  }
}

/// Official card (reused from local_body_screen.dart pattern)
class _OfficialCard extends StatelessWidget {
  final ElectedOfficial official;

  const _OfficialCard({required this.official});

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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPositionColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      official.position,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getPositionColor(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    official.nameNp.isNotEmpty ? official.nameNp : official.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (official.partySymbol.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CachedNetworkImage(
                            imageUrl: official.partySymbol,
                            width: 20,
                            height: 20,
                            errorWidget: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          official.party,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (official.votes > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.how_to_vote, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${official.votes} votes',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
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

  Color _getPositionColor() {
    if (official.position.contains('Mayor') || official.position.contains('Chairperson')) {
      return Colors.amber.shade800;
    }
    return Colors.blue.shade700;
  }

  Widget _buildAvatar(BuildContext context) {
    final fallback = CircleAvatar(
      radius: 28,
      backgroundColor: _getPositionColor().withValues(alpha: 0.1),
      child: Icon(
        official.position.contains('Mayor') || official.position.contains('Chairperson')
            ? Icons.person
            : Icons.person_outline,
        color: _getPositionColor(),
      ),
    );

    if (official.imageUrl.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: official.imageUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 28,
        backgroundImage: imageProvider,
      ),
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
