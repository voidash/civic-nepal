import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/osm_data.dart';
import '../providers/osm_provider.dart';

/// Overlay widget that renders OSM data layers on the map
class MapLayersOverlay extends ConsumerWidget {
  final double currentZoom;

  const MapLayersOverlay({
    super.key,
    required this.currentZoom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layerState = ref.watch(mapLayersProvider);

    if (!layerState.hasAnyLayer) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Roads layer (render first, below points)
        if (layerState.showRoads) _RoadsLayer(layerState: layerState),

        // Point layers
        if (layerState.showSchools)
          _PointsLayer(
            dataProvider: schoolsProvider,
            color: Colors.orange,
            icon: Icons.school,
            currentZoom: currentZoom,
          ),
        if (layerState.showColleges)
          _PointsLayer(
            dataProvider: collegesProvider,
            color: Colors.purple,
            icon: Icons.account_balance,
            currentZoom: currentZoom,
          ),
        if (layerState.showGovernment)
          _PointsLayer(
            dataProvider: governmentProvider,
            color: Colors.blue,
            icon: Icons.assured_workload,
            currentZoom: currentZoom,
          ),
      ],
    );
  }
}

/// Layer for rendering road lines
class _RoadsLayer extends ConsumerWidget {
  final MapLayerState layerState;

