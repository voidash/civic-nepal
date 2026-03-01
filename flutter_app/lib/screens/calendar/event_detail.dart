import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar_event.dart';
import '../../models/calendar_view_state.dart';
import '../../providers/calendar_view_provider.dart';
import '../../providers/google_auth_provider.dart';
import '../../services/nepali_date_service.dart';
import '../../l10n/app_localizations.dart';
import 'calendar_list_panel.dart';

/// Side panel showing events for the selected day, or month overview.
class EventDetailPanel extends ConsumerWidget {
  final DateTime? selectedDay;
  const EventDetailPanel({super.key, required this.selectedDay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merger = ref.read(calendarEventMergerProvider);
    final dateSystem = ref.watch(dateSystemNotifierProvider);
    final l10n = AppLocalizations.of(context);
    final focused = ref.watch(focusedDateNotifierProvider);
    // Watch Google sync so events update when signed in
    final syncState = ref.watch(googleCalendarSyncProvider);

    if (selectedDay != null) {
      return _SelectedDayDetail(
        date: selectedDay!,
        dateSystem: dateSystem,
        merger: merger,
        l10n: l10n,
        syncLoading: syncState.isLoading,
      );
    }

    // Show month overview
    return _MonthOverview(
      focused: focused,
      dateSystem: dateSystem,
      merger: merger,
      l10n: l10n,
      syncLoading: syncState.isLoading,
    );
  }
}

class _SelectedDayDetail extends ConsumerWidget {
  final DateTime date;
  final DateSystem dateSystem;
  final dynamic merger; // CalendarEventMerger
  final AppLocalizations l10n;
  final bool syncLoading;

