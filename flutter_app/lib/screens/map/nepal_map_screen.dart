import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/osm_data.dart';
import '../../providers/osm_provider.dart';
import '../../widgets/home_title.dart';
import '../../widgets/source_attribution.dart';

part 'nepal_map_screen.g.dart';

/// OSM Boundaries data model
class OsmBoundaries {
  final String source;
  final List<BoundaryFeature> country;
  final List<BoundaryFeature> provinces;
  final List<BoundaryFeature> districts;

  OsmBoundaries({
    required this.source,
    required this.country,
    required this.provinces,
    required this.districts,
  });

  factory OsmBoundaries.fromJson(Map<String, dynamic> json) {
    return OsmBoundaries(
      source: json['source'] as String,
      country: (json['country'] as List)
          .map((e) => BoundaryFeature.fromJson(e))
          .toList(),
      provinces: (json['provinces'] as List)
          .map((e) => BoundaryFeature.fromJson(e))
          .toList(),
      districts: (json['districts'] as List)
          .map((e) => BoundaryFeature.fromJson(e))
          .toList(),
    );
  }
}

class BoundaryFeature {
  final int id;
  final String name;
  final String nameNe;
  final int adminLevel;
  final List<List<List<double>>> rings;
  final int? province;

  BoundaryFeature({
    required this.id,
    required this.name,
    required this.nameNe,
    required this.adminLevel,
    required this.rings,
    this.province,
  });

  factory BoundaryFeature.fromJson(Map<String, dynamic> json) {
    return BoundaryFeature(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      nameNe: json['name_ne'] as String? ?? '',
      adminLevel: json['admin_level'] as int,
      rings: (json['rings'] as List)
          .map((ring) => (ring as List)
              .map((point) => (point as List).cast<double>().toList())
              .toList())
          .toList(),
      province: json['province'] as int?,
    );
  }

  Offset get centroid {
    if (rings.isEmpty || rings[0].isEmpty) return Offset.zero;
    double sumX = 0, sumY = 0;
    int count = 0;
    for (final ring in rings) {
      for (final point in ring) {
        sumX += point[0];
        sumY += point[1];
        count++;
      }
    }
    return Offset(sumX / count, sumY / count);
  }
}

/// Provider for boundaries data
@Riverpod(keepAlive: true)
Future<OsmBoundaries> boundaries(Ref ref) async {
  final jsonString =
      await rootBundle.loadString('assets/data/osm/boundaries.json');
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return OsmBoundaries.fromJson(json);
}

/// Selected district state
@riverpod
class SelectedMapDistrict extends _$SelectedMapDistrict {
  @override
  BoundaryFeature? build() => null;

  void select(BoundaryFeature? district) => state = district;
  void clear() => state = null;
}

/// Generic selected point of interest (works with any point type)
class SelectedPOI {
  final double lat;
  final double lon;
  final String name;
  final String type;
  final Map<String, String> extra;

  const SelectedPOI({
    required this.lat,
    required this.lon,
    required this.name,
    required this.type,
    this.extra = const {},
  });

  factory SelectedPOI.fromOsmPoint(OsmPoint point, String type) {
    return SelectedPOI(
      lat: point.lat,
      lon: point.lon,
      name: point.name,
      type: type,
      extra: {
        if (point.type != null) 'subtype': point.type!,
      },
    );
  }

  factory SelectedPOI.fromReligious(ReligiousPoint point) {
    return SelectedPOI(
      lat: point.lat,
      lon: point.lon,
      name: point.name,
      type: 'religious',
      extra: {
        'religion': point.religion,
        if (point.denomination != null) 'denomination': point.denomination!,
      },
    );
  }

  factory SelectedPOI.fromPolice(PolicePoint point) {
    return SelectedPOI(
      lat: point.lat,
      lon: point.lon,
      name: point.name,
      type: 'police',
      extra: {
        if (point.phone != null && point.phone!.isNotEmpty) 'phone': point.phone!,
      },
    );
  }

  factory SelectedPOI.fromTrekking(TrekkingPoint point) {
    return SelectedPOI(
      lat: point.lat,
      lon: point.lon,
      name: point.name,
      type: 'trekking',
      extra: {
        'trekking_type': point.type,
        if (point.elevation != null && point.elevation!.isNotEmpty) 'elevation': point.elevation!,
      },
    );
  }
}

/// Selected point state
@riverpod
class SelectedMapPOI extends _$SelectedMapPOI {
  @override
  SelectedPOI? build() => null;