  const _RoadsLayer({required this.layerState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadsAsync = ref.watch(roadsProvider);

    return roadsAsync.when(
      data: (roadData) => CustomPaint(
        size: const Size(1225, 817),
        painter: _RoadsPainter(
          roadData: roadData,
          showTrunk: layerState.showTrunk,
          showPrimary: layerState.showPrimary,
          showSecondary: layerState.showSecondary,
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Custom painter for roads
class _RoadsPainter extends CustomPainter {
  final OsmRoadData roadData;
  final bool showTrunk;
  final bool showPrimary;
  final bool showSecondary;

  _RoadsPainter({
    required this.roadData,
    required this.showTrunk,
    required this.showPrimary,
    required this.showSecondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw secondary first (bottom), then primary, then trunk (top)
    if (showSecondary) {
      _drawRoads(canvas, roadData.roads['secondary'] ?? [], Colors.grey, 1.0);
    }
    if (showPrimary) {
      _drawRoads(canvas, roadData.roads['primary'] ?? [], Colors.amber.shade700, 1.5);
    }
    if (showTrunk) {
      _drawRoads(canvas, roadData.roads['trunk'] ?? [], Colors.red.shade700, 2.0);
    }
  }

  void _drawRoads(Canvas canvas, List<OsmRoad> roads, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final road in roads) {
      if (road.coords.length < 2) continue;

      final path = Path();
      bool first = true;

      for (final coord in road.coords) {
        if (coord.length < 2) continue;

        final lon = coord[0];
        final lat = coord[1];
        final (x, y) = NepalBounds.latLonToSvg(lat, lon);

        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadsPainter oldDelegate) {
    return showTrunk != oldDelegate.showTrunk ||
        showPrimary != oldDelegate.showPrimary ||
        showSecondary != oldDelegate.showSecondary;
  }
}

/// Layer for rendering point markers
class _PointsLayer extends ConsumerWidget {
  final FutureProvider<OsmPointData> dataProvider;
  final Color color;
  final IconData icon;
  final double currentZoom;

  const _PointsLayer({
    required this.dataProvider,
    required this.color,
    required this.icon,
    required this.currentZoom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataProvider);

    return dataAsync.when(
      data: (data) => CustomPaint(
        size: const Size(1225, 817),
        painter: _PointsPainter(
          points: data.items,
          color: color,
          currentZoom: currentZoom,
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Custom painter for point markers
class _PointsPainter extends CustomPainter {
  final List<OsmPoint> points;
  final Color color;
  final double currentZoom;

  _PointsPainter({
    required this.points,
    required this.color,
    required this.currentZoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Adaptive rendering based on zoom level
    // At low zoom, only show a subset of points to avoid clutter
    final pointsToShow = _getPointsForZoom();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Point size scales inversely with zoom (smaller when zoomed out)
    final baseRadius = 3.0 / currentZoom.clamp(0.5, 3.0);
    final radius = baseRadius.clamp(2.0, 6.0);

    for (final point in pointsToShow) {
      final (x, y) = NepalBounds.latLonToSvg(point.lat, point.lon);

      // Skip if outside visible bounds
      if (x < 0 || x > size.width || y < 0 || y > size.height) continue;

      canvas.drawCircle(Offset(x, y), radius, paint);
      canvas.drawCircle(Offset(x, y), radius, borderPaint);
    }
  }

  List<OsmPoint> _getPointsForZoom() {
    // At low zoom, sample points to reduce clutter
    if (currentZoom < 1.5) {
      // Show ~10% of points when zoomed out
      return points.where((p) => p.id % 10 == 0).toList();
    } else if (currentZoom < 3.0) {
      // Show ~30% of points
      return points.where((p) => p.id % 3 == 0).toList();
    } else if (currentZoom < 5.0) {
      // Show ~50% of points
      return points.where((p) => p.id % 2 == 0).toList();
    }
    // Show all points when zoomed in
    return points;
  }

  @override
  bool shouldRepaint(covariant _PointsPainter oldDelegate) {
    return currentZoom != oldDelegate.currentZoom ||
        color != oldDelegate.color;
  }
}

/// Layer control panel widget
class MapLayerControls extends ConsumerWidget {
  const MapLayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layerState = ref.watch(mapLayersProvider);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Layers',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () =>
                          ref.read(mapLayersProvider.notifier).showAll(),
                      child: const Text('All'),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(mapLayersProvider.notifier).hideAll(),
                      child: const Text('None'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            _LayerToggle(
              label: 'Roads',
              icon: Icons.route,
              color: Colors.red,
              isEnabled: layerState.showRoads,
              onToggle: () =>
                  ref.read(mapLayersProvider.notifier).toggleRoads(),
            ),
            if (layerState.showRoads) ...[
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  children: [
                    _SubLayerToggle(
                      label: 'Trunk (National)',
                      color: Colors.red.shade700,
                      isEnabled: layerState.showTrunk,
                      onToggle: () =>
                          ref.read(mapLayersProvider.notifier).toggleTrunk(),
                    ),
                    _SubLayerToggle(
                      label: 'Primary',
                      color: Colors.amber.shade700,
                      isEnabled: layerState.showPrimary,
                      onToggle: () =>
                          ref.read(mapLayersProvider.notifier).togglePrimary(),
                    ),
                    _SubLayerToggle(
                      label: 'Secondary',
                      color: Colors.grey,
                      isEnabled: layerState.showSecondary,
                      onToggle: () =>
                          ref.read(mapLayersProvider.notifier).toggleSecondary(),
                    ),
                  ],
                ),
              ),
            ],
            _LayerToggle(
              label: 'Schools',
              icon: Icons.school,
              color: Colors.orange,
              isEnabled: layerState.showSchools,
              onToggle: () =>
                  ref.read(mapLayersProvider.notifier).toggleSchools(),
            ),
            _LayerToggle(
              label: 'Colleges',
              icon: Icons.account_balance,
              color: Colors.purple,
              isEnabled: layerState.showColleges,
              onToggle: () =>
                  ref.read(mapLayersProvider.notifier).toggleColleges(),
            ),
            _LayerToggle(
              label: 'Government',
              icon: Icons.assured_workload,
              color: Colors.blue,
              isEnabled: layerState.showGovernment,
              onToggle: () =>
                  ref.read(mapLayersProvider.notifier).toggleGovernment(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isEnabled;
  final VoidCallback onToggle;

  const _LayerToggle({
    required this.label,
    required this.icon,
    required this.color,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isEnabled ? color : Colors.grey),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            Switch(
              value: isEnabled,
              onChanged: (_) => onToggle(),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubLayerToggle extends StatelessWidget {
  final String label;
  final Color color;
  final bool isEnabled;
  final VoidCallback onToggle;

  const _SubLayerToggle({
    required this.label,
    required this.color,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 3,
              color: isEnabled ? color : Colors.grey.shade300,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Checkbox(
              value: isEnabled,
              onChanged: (_) => onToggle(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