  const _SelectedDayDetail({
    required this.date,
    required this.dateSystem,
    required this.merger,
    required this.l10n,
    required this.syncLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(googleAuthProvider);
    final events = merger.eventsForAdDate(date) as List<CalendarEvent>;
    final bs = NepaliDateService.adToBs(date);

    final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final weekdaysNp = ['आइतबार', 'सोमबार', 'मंगलबार', 'बुधबार', 'बिहीबार', 'शुक्रबार', 'शनिबार'];
    final adWeekday = date.weekday % 7;

    final googleEvents = events.where((e) => e.source == CalendarEventSource.google).toList();
    final holidays = events.where((e) => e.isHoliday).toList();
    final regularEvents = events.where((e) =>
        !e.isHoliday && e.auspiciousType == null && e.source != CalendarEventSource.google).toList();
    final auspiciousEvents = events.where((e) => e.auspiciousType != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateSystem == DateSystem.bs
                    ? '${weekdaysNp[adWeekday]}, ${NepaliDateService.formatShortNp(bs)}'
                    : '${weekdays[adWeekday]}, ${_formatAdShort(date)}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                dateSystem == DateSystem.bs
                    ? _formatAdShort(date)
                    : NepaliDateService.formatShortNp(bs),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Events list — sectioned with Google Calendar first
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Sign in prompt (when not signed in)
              if (!authState.isSignedIn) ...[
                _GoogleSignInCard(authState: authState, ref: ref),
                const Divider(),
              ],
              // Google sync loading (first load — no events yet)
              if (authState.isSignedIn && syncLoading && googleEvents.isEmpty)
                _LoadingIndicator(label: 'Loading Google Calendar...'),
              // Google Calendar events (always first)
              if (googleEvents.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.cloud,
                  title: 'Google Calendar',
                  color: Colors.blue,
                  count: googleEvents.length,
                  syncing: syncLoading,
                ),
                ...googleEvents.map((e) => _EventTile(event: e, isNepali: l10n.isNepali)),
                const SizedBox(height: 8),
              ],
              // Holidays
              if (holidays.isNotEmpty) ...[
                _SectionHeader(icon: Icons.celebration, title: l10n.holiday, color: Colors.red, count: holidays.length),
                ...holidays.map((e) => _EventTile(event: e, isNepali: l10n.isNepali)),
                const SizedBox(height: 8),
              ],
              // Regular events
              if (regularEvents.isNotEmpty) ...[
                _SectionHeader(icon: Icons.event, title: l10n.event, color: Colors.orange, count: regularEvents.length),
                ...regularEvents.map((e) => _EventTile(event: e, isNepali: l10n.isNepali)),
                const SizedBox(height: 8),
              ],
              // Auspicious
              if (auspiciousEvents.isNotEmpty) ...[
                _SectionHeader(icon: Icons.auto_awesome, title: l10n.auspicious, color: Colors.green, count: auspiciousEvents.length),
                ...auspiciousEvents.map((e) => _EventTile(event: e, isNepali: l10n.isNepali)),
              ],
              // No events at all
              if (events.isEmpty && !syncLoading)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_available, size: 40,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text(l10n.noEvents,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            )),
                      ],
                    ),
                  ),
                ),
              // Calendar list (when signed in)
              if (authState.isSignedIn) ...[
                const Divider(),
                const CalendarListPanel(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatAdShort(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _MonthOverview extends ConsumerWidget {
  final DateTime focused;
  final DateSystem dateSystem;
  final dynamic merger; // CalendarEventMerger
  final AppLocalizations l10n;
  final bool syncLoading;

  const _MonthOverview({
    required this.focused,
    required this.dateSystem,
    required this.merger,
    required this.l10n,
    required this.syncLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(googleAuthProvider);
    final bs = NepaliDateService.adToBs(focused);
    final events = merger.eventsForBsMonth(bs.year, bs.month) as List<CalendarEvent>;

    final googleEvents = events.where((e) => e.source == CalendarEventSource.google).toList();
    final holidays = events.where((e) => e.isHoliday).toList();
    final regularEvents = events.where((e) =>
        !e.isHoliday && e.auspiciousType == null && e.source != CalendarEventSource.google).toList();
    final auspiciousEvents = events.where((e) => e.auspiciousType != null).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Today card + go-to-today button
        _TodayCard(dateSystem: dateSystem),
        // "Go to Today" button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(focusedDateNotifierProvider.notifier).goToToday();
              ref.read(selectedDayNotifierProvider.notifier).clear();
            },
            icon: const Icon(Icons.today, size: 16),
            label: const Text('Go to Today', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 32),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const Divider(),

        // Sign in prompt (when not signed in — prominent, before events)
        if (!authState.isSignedIn) ...[
          _GoogleSignInCard(authState: authState, ref: ref),
          const Divider(),
        ],

        // Google sync loading indicator (first load — no events yet)
        if (authState.isSignedIn && syncLoading && googleEvents.isEmpty)
          _LoadingIndicator(label: 'Syncing Google Calendar...'),

        // Google Calendar events (FIRST)
        if (googleEvents.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.cloud,
            title: 'Google Calendar',
            color: Colors.blue,
            count: googleEvents.length,
            syncing: syncLoading,
          ),
          ...googleEvents.map((e) => _EventTile(event: e, isNepali: l10n.isNepali)),
          const SizedBox(height: 8),
        ],

        // Calendar list (right after Google events, when signed in)
        if (authState.isSignedIn) ...[
          const CalendarListPanel(),
          const Divider(),
        ],

        // Holidays
        if (holidays.isNotEmpty) ...[
          _SectionHeader(icon: Icons.celebration, title: l10n.holiday, color: Colors.red, count: holidays.length),
          ...holidays.map((e) => _EventTile(event: e, isNepali: l10n.isNepali)),
          const SizedBox(height: 8),
        ],
        // Events
        if (regularEvents.isNotEmpty) ...[
          _SectionHeader(icon: Icons.event, title: l10n.event, color: Colors.orange, count: regularEvents.length),
          ...regularEvents.map((e) => _EventTile(event: e, isNepali: l10n.isNepali)),
          const SizedBox(height: 8),
        ],
        // Auspicious
        if (auspiciousEvents.isNotEmpty) ...[
          _SectionHeader(icon: Icons.auto_awesome, title: l10n.auspicious, color: Colors.green, count: auspiciousEvents.length),
          ...auspiciousEvents.map((e) => _EventTile(event: e, isNepali: l10n.isNepali)),
        ],
        if (events.isEmpty && !syncLoading)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text(l10n.noEvents,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      )),
                ],
              ),
            ),
          ),
        // Account info (small, at bottom when signed in)
        if (authState.isSignedIn) ...[
          const Divider(),
          _GoogleAccountCard(authState: authState, ref: ref),
        ],
      ],
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────

