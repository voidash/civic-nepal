import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/leaders_provider.dart';
import '../../models/leader.dart';

part 'leaders_screen.g.dart';

/// Leaders screen with filters and list
class LeadersScreen extends ConsumerWidget {
  const LeadersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadersAsync = ref.watch(leadersProvider);
    final filteredLeaders = ref.watch(filteredLeadersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filters
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(context, ref),
          // Leaders list
          Expanded(
            child: leadersAsync.when(
              data: (_) {
                if (filteredLeaders.isEmpty) {
                  return const Center(child: Text('No leaders found'));
                }
                return ListView.builder(
                  itemCount: filteredLeaders.length,
                  itemBuilder: (context, index) {
                    final leader = filteredLeaders[index];
                    return LeaderCard(leader: leader);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChip(
            label: const Text('All'),
            selected: true,
            onSelected: (selected) {
              // Clear filters
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('By Party'),
            onSelected: (selected) {
              // Show party filter
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('By District'),
            onSelected: (selected) {
              // Show district filter
            },
          ),
        ],
      ),
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
        onTap: () {
          // Navigate to leader detail
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Leader image
              CircleAvatar(
                radius: 32,
                backgroundImage: leader.imageUrl.isNotEmpty
                    ? NetworkImage(leader.imageUrl)
                    : null,
                child: leader.imageUrl.isEmpty
                    ? Text(leader.name[0])
                    : null,
              ),
              const SizedBox(width: 16),
              // Leader info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leader.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leader.party,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leader.district ?? 'Unknown district',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Vote count
              Column(
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                  Text(
                    '${leader.totalVotes}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
