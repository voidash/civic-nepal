import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/leaders_provider.dart';
import '../../models/district.dart';
import '../../models/leader.dart';

part 'district_map_screen.g.dart';

/// Selected district provider
@riverpod
class SelectedDistrict extends _$SelectedDistrict {
  @override
  String? build() => null;

  void setDistrict(String? districtId) {
    state = districtId;
  }

  void clear() {
    state = null;
  }
}

/// Selected province filter provider
@riverpod
class SelectedProvince extends _$SelectedProvince {
  @override
  int? build() => null;

  void setProvince(int? province) {
    state = province;
  }

  void clear() {
    state = null;
  }
}

/// Leaders for selected district
@riverpod
Future<List<Leader>> leadersForDistrict(LeadersForDistrictRef ref, String districtName) async {
  final leadersData = await ref.watch(leadersProvider.future);
  return leadersData.leaders
      .where((leader) => leader.district == districtName)
      .toList();
}

/// District map screen with interactive SVG
class DistrictMapScreen extends ConsumerStatefulWidget {
  const DistrictMapScreen({super.key});

  @override
  ConsumerState<DistrictMapScreen> createState() => _DistrictMapScreenState();
}

class _DistrictMapScreenState extends ConsumerState<DistrictMapScreen> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _showProvinceFilter(BuildContext context) {
    final provinces = [1, 2, 3, 4, 5, 6, 7];
    final selectedProvince = ref.watch(selectedProvinceProvider);

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
                Text(
                  'Filter by Province',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (selectedProvince != null)
                  TextButton(
                    onPressed: () {
                      ref.read(selectedProvinceProvider.notifier).clear();
                      context.pop();
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const Divider(),
            ...provinces.map((province) => RadioListTile<int>(
                  title: Text('Province $province'),
                  value: province,
                  groupValue: selectedProvince,
                  onChanged: (value) {
                    ref.read(selectedProvinceProvider.notifier).setProvince(value);
                    context.pop();
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDistrict = ref.watch(selectedDistrictProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final selectedProvince = ref.watch(selectedProvinceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nepal Districts'),
        actions: [
          if (selectedProvince != null)
            Chip(
              label: Text('P${selectedProvince}'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => ref.read(selectedProvinceProvider.notifier).clear(),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by Province',
            onPressed: () => _showProvinceFilter(context),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            tooltip: 'Reset Zoom',
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
          ),
        ],
      ),
      body: districtsAsync.when(
        data: (districtData) => Row(
          children: [
            // Map area
            Expanded(
              child: Stack(
                children: [
                  _buildInteractiveMap(districtData, selectedProvince),
                  // Selected district info overlay
                  if (selectedDistrict != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _DistrictInfoChip(
                        districtName: selectedDistrict,
                        districtInfo: districtData.districts.entries
                            .firstWhere(
                              (e) => e.value.name == selectedDistrict,
                              orElse: () => const MapEntry('', DistrictInfo(name: '', province: 0)),
                            )
                            .value,
                      ),
                    ),
                ],
              ),
            ),
            // Side panel for selected district leaders
            if (selectedDistrict != null)
              _buildLeadersPanel(selectedDistrict),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInteractiveMap(DistrictData districtData, int? selectedProvince) {
    // Get districts to highlight based on province filter
    final visibleDistricts = selectedProvince == null
        ? districtData.districts
        : districtData.districts
            .where((d) => d.value.province == selectedProvince)
            .map((e) => MapEntry(e.key, e.value));

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      constrained: false,
      child: SizedBox(
        width: 1225,
        height: 817,
        child: _NepalMapWidget(
          districts: visibleDistricts,
          onDistrictTap: (districtName) {
            ref.read(selectedDistrictProvider.notifier).setDistrict(districtName);
          },
        ),
      ),
    );
  }

  Widget _buildLeadersPanel(String districtName) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
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
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        districtName,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Leaders from this district',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      ref.read(selectedDistrictProvider.notifier).clear(),
                ),
              ],
            ),
          ),
          // Leaders list
          Expanded(
            child: _DistrictLeadersList(districtName: districtName),
          ),
        ],
      ),
    );
  }
}

/// District info chip overlay
class _DistrictInfoChip extends StatelessWidget {
  final String districtName;
  final DistrictInfo districtInfo;

  const _DistrictInfoChip({
    required this.districtName,
    required this.districtInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: _getProvinceColor(districtInfo.province),
            ),
            const SizedBox(width: 8),
            Text(
              districtName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('P${districtInfo.province}'),
              backgroundColor: _getProvinceColor(districtInfo.province).withOpacity(0.2),
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Color _getProvinceColor(int province) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[(province - 1) % colors.length];
  }
}

/// Leaders list for a district
class _DistrictLeadersList extends ConsumerWidget {
  final String districtName;

  const _DistrictLeadersList({required this.districtName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadersAsync = ref.watch(leadersForDistrictProvider(districtName));

    return leadersAsync.when(
      data: (leaders) {
        if (leaders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No leaders found\nfor $districtName',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: leaders.length,
          itemBuilder: (context, index) {
            final leader = leaders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: leader.imageUrl.isNotEmpty
                      ? NetworkImage(leader.imageUrl)
                      : null,
                  child: leader.imageUrl.isEmpty
                      ? Text(leader.name[0])
                      : null,
                ),
                title: Text(leader.name),
                subtitle: Text(leader.party),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: Colors.green.shade700,
                      size: 14,
                    ),
                    Text(
                      '${leader.totalVotes}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                onTap: () => context.push('/leaders/${leader.id}'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
    );
  }
}

/// Interactive Nepal SVG Map Widget
class _NepalMapWidget extends StatefulWidget {
  final Map<String, DistrictInfo> districts;
  final void Function(String districtName) onDistrictTap;

  const _NepalMapWidget({
    required this.districts,
    required this.onDistrictTap,
  });

  @override
  State<_NepalMapWidget> createState() => _NepalMapWidgetState();
}

class _NepalMapWidgetState extends State<_NepalMapWidget> {
  String? _hoveredDistrict;
  final Map<String, GlobalKey> _districtKeys = {};

  @override
  void initState() {
    super.initState();
    // Initialize keys for all districts
    for (final district in widget.districts.keys) {
      _districtKeys[district] = GlobalKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadSvg(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Map not available'));
        }

        // For now, show a placeholder until proper SVG parsing is implemented
        return _buildPlaceholderMap();
      },
    );
  }

  Widget _buildPlaceholderMap() {
    return CustomPaint(
      size: const Size(1225, 817),
      painter: _NepalMapPainter(
        districts: widget.districts,
        hoveredDistrict: _hoveredDistrict,
        onDistrictHover: (district) {
          setState(() => _hoveredDistrict = district);
        },
      ),
      child: GestureDetector(
        onHover: (event) {
          // Handle hover for desktop
          final localPosition = event.localPosition;
          _findDistrictAtPosition(localPosition);
        },
        onTapUp: (details) {
          // Handle tap to select district
          final localPosition = details.localPosition;
          _findAndSelectDistrict(localPosition);
        },
      ),
    );
  }

  void _findDistrictAtPosition(Offset position) {
    // This is a simplified implementation
    // In production, you would use proper SVG hit testing
    // or use a package like flutter_svg with custom painters
  }

  void _findAndSelectDistrict(Offset position) {
    // This is a simplified implementation
    // Show a dialog to select district for now
    _showDistrictSelector();
  }

  void _showDistrictSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DistrictSelectorSheet(
        districts: widget.districts,
        onDistrictTap: widget.onDistrictTap,
      ),
    );
  }

  Future<String> _loadSvg() async {
    // This would load the actual SVG from assets
    // For now, we're using a custom painter approach
    return '';
  }
}

/// Custom painter for Nepal map (simplified)
class _NepalMapPainter extends CustomPainter {
  final Map<String, DistrictInfo> districts;
  final String? hoveredDistrict;
  final void Function(String?) onDistrictHover;

  _NepalMapPainter({
    required this.districts,
    required this.hoveredDistrict,
    required this.onDistrictHover,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw a simplified Nepal outline
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw Nepal outline (simplified path)
    final path = Path();
    // This is a very simplified representation
    // In production, you would use the actual SVG paths
    path.moveTo(400, 100);
    path.lineTo(800, 100);
    path.lineTo(900, 300);
    path.lineTo(800, 500);
    path.lineTo(600, 700);
    path.lineTo(400, 700);
    path.lineTo(200, 500);
    path.lineTo(100, 300);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Draw province indicators
    _drawProvinceIndicators(canvas, size);
  }

  void _drawProvinceIndicators(Canvas canvas, Size size) {
    // Group districts by province
    final provinces = <int, List<String>>{};
    for (final entry in districts.entries) {
      provinces.putIfAbsent(entry.value.province, () => []).add(entry.key);
    }

    // Draw circles for each province
    final positions = [
      const Offset(300, 200), // P1
      const Offset(500, 150), // P2
      const Offset(700, 250), // P3
      const Offset(600, 400), // P4
      const Offset(400, 450), // P5
      const Offset(250, 350), // P6
      const Offset(350, 550), // P7
    ];

    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    for (int i = 0; i < provinces.length && i < positions.length; i++) {
      final provinceNumber = i + 1;
      final hasDistricts = provinces.containsKey(provinceNumber);

      if (hasDistricts) {
        final paint = Paint()
          ..color = colors[i].withOpacity(0.6)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(positions[i], 40, paint);

        // Draw province number
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'P$provinceNumber',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          positions[i] - Offset(textPainter.width / 2, textPainter.height / 2),
        );

        // Draw district count
        final countPainter = TextPainter(
          text: TextSpan(
            text: '${provinces[provinceNumber]!.length} districts',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        countPainter.layout();
        countPainter.paint(
          canvas,
          positions[i] - Offset(countPainter.width / 2, -countPainter.height - 5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NepalMapPainter oldDelegate) {
    return oldDelegate.hoveredDistrict != hoveredDistrict;
  }
}

/// District selector bottom sheet
class _DistrictSelectorSheet extends StatelessWidget {
  final Map<String, DistrictInfo> districts;
  final void Function(String districtName) onDistrictTap;

  const _DistrictSelectorSheet({
    required this.districts,
    required this.onDistrictTap,
  });

  @override
  Widget build(BuildContext context) {
    // Group by province
    final provinces = <int, List<MapEntry<String, DistrictInfo>>>{};
    for (final entry in districts.entries) {
      provinces.putIfAbsent(entry.value.province, () => []).add(entry);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Select District',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: provinces.keys.length,
                  itemBuilder: (context, index) {
                    final province = provinces.keys.toList()..sort();
                    province.sort();
                    final currentProvince = province[index];
                    final districtList = provinces[currentProvince]!;

                    return ExpansionTile(
                      title: Text('Province $currentProvince'),
                      subtitle: Text('${districtList.length} districts'),
                      children: districtList.map((entry) {
                        return ListTile(
                          title: Text(entry.value.name),
                          onTap: () {
                            onDistrictTap(entry.value.name);
                            context.pop();
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