/// Prominent Google Sign-In card shown at top of sidebar when not signed in.
class _GoogleSignInCard extends StatelessWidget {
  final GoogleAuthState authState;
  final WidgetRef ref;

  const _GoogleSignInCard({required this.authState, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_month, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              'Connect Google Calendar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'See your events, create new ones, and get reminders',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: authState.isLoading
                  ? null
                  : () => ref.read(googleAuthProvider.notifier).signIn(),
              icon: authState.isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login, size: 18),
              label: const Text('Sign in with Google'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading indicator for Google Calendar sync.
class _LoadingIndicator extends StatelessWidget {
  final String label;
  const _LoadingIndicator({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _GoogleAccountCard extends StatelessWidget {
  final GoogleAuthState authState;
  final WidgetRef ref;

  const _GoogleAccountCard({required this.authState, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!authState.isSignedIn) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_done, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Google Calendar',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary),
                ),
                Text(
                  authState.email ?? '',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.read(googleAuthProvider.notifier).signOut(),
            child: const Text('Sign out', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final DateSystem dateSystem;
  const _TodayCard({required this.dateSystem});

  static String _toNepaliNumeral(int number) {
    const nepaliDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number.toString().split('').map((d) => nepaliDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = NepaliDateService.today();
    final todayAd = NepaliDateService.bsToAd(today);

    final weekdaysNp = ['आइतबार', 'सोमबार', 'मंगलबार', 'बुधबार', 'बिहीबार', 'शुक्रबार', 'शनिबार'];
    final adWeekday = todayAd.weekday % 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Large day number
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _toNepaliNumeral(today.day),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekdaysNp[adWeekday],
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  NepaliDateService.formatNp(today),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  _formatAdFull(todayAd),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAdFull(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final int count;
  final bool syncing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    required this.count,
    this.syncing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(
            fontWeight: FontWeight.w600, fontSize: 12, color: color,
          )),
          if (syncing) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text('Syncing...', style: TextStyle(
              fontSize: 10, color: color.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            )),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(count.toString(), style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color,
            )),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final CalendarEvent event;
  final bool isNepali;

  const _EventTile({required this.event, required this.isNepali});

  static String _toNepaliNumeral(int number) {
    const nepaliDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number.toString().split('').map((d) => nepaliDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    IconData trailingIcon;

    if (event.isHoliday) {
      indicatorColor = Colors.red;
      trailingIcon = Icons.celebration;
    } else if (event.auspiciousType != null) {
      indicatorColor = Colors.green;
      trailingIcon = Icons.auto_awesome;
    } else if (event.source == CalendarEventSource.google) {
      indicatorColor = event.color ?? Colors.blue;
      trailingIcon = Icons.cloud;
    } else {
      indicatorColor = Colors.orange;
      trailingIcon = Icons.event;
    }

    final bs = NepaliDateService.adToBs(event.startTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: indicatorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                _toNepaliNumeral(bs.day),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: indicatorColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.localizedTitle(isNepali),
              style: TextStyle(
                fontSize: 13,
                color: event.isHoliday ? Colors.red : null,
                fontWeight: event.isHoliday ? FontWeight.w500 : null,
              ),
            ),
          ),
          Icon(trailingIcon, size: 14, color: indicatorColor.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
