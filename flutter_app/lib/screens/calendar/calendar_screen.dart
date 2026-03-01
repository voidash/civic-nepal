import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar_view_state.dart';
import '../../providers/calendar_view_provider.dart';
import '../../providers/google_auth_provider.dart';
import '../../services/nepali_date_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/home_title.dart';
import 'month_view.dart';
import 'week_view.dart';
import 'day_view.dart';
import 'year_view.dart';
import 'event_detail.dart';
import 'event_editor.dart';

/// Main calendar screen with view mode switching, AD/BS toggle, and navigation.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure calendar data is loaded
    Future.microtask(() {
      ref.read(calendarDataLoaderProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(calendarViewModeNotifierProvider);
    final dateSystem = ref.watch(dateSystemNotifierProvider);
    final focused = ref.watch(focusedDateNotifierProvider);
    final selectedDay = ref.watch(selectedDayNotifierProvider);
    final l10n = AppLocalizations.of(context);
    final isWide = MediaQuery.of(context).size.width > 700;

    final authState = ref.watch(googleAuthProvider);
    final syncState = ref.watch(googleCalendarSyncProvider);
    final isSyncing = authState.isSignedIn && syncState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(child: Text(_buildHeaderTitle(viewMode, dateSystem, focused))),
        actions: [
          // View mode segmented button (compact on mobile)
          _ViewModeSelector(currentMode: viewMode),
          const SizedBox(width: 4),
          // AD/BS toggle
          _DateSystemToggle(dateSystem: dateSystem),
          const SizedBox(width: 4),
          // Today button
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: l10n.today,
            onPressed: () {
              ref.read(focusedDateNotifierProvider.notifier).goToToday();
              ref.read(selectedDayNotifierProvider.notifier).clear();
            },
          ),
          // Navigation arrows
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateBack(viewMode, dateSystem),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateForward(viewMode, dateSystem),
          ),
          // Sync indicator
          if (isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          // Google account
          _GoogleAccountButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: isWide
          ? _buildWideLayout(viewMode, selectedDay)
          : _buildNarrowLayout(viewMode, selectedDay),
      floatingActionButton: authState.isSignedIn
          ? FloatingActionButton(
              onPressed: () => EventEditorDialog.show(
                context,
                initialDate: selectedDay ?? focused,
              ),
              tooltip: 'Create event',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildWideLayout(CalendarViewMode viewMode, DateTime? selectedDay) {
    // In day view, always show the focused date's events in sidebar
    final sidebarDay = viewMode == CalendarViewMode.day
        ? ref.watch(focusedDateNotifierProvider)
        : selectedDay;

    return Row(
      children: [
        // Calendar view (left)
        Expanded(child: _buildCalendarView(viewMode)),
        // Event sidebar (right) — for month and day views
        if (viewMode == CalendarViewMode.month || viewMode == CalendarViewMode.day)
          Container(
            width: 320,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: EventDetailPanel(selectedDay: sidebarDay),
          ),
      ],
    );
  }

  Widget _buildNarrowLayout(CalendarViewMode viewMode, DateTime? selectedDay) {
    if (viewMode == CalendarViewMode.year) {
      return _buildCalendarView(viewMode);
    }

    return Column(
      children: [
        Expanded(child: _buildCalendarView(viewMode)),
        if (selectedDay != null && viewMode == CalendarViewMode.month) ...[
          const Divider(height: 1),
          SizedBox(
            height: 200,
            child: EventDetailPanel(selectedDay: selectedDay),
          ),
        ],
      ],
    );
  }

  Widget _buildCalendarView(CalendarViewMode viewMode) {
    switch (viewMode) {
      case CalendarViewMode.month:
        return const MonthView();
      case CalendarViewMode.week:
        return const WeekView();
      case CalendarViewMode.day:
        return const DayView();
      case CalendarViewMode.year:
        return const YearView();
    }
  }

  String _buildHeaderTitle(CalendarViewMode viewMode, DateSystem dateSystem, DateTime focused) {
    final bs = NepaliDateService.adToBs(focused);

    switch (viewMode) {
      case CalendarViewMode.month:
        if (dateSystem == DateSystem.bs) {
          return '${NepaliDateService.getMonthNameNp(bs.month)} ${_toNepaliNumeral(bs.year)}';
        } else {
          const months = ['January', 'February', 'March', 'April', 'May', 'June',
                         'July', 'August', 'September', 'October', 'November', 'December'];
          return '${months[focused.month - 1]} ${focused.year}';
        }
      case CalendarViewMode.week:
        final weekday = focused.weekday % 7;
        final weekStart = focused.subtract(Duration(days: weekday));
        final weekEnd = weekStart.add(const Duration(days: 6));
        if (dateSystem == DateSystem.bs) {
          final bsStart = NepaliDateService.adToBs(weekStart);
          final bsEnd = NepaliDateService.adToBs(weekEnd);
          return '${NepaliDateService.getMonthNameNp(bsStart.month)} '
              '${_toNepaliNumeral(bsStart.day)}–${_toNepaliNumeral(bsEnd.day)}, '
              '${_toNepaliNumeral(bsStart.year)}';
        } else {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '${months[weekStart.month - 1]} ${weekStart.day}–${weekEnd.day}, ${weekStart.year}';
        }
      case CalendarViewMode.day:
        if (dateSystem == DateSystem.bs) {
          return NepaliDateService.formatShortNp(bs);
        } else {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '${months[focused.month - 1]} ${focused.day}, ${focused.year}';
        }
      case CalendarViewMode.year:
        if (dateSystem == DateSystem.bs) {
          return _toNepaliNumeral(bs.year);
        } else {
          return focused.year.toString();
        }
    }
  }

  void _navigateBack(CalendarViewMode viewMode, DateSystem dateSystem) {
    ref.read(selectedDayNotifierProvider.notifier).clear();
    final notifier = ref.read(focusedDateNotifierProvider.notifier);
    switch (viewMode) {
      case CalendarViewMode.month:
        notifier.navigateMonths(-1, dateSystem: dateSystem);
      case CalendarViewMode.week:
        notifier.navigateWeeks(-1);
      case CalendarViewMode.day:
        notifier.navigateDays(-1);
      case CalendarViewMode.year:
        notifier.navigateYears(-1, dateSystem: dateSystem);
    }
  }

  void _navigateForward(CalendarViewMode viewMode, DateSystem dateSystem) {
    ref.read(selectedDayNotifierProvider.notifier).clear();
    final notifier = ref.read(focusedDateNotifierProvider.notifier);
    switch (viewMode) {
      case CalendarViewMode.month:
        notifier.navigateMonths(1, dateSystem: dateSystem);
      case CalendarViewMode.week:
        notifier.navigateWeeks(1);
      case CalendarViewMode.day:
        notifier.navigateDays(1);
      case CalendarViewMode.year:
        notifier.navigateYears(1, dateSystem: dateSystem);
    }
  }

  static String _toNepaliNumeral(int number) {
    const nepaliDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number.toString().split('').map((d) => nepaliDigits[int.parse(d)]).join();
  }
}

/// View mode segmented button.
class _ViewModeSelector extends ConsumerWidget {
  final CalendarViewMode currentMode;
  const _ViewModeSelector({required this.currentMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<CalendarViewMode>(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8)),
      ),
      segments: const [
        ButtonSegment(value: CalendarViewMode.day, label: Text('D', style: TextStyle(fontSize: 12))),
        ButtonSegment(value: CalendarViewMode.week, label: Text('W', style: TextStyle(fontSize: 12))),
        ButtonSegment(value: CalendarViewMode.month, label: Text('M', style: TextStyle(fontSize: 12))),
        ButtonSegment(value: CalendarViewMode.year, label: Text('Y', style: TextStyle(fontSize: 12))),
      ],
      selected: {currentMode},
      onSelectionChanged: (selected) {
        ref.read(calendarViewModeNotifierProvider.notifier).setMode(selected.first);
      },
    );
  }
}

/// AD/BS toggle chip.
class _DateSystemToggle extends ConsumerWidget {
  final DateSystem dateSystem;
  const _DateSystemToggle({required this.dateSystem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      avatar: Icon(
        Icons.swap_horiz,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        dateSystem == DateSystem.bs ? 'BS' : 'AD',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      onPressed: () {
        ref.read(dateSystemNotifierProvider.notifier).toggle();
      },
    );
  }
}

/// Google account button in AppBar — shows sign-in or account popup.
class _GoogleAccountButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(googleAuthProvider);

    if (authState.isSignedIn) {
      return PopupMenuButton<String>(
        tooltip: 'Google Calendar: ${authState.email}',
        offset: const Offset(0, 40),
        onSelected: (value) {
          if (value == 'signout') {
            ref.read(googleAuthProvider.notifier).signOut();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Google Calendar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(authState.email ?? '', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'signout',
            child: Text('Sign out'),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white,
            child: Text(
              (authState.email ?? 'G')[0].toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    // Not signed in — show sign-in button
    return IconButton(
      icon: authState.isLoading
          ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.account_circle_outlined),
      tooltip: 'Sign in with Google',
      onPressed: authState.isLoading
          ? null
          : () => ref.read(googleAuthProvider.notifier).signIn(),
    );
  }
}
