import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/leaders_provider.dart';
import '../../models/leader.dart';
import '../../models/district.dart';
import '../../widgets/home_title.dart';

/// Leaders screen with filters and list
class LeadersScreen extends ConsumerStatefulWidget {
  const LeadersScreen({super.key});

  @override
  ConsumerState<LeadersScreen> createState() => _LeadersScreenState();
}

class _LeadersScreenState extends ConsumerState<LeadersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _FilterBottomSheet(),
    );
  }

  void _showSortDialog(BuildContext context, WidgetRef ref) {
    final currentSort = ref.read(leadersSortOptionProvider);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sortBy),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SortOption(
              label: l10n.name,
              value: 'name',
              current: currentSort,
              onTap: () {
                ref.read(leadersSortOptionProvider.notifier).setSortOption('name');
                context.pop();
              },
            ),
            _SortOption(
              label: l10n.district,
              value: 'district',
              current: currentSort,
              onTap: () {
                ref.read(leadersSortOptionProvider.notifier).setSortOption('district');
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadersAsync = ref.watch(leadersProvider);
    final filteredLeaders = ref.watch(filteredLeadersProvider);
    final selectedParty = ref.watch(selectedPartyProvider);
    final selectedDistrict = ref.watch(selectedDistrictProvider);
    final l10n = AppLocalizations.of(context);

    // Apply fuzzy search filter
    final searchFilteredLeaders = _searchQuery.isEmpty
        ? filteredLeaders
        : _fuzzySearchLeaders(filteredLeaders, _searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(child: Text(l10n.leaders)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sort,
            onPressed: () => _showSortDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: l10n.filter,
            onPressed: () => _showFilterDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters chips
          if (selectedParty != null || selectedDistrict != null)
            _ActiveFiltersChips(
              selectedParty: selectedParty,
              selectedDistrict: selectedDistrict,
              onClearParty: () => ref.read(selectedPartyProvider.notifier).clear(),
              onClearDistrict: () => ref.read(selectedDistrictProvider.notifier).clear(),
            ),

          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchLeaders,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Leaders list
          Expanded(
            child: leadersAsync.when(
              data: (_) {
                if (searchFilteredLeaders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ||
                                  selectedParty != null ||
                                  selectedDistrict != null
                              ? l10n.noLeadersMatch
                              : l10n.noLeadersFound,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: searchFilteredLeaders.length,
                  itemBuilder: (context, index) {
                    final leader = searchFilteredLeaders[index];
                    return LeaderCard(leader: leader);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('${l10n.error}: $error'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(leadersProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fuzzy search leaders by name, party, or district
  List<Leader> _fuzzySearchLeaders(List<Leader> leaders, String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return leaders;

    final scored = leaders.map((leader) {
      final nameScore = _fuzzyScore(leader.name.toLowerCase(), normalizedQuery);
      final partyScore = _fuzzyScore(leader.party.toLowerCase(), normalizedQuery);
      final districtScore = leader.district != null
          ? _fuzzyScore(leader.district!.toLowerCase(), normalizedQuery)
          : 0.0;
      final bestScore = [nameScore, partyScore, districtScore].reduce((a, b) => a > b ? a : b);
      return (leader: leader, score: bestScore);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.where((s) => s.score > 0.3).map((s) => s.leader).toList();
  }

  double _fuzzyScore(String text, String query) {
    if (text == query) return 1.0;
    if (text.contains(query)) return 0.9;
    if (text.startsWith(query)) return 0.85;
    for (final word in text.split(RegExp(r'\s+'))) {
      if (word.startsWith(query)) return 0.8;
    }
    if (_isSubsequence(query, text)) return 0.5 + (query.length / text.length * 0.3);
    final overlap = query.split('').toSet().intersection(text.split('').toSet()).length / query.length;
    if (overlap > 0.6) return overlap * 0.5;
    return 0.0;
  }

  bool _isSubsequence(String query, String text) {
    int qi = 0;
    for (int ti = 0; ti < text.length && qi < query.length; ti++) {
      if (text[ti] == query[qi]) qi++;
    }
    return qi == query.length;
  }
}

/// Active filter chips display
class _ActiveFiltersChips extends StatelessWidget {
  final String? selectedParty;
  final String? selectedDistrict;
  final VoidCallback onClearParty;
  final VoidCallback onClearDistrict;

  const _ActiveFiltersChips({
    required this.selectedParty,
    required this.selectedDistrict,
    required this.onClearParty,
    required this.onClearDistrict,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          if (selectedParty != null)
            Chip(
              label: Text('${l10n.party}: $selectedParty'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: onClearParty,
              avatar: const Icon(Icons.groups, size: 18),
            ),
          if (selectedDistrict != null)
            Chip(
              label: Text('${l10n.district}: $selectedDistrict'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: onClearDistrict,
              avatar: const Icon(Icons.location_on, size: 18),
            ),
        ],
      ),
    );
  }
}

/// Sort option radio button
class _SortOption extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      leading: Radio<String>(
        value: value,
        groupValue: current,
        onChanged: (_) => onTap(),
      ),
      onTap: onTap,
    );
  }
}

/// Filter bottom sheet
class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(partiesProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final l10n = AppLocalizations.of(context);

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
              // Drag handle
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

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.filters,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedPartyProvider.notifier).clear();
                      ref.read(selectedDistrictProvider.notifier).clear();
                      context.pop();
                    },
                    child: Text(l10n.clearAll),
                  ),
                ],
              ),
              const Divider(),

              // Party filter section
              Text(l10n.party, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: partiesAsync.when(
                  data: (partyData) {
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: partyData.parties.length,
                      itemBuilder: (context, index) {
                        final party = partyData.parties[index];
                        final selectedParty = ref.watch(selectedPartyProvider);
                        final isSelected = selectedParty == party.name;

                        return CheckboxListTile(
                          title: Text(party.name),
                          subtitle: Text(l10n.leadersCount(party.leaderCount)),
                          secondary: CircleAvatar(
                            backgroundColor: Color(
                              int.parse(party.color.replaceFirst('#', '0xFF')),
                            ),
                            radius: 8,
                          ),
                          value: isSelected,
                          onChanged: (_) {
                            ref.read(selectedPartyProvider.notifier).setParty(
                                  isSelected ? null : party.name,
                                );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('${l10n.error}: $error'),
                ),
              ),

              // District filter button (shows second sheet)
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDistrictFilter(context, ref);
                  },
                  icon: const Icon(Icons.location_on),
                  label: Text(l10n.filterByDistrict),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDistrictFilter(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DistrictFilterSheet(),
    );
  }
}

/// District filter sheet
class _DistrictFilterSheet extends ConsumerWidget {
  const _DistrictFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districtsAsync = ref.watch(districtsProvider);
    final l10n = AppLocalizations.of(context);

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
              // Drag handle
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

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.selectDistrict,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedDistrictProvider.notifier).clear();
                      context.pop();
                    },
                    child: Text(l10n.clear),
                  ),
                ],
              ),
              const Divider(),

              // District list grouped by province
              Expanded(
                child: districtsAsync.when(
                  data: (districtData) {
                    // Group districts by province
                    final provinces = <int, List<MapEntry<String, dynamic>>>{};
                    districtData.districts.forEach((districtId, info) {
                      provinces.putIfAbsent(info.province, () => []).add(MapEntry(districtId, info));
                    });

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: provinces.keys.length,
                      itemBuilder: (context, index) {
                        final province = provinces.keys.toList()..sort();
                        province.sort();
                        final currentProvince = province[index];
                        final districtList = provinces[currentProvince]!;

                    return ExpansionTile(
                      title: Text(l10n.provinceNumber(currentProvince)),
                      subtitle: Text(l10n.districtsCount(districtList.length)),
                      children: districtList.map((entry) {
                        final districtId = entry.key;
                        final info = entry.value;
                        final selectedDistrict = ref.watch(selectedDistrictProvider);
                        final isSelected = selectedDistrict == info.name;

                        return CheckboxListTile(
                          title: Text(info.name),
                          value: isSelected,
                          onChanged: (_) {
                            ref.read(selectedDistrictProvider.notifier).setDistrict(
                                  isSelected ? null : info.name,
                                );
                            context.pop();
                          },
                          dense: true,
                        );
                      }).toList(),
                    );
                  },
                );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('${l10n.error}: $error'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Leader card widget - shows name, party, district, and bio snippet
class LeaderCard extends StatelessWidget {
  final Leader leader;

  const LeaderCard({
    super.key,
    required this.leader,
  });

  @override
  Widget build(BuildContext context) {
    // Get first ~100 chars of biography as snippet
    final bioSnippet = leader.biography.length > 100
        ? '${leader.biography.substring(0, 100).replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ')}...'
        : leader.biography.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/leaders/${leader.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leader image
              Hero(
                tag: 'leader-${leader.id}',
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: leader.imageUrl.isNotEmpty
                      ? _getImageProvider(leader.imageUrl)
                      : null,
                  child: leader.imageUrl.isEmpty
                      ? Text(
                          leader.name.isNotEmpty ? leader.name[0] : '?',
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Leader info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leader.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    // Party and District
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.groups,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                leader.party,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (leader.district != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                leader.district!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (bioSnippet.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        bioSnippet,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl);
    } else {
      return AssetImage(imageUrl);
    }
  }
}