  void select(SelectedPOI? poi) => state = poi;
  void clear() => state = null;
}

/// Selected point state (for schools, colleges, government offices)
@riverpod
class SelectedMapPoint extends _$SelectedMapPoint {
  @override
  OsmPoint? build() => null;

  void select(OsmPoint? point) => state = point;
  void clear() => state = null;
}

/// Selected point type
@riverpod
class SelectedPointType extends _$SelectedPointType {
  @override
  String? build() => null;

  void setType(String? type) => state = type;
}

/// Nepal Map Screen
class NepalMapScreen extends ConsumerStatefulWidget {
  const NepalMapScreen({super.key});

  @override
  ConsumerState<NepalMapScreen> createState() => _NepalMapScreenState();
}

class _NepalMapScreenState extends ConsumerState<NepalMapScreen> {
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
    final boundariesAsync = ref.watch(boundariesProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(child: Text(l10n.nepalMap)),
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
      bottomNavigationBar: const SourceAttribution.osm(),
      body: boundariesAsync.when(
        data: (boundaries) => _buildMapWithControls(boundaries),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('${l10n.error}: $error'),
        ),
      ),
    );
  }

  Widget _buildMapWithControls(OsmBoundaries boundaries) {
    final selectedDistrict = ref.watch(selectedMapDistrictProvider);
    final selectedPOI = ref.watch(selectedMapPOIProvider);
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Row(
      children: [
        // Layer controls panel (always visible on wide screens)
        if (isWideScreen)
          SizedBox(
            width: 280,
            child: _LayerControlPanel(currentZoom: _currentZoom),
          ),

        // Map area
        Expanded(
          child: Stack(
            children: [
              // The map
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 20.0,
                constrained: false,
                child: SizedBox(
                  width: 1200,
                  height: 800,
                  child: GestureDetector(
                    onTapUp: (details) => _handleTap(details, boundaries),
                    child: CustomPaint(
                      size: const Size(1200, 800),
                      painter: _NepalMapPainter(
                        boundaries: boundaries,
                        selectedDistrict: selectedDistrict,
                        currentZoom: _currentZoom,
                        layerState: ref.watch(mapLayersProvider),
                        roadsData: ref.watch(roadsProvider).valueOrNull,
                        schoolsData: ref.watch(schoolsProvider).valueOrNull,
                        collegesData: ref.watch(collegesProvider).valueOrNull,
                        governmentData: ref.watch(governmentProvider).valueOrNull,
                        religiousData: ref.watch(religiousSitesProvider).valueOrNull,
                        policeData: ref.watch(policeStationsProvider).valueOrNull,
                        trekkingData: ref.watch(trekkingSpotsProvider).valueOrNull,
                      ),
                    ),
                  ),
                ),
              ),

              // Floating layer controls for narrow screens
              if (!isWideScreen)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _CompactLayerControls(),
                ),

              // Selected POI info card
              if (selectedPOI != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: isWideScreen ? 16 : 16,
                  child: _POIInfoCard(
                    poi: selectedPOI,
                    onClose: () => ref.read(selectedMapPOIProvider.notifier).clear(),
                  ),
                ),

              // District info (when tapped)
              if (selectedDistrict != null && selectedPOI == null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: isWideScreen ? 16 : 16,
                  child: _DistrictInfoCard(
                    district: selectedDistrict,
                    onClose: () => ref.read(selectedMapDistrictProvider.notifier).clear(),
                  ),
                ),

              // Zoom indicator
              Positioned(
                bottom: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      '${(_currentZoom * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleTap(TapUpDetails details, OsmBoundaries boundaries) {
    final localPosition = details.localPosition;
    final matrix = _transformationController.value.clone()..invert();
    final transformed = MatrixUtils.transformPoint(matrix, localPosition);
    final (lon, lat) = _svgToLatLon(transformed.dx, transformed.dy);

    final layerState = ref.read(mapLayersProvider);

    // Check points first (they're on top visually)
    // Trekking spots (highest priority - tourist info)
    if (layerState.showTrekking) {
      final trekking = ref.read(trekkingSpotsProvider).valueOrNull;
      if (trekking != null) {
        final point = _findNearestTrekkingPoint(lon, lat, trekking);
        if (point != null) {
          ref.read(selectedMapPOIProvider.notifier).select(SelectedPOI.fromTrekking(point));
          ref.read(selectedMapDistrictProvider.notifier).clear();
          return;
        }
      }
    }

    // Religious sites
    if (layerState.showReligious) {
      final religious = ref.read(religiousSitesProvider).valueOrNull;
      if (religious != null) {
        final point = _findNearestReligiousPoint(lon, lat, religious);
        if (point != null) {
          ref.read(selectedMapPOIProvider.notifier).select(SelectedPOI.fromReligious(point));
          ref.read(selectedMapDistrictProvider.notifier).clear();
          return;
        }
      }
    }

    // Police stations
    if (layerState.showPolice) {
      final police = ref.read(policeStationsProvider).valueOrNull;
      if (police != null) {
        final point = _findNearestPolicePoint(lon, lat, police);
        if (point != null) {
          ref.read(selectedMapPOIProvider.notifier).select(SelectedPOI.fromPolice(point));
          ref.read(selectedMapDistrictProvider.notifier).clear();
          return;
        }
      }
    }

    if (layerState.showSchools) {
      final schools = ref.read(schoolsProvider).valueOrNull;
      if (schools != null) {
        final point = _findNearestPoint(lon, lat, schools.items);
        if (point != null) {
          ref.read(selectedMapPOIProvider.notifier).select(SelectedPOI.fromOsmPoint(point, 'school'));
          ref.read(selectedMapDistrictProvider.notifier).clear();
          return;
        }
      }
    }

    if (layerState.showColleges) {
      final colleges = ref.read(collegesProvider).valueOrNull;
      if (colleges != null) {
        final point = _findNearestPoint(lon, lat, colleges.items);
        if (point != null) {
          ref.read(selectedMapPOIProvider.notifier).select(SelectedPOI.fromOsmPoint(point, 'college'));
          ref.read(selectedMapDistrictProvider.notifier).clear();
          return;
        }
      }
    }

    if (layerState.showGovernment) {
      final govt = ref.read(governmentProvider).valueOrNull;
      if (govt != null) {
        final point = _findNearestPoint(lon, lat, govt.items);
        if (point != null) {
          ref.read(selectedMapPOIProvider.notifier).select(SelectedPOI.fromOsmPoint(point, 'government'));
          ref.read(selectedMapDistrictProvider.notifier).clear();
          return;
        }
      }
    }

    // Clear point selection
    ref.read(selectedMapPOIProvider.notifier).clear();

    // Check districts
    for (final district in boundaries.districts) {
      if (_isPointInPolygon(lon, lat, district.rings)) {
        ref.read(selectedMapDistrictProvider.notifier).select(district);
        return;
      }
    }

    ref.read(selectedMapDistrictProvider.notifier).clear();
  }

  /// Get the step value for filtering points based on zoom level
  /// This must match the painter's filtering logic
  int _getFilterStep() {
    if (_currentZoom < 1.5) return 10;
    if (_currentZoom < 3.0) return 3;
    if (_currentZoom < 5.0) return 2;
    return 1;
  }

  TrekkingPoint? _findNearestTrekkingPoint(double lon, double lat, List<TrekkingPoint> points) {
    final threshold = 0.05 / _currentZoom;
    final step = _getFilterStep();
    TrekkingPoint? nearest;
    double minDist = threshold;
    for (int i = 0; i < points.length; i += step) {
      final point = points[i];
      final dist = _distance(lon, lat, point.lon, point.lat);
      if (dist < minDist) {
        minDist = dist;
        nearest = point;
      }
    }
    return nearest;
  }

  ReligiousPoint? _findNearestReligiousPoint(double lon, double lat, List<ReligiousPoint> points) {
    final threshold = 0.05 / _currentZoom;
    final step = _getFilterStep();
    ReligiousPoint? nearest;
    double minDist = threshold;
    for (int i = 0; i < points.length; i += step) {
      final point = points[i];
      final dist = _distance(lon, lat, point.lon, point.lat);
      if (dist < minDist) {
        minDist = dist;
        nearest = point;
      }
    }
    return nearest;
  }

  PolicePoint? _findNearestPolicePoint(double lon, double lat, List<PolicePoint> points) {
    final threshold = 0.05 / _currentZoom;
    final step = _getFilterStep();
    PolicePoint? nearest;
    double minDist = threshold;
    for (int i = 0; i < points.length; i += step) {
      final point = points[i];
      final dist = _distance(lon, lat, point.lon, point.lat);
      if (dist < minDist) {
        minDist = dist;
        nearest = point;
      }
    }
    return nearest;
  }

  OsmPoint? _findNearestPoint(double lon, double lat, List<OsmPoint> points) {
    // Threshold adjusts based on zoom - smaller threshold when zoomed in
    final threshold = 0.05 / _currentZoom;
    OsmPoint? nearest;
    double minDist = threshold;

    // Filter must match painter's _filterPointsForZoom logic
    for (final point in points) {
      // Skip points that aren't drawn at current zoom
      if (_currentZoom < 1.5 && point.id % 10 != 0) continue;
      if (_currentZoom >= 1.5 && _currentZoom < 3.0 && point.id % 3 != 0) continue;
      if (_currentZoom >= 3.0 && _currentZoom < 5.0 && point.id % 2 != 0) continue;

      final dist = _distance(lon, lat, point.lon, point.lat);
      if (dist < minDist) {
        minDist = dist;
        nearest = point;
      }
    }

    return nearest;
  }

  double _distance(double lon1, double lat1, double lon2, double lat2) {
    final dLon = lon1 - lon2;
    final dLat = lat1 - lat2;
    return (dLon * dLon + dLat * dLat);
  }

  (double lon, double lat) _svgToLatLon(double x, double y) {
    const minLon = 80.0;
    const maxLon = 88.2;
    const minLat = 26.3;
    const maxLat = 30.5;
    const width = 1200.0;
    const height = 800.0;

    final lon = minLon + (x / width) * (maxLon - minLon);
    final lat = maxLat - (y / height) * (maxLat - minLat);
    return (lon, lat);
  }

  bool _isPointInPolygon(double x, double y, List<List<List<double>>> rings) {
    for (final ring in rings) {
      if (_isPointInRing(x, y, ring)) return true;
    }
    return false;
  }

  bool _isPointInRing(double x, double y, List<List<double>> ring) {
    bool inside = false;
    int j = ring.length - 1;
    for (int i = 0; i < ring.length; i++) {
      final xi = ring[i][0], yi = ring[i][1];
      final xj = ring[j][0], yj = ring[j][1];
      if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }
}

/// Layer control panel (sidebar)
class _LayerControlPanel extends ConsumerWidget {
  final double currentZoom;

  const _LayerControlPanel({required this.currentZoom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layerState = ref.watch(mapLayersProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.layers, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.mapLayers,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Layer toggles
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _LayerTile(
                  icon: Icons.route,
                  label: l10n.roads,
                  color: Colors.red,
                  isEnabled: layerState.showRoads,
                  onToggle: () => ref.read(mapLayersProvider.notifier).toggleRoads(),
                  trailing: layerState.showRoads
                      ? _RoadSubOptions(layerState: layerState, ref: ref, l10n: l10n)
                      : null,
                ),
                _LayerTile(
                  icon: Icons.school,
                  label: l10n.schools,
                  subtitle: '25,321',
                  color: Colors.orange,
                  isEnabled: layerState.showSchools,
                  onToggle: () => ref.read(mapLayersProvider.notifier).toggleSchools(),
                ),
                _LayerTile(
                  icon: Icons.account_balance,
                  label: l10n.colleges,
                  subtitle: '906',
                  color: Colors.purple,
                  isEnabled: layerState.showColleges,
                  onToggle: () => ref.read(mapLayersProvider.notifier).toggleColleges(),
                ),
                _LayerTile(
                  icon: Icons.assured_workload,
                  label: l10n.governmentOffices,
                  subtitle: '3,379',
                  color: Colors.blue,
                  isEnabled: layerState.showGovernment,
                  onToggle: () => ref.read(mapLayersProvider.notifier).toggleGovernment(),
                ),
                const Divider(height: 16),
                _LayerTile(
                  icon: Icons.temple_hindu,
                  label: l10n.religiousSites,
                  subtitle: '9,069',
                  color: Colors.amber,
                  isEnabled: layerState.showReligious,
                  onToggle: () => ref.read(mapLayersProvider.notifier).toggleReligious(),
                ),
                _LayerTile(
                  icon: Icons.local_police,
                  label: l10n.policeStations,
                  subtitle: '857',
                  color: Colors.indigo,
                  isEnabled: layerState.showPolice,
                  onToggle: () => ref.read(mapLayersProvider.notifier).togglePolice(),
                ),
                _LayerTile(
                  icon: Icons.terrain,
                  label: l10n.trekkingSpots,
                  subtitle: '3,604',
                  color: Colors.green,
                  isEnabled: layerState.showTrekking,
                  onToggle: () => ref.read(mapLayersProvider.notifier).toggleTrekking(),
                ),
              ],
            ),
          ),

          // Quick actions
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(mapLayersProvider.notifier).showAll(),
                    child: Text(l10n.all),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(mapLayersProvider.notifier).hideAll(),
                    child: Text(l10n.none),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadSubOptions extends StatelessWidget {
  final MapLayerState layerState;
  final WidgetRef ref;
  final AppLocalizations l10n;

  const _RoadSubOptions({
    required this.layerState,
    required this.ref,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 4, bottom: 8),
      child: Column(
        children: [
          _SubLayerChip(
            label: l10n.trunkRoads,
            color: Colors.red.shade700,
            isEnabled: layerState.showTrunk,
            onToggle: () => ref.read(mapLayersProvider.notifier).toggleTrunk(),
          ),
          _SubLayerChip(
            label: l10n.primaryRoads,
            color: Colors.amber.shade700,
            isEnabled: layerState.showPrimary,
            onToggle: () => ref.read(mapLayersProvider.notifier).togglePrimary(),
          ),
          _SubLayerChip(
            label: l10n.secondaryRoads,
            color: Colors.grey,
            isEnabled: layerState.showSecondary,
            onToggle: () => ref.read(mapLayersProvider.notifier).toggleSecondary(),
          ),
        ],
      ),
    );
  }
}

class _SubLayerChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isEnabled;
  final VoidCallback onToggle;

  const _SubLayerChip({
    required this.label,
    required this.color,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: isEnabled ? color : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isEnabled ? null : Colors.grey,
                ),
              ),
            ),
            Checkbox(
              value: isEnabled,
              onChanged: (_) => onToggle(),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final bool isEnabled;
  final VoidCallback onToggle;
  final Widget? trailing;

  const _LayerTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.isEnabled,
    required this.onToggle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isEnabled ? color : Colors.grey).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isEnabled ? color : Colors.grey, size: 20),
          ),
          title: Text(label),
          subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 11)) : null,
          trailing: Switch(
            value: isEnabled,
            onChanged: (_) => onToggle(),
            activeColor: color,
          ),
          onTap: onToggle,
          dense: true,
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Compact layer controls for narrow screens
class _CompactLayerControls extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layerState = ref.watch(mapLayersProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _CompactLayerChip(
              icon: Icons.route,
              color: Colors.red,
              isEnabled: layerState.showRoads,
              onToggle: () => ref.read(mapLayersProvider.notifier).toggleRoads(),
            ),
            _CompactLayerChip(
              icon: Icons.school,
              color: Colors.orange,
              isEnabled: layerState.showSchools,
              onToggle: () => ref.read(mapLayersProvider.notifier).toggleSchools(),
            ),
            _CompactLayerChip(
              icon: Icons.account_balance,
              color: Colors.purple,
              isEnabled: layerState.showColleges,
              onToggle: () => ref.read(mapLayersProvider.notifier).toggleColleges(),
            ),
            _CompactLayerChip(
              icon: Icons.assured_workload,
              color: Colors.blue,
              isEnabled: layerState.showGovernment,
              onToggle: () => ref.read(mapLayersProvider.notifier).toggleGovernment(),
            ),
            _CompactLayerChip(
              icon: Icons.temple_hindu,
              color: Colors.amber,
              isEnabled: layerState.showReligious,
              onToggle: () => ref.read(mapLayersProvider.notifier).toggleReligious(),
            ),
            _CompactLayerChip(
              icon: Icons.local_police,
              color: Colors.indigo,
              isEnabled: layerState.showPolice,
              onToggle: () => ref.read(mapLayersProvider.notifier).togglePolice(),
            ),
            _CompactLayerChip(
              icon: Icons.terrain,
              color: Colors.green,
              isEnabled: layerState.showTrekking,
              onToggle: () => ref.read(mapLayersProvider.notifier).toggleTrekking(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactLayerChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isEnabled;
  final VoidCallback onToggle;

  const _CompactLayerChip({
    required this.icon,
    required this.color,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled ? color.withValues(alpha: 0.2) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Icon(icon, size: 18, color: isEnabled ? color : Colors.grey),
      ),
    );
  }
}

/// POI info card with Google Maps link
class _POIInfoCard extends StatelessWidget {
  final SelectedPOI poi;
  final VoidCallback onClose;

  const _POIInfoCard({
    required this.poi,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = _getColorForType(poi.type);
    final icon = _getIconForType(poi.type);
    final typeLabel = _getLabelForType(poi.type, context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        poi.name.isNotEmpty ? poi.name : l10n.unknown,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ..._buildExtraTags(context, theme),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Extra info row
            if (poi.extra.isNotEmpty) ...[
              _buildExtraInfo(context, theme),
              const SizedBox(height: 8),
            ],
            // Coordinates and Google Maps button
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${poi.lat.toStringAsFixed(5)}°N, ${poi.lon.toStringAsFixed(5)}°E',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openInGoogleMaps(),
                  icon: const Icon(Icons.map, size: 16),
                  label: Text(l10n.openInGoogleMaps),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExtraTags(BuildContext context, ThemeData theme) {
    final widgets = <Widget>[];
    final l10n = AppLocalizations.of(context);

    // Religion tag for religious sites
    if (poi.extra.containsKey('religion')) {
      final religion = poi.extra['religion']!;
      final religionLabel = _getReligionLabel(religion, l10n);
      widgets.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          religionLabel,
          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
        ),
      ));
    }

    // Trekking type tag
    if (poi.extra.containsKey('trekking_type')) {
      final trekkingType = poi.extra['trekking_type']!;
      final trekkingLabel = _getTrekkingTypeLabel(trekkingType, l10n);
      widgets.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          trekkingLabel,
          style: TextStyle(fontSize: 10, color: Colors.green.shade700),
        ),
      ));
    }

    return widgets;
  }

  Widget _buildExtraInfo(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final infoItems = <Widget>[];

    // Elevation for trekking spots
    if (poi.extra.containsKey('elevation')) {
      infoItems.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.height, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            '${l10n.elevation}: ${poi.extra['elevation']}m',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ));
    }

    // Phone for police stations
    if (poi.extra.containsKey('phone')) {
      infoItems.add(GestureDetector(
        onTap: () => _callPhone(poi.extra['phone']!),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              poi.extra['phone']!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ));
    }

    if (infoItems.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 16, runSpacing: 8, children: infoItems);
  }

  String _getReligionLabel(String religion, AppLocalizations l10n) {
    switch (religion.toLowerCase()) {
      case 'hindu':
        return l10n.hindu;
      case 'buddhist':
        return l10n.buddhist;
      case 'christian':
        return l10n.christian;
      case 'muslim':
        return l10n.muslim;
      case 'sikh':
        return l10n.sikh;
      default:
        return religion;
    }
  }

  String _getTrekkingTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'peak':
        return l10n.peak;
      case 'viewpoint':
        return l10n.viewpoint;
      case 'campsite':
        return l10n.campsite;
      case 'alpine_hut':
        return l10n.alpineHut;
      case 'pass':
        return l10n.mountainPass;
      case 'guidepost':
        return l10n.guidepost;
      default:
        return type;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'school':
        return Colors.orange;
      case 'college':
        return Colors.purple;
      case 'government':
        return Colors.blue;
      case 'religious':
        return Colors.amber;
      case 'police':
        return Colors.indigo;
      case 'trekking':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'school':
        return Icons.school;
      case 'college':
        return Icons.account_balance;
      case 'government':
        return Icons.assured_workload;
      case 'religious':
        return Icons.temple_hindu;
      case 'police':
        return Icons.local_police;
      case 'trekking':
        return Icons.terrain;
      default:
        return Icons.location_on;
    }
  }

  String _getLabelForType(String type, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case 'school':
        return l10n.schools;
      case 'college':
        return l10n.colleges;
      case 'government':
        return l10n.governmentOffices;
      case 'religious':
        return l10n.religiousSites;
      case 'police':
        return l10n.policeStations;
      case 'trekking':
        return l10n.trekkingSpots;
      default:
        return type;
    }
  }

  Future<void> _openInGoogleMaps() async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${poi.lat},${poi.lon}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

