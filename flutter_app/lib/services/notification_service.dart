import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/ipo.dart';
import 'nepali_date_service.dart';

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

  static const int _stickyDateNotificationId = 999999;

  /// Initialize notification service
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
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

  /// Show sticky date notification with today's Nepali date
  static Future<void> showStickyDateNotification() async {
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
          ongoing: true, // Make it sticky
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

  /// Cancel sticky date notification
  static Future<void> cancelStickyDateNotification() async {
    await _notifications.cancel(_stickyDateNotificationId);
  }

  /// Update sticky date notification (call at midnight or app open)
  static Future<void> updateStickyDateNotificationIfEnabled() async {
    // This will be called from settings screen when toggled
    await showStickyDateNotification();
  }
}
