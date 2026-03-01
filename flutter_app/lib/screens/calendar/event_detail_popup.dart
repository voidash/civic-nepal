import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:url_launcher/url_launcher.dart';
import '../../models/calendar_event.dart';
import '../../providers/calendar_view_provider.dart';
import '../../services/google_auth_service.dart';
import '../../services/nepali_date_service.dart';

/// Shows event details when tapping an event block on the timeline.
class EventDetailPopup {
  static void show(BuildContext context, WidgetRef ref, CalendarEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => _EventDetailDialog(event: event),
    );
  }
}

class _EventDetailDialog extends ConsumerWidget {
  final CalendarEvent event;
  const _EventDetailDialog({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color eventColor;
    if (event.source == CalendarEventSource.google) {
      eventColor = event.color ?? Colors.blue;
    } else if (event.isHoliday) {
      eventColor = Colors.red;
    } else if (event.auspiciousType != null) {
      eventColor = Colors.green;
    } else {
      eventColor = Colors.orange;
    }

    final bs = NepaliDateService.adToBs(event.startTime);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color bar + title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: eventColor.withValues(alpha: isDark ? 0.3 : 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: eventColor.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: eventColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (event.titleNp != null && event.titleNp != event.title)
                          Text(
                            event.titleNp!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Details
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and time
                    _DetailRow(
                      icon: Icons.access_time,
                      color: eventColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateRange(),
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            NepaliDateService.formatShortNp(bs),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Location
                    if (event.location != null && event.location!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.location_on,
                        color: eventColor,
                        child: Text(event.location!, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                    // Description
                    if (event.description != null && event.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.notes,
                        color: eventColor,
                        child: Text(event.description!, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                    // Source badge
                    const SizedBox(height: 16),
                    _SourceBadge(event: event, color: eventColor),
                    // Actions for Google events
                    if (event.source == CalendarEventSource.google) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openInGoogleCalendar(event),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Open in Google Calendar', style: TextStyle(fontSize: 12)),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _deleteEvent(context, ref, event),
                            icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                            label: Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red.shade400)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange() {
    if (event.isAllDay) {
      return _formatDate(event.startTime);
    }
    final start = _formatTime(event.startTime);
    if (event.endTime != null) {
      final end = _formatTime(event.endTime!);
      final sameDay = event.startTime.year == event.endTime!.year &&
          event.startTime.month == event.endTime!.month &&
          event.startTime.day == event.endTime!.day;
      if (sameDay) {
        return '${_formatDate(event.startTime)}, $start \u2013 $end';
      }
      return '${_formatDate(event.startTime)} $start \u2013 ${_formatDate(event.endTime!)} $end';
    }
    return '${_formatDate(event.startTime)}, $start';
  }

  static String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$min $ampm';
  }

  void _openInGoogleCalendar(CalendarEvent event) {
    final url = 'https://calendar.google.com/calendar/event?eid=${event.id}';
    launchUrl(Uri.parse(url));
  }

  Future<void> _deleteEvent(BuildContext context, WidgetRef ref, CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('Delete "${event.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final api = GoogleAuthService.instance.calendarApi;
    if (api == null) return;

    try {
      await api.events.delete(event.calendarId ?? 'primary', event.id);
      ref.invalidate(googleCalendarSyncProvider);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${event.title}" deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Widget child;

  const _DetailRow({required this.icon, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final CalendarEvent event;
  final Color color;

  const _SourceBadge({required this.event, required this.color});

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;

    switch (event.source) {
      case CalendarEventSource.google:
        label = 'Google Calendar';
        icon = Icons.cloud;
      case CalendarEventSource.nepali:
        if (event.isHoliday) {
          label = 'Public Holiday';
          icon = Icons.celebration;
        } else if (event.auspiciousType != null) {
          label = 'Auspicious Day';
          icon = Icons.auto_awesome;
        } else {
          label = 'Nepali Calendar';
          icon = Icons.event;
        }
      case CalendarEventSource.local:
        label = 'Local Event';
        icon = Icons.phone_android;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
