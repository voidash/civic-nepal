import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import '../../models/calendar_event.dart';
import '../../providers/calendar_view_provider.dart';
import '../../services/google_auth_service.dart';
import '../../services/google_calendar_service.dart';
import '../../services/notification_service.dart';

/// Dialog for creating/editing Google Calendar events.
/// Supports title, date/time, location, description, video call, and invites.
class EventEditorDialog extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const EventEditorDialog({
    super.key,
    this.initialDate,
    this.initialTime,
  });

  /// Show as a dialog and return true if an event was created.
  static Future<bool?> show(BuildContext context, {DateTime? initialDate, TimeOfDay? initialTime}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EventEditorDialog(
        initialDate: initialDate,
        initialTime: initialTime,
      ),
    );
  }

  @override
  ConsumerState<EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends ConsumerState<EventEditorDialog> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _inviteController = TextEditingController();

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  bool _isAllDay = false;
  bool _addVideoCall = false;
  String? _selectedCalendarId;
  final List<String> _invitees = [];
  bool _isSaving = false;
  final List<int> _reminders = [30, 10]; // Default: 30 min + 10 min before

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate ?? DateTime.now();
    _startTime = widget.initialTime ?? TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
    _startTime = TimeOfDay(hour: _startTime.hour, minute: 0); // Round to hour
    _endDate = _startDate;
    _endTime = TimeOfDay(hour: (_startTime.hour + 1) % 24, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calendars = ref.watch(googleCalendarListProvider);
    final theme = Theme.of(context);

    // Auto-select primary calendar if none selected
    if (_selectedCalendarId == null && calendars.isNotEmpty) {
      _selectedCalendarId = calendars.values
          .where((c) => c.primary)
          .map((c) => c.id)
          .firstOrNull ?? calendars.keys.first;
    }

    return Dialog(
      child: SizedBox(
        width: 500,
        height: 650,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_note, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text('New Event', style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event title',
                        prefixIcon: Icon(Icons.title),
                        isDense: true,
                      ),
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Calendar selector
                    if (calendars.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCalendarId,
                        decoration: const InputDecoration(
                          labelText: 'Calendar',
                          prefixIcon: Icon(Icons.calendar_month),
                          isDense: true,
                        ),
                        items: calendars.entries.map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Row(
                            children: [
                              Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(
                                  color: e.value.color ?? theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(child: Text(e.value.summary, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedCalendarId = v),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // All-day toggle
                    SwitchListTile(
                      value: _isAllDay,
                      onChanged: (v) => setState(() => _isAllDay = v),
                      title: const Text('All-day event', style: TextStyle(fontSize: 14)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Date/time pickers
                    _DateTimePicker(
                      label: 'Start',
                      date: _startDate,
                      time: _isAllDay ? null : _startTime,
                      onDateChanged: (d) => setState(() {
                        _startDate = d;
                        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
                      }),
                      onTimeChanged: _isAllDay ? null : (t) => setState(() => _startTime = t),
                    ),
                    const SizedBox(height: 8),
                    _DateTimePicker(
                      label: 'End',
                      date: _endDate,
                      time: _isAllDay ? null : _endTime,
                      onDateChanged: (d) => setState(() => _endDate = d),
                      onTimeChanged: _isAllDay ? null : (t) => setState(() => _endTime = t),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Video call toggle
                    SwitchListTile(
                      value: _addVideoCall,
                      onChanged: (v) => setState(() => _addVideoCall = v),
                      title: const Text('Add Google Meet video call', style: TextStyle(fontSize: 14)),
                      secondary: Icon(Icons.videocam, color: _addVideoCall ? Colors.green : null),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),

                    // Reminders (multiple)
                    Row(
                      children: [
                        Icon(Icons.notifications_active, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text('Reminders', style: theme.textTheme.labelMedium),
                        const Spacer(),
                        PopupMenuButton<int>(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          tooltip: 'Add reminder',
                          onSelected: (minutes) {
                            if (!_reminders.contains(minutes)) {
                              setState(() {
                                _reminders.add(minutes);
                                _reminders.sort((a, b) => b.compareTo(a));
                              });
                            }
                          },
                          itemBuilder: (context) => [
                            for (final m in [5, 10, 15, 30, 60, 120])
                              if (!_reminders.contains(m))
                                PopupMenuItem(value: m, child: Text(_reminderLabel(m))),
                          ],
                        ),
                      ],
                    ),
                    if (_reminders.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _reminders.map((m) => Chip(
                            avatar: const Icon(Icons.alarm, size: 14),
                            label: Text(_reminderLabel(m), style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _reminders.remove(m)),
                            visualDensity: VisualDensity.compact,
                          )).toList(),
                        ),
                      ),
                    if (_reminders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 4),
                        child: Text('No reminders', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    const SizedBox(height: 16),

                    // Invitees
                    Text('Invitees', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inviteController,
                            decoration: const InputDecoration(
                              hintText: 'Email address',
                              prefixIcon: Icon(Icons.person_add),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onSubmitted: (_) => _addInvitee(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addInvitee,
                          tooltip: 'Add invitee',
                        ),
                      ],
                    ),
                    if (_invitees.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _invitees.map((email) => Chip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: Text(email, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _invitees.remove(email)),
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Description
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.notes),
                        isDense: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _createEvent,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _reminderLabel(int minutes) {
    if (minutes < 60) return '$minutes minutes before';
    final hours = minutes ~/ 60;
    return '$hours hour${hours > 1 ? 's' : ''} before';
  }

  void _addInvitee() {
    final email = _inviteController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    if (_invitees.contains(email)) return;
    setState(() {
      _invitees.add(email);
      _inviteController.clear();
    });
  }

  Future<void> _createEvent() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event title')),
      );
      return;
    }

    final api = GoogleAuthService.instance.calendarApi;
    if (api == null) return;

    final calendarId = _selectedCalendarId ?? 'primary';

    setState(() => _isSaving = true);

    try {
      final startDt = _isAllDay
          ? DateTime(_startDate.year, _startDate.month, _startDate.day)
          : DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
      final endDt = _isAllDay
          ? DateTime(_endDate.year, _endDate.month, _endDate.day).add(const Duration(days: 1))
          : DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);

      final event = gcal.Event(
        summary: title,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        start: _isAllDay
            ? gcal.EventDateTime(date: startDt)
            : gcal.EventDateTime(dateTime: startDt),
        end: _isAllDay
            ? gcal.EventDateTime(date: endDt)
            : gcal.EventDateTime(dateTime: endDt),
        attendees: _invitees.isEmpty ? null : _invitees.map((e) => gcal.EventAttendee(email: e)).toList(),
      );

      // Set reminders on the Google Calendar event
      if (_reminders.isNotEmpty) {
        event.reminders = gcal.EventReminders(
          useDefault: false,
          overrides: _reminders
              .map((m) => gcal.EventReminder(method: 'popup', minutes: m))
              .toList(),
        );
      } else {
        event.reminders = gcal.EventReminders(useDefault: false, overrides: []);
      }

      // Add Google Meet conference if requested
      final conferenceDataVersion = _addVideoCall ? 1 : 0;

      if (_addVideoCall) {
        event.conferenceData = gcal.ConferenceData(
          createRequest: gcal.CreateConferenceRequest(
            requestId: '${DateTime.now().millisecondsSinceEpoch}',
            conferenceSolutionKey: gcal.ConferenceSolutionKey(type: 'hangoutsMeet'),
          ),
        );
      }

      final created = await api.events.insert(
        event,
        calendarId,
        conferenceDataVersion: conferenceDataVersion,
        sendUpdates: _invitees.isNotEmpty ? 'all' : 'none',
      );

      // Instant sync — inject into merger cache immediately so it appears without delay
      final calendars = GoogleCalendarService.instance.calendars;
      final calMeta = calendars[calendarId];
      final calEvent = CalendarEvent(
        id: created.id ?? 'google_${DateTime.now().millisecondsSinceEpoch}',
        title: created.summary ?? title,
        startTime: startDt,
        endTime: _isAllDay ? null : endDt,
        isAllDay: _isAllDay,
        source: CalendarEventSource.google,
        calendarId: calendarId,
        color: calMeta?.color,
        location: created.location,
        description: created.description,
      );
      ref.read(calendarEventMergerProvider).addSingleGoogleEvent(calEvent);

      // Schedule local notifications for reminders (works while app is running)
      if (!_isAllDay && !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
        for (final minutes in _reminders) {
          NotificationService.scheduleEventReminder(
            eventId: calEvent.id,
            title: title,
            eventStart: startDt,
            minutesBefore: minutes,
            location: calEvent.location,
          );
        }
      }

      // Clear draft event
      ref.read(draftEventProvider.notifier).state = null;

      // Also invalidate for full consistency (background re-fetch)
      ref.invalidate(googleCalendarSyncProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event "$title" created')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: $e')),
        );
      }
    }
  }
}

/// Compact date+time picker row.
class _DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime date;
  final TimeOfDay? time;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay>? onTimeChanged;

  const _DateTimePicker({
    required this.label,
    required this.date,
    required this.onDateChanged,
    this.time,
    this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        ),
        // Date chip
        ActionChip(
          avatar: const Icon(Icons.calendar_today, size: 14),
          label: Text('${months[date.month - 1]} ${date.day}, ${date.year}', style: const TextStyle(fontSize: 13)),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onDateChanged(picked);
          },
          visualDensity: VisualDensity.compact,
        ),
        if (time != null && onTimeChanged != null) ...[
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.access_time, size: 14),
            label: Text(time!.format(context), style: const TextStyle(fontSize: 13)),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time!,
              );
              if (picked != null) onTimeChanged!(picked);
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }
}
