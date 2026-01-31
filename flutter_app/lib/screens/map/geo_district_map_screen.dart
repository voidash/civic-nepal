import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/geo_districts_provider.dart';
import '../../widgets/home_title.dart';
import '../../widgets/source_attribution.dart';

/// Province colors for the map
const _provinceColors = [
  Color(0xFFE57373), // Province 1 - Red
  Color(0xFF64B5F6), // Province 2 - Blue
  Color(0xFF81C784), // Province 3 - Green
  Color(0xFFFFD54F), // Province 4 - Yellow
  Color(0xFFBA68C8), // Province 5 - Purple
  Color(0xFF4DB6AC), // Province 6 - Teal
  Color(0xFFFF8A65), // Province 7 - Orange
];

Color _getProvinceColor(int province) {
  if (province < 1 || province > 7) return Colors.grey;
  return _provinceColors[province - 1];
}

/// GeoJSON-based District Map Screen
class GeoDistrictMapScreen extends ConsumerStatefulWidget {
  const GeoDistrictMapScreen({super.key});

  @override
  ConsumerState<GeoDistrictMapScreen> createState() => _GeoDistrictMapScreenState();
}

class _GeoDistrictMapScreenState extends ConsumerState<GeoDistrictMapScreen> {
  final TransformationController _transformationController = TransformationController();
  double _currentZoom = 1.0;
  int? _selectedProvince;

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

