import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import '../../providers/calendar_view_provider.dart';
import '../../providers/google_auth_provider.dart';
import '../../services/google_auth_service.dart';
import '../../services/google_calendar_service.dart';

/// Panel showing the user's Google calendars with toggles to show/hide each one.
/// Also allows subscribing to new calendars by ID.
class CalendarListPanel extends ConsumerWidget {
  const CalendarListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(googleAuthProvider);
    final calendars = ref.watch(googleCalendarListProvider);
    final enabledIds = ref.watch(enabledCalendarsNotifierProvider);
    final theme = Theme.of(context);

    if (!auth.isSignedIn) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 32, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              'Sign in with Google to see your calendars',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ref.read(googleAuthProvider.notifier).signIn(),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Sign in with Google', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (calendars.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8, width: 8, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(height: 8),
            Text('Loading calendars...', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      );
    }

    // Separate primary/owned calendars from subscribed/other
    final myCalendars = <CalendarMeta>[];
    final otherCalendars = <CalendarMeta>[];
    for (final cal in calendars.values) {
      if (cal.primary) {
        myCalendars.insert(0, cal); // Primary first
      } else {
        otherCalendars.add(cal);
      }
    }

    // If enabledIds is empty, all are considered enabled
    final allEnabled = enabledIds.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.calendar_month, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('My Calendars', style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.primary,
              )),
              const Spacer(),
              // Subscribe button
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                tooltip: 'Subscribe to calendar',
                onPressed: () => _showSubscribeDialog(context, ref),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        // My calendars
        ...myCalendars.map((cal) => _CalendarToggle(
          calendar: cal,
          isEnabled: allEnabled || enabledIds.contains(cal.id),
          onToggle: () => ref.read(enabledCalendarsNotifierProvider.notifier).toggle(cal.id),
        )),
        // Other calendars
        if (otherCalendars.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
            child: Text('Other Calendars', style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            )),
          ),
          ...otherCalendars.map((cal) => _CalendarToggle(
            calendar: cal,
            isEnabled: allEnabled || enabledIds.contains(cal.id),
            onToggle: () => ref.read(enabledCalendarsNotifierProvider.notifier).toggle(cal.id),
          )),
        ],
      ],
    );
  }

  void _showSubscribeDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscribe to Calendar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a calendar ID (email address) or public calendar URL to subscribe.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g. en.np#holiday@group.v.calendar.google.com',
                labelText: 'Calendar ID',
                isDense: true,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final id = controller.text.trim();
              if (id.isEmpty) return;
              Navigator.pop(context);
              await _subscribeToCalendar(context, ref, id);
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribeToCalendar(BuildContext context, WidgetRef ref, String calendarId) async {
    final api = GoogleAuthService.instance.calendarApi;
    if (api == null) return;

    try {
      final entry = await api.calendarList.insert(
        gcal.CalendarListEntry(id: calendarId),
      );
      // Refresh calendar list
      await GoogleCalendarService.instance.fetchCalendarList();
      // Force provider refresh
      ref.invalidate(googleCalendarListProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscribed to ${entry.summary ?? calendarId}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to subscribe: $e')),
        );
      }
    }
  }
}

class _CalendarToggle extends StatelessWidget {
  final CalendarMeta calendar;
  final bool isEnabled;
  final VoidCallback onToggle;

  const _CalendarToggle({
    required this.calendar,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calColor = calendar.color ?? theme.colorScheme.primary;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // Color checkbox
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isEnabled ? calColor : Colors.transparent,
                border: Border.all(color: calColor, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isEnabled
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                calendar.summary,
                style: TextStyle(
                  fontSize: 13,
                  color: isEnabled ? null : theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (calendar.primary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: calColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Primary', style: TextStyle(fontSize: 9, color: calColor)),
              ),
          ],
        ),
      ),
    );
  }
}
