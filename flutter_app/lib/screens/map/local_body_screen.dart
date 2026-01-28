import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../l10n/app_localizations.dart';
import '../../services/svg_path_parser.dart';
import '../../widgets/home_title.dart';

part 'local_body_screen.g.dart';

/// Local election results data model
class LocalElectionData {
  final String version;
  final int totalLocalBodies;
  final List<LocalBodyResult> localBodies;

  LocalElectionData({
    required this.version,
    required this.totalLocalBodies,
    required this.localBodies,
  });

  factory LocalElectionData.fromJson(Map<String, dynamic> json) {
    return LocalElectionData(
      version: json['version'] ?? '',
      totalLocalBodies: json['totalLocalBodies'] ?? 0,
      localBodies: (json['localBodies'] as List?)
              ?.map((e) => LocalBodyResult.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class LocalBodyResult {
  final String id;
  final String locId;
  final String name;
  final String nameNp;
  final String district;
  final int province;
  final String type;
  final List<ElectedOfficial> officials;

  LocalBodyResult({
    required this.id,
    required this.locId,
    required this.name,
    required this.nameNp,
    required this.district,
    required this.province,
    required this.type,
    required this.officials,
  });

  factory LocalBodyResult.fromJson(Map<String, dynamic> json) {
    return LocalBodyResult(
      id: json['id'] ?? '',
      locId: json['locId'] ?? '',
      name: json['name'] ?? '',
      nameNp: json['nameNp'] ?? '',
      district: json['district'] ?? '',
      province: json['province'] ?? 0,
      type: json['type'] ?? '',
      officials: (json['officials'] as List?)
              ?.map((e) => ElectedOfficial.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ElectedOfficial {
  final String name;
  final String nameNp;
  final String position;
  final String party;
  final int votes;
  final String imageUrl;
  final String partySymbol;

  ElectedOfficial({
    required this.name,
    required this.nameNp,
    required this.position,
    required this.party,
    required this.votes,
    required this.imageUrl,
    required this.partySymbol,
  });

  factory ElectedOfficial.fromJson(Map<String, dynamic> json) {
    return ElectedOfficial(
      name: json['name'] ?? '',
      nameNp: json['nameNp'] ?? '',
      position: json['position'] ?? '',
      party: json['party'] ?? '',
      votes: json['votes'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      partySymbol: json['partySymbol'] ?? '',
    );
  }
}

/// Provider for local election results
@riverpod
Future<LocalElectionData> localElectionResults(LocalElectionResultsRef ref) async {
  final jsonString = await rootBundle.loadString('assets/data/election/local_election_results.json');
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return LocalElectionData.fromJson(json);
}

/// Provider for local bodies in a specific district
@riverpod
List<LocalBodyResult> localBodiesForDistrict(LocalBodiesForDistrictRef ref, String districtName) {
  final dataAsync = ref.watch(localElectionResultsProvider);
  final data = dataAsync.valueOrNull;
  if (data == null) return [];

  return data.localBodies
      .where((lb) => lb.district.toLowerCase() == districtName.toLowerCase())
      .toList();
}

/// Selected local body provider
@riverpod
class SelectedLocalBody extends _$SelectedLocalBody {
  @override
  String? build() => null;

  void setLocalBody(String? id) {
    state = id;
  }

  void clear() {
    state = null;
  }
}

/// Screen showing local bodies for a district with interactive SVG map
class LocalBodyScreen extends ConsumerStatefulWidget {
  final String districtName;

  const LocalBodyScreen({super.key, required this.districtName});

  @override
  ConsumerState<LocalBodyScreen> createState() => _LocalBodyScreenState();
}

class _LocalBodyScreenState extends ConsumerState<LocalBodyScreen> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  String _getSvgPath() {
    // Special mappings for district names to SVG file slugs
    // These must match the SVG file names in assets/data/election/districts/
    const nameToSlug = {
      'Nawalparasi West': 'nawalparasi-west',
      'Nawalparasi East': 'nawalparasi-east',
      'Eastern Rukum': 'eastern-rukum',
      'Western Rukum': 'western-rukum',
      'Kavrepalanchowk': 'kavrepalanchowk',
      'Sindhupalchowk': 'sindhupalchowk',
      'Illam': 'illam',
      'Tanahun': 'tanahun',
    };

    // Check for special mapping first
    if (nameToSlug.containsKey(widget.districtName)) {
      return 'assets/data/election/districts/${nameToSlug[widget.districtName]}.svg';
    }

    // Convert district name to slug for SVG file
    final slug = widget.districtName
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll('(', '')
        .replaceAll(')', '');
    return 'assets/data/election/districts/$slug.svg';
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocalBody = ref.watch(selectedLocalBodyProvider);
    final localBodies = ref.watch(localBodiesForDistrictProvider(widget.districtName));
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: selectedLocalBody == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedLocalBody != null) {
          ref.read(selectedLocalBodyProvider.notifier).clear();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: HomeTitle(child: Text(widget.districtName)),
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
        body: localBodies.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  // Map area
                  Expanded(
                    child: Stack(
                      children: [
                        _buildInteractiveMap(localBodies),
                        if (selectedLocalBody != null)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: _LocalBodyInfoChip(name: selectedLocalBody),
                          ),
                      ],
                    ),
                  ),
                  // Side panel for selected local body
                  if (selectedLocalBody != null)
                    _buildOfficialsPanel(localBodies, selectedLocalBody),
                ],
              ),
      ),
    );
  }

  Widget _buildInteractiveMap(List<LocalBodyResult> localBodies) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      constrained: false,
      child: SizedBox(
        width: 800,
        height: 600,
        child: _LocalBodyMapWidget(
          svgPath: _getSvgPath(),
          localBodies: localBodies,
          onLocalBodyTap: (name) {
            if (name.isEmpty) {
              ref.read(selectedLocalBodyProvider.notifier).clear();
            } else {
              ref.read(selectedLocalBodyProvider.notifier).setLocalBody(name);
            }
          },
        ),
      ),
    );
  }

  Widget _buildOfficialsPanel(List<LocalBodyResult> localBodies, String localBodyName) {
    // Find the local body
    final localBody = localBodies.firstWhere(
      (lb) => lb.name == localBodyName || lb.id == localBodyName,
      orElse: () => LocalBodyResult(
        id: '',
        locId: '',
        name: localBodyName,
        nameNp: '',
        district: '',
        province: 0,
        type: '',
        officials: [],
      ),
    );

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
                        localBody.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (localBody.nameNp.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          localBody.nameNp,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      _LocalBodyTypeChip(type: localBody.type),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      ref.read(selectedLocalBodyProvider.notifier).clear(),
                ),
              ],
            ),
          ),
          // Officials list
          Expanded(
            child: localBody.officials.isEmpty
                ? Center(
                    child: Text(
                      l10n.noCandidatesFound,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
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

/// Interactive local body map widget
class _LocalBodyMapWidget extends StatefulWidget {
  final String svgPath;
  final List<LocalBodyResult> localBodies;
  final void Function(String name) onLocalBodyTap;

  const _LocalBodyMapWidget({
    required this.svgPath,
    required this.localBodies,
    required this.onLocalBodyTap,
  });

  @override
  State<_LocalBodyMapWidget> createState() => _LocalBodyMapWidgetState();
}

class _LocalBodyMapWidgetState extends State<_LocalBodyMapWidget> {
  final SvgPathParser _pathParser = SvgPathParser();
  final GlobalKey _mapKey = GlobalKey();
  bool _isLoading = true;
  bool _svgExists = true;

  @override
  void initState() {
    super.initState();
    _loadSvgPaths();
  }

  Future<void> _loadSvgPaths() async {
    try {
      await _pathParser.loadSvg(widget.svgPath);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _svgExists = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_svgExists) {
      // Fallback to list view if SVG doesn't exist
      return _buildListFallback();
    }

    return Stack(
      children: [
        SvgPicture.asset(
          widget.svgPath,
          key: _mapKey,
          width: 800,
          height: 600,
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

  Widget _buildListFallback() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.localBodies.length,
      itemBuilder: (context, index) {
        final lb = widget.localBodies[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getTypeColor(lb.type),
              child: Icon(
                _getTypeIcon(lb.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(lb.name),
            subtitle: Text(lb.nameNp),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => widget.onLocalBodyTap(lb.name),
          ),
        );
      },
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
      // Find matching local body
      final localBodyName = _findLocalBodyName(pathId);
      if (localBodyName != null) {
        widget.onLocalBodyTap(localBodyName);
      }
    } else {
      widget.onLocalBodyTap('');
    }
  }

  String? _findLocalBodyName(String pathId) {
    // Try to match path ID with local body ID or name
    for (final lb in widget.localBodies) {
      final normalizedId = lb.id.toLowerCase().replaceAll(' ', '-');
      final normalizedName = lb.name.toLowerCase().replaceAll(' ', '-');
      if (normalizedId == pathId || normalizedName == pathId || lb.id == pathId) {
        return lb.name;
      }
    }
    // Return formatted name as fallback
    return pathId.split('-').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'metropolitan':
        return Colors.purple;
      case 'sub-metropolitan':
        return Colors.indigo;
      case 'municipality':
        return Colors.blue;
      case 'rural-municipality':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'metropolitan':
      case 'sub-metropolitan':
        return Icons.location_city;
      case 'municipality':
        return Icons.business;
      case 'rural-municipality':
        return Icons.nature_people;
      default:
        return Icons.place;
    }
  }
}

class _LocalBodyInfoChip extends StatelessWidget {
  final String name;

  const _LocalBodyInfoChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_city, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            Text(name, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _LocalBodyTypeChip extends StatelessWidget {
  final String type;

  const _LocalBodyTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final label = type.replaceAll('-', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: _getColor().withOpacity(0.2),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _getColor() {
    switch (type) {
      case 'metropolitan':
        return Colors.purple;
      case 'sub-metropolitan':
        return Colors.indigo;
      case 'municipality':
        return Colors.blue;
      case 'rural-municipality':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

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
                  // Position badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPositionColor().withOpacity(0.1),
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
                  // Name
                  Text(
                    official.nameNp.isNotEmpty ? official.nameNp : official.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  // Party
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
                  // Votes
                  if (official.votes > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.how_to_vote, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${official.votes} votes',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
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
      backgroundColor: _getPositionColor().withOpacity(0.1),
      child: Icon(
        official.position.contains('Mayor') || official.position.contains('Chairperson')
            ? Icons.person
            : Icons.person_outline,
        color: _getPositionColor(),
      ),
    );

    if (official.imageUrl.isEmpty) {
      return fallback;
    }

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
