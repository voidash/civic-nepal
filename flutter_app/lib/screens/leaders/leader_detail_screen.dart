import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);

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
                          ? _buildLeaderImage(context, leader)
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

                      // Party and district
                      _SectionCard(
                        icon: Icons.groups,
                        title: l10n.party,
                        child: Text(
                          leader.party,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (leader.district != null)
                        _SectionCard(
                          icon: Icons.location_on,
                          title: l10n.district,
                          child: Text(
                            leader.district!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Biography
                      Text(
                        l10n.biography,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        leader.biography.isNotEmpty
                            ? leader.biography
                            : l10n.noBiography,
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
                          label: Text(l10n.viewAllLeaders),
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
              Text('${l10n.error}: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: Text(l10n.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderImage(BuildContext context, Leader leader) {
    final isNetworkImage = leader.imageUrl.startsWith('http://') || leader.imageUrl.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        leader.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(context, leader),
      );
    } else {
      return Image.asset(
        leader.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(context, leader),
      );
    }
  }

  Widget _buildFallbackImage(BuildContext context, Leader leader) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: Text(
          leader.name.isNotEmpty ? leader.name[0] : '?',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