/// District info card
class _DistrictInfoCard extends StatelessWidget {
  final BoundaryFeature district;
  final VoidCallback onClose;

  const _DistrictInfoCard({
    required this.district,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_city, color: Colors.teal, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    district.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (district.nameNe.isNotEmpty)
                    Text(
                      district.nameNe,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for Nepal map
class _NepalMapPainter extends CustomPainter {
  final OsmBoundaries boundaries;
  final BoundaryFeature? selectedDistrict;
  final double currentZoom;
  final MapLayerState layerState;
  final OsmRoadData? roadsData;
  final OsmPointData? schoolsData;
  final OsmPointData? collegesData;
  final OsmPointData? governmentData;
  final List<ReligiousPoint>? religiousData;
  final List<PolicePoint>? policeData;
  final List<TrekkingPoint>? trekkingData;

  static const minLon = 80.0;
  static const maxLon = 88.2;
  static const minLat = 26.3;
  static const maxLat = 30.5;

  _NepalMapPainter({
    required this.boundaries,
    required this.selectedDistrict,
    required this.currentZoom,
    required this.layerState,
    this.roadsData,
    this.schoolsData,
    this.collegesData,
    this.governmentData,
    this.religiousData,
    this.policeData,
    this.trekkingData,
  });

  Offset _latLonToCanvas(double lat, double lon, Size size) {
    final x = (lon - minLon) / (maxLon - minLon) * size.width;
    final y = (maxLat - lat) / (maxLat - minLat) * size.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawCountryFill(canvas, size);
    _drawProvinces(canvas, size);
    _drawDistricts(canvas, size);
    _drawCountryOutline(canvas, size);

    if (layerState.showRoads && roadsData != null) {
      _drawRoads(canvas, size);
    }
    if (layerState.showSchools && schoolsData != null) {
      _drawPoints(canvas, size, schoolsData!.items, Colors.orange);
    }
    if (layerState.showColleges && collegesData != null) {
      _drawPoints(canvas, size, collegesData!.items, Colors.purple);
    }
    if (layerState.showGovernment && governmentData != null) {
      _drawPoints(canvas, size, governmentData!.items, Colors.blue);
    }
    if (layerState.showReligious && religiousData != null) {
      _drawGenericPoints(canvas, size, religiousData!, Colors.amber, (p) => p.lat, (p) => p.lon);
    }
    if (layerState.showPolice && policeData != null) {
      _drawGenericPoints(canvas, size, policeData!, Colors.indigo, (p) => p.lat, (p) => p.lon);
    }
    if (layerState.showTrekking && trekkingData != null) {
      _drawTrekkingPoints(canvas, size, trekkingData!);
    }

    if (currentZoom > 2.0) {
      _drawDistrictLabels(canvas, size);
    }
  }

  void _drawCountryFill(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    for (final country in boundaries.country) {
      final path = Path();
      for (final ring in country.rings) {
        if (ring.length < 3) continue;
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
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawProvinces(Canvas canvas, Size size) {
    final provinceColors = [
      Colors.red.shade100,
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
      Colors.pink.shade100,
    ];

    for (final province in boundaries.provinces) {
      final colorIndex = (province.province ?? 1) - 1;
      final color = provinceColors[colorIndex % provinceColors.length];
      final paint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      final path = Path();
      for (final ring in province.rings) {
        if (ring.length < 3) continue;
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
      }
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(path, paint);
    }
  }

  void _drawDistricts(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeJoin = StrokeJoin.round;

    final selectedPaint = Paint()
      ..color = Colors.blue.shade300.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final selectedBorderPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final district in boundaries.districts) {
      final isSelected = selectedDistrict?.id == district.id;
      final path = Path();

      for (final ring in district.rings) {
        if (ring.length < 3) continue;
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
      }

      if (isSelected) {
        canvas.drawPath(path, selectedPaint);
        canvas.drawPath(path, selectedBorderPaint);
      } else {
        canvas.drawPath(path, borderPaint);
      }
    }
  }

  void _drawCountryOutline(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    for (final country in boundaries.country) {
      final path = Path();
      for (final ring in country.rings) {
        if (ring.length < 3) continue;
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
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawRoads(Canvas canvas, Size size) {
    if (roadsData == null) return;

    if (layerState.showSecondary) {
      _drawRoadType(canvas, size, roadsData!.roads['secondary'] ?? [], Colors.grey, 0.5);
    }
    if (layerState.showPrimary) {
      _drawRoadType(canvas, size, roadsData!.roads['primary'] ?? [], Colors.amber.shade700, 1.0);
    }
    if (layerState.showTrunk) {
      _drawRoadType(canvas, size, roadsData!.roads['trunk'] ?? [], Colors.red.shade700, 1.5);
    }
  }

  void _drawRoadType(Canvas canvas, Size size, List<OsmRoad> roads, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    for (final road in roads) {
      if (road.coords.length < 2) continue;
      final path = Path();
      bool first = true;
      for (final coord in road.coords) {
        if (coord.length < 2) continue;
        final offset = _latLonToCanvas(coord[1], coord[0], size);
        if (first) {
          path.moveTo(offset.dx, offset.dy);
          first = false;
        } else {
          path.lineTo(offset.dx, offset.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawPoints(Canvas canvas, Size size, List<OsmPoint> points, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final pointsToShow = _filterPointsForZoom(points);
    final radius = (3.0 / currentZoom).clamp(2.0, 5.0);

    for (final point in pointsToShow) {
      final offset = _latLonToCanvas(point.lat, point.lon, size);
      if (offset.dx < 0 || offset.dx > size.width || offset.dy < 0 || offset.dy > size.height) {
        continue;
      }
      canvas.drawCircle(offset, radius, paint);
      canvas.drawCircle(offset, radius, borderPaint);
    }
  }

  List<OsmPoint> _filterPointsForZoom(List<OsmPoint> points) {
    if (currentZoom < 1.5) return points.where((p) => p.id % 10 == 0).toList();
    if (currentZoom < 3.0) return points.where((p) => p.id % 3 == 0).toList();
    if (currentZoom < 5.0) return points.where((p) => p.id % 2 == 0).toList();
    return points;
  }

  void _drawDistrictLabels(Canvas canvas, Size size) {
    final textStyle = ui.TextStyle(
      color: Colors.black87,
      fontSize: 8 / currentZoom.clamp(1.0, 3.0),
      fontWeight: FontWeight.w500,
    );

    for (final district in boundaries.districts) {
      if (district.rings.isEmpty) continue;
      final centroid = district.centroid;
      final offset = _latLonToCanvas(centroid.dy, centroid.dx, size);

      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 1,
      ))
        ..pushStyle(textStyle)
        ..addText(district.name);

      final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 100));
      canvas.drawParagraph(
        paragraph,
        Offset(offset.dx - paragraph.width / 2, offset.dy - paragraph.height / 2),
      );
    }
  }

  void _drawGenericPoints<T>(
    Canvas canvas,
    Size size,
    List<T> points,
    Color color,
    double Function(T) getLat,
    double Function(T) getLon,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final radius = (3.0 / currentZoom).clamp(2.0, 5.0);

    // Simple filtering based on index for performance
    final step = currentZoom < 1.5 ? 10 : (currentZoom < 3.0 ? 3 : (currentZoom < 5.0 ? 2 : 1));
    for (int i = 0; i < points.length; i += step) {
      final point = points[i];
      final offset = _latLonToCanvas(getLat(point), getLon(point), size);
      if (offset.dx < 0 || offset.dx > size.width || offset.dy < 0 || offset.dy > size.height) {
        continue;
      }
      canvas.drawCircle(offset, radius, paint);
      canvas.drawCircle(offset, radius, borderPaint);
    }
  }

  void _drawTrekkingPoints(Canvas canvas, Size size, List<TrekkingPoint> points) {
    final peakPaint = Paint()..color = Colors.green.shade700..style = PaintingStyle.fill;
    final viewpointPaint = Paint()..color = Colors.teal..style = PaintingStyle.fill;
    final campsitePaint = Paint()..color = Colors.brown..style = PaintingStyle.fill;
    final otherPaint = Paint()..color = Colors.green..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final radius = (3.0 / currentZoom).clamp(2.0, 5.0);

    // Filter based on zoom level
    final step = currentZoom < 1.5 ? 10 : (currentZoom < 3.0 ? 3 : (currentZoom < 5.0 ? 2 : 1));
    for (int i = 0; i < points.length; i += step) {
      final point = points[i];
      final offset = _latLonToCanvas(point.lat, point.lon, size);
      if (offset.dx < 0 || offset.dx > size.width || offset.dy < 0 || offset.dy > size.height) {
        continue;
      }

      final paint = switch (point.type) {
        'peak' => peakPaint,
        'viewpoint' => viewpointPaint,
        'campsite' || 'alpine_hut' => campsitePaint,
        _ => otherPaint,
      };

      // Draw triangle for peaks, circle for others
      if (point.type == 'peak') {
        final path = Path()
          ..moveTo(offset.dx, offset.dy - radius)
          ..lineTo(offset.dx - radius, offset.dy + radius)
          ..lineTo(offset.dx + radius, offset.dy + radius)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
      } else {
        canvas.drawCircle(offset, radius, paint);
        canvas.drawCircle(offset, radius, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NepalMapPainter oldDelegate) {
    return selectedDistrict != oldDelegate.selectedDistrict ||
        currentZoom != oldDelegate.currentZoom ||
        layerState != oldDelegate.layerState;
  }
}
