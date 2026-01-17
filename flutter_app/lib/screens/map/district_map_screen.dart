import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/leaders_provider.dart';
import '../../models/district.dart';
import '../../models/leader.dart';
import '../../services/svg_path_parser.dart';

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

    return PopScope(
      // Intercept back gesture when panel is open
      canPop: selectedDistrict == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedDistrict != null) {
          // Close the panel instead of popping the screen
          ref.read(selectedDistrictProvider.notifier).clear();
        }
      },
      child: Scaffold(
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
    ),
    );
  }

  Widget _buildInteractiveMap(DistrictData districtData, int? selectedProvince) {
    // Get districts to highlight based on province filter
    final visibleDistricts = selectedProvince == null
        ? districtData.districts
        : Map.fromEntries(districtData.districts.entries
            .where((d) => d.value.province == selectedProvince));

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
            if (districtName.isEmpty) {
              // Tapped outside any district - close panel
              ref.read(selectedDistrictProvider.notifier).clear();
            } else {
              ref.read(selectedDistrictProvider.notifier).setDistrict(districtName);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLeadersPanel(String districtName) {
    final districtsAsync = ref.watch(districtsProvider);
    final districtInfo = districtsAsync.whenData((data) {
      return data.districts.entries
          .firstWhere(
            (e) => e.value.name == districtName,
            orElse: () => const MapEntry('', DistrictInfo(name: '', province: 0)),
          )
          .value;
    });

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
          // Header with district info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          if (districtInfo.hasValue && districtInfo.value!.nameNp != null)
                            Text(
                              districtInfo.value!.nameNp!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                if (districtInfo.hasValue) ...[
                  const SizedBox(height: 12),
                  _DistrictDetailsCard(info: districtInfo.value!),
                ],
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

/// District details card showing enhanced info
class _DistrictDetailsCard extends StatelessWidget {
  final DistrictInfo info;

  const _DistrictDetailsCard({required this.info});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Province and Headquarters
            Row(
              children: [
                _InfoItem(
                  icon: Icons.flag,
                  label: 'Province ${info.province}',
                ),
                const SizedBox(width: 16),
                if (info.headquarters != null)
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.location_city,
                      label: info.headquarters!,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Population and Area
            Row(
              children: [
                if (info.population != null)
                  _InfoItem(
                    icon: Icons.people,
                    label: _formatNumber(info.population!),
                  ),
                if (info.population != null && info.area != null)
                  const SizedBox(width: 16),
                if (info.area != null)
                  _InfoItem(
                    icon: Icons.square_foot,
                    label: '${_formatNumber(info.area!)} km²',
                  ),
              ],
            ),
            // Famous for
            if (info.famousFor != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.star,
                    size: 14,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      info.famousFor!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // Action buttons
            if (info.wikiUrl != null || info.websiteUrl != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (info.wikiUrl != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchUrl(info.wikiUrl!),
                        icon: const Icon(Icons.language, size: 16),
                        label: const Text('Wikipedia'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  if (info.wikiUrl != null && info.websiteUrl != null)
                    const SizedBox(width: 8),
                  if (info.websiteUrl != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchUrl(info.websiteUrl!),
                        icon: const Icon(Icons.public, size: 16),
                        label: const Text('Website'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
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
                      ? _getImageProvider(leader.imageUrl)
                      : null,
                  child: leader.imageUrl.isEmpty
                      ? Text(leader.name[0])
                      : null,
                ),
                title: Text(leader.name),
                subtitle: Text(leader.party),
                trailing: const Icon(Icons.chevron_right),
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

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl);
    }
    return AssetImage(imageUrl);
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
  final SvgPathParser _pathParser = SvgPathParser();
  final GlobalKey _mapKey = GlobalKey();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSvgPaths();
  }

  Future<void> _loadSvgPaths() async {
    await _pathParser.loadSvg('assets/images/nepal_districts.svg');
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Render the actual SVG map
        SvgPicture.asset(
          'assets/images/nepal_districts.svg',
          key: _mapKey,
          width: 1225,
          height: 817,
          fit: BoxFit.contain,
        ),
        // Overlay for tap detection with hit testing
        Positioned.fill(
          child: GestureDetector(
            onTapUp: _isLoading ? null : _handleTap,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        if (_isLoading)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  void _handleTap(TapUpDetails details) {
    final renderBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;

    // Convert screen coordinates to SVG coordinates
    final svgPoint = _pathParser.screenToSvg(localPosition, size);

    // Find which district was tapped
    final districtId = _pathParser.hitTest(svgPoint);

    if (districtId != null) {
      // Convert district ID to proper name (e.g., "jhapa" -> "Jhapa")
      final districtName = _formatDistrictName(districtId);
      widget.onDistrictTap(districtName);
    } else {
      // Tapped outside any district - signal to close panel
      widget.onDistrictTap('');
    }
  }

  String _formatDistrictName(String id) {
    // Convert snake_case/lowercase to Title Case
    // e.g., "jhapa" -> "Jhapa", "okhaldhunga" -> "Okhaldhunga"
    return id.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
