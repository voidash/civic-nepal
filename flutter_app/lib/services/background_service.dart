import 'package:workmanager/workmanager.dart';
import 'package:workmanager_platform_interface/src/pigeon/workmanager_api.g.dart' show ExistingPeriodicWorkPolicy;
import 'ipo_service.dart';
import 'notification_service.dart';

/// Background task names
const String ipoCheckTask = 'com.nepal.civic.ipoCheck';
const String ipoCheckTaskUnique = 'ipoCheckTaskUnique';

/// Callback dispatcher for WorkManager
/// This must be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case ipoCheckTask:
        await _checkForNewIpos();
        return true;
      default:
        return true;
    }
  });
}

/// Check for new IPOs and send notifications
Future<void> _checkForNewIpos() async {
  try {
    // Clean up old notification records periodically
    await IpoService.cleanupOldNotifications();

    // Fetch current IPO list
    final ipos = await IpoService.fetchIpoList();
    if (ipos.isEmpty) return;

    final now = DateTime.now();

    for (final ipo in ipos) {
      // 1. New IPO notification (only for IPOs opening within 7 days)
      final daysUntilOpen = ipo.openDate.difference(now).inDays;
      if (daysUntilOpen >= 0 && daysUntilOpen <= 7) {
        final wasNewNotified = await IpoService.wasEventNotified(ipo, IpoService.eventNew);
        if (!wasNewNotified) {
          await NotificationService.showNewIpoNotification(ipo);
          await IpoService.markEventNotified(ipo, IpoService.eventNew);
        }
      }

      // 2. Opening today/tomorrow notification
      if (daysUntilOpen >= 0 && daysUntilOpen <= 1) {
        final wasOpeningNotified = await IpoService.wasEventNotified(ipo, IpoService.eventOpening);
        if (!wasOpeningNotified) {
          await NotificationService.showIpoOpeningTodayNotification(ipo);
          await IpoService.markEventNotified(ipo, IpoService.eventOpening);
        }
      }

      // 3. Closing soon notification (today or tomorrow)
      if (IpoService.isCurrentlyOpen(ipo)) {
        final daysUntilClose = ipo.closeDate.difference(now).inDays;
        if (daysUntilClose >= 0 && daysUntilClose <= 1) {
          final wasClosingNotified = await IpoService.wasEventNotified(ipo, IpoService.eventClosing);
          if (!wasClosingNotified) {
            await NotificationService.showIpoClosingSoonNotification(ipo);
            await IpoService.markEventNotified(ipo, IpoService.eventClosing);
          }
        }
      }
    }

    // Mark all current IPOs as seen (for the "seen" list, separate from notifications)
    await IpoService.markIposAsSeen(ipos);
  } catch (e) {
    // Silent fail for background tasks
  }
}

/// Service for managing background tasks
class BackgroundService {
  /// Initialize background task service
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Register periodic IPO check task (every 3 hours)
  static Future<void> registerIpoCheckTask() async {
    await Workmanager().registerPeriodicTask(
      ipoCheckTaskUnique,
      ipoCheckTask,
      frequency: const Duration(hours: 3),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  /// Run IPO check immediately
  static Future<void> runIpoCheckNow() async {
    await _checkForNewIpos();
  }

  /// Cancel all background tasks
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  /// Cancel IPO check task
  static Future<void> cancelIpoCheckTask() async {
    await Workmanager().cancelByUniqueName(ipoCheckTaskUnique);
  }
}
