import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/ronb_provider.dart';
import '../../services/ronb_service.dart';
import '../../widgets/home_title.dart';

/// RONB (Routine of Nepal Banda) news feed screen.
///
/// Scrapes the RONB Facebook page directly (no backend needed).
/// Auto-refreshes every 30 minutes, supports pull-to-refresh.
/// Shows cached data instantly, fetches updates in background.
class RonbFeedScreen extends ConsumerStatefulWidget {
  const RonbFeedScreen({super.key});

  @override
  ConsumerState<RonbFeedScreen> createState() => _RonbFeedScreenState();
}

class _RonbFeedScreenState extends ConsumerState<RonbFeedScreen> {
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _scheduleAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _refresh(),
    );
  }

  Future<void> _refresh() async {
    ref.read(ronbRefreshingProvider.notifier).set(true);
    try {
      await RonbService.fetchFeed(forceRefresh: true);
      ref.invalidate(ronbFeedProvider);
    } finally {
      if (mounted) {
        ref.read(ronbRefreshingProvider.notifier).set(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(ronbFeedProvider);
    final isRefreshing = ref.watch(ronbRefreshingProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? null // default back button
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/home'),
                tooltip: 'Back to Home',
              ),
        title: const HomeTitle(child: Text('RONB Feed')),
        actions: [
          if (isRefreshing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh feed',
              onPressed: _refresh,
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open on Facebook',
            onPressed: () => _openFacebook(),
          ),
        ],
      ),
      body: feedAsync.when(
        data: (feed) => _buildFeed(context, feed),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, error),
      ),
    );
  }

  Widget _buildFeed(BuildContext context, RonbFeed feed) {
    if (feed.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No posts found'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: feed.posts.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFeedHeader(context, feed);
          }
          return _PostCard(post: feed.posts[index - 1]);
        },
      ),
    );
  }

  Widget _buildFeedHeader(BuildContext context, RonbFeed feed) {
    final npt = feed.scrapedAt.add(const Duration(hours: 5, minutes: 45));
    final timeStr =
        '${npt.hour.toString().padLeft(2, '0')}:${npt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1877F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'R',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Routine of Nepal Banda',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${feed.posts.length} posts \u00b7 Updated $timeStr NPT',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Could not load feed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(ronbFeedProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFacebook() async {
    final uri = Uri.parse('https://www.facebook.com/officialroutineofnepalbanda/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Individual post card widget.
class _PostCard extends StatelessWidget {
  final RonbPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header with timestamp
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.campaign,
                    size: 16,
                    color: Color(0xFF1877F2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RONB',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        post.relativeTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.postUrl != null)
                  IconButton(
                    icon: Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => _openPost(post.postUrl!),
                    tooltip: 'Open on Facebook',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),

          // Post text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: SelectableText(
              post.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          // Post image (fetched with Googlebot UA)
          if (post.imageUrl != null) _RonbImage(url: post.imageUrl!),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _openPost(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Image widget that fetches via Googlebot UA.
///
/// Facebook lookaside URLs require Googlebot UA to return actual image bytes.
/// Normal HTTP requests get redirected to a login page.
/// Uses in-memory caching for app lifetime.
class _RonbImage extends StatefulWidget {
  final String url;

  const _RonbImage({required this.url});

  @override
  State<_RonbImage> createState() => _RonbImageState();
}

class _RonbImageState extends State<_RonbImage> {
  Uint8List? _imageBytes;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await RonbService.fetchImage(widget.url);
    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _loading = false;
        _failed = bytes == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _loading
            ? Container(
                height: 200,
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Image.memory(
                _imageBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
      ),
    );
  }
}
