import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../models/constituency.dart';
import '../../providers/constituencies_provider.dart';
import '../../widgets/home_title.dart';

/// Screen showing federal constituencies for a district
class ConstituencyScreen extends ConsumerStatefulWidget {
  final String districtName;

  const ConstituencyScreen({
    super.key,
    required this.districtName,
  });

  @override
  ConsumerState<ConstituencyScreen> createState() => _ConstituencyScreenState();
}

class _ConstituencyScreenState extends ConsumerState<ConstituencyScreen> {
  @override
  Widget build(BuildContext context) {
    final constituencies = ref.watch(constituenciesForDistrictProvider(widget.districtName));
    final selectedConstituency = ref.watch(selectedConstituencyProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(child: Text('${widget.districtName} ${l10n.constituencies}')),
      ),
      body: constituencies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noConstituenciesFound,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                // Constituencies list
                Expanded(
                  flex: selectedConstituency != null ? 1 : 2,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: constituencies.length,
                    itemBuilder: (context, index) {
                      final constituency = constituencies[index];
                      final isSelected = selectedConstituency?.id == constituency.id;

                      return Card(
                        elevation: isSelected ? 4 : 1,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getProvinceColor(constituency.province),
                            child: Text(
                              '${constituency.number}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(constituency.name),
                          subtitle: Text('${constituency.candidates.length} ${l10n.candidates}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ref
                                .read(selectedConstituencyProvider.notifier)
                                .setConstituency(constituency);
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Candidates panel
                if (selectedConstituency != null)
                  Expanded(
                    flex: 2,
                    child: _CandidatesPanel(
                      constituency: selectedConstituency,
                      onClose: () {
                        ref.read(selectedConstituencyProvider.notifier).clear();
                      },
                    ),
                  ),
              ],
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

/// Panel showing candidates for a constituency
class _CandidatesPanel extends StatelessWidget {
  final Constituency constituency;
  final VoidCallback onClose;

  const _CandidatesPanel({
    required this.constituency,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
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
                        constituency.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${constituency.candidates.length} ${l10n.candidates}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          // Candidates list
          Expanded(
            child: constituency.candidates.isEmpty
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
                    itemCount: constituency.candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = constituency.candidates[index];
                      return _CandidateCard(candidate: candidate);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Card showing candidate details
class _CandidateCard extends StatelessWidget {
  final Candidate candidate;

  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Candidate photo
            _buildAvatar(context),
            const SizedBox(width: 12),
            // Candidate info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Party symbol
                      if (candidate.partySymbol.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CachedNetworkImage(
                            imageUrl: candidate.partySymbol,
                            width: 20,
                            height: 20,
                            errorWidget: (context, url, error) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          candidate.party,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (candidate.votes > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.how_to_vote, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${candidate.votes} votes',
                          style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildAvatar(BuildContext context) {
    final fallback = CircleAvatar(
      radius: 28,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        candidate.name.isNotEmpty ? candidate.name[0] : '?',
        style: TextStyle(
          fontSize: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    if (candidate.imageUrl.isEmpty ||
        candidate.imageUrl.contains('placeholder')) {
      return fallback;
    }

    return CachedNetworkImage(
      imageUrl: candidate.imageUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 28,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: 28,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => fallback,
    );
  }
}
