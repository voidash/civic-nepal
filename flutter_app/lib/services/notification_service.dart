import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/ipo.dart';
import 'nepali_date_service.dart';

/// Method channel for foreground service control
const _foregroundServiceChannel = MethodChannel('com.nepal.constitution.nepal_civic/foreground_service');

/// Service for handling local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _ipoChannelId = 'ipo_alerts';
  static const String _ipoChannelName = 'IPO Alerts';
  static const String _ipoChannelDesc = 'Notifications for new IPO listings';

  static const String _dateChannelId = 'date_notification';
  static const String _dateChannelName = 'Today\'s Date';
  static const String _dateChannelDesc = 'Sticky notification showing today\'s Nepali date';

  static const String _eventChannelId = 'event_reminders';
  static const String _eventChannelName = 'Event Reminders';
  static const String _eventChannelDesc = 'Reminders for upcoming calendar events';

  static const int _stickyDateNotificationId = 999999;

  /// Initialize notification service
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const macOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      // IPO alerts channel
      const ipoChannel = AndroidNotificationChannel(
        _ipoChannelId,
        _ipoChannelName,
        description: _ipoChannelDesc,
        importance: Importance.high,
      );
      await android.createNotificationChannel(ipoChannel);

      // Sticky date channel (low importance for persistent notification)
      const dateChannel = AndroidNotificationChannel(
        _dateChannelId,
        _dateChannelName,
        description: _dateChannelDesc,
        importance: Importance.low,
        showBadge: false,
      );
      await android.createNotificationChannel(dateChannel);

      // Event reminders channel
      const eventChannel = AndroidNotificationChannel(
        _eventChannelId,
        _eventChannelName,
        description: _eventChannelDesc,
        importance: Importance.high,
      );
      await android.createNotificationChannel(eventChannel);
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - navigate to IPO screen
    // This will be handled by the app's navigation
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Show notification for new IPO
  static Future<void> showNewIpoNotification(Ipo ipo) async {
    final daysUntilOpen = ipo.openDate.difference(DateTime.now()).inDays;
    String body;

    if (daysUntilOpen <= 0) {
      body = '${ipo.symbol} IPO is now open! Closes on ${_formatDate(ipo.closeDate)}';
    } else if (daysUntilOpen == 1) {
      body = '${ipo.symbol} IPO opens tomorrow! Don\'t miss it.';
    } else {
      body = '${ipo.symbol} IPO opens in $daysUntilOpen days (${_formatDate(ipo.openDate)})';
    }

    await _notifications.show(
      ipo.symbol.hashCode,
      'New IPO: ${ipo.companyName}',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _ipoChannelId,
          _ipoChannelName,
          channelDescription: _ipoChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'ipo:${ipo.symbol}',
    );
  }

  /// Show notification for IPO opening today
  static Future<void> showIpoOpeningTodayNotification(Ipo ipo) async {
    await _notifications.show(
      '${ipo.symbol}_today'.hashCode,
      'IPO Opens Today!',
      '${ipo.companyName} (${ipo.symbol}) IPO is open for application. Closes on ${_formatDate(ipo.closeDate)}.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _ipoChannelId,
          _ipoChannelName,
          channelDescription: _ipoChannelDesc,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'ipo:${ipo.symbol}',
    );
  }

  /// Show notification for IPO closing soon
  static Future<void> showIpoClosingSoonNotification(Ipo ipo) async {
    final daysUntilClose = ipo.closeDate.difference(DateTime.now()).inDays;
    String body;

    if (daysUntilClose <= 0) {
      body = 'Today is the last day to apply for ${ipo.symbol}!';
    } else {
      body = '${ipo.symbol} IPO closes in $daysUntilClose day${daysUntilClose > 1 ? 's' : ''}. Apply now!';
    }

    await _notifications.show(
      '${ipo.symbol}_closing'.hashCode,
      'IPO Closing Soon',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _ipoChannelId,
          _ipoChannelName,
          channelDescription: _ipoChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'ipo:${ipo.symbol}',
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Show sticky date notification using foreground service (Android only)
  /// This notification cannot be dismissed by the user
  static Future<void> showStickyDateNotification() async {
    try {
      await _foregroundServiceChannel.invokeMethod('startDateService');
    } catch (e) {
      // Fallback to regular notification if foreground service fails
      await _showRegularStickyNotification();
    }
  }

  /// Fallback method using regular notification (can be dismissed on Android 13+)
  static Future<void> _showRegularStickyNotification() async {
    final today = NepaliDateService.today();
    final dayNameNp = NepaliDateService.getWeekdayNp(today);
    final dayNameEn = NepaliDateService.getWeekdayEn(today);
    final dateNp = NepaliDateService.formatNp(today);
    final dateEn = NepaliDateService.formatEn(today);

    await _notifications.show(
      _stickyDateNotificationId,
      '$dateNp • $dayNameNp',
      '$dateEn ($dayNameEn)',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dateChannelId,
          _dateChannelName,
          channelDescription: _dateChannelDesc,
          importance: Importance.low,
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
          ongoing: true,
          autoCancel: false,
          showWhen: false,
          playSound: false,
          enableVibration: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  /// Cancel sticky date notification (stops foreground service)
  static Future<void> cancelStickyDateNotification() async {
    try {
      await _foregroundServiceChannel.invokeMethod('stopDateService');
    } catch (e) {
      // Fallback to canceling regular notification
      await _notifications.cancel(_stickyDateNotificationId);
    }
  }

  /// Check if sticky date service is running
  static Future<bool> isStickyDateServiceRunning() async {
    try {
      final result = await _foregroundServiceChannel.invokeMethod('isServiceRunning');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Schedule a local notification for an upcoming calendar event.
  /// Uses a delayed future — works while the app is running.
  /// [minutesBefore] is how many minutes before [eventStart] to notify.
  static Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime eventStart,
    required int minutesBefore,
    String? location,
  }) async {
    final notifyAt = eventStart.subtract(Duration(minutes: minutesBefore));
    final now = DateTime.now();
    if (notifyAt.isBefore(now)) return; // Already past

    final delay = notifyAt.difference(now);
    final notificationId = '${eventId}_$minutesBefore'.hashCode;

    Future.delayed(delay, () async {
      String body;
      if (minutesBefore == 0) {
        body = 'Starting now';
      } else if (minutesBefore < 60) {
        body = 'Starting in $minutesBefore minutes';
      } else {
        final hours = minutesBefore ~/ 60;
        body = 'Starting in $hours hour${hours > 1 ? 's' : ''}';
      }
      if (location != null && location.isNotEmpty) {
        body += ' \u2022 $location';
      }

      try {
        await _notifications.show(
          notificationId,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _eventChannelId,
              _eventChannelName,
              channelDescription: _eventChannelDesc,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
            macOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: 'event:$eventId',
        );
      } catch (_) {
        // Notification failed — not critical
      }
    });
  }

  /// Cancel a scheduled event reminder.
  static Future<void> cancelEventReminder(String eventId, int minutesBefore) async {
    final notificationId = '${eventId}_$minutesBefore'.hashCode;
    await _notifications.cancel(notificationId);
  }
}
