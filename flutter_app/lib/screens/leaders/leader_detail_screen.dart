import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../models/leader.dart';
import '../../providers/leaders_provider.dart';

part 'leader_detail_screen.g.dart';

/// Provider for the selected leader ID
@riverpod
class SelectedLeaderId extends _$SelectedLeaderId {
  @override
  String? build() => null;

  void setLeaderId(String? id) {
    state = id;
  }
}

/// Screen displaying detailed information about a single leader
class LeaderDetailScreen extends ConsumerWidget {
  final String leaderId;

  const LeaderDetailScreen({
    super.key,
    required this.leaderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadersAsync = ref.watch(leadersProvider);

    return Scaffold(
      body: leadersAsync.when(
        data: (data) {
          final leader = data.leaders.firstWhere(
            (l) => l.id == leaderId,
            orElse: () => throw LeaderNotFoundException(leaderId),
          );

          return CustomScrollView(
            slivers: [
              // App bar with image
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(leader.name),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      leader.imageUrl.isNotEmpty
                          ? Image.network(
                              leader.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  child: Center(
                                    child: Text(
                                      leader.name[0],
                                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: Center(
                                child: Text(
                                  leader.name[0],
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ),
                      // Gradient overlay for better text readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and position
                      Text(
                        leader.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        leader.position,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Info cards row
                      Row(
                        children: [
                          Expanded(
                            child: _InfoCard(
                              icon: Icons.how_to_vote,
                              label: 'Total Votes',
                              value: '${leader.totalVotes}',
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoCard(
                              icon: Icons.thumb_up,
                              label: 'Upvotes',
                              value: '${leader.upvotes}',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoCard(
                              icon: Icons.thumb_down,
                              label: 'Downvotes',
                              value: '${leader.downvotes}',
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Party and district
                      _SectionCard(
                        icon: Icons.groups,
                        title: 'Party',
                        child: Text(
                          leader.party,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (leader.district != null)
                        _SectionCard(
                          icon: Icons.location_on,
                          title: 'District',
                          child: Text(
                            leader.district!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Biography
                      Text(
                        'Biography',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        leader.biography.isNotEmpty
                            ? leader.biography
                            : 'No biography available.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // View other leaders button
                      Center(
                        child: FilledButton.tonalIcon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.list),
                          label: const Text('View All Leaders'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
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
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: child,
      ),
    );
  }
}

/// Exception thrown when a leader is not found
class LeaderNotFoundException implements Exception {
  final String leaderId;
  LeaderNotFoundException(this.leaderId);

  @override
  String toString() => 'Leader with ID "$leaderId" not found';
}
