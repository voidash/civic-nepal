import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/ronb_service.dart';

part 'ronb_provider.g.dart';

/// Fetches the RONB feed from Facebook.
///
/// Strategy for snappiness:
/// - Returns cached data immediately if available
/// - If cache is stale (>30 min), still returns it but triggers background refresh
/// - Force refresh fetches fresh data from Facebook
@riverpod
Future<RonbFeed> ronbFeed(Ref ref) async {
  // First try to get cached data instantly
  final cached = await RonbService.getCachedFeed();
  if (cached != null) {
    // Check if stale - if so, schedule background refresh
    final age = DateTime.now().toUtc().difference(cached.scrapedAt);
    if (age > const Duration(minutes: 30)) {
      // Fire-and-forget background refresh
      RonbService.fetchFeed(forceRefresh: true).then((fresh) {
        // After background fetch completes, invalidate to show new data
        ref.invalidateSelf();
      }).catchError((_) {});
    }
    return cached;
  }

  // No cache - must fetch fresh
  return RonbService.fetchFeed();
}

/// Tracks whether a manual refresh is in progress.
@riverpod
class RonbRefreshing extends _$RonbRefreshing {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
