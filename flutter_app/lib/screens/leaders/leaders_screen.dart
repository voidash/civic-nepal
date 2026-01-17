import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/leaders_provider.dart';
import '../../models/leader.dart';
import '../../models/district.dart';

part 'leaders_screen.g.dart';

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort by'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SortOption(
              label: 'Name',
              value: 'name',
              current: currentSort,
              onTap: () {
                ref.read(leadersSortOptionProvider.notifier).setSortOption('name');
                context.pop();
              },
            ),
            _SortOption(
              label: 'Votes',
              value: 'votes',
              current: currentSort,
              onTap: () {
                ref.read(leadersSortOptionProvider.notifier).setSortOption('votes');
                context.pop();
              },
            ),
            _SortOption(
              label: 'District',
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

    // Apply search filter
    final searchFilteredLeaders = _searchQuery.isEmpty
        ? filteredLeaders
        : filteredLeaders
            .where((l) =>
                l.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                l.party.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (l.district?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: () => _showSortDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
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
                hintText: 'Search leaders...',
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
                              ? 'No leaders match your filters'
                              : 'No leaders found',
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
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(leadersProvider),
                      child: const Text('Retry'),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          if (selectedParty != null)
            Chip(
              label: Text('Party: $selectedParty'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: onClearParty,
              avatar: const Icon(Icons.partybox, size: 18),
            ),
          if (selectedDistrict != null)
            Chip(
              label: Text('District: $selectedDistrict'),
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
                    'Filters',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedPartyProvider.notifier).clear();
                      ref.read(selectedDistrictProvider.notifier).clear();
                      context.pop();
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const Divider(),

              // Party filter section
              const Text('Party', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          subtitle: Text('${party.leaderCount} leaders'),
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
                  error: (error, stack) => Text('Error loading parties: $error'),
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
                  label: const Text('Filter by District'),
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
                    'Select District',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedDistrictProvider.notifier).clear();
                      context.pop();
                    },
                    child: const Text('Clear'),
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
                      title: Text('Province $currentProvince'),
                      subtitle: Text('${districtList.length} districts'),
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
                  error: (error, stack) => Text('Error loading districts: $error'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Leader card widget
class LeaderCard extends StatelessWidget {
  final Leader leader;

  const LeaderCard({
    super.key,
    required this.leader,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/leaders/${leader.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Leader image
              Hero(
                tag: 'leader-${leader.id}',
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: leader.imageUrl.isNotEmpty
                      ? NetworkImage(leader.imageUrl)
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
                    Row(
                      children: [
                        Icon(
                          Icons.partybox,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            leader.party,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            leader.district ?? 'Unknown district',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Vote count
              Column(
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: Colors.green.shade700,
                    size: 16,
                  ),
                  Text(
                    _formatVotes(leader.totalVotes),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatVotes(int votes) {
    if (votes >= 1000000) {
      return '${(votes / 1000000).toStringAsFixed(1)}M';
    } else if (votes >= 1000) {
      return '${(votes / 1000).toStringAsFixed(1)}K';
    }
    return votes.toString();
  }
}