  void _showProvinceFilter(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.filterByProvince, style: Theme.of(context).textTheme.titleLarge),
                if (_selectedProvince != null)
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedProvince = null);
                      context.pop();
                    },
                    child: Text(l10n.clear),
                  ),
              ],
            ),
            const Divider(),
            ...List.generate(7, (i) {
              final province = i + 1;
              return RadioListTile<int>(
                title: Text(l10n.provinceNumber(province)),
                value: province,
                groupValue: _selectedProvince,
                onChanged: (value) {
                  setState(() => _selectedProvince = value);
                  context.pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final districtsAsync = ref.watch(geoDistrictsProvider);
    final selectedDistrict = ref.watch(selectedGeoDistrictProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      bottomNavigationBar: const SourceAttribution.election(),
      appBar: AppBar(
        title: HomeTitle(child: Text(l10n.nepalDistricts)),
        actions: [
          if (_selectedProvince != null)
            Chip(
              label: Text('P$_selectedProvince'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => setState(() => _selectedProvince = null),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: l10n.filterByProvince,
            onPressed: () => _showProvinceFilter(context),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            tooltip: l10n.resetZoom,
            onPressed: () => _transformationController.value = Matrix4.identity(),
          ),
        ],
      ),
      body: districtsAsync.when(
        data: (data) => _buildMapContent(data, selectedDistrict),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // Canvas dimensions - 2:1 aspect ratio matching Nepal's shape
  static const _canvasWidth = 1200.0;
  static const _canvasHeight = 600.0;

  // Actual data bounds (calculated from districts_geo.json)
  static const _minLon = 80.0585;
  static const _maxLon = 88.2011;
  static const _minLat = 26.3478;
  static const _maxLat = 30.4730;

  Widget _buildMapContent(GeoDistrictsData data, GeoDistrict? selectedDistrict) {
    // Filter districts by province if selected
    final visibleDistricts = _selectedProvince == null
        ? data.districts
        : data.districts.where((d) => d.province == _selectedProvince).toList();

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
              onTapUp: (details) => _handleTap(details, data.districts),
              child: CustomPaint(
                size: const Size(_canvasWidth, _canvasHeight),
                painter: _GeoDistrictMapPainter(
                  districts: visibleDistricts,
                  allDistricts: data.districts,
                  selectedDistrict: selectedDistrict,
                  currentZoom: _currentZoom,
                ),
              ),
            ),
          ),
        ),
        // Selected district info card
        if (selectedDistrict != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _DistrictInfoCard(
              district: selectedDistrict,
              onClose: () => ref.read(selectedGeoDistrictProvider.notifier).clear(),
              onViewLocalBodies: () {
                ref.read(selectedGeoDistrictProvider.notifier).clear();
                context.push('/map/districts/${Uri.encodeComponent(selectedDistrict.name)}');
              },
            ),
          ),
      ],
    );
  }

  void _handleTap(TapUpDetails details, List<GeoDistrict> districts) {
    // localPosition is already in canvas coordinates (0 to canvasWidth/Height)
    // because GestureDetector is inside the InteractiveViewer's child
    final canvasPos = details.localPosition;

    // Convert canvas position to lon/lat using actual data bounds
    final lon = _minLon + (canvasPos.dx / _canvasWidth) * (_maxLon - _minLon);
    final lat = _maxLat - (canvasPos.dy / _canvasHeight) * (_maxLat - _minLat);

    // Find which district was tapped
    for (final district in districts) {
      if (_isPointInDistrict(lon, lat, district)) {
        ref.read(selectedGeoDistrictProvider.notifier).select(district);
        return;
      }
    }

    ref.read(selectedGeoDistrictProvider.notifier).clear();
  }

  bool _isPointInDistrict(double lon, double lat, GeoDistrict district) {
    for (final ring in district.rings) {
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
}

/// Custom painter for GeoJSON district map
class _GeoDistrictMapPainter extends CustomPainter {
  final List<GeoDistrict> districts;
  final List<GeoDistrict> allDistricts;
  final GeoDistrict? selectedDistrict;
  final double currentZoom;

  // Use actual data bounds matching the state class
  static const minLon = 80.0585;
  static const maxLon = 88.2011;
  static const minLat = 26.3478;
  static const maxLat = 30.4730;

  _GeoDistrictMapPainter({
    required this.districts,
    required this.allDistricts,
    required this.selectedDistrict,
    required this.currentZoom,
  });

  Offset _latLonToCanvas(double lat, double lon, Size size) {
    final x = (lon - minLon) / (maxLon - minLon) * size.width;
    final y = (maxLat - lat) / (maxLat - minLat) * size.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background for filtered-out districts (grey)
    final greyPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    final greyBorderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final district in allDistricts) {
      if (!districts.contains(district)) {
        _drawDistrict(canvas, size, district, greyPaint, greyBorderPaint);
      }
    }

    // Draw visible districts
    for (final district in districts) {
      final isSelected = selectedDistrict?.name == district.name;
      final baseColor = _getProvinceColor(district.province);

      final fillPaint = Paint()
        ..color = isSelected ? baseColor : baseColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = isSelected ? Colors.black : Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 0.8
        ..strokeJoin = StrokeJoin.round;

      _drawDistrict(canvas, size, district, fillPaint, borderPaint);
    }

    // Draw labels at higher zoom
    if (currentZoom > 1.5) {
      _drawLabels(canvas, size);
    }
  }

  void _drawDistrict(Canvas canvas, Size size, GeoDistrict district, Paint fillPaint, Paint borderPaint) {
    for (final ring in district.rings) {
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
      fontSize: 12 / currentZoom.clamp(1.0, 3.0),
      fontWeight: FontWeight.w600,
    );

    for (final district in districts) {
      final (lon, lat) = district.centroid;
      final offset = _latLonToCanvas(lat, lon, size);

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

  @override
  bool shouldRepaint(covariant _GeoDistrictMapPainter oldDelegate) {
    return selectedDistrict != oldDelegate.selectedDistrict ||
        currentZoom != oldDelegate.currentZoom ||
        districts.length != oldDelegate.districts.length;
  }
}

/// District info card
class _DistrictInfoCard extends StatelessWidget {
  final GeoDistrict district;
  final VoidCallback onClose;
  final VoidCallback onViewLocalBodies;

  const _DistrictInfoCard({
    required this.district,
    required this.onClose,
    required this.onViewLocalBodies,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = _getProvinceColor(district.province);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_city, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        district.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.provinceNumber(district.province),
                              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            district.provinceName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onViewLocalBodies,
                icon: const Icon(Icons.apartment),
                label: Text(l10n.viewLocalBodies),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
