import 'package:flutter/material.dart';
import '../../services/nepali_date_service.dart';
import '../../services/data_service.dart';

/// Calendar day info with events
class CalendarDayInfo {
  final int day;
  final List<String> events;
  final bool isHoliday;

  CalendarDayInfo({
    required this.day,
    required this.events,
    required this.isHoliday,
  });

  factory CalendarDayInfo.fromJson(Map<String, dynamic> json) {
    return CalendarDayInfo(
      day: json['day'] as int,
      events: (json['events'] as List<dynamic>).cast<String>(),
      isHoliday: json['is_holiday'] as bool? ?? false,
    );
  }
}

/// Auspicious days info
class AuspiciousDaysInfo {
  final List<int> bibahaLagan;
  final List<int> bratabandha;
  final List<int> pasni;

  AuspiciousDaysInfo({
    required this.bibahaLagan,
    required this.bratabandha,
    required this.pasni,
  });

  factory AuspiciousDaysInfo.fromJson(Map<String, dynamic> json) {
    return AuspiciousDaysInfo(
      bibahaLagan: (json['bibaha_lagan'] as List<dynamic>?)?.cast<int>() ?? [],
      bratabandha: (json['bratabandha'] as List<dynamic>?)?.cast<int>() ?? [],
      pasni: (json['pasni'] as List<dynamic>?)?.cast<int>() ?? [],
    );
  }

  bool hasAuspiciousDay(int day) {
    return bibahaLagan.contains(day) ||
        bratabandha.contains(day) ||
        pasni.contains(day);
  }

  List<String> getAuspiciousTypes(int day) {
    final types = <String>[];
    if (bibahaLagan.contains(day)) types.add('विवाह (Wedding)');
    if (bratabandha.contains(day)) types.add('ब्रतबन्ध (Bratabandha)');
    if (pasni.contains(day)) types.add('पास्नी (Rice Feeding)');
    return types;
  }
}

/// Simple Nepali calendar utility screen with events
class NepaliCalendarScreen extends StatefulWidget {
  const NepaliCalendarScreen({super.key});

  @override
  State<NepaliCalendarScreen> createState() => _NepaliCalendarScreenState();
}

class _NepaliCalendarScreenState extends State<NepaliCalendarScreen> {
  late int _currentYear;
  late int _currentMonth;
  late NepaliDateTime _today;
  int? _selectedDay;

  Map<String, dynamic>? _eventsData;
  Map<String, dynamic>? _auspiciousData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _today = NepaliDateService.today();
    _currentYear = _today.year;
    _currentMonth = _today.month;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final events = await DataService.loadCalendarEvents();
      final auspicious = await DataService.loadAuspiciousDays();
      if (mounted) {
        setState(() {
          _eventsData = events;
          _auspiciousData = auspicious;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getMonthKey(int year, int month) => '$year-${month.toString().padLeft(2, '0')}';

  Map<int, CalendarDayInfo> _getEventsForMonth() {
    if (_eventsData == null) return {};
    final key = _getMonthKey(_currentYear, _currentMonth);
    final monthData = _eventsData![key] as Map<String, dynamic>?;
    if (monthData == null) return {};

    final days = monthData['days'] as List<dynamic>?;
    if (days == null) return {};

    final result = <int, CalendarDayInfo>{};
    for (final dayJson in days) {
      final info = CalendarDayInfo.fromJson(dayJson as Map<String, dynamic>);
      result[info.day] = info;
    }
    return result;
  }

  AuspiciousDaysInfo? _getAuspiciousForMonth() {
    if (_auspiciousData == null) return null;
    final key = _getMonthKey(_currentYear, _currentMonth);
    final monthData = _auspiciousData![key] as Map<String, dynamic>?;
    if (monthData == null) return null;
    return AuspiciousDaysInfo.fromJson(monthData);
  }

  void _previousMonth() {
    setState(() {
      _selectedDay = null;
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDay = null;
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    });
  }

  void _goToToday() {
    setState(() {
      _today = NepaliDateService.today();
      _currentYear = _today.year;
      _currentMonth = _today.month;
      _selectedDay = null;
    });
  }

  void _selectDay(int day) {
    setState(() {
      _selectedDay = _selectedDay == day ? null : day;
    });
  }

  /// Get English month range for the current BS month
  String _getEnglishMonthRange() {
    final daysInMonth = NepaliDateService.getDaysInMonth(_currentYear, _currentMonth);
    final firstDayBs = NepaliDateService.fromBsDate(_currentYear, _currentMonth, 1);
    final lastDayBs = NepaliDateService.fromBsDate(_currentYear, _currentMonth, daysInMonth);

    final firstDayAd = NepaliDateService.bsToAd(firstDayBs);
    final lastDayAd = NepaliDateService.bsToAd(lastDayBs);

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final startMonth = months[firstDayAd.month - 1];
    final endMonth = months[lastDayAd.month - 1];

    if (firstDayAd.month == lastDayAd.month && firstDayAd.year == lastDayAd.year) {
      return '$startMonth ${firstDayAd.year}';
    } else if (firstDayAd.year == lastDayAd.year) {
      return '$startMonth - $endMonth ${firstDayAd.year}';
    } else {
      return '$startMonth ${firstDayAd.year} - $endMonth ${lastDayAd.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = NepaliDateService.getDaysInMonth(_currentYear, _currentMonth);
    final firstDayOfMonth = NepaliDateService.fromBsDate(_currentYear, _currentMonth, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Sunday in Nepali calendar
    final eventsForMonth = _getEventsForMonth();
    final auspiciousForMonth = _getAuspiciousForMonth();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nepali Calendar'),
        actions: [
          TextButton.icon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today),
            label: const Text('Today'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month/Year header
                _buildMonthHeader(),
                const Divider(height: 1),
                // Legend
                _buildLegend(),
                const Divider(height: 1),
                // Weekday headers
                _buildWeekdayHeaders(),
                const Divider(height: 1),
                // Calendar grid
                Expanded(
                  child: _buildCalendarGrid(
                    daysInMonth,
                    firstWeekday,
                    eventsForMonth,
                    auspiciousForMonth,
                  ),
                ),
                // Events panel or today info
                if (_selectedDay != null)
                  _buildSelectedDayEvents(eventsForMonth, auspiciousForMonth)
                else
                  _buildTodayInfo(eventsForMonth),
              ],
            ),
    );
  }

  Widget _buildMonthHeader() {
    final monthNameNp = NepaliMonth.namesNp[_currentMonth - 1];
    final monthNameEn = NepaliMonth.names[_currentMonth - 1];
    final englishMonthRange = _getEnglishMonthRange();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
            tooltip: 'Previous month',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$monthNameNp $_currentYear',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  monthNameEn,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  englishMonthRange,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.red, 'Holiday'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.orange, 'Event'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.green, 'Auspicious'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdaysNp = ['आइत', 'सोम', 'मंगल', 'बुध', 'बिही', 'शुक्र', 'शनि'];
    const weekdaysEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(7, (index) {
          final isSaturday = index == 6;
          return Expanded(
            child: Column(
              children: [
                Text(
                  weekdaysNp[index],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isSaturday ? Colors.red : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  weekdaysEn[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: isSaturday ? Colors.red[300] : Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCalendarGrid(
    int daysInMonth,
    int firstWeekday,
    Map<int, CalendarDayInfo> eventsForMonth,
    AuspiciousDaysInfo? auspiciousForMonth,
  ) {
    // firstWeekday: 1 = Sunday, 7 = Saturday
    final startOffset = firstWeekday - 1; // Convert to 0-indexed (0 = Sunday)
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.75, // Make cells taller to fit indicators
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final dayNumber = index - startOffset + 1;

        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final isToday = _currentYear == _today.year &&
            _currentMonth == _today.month &&
            dayNumber == _today.day;
        final isSaturday = index % 7 == 6;
        final isSelected = _selectedDay == dayNumber;

        // Get English date for this BS day
        final bsDate = NepaliDateService.fromBsDate(_currentYear, _currentMonth, dayNumber);
        final adDate = NepaliDateService.bsToAd(bsDate);

        // Get events and auspicious info
        final dayInfo = eventsForMonth[dayNumber];
        final hasEvents = dayInfo != null && dayInfo.events.isNotEmpty;
        final isHoliday = dayInfo?.isHoliday ?? false;
        final isAuspicious = auspiciousForMonth?.hasAuspiciousDay(dayNumber) ?? false;

        return _buildDayCell(
          dayNumber,
          adDate.day,
          isToday,
          isSaturday,
          isSelected,
          hasEvents,
          isHoliday,
          isAuspicious,
        );
      },
    );
  }

  Widget _buildDayCell(
    int bsDay,
    int adDay,
    bool isToday,
    bool isSaturday,
    bool isSelected,
    bool hasEvents,
    bool isHoliday,
    bool isAuspicious,
  ) {
    Color? backgroundColor;
    Color? textColor;
    BoxBorder? border;

    if (isToday) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      textColor = Colors.white;
    } else if (isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      border = Border.all(color: Theme.of(context).colorScheme.primary, width: 2);
    } else if (isHoliday) {
      backgroundColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red;
    } else if (isSaturday) {
      textColor = Colors.red;
    }

    return GestureDetector(
      onTap: () => _selectDay(bsDay),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: border ?? Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BS day (main, larger)
            Text(
              bsDay.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
            // AD day (smaller, below)
            Text(
              adDay.toString(),
              style: TextStyle(
                fontSize: 9,
                color: isToday
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.grey[500],
              ),
            ),
            // Event indicators
            if (hasEvents || isAuspicious) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isHoliday)
                    _buildDot(Colors.red)
                  else if (hasEvents)
                    _buildDot(Colors.orange),
                  if (isAuspicious) ...[
                    if (hasEvents) const SizedBox(width: 2),
                    _buildDot(Colors.green),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSelectedDayEvents(
    Map<int, CalendarDayInfo> eventsForMonth,
    AuspiciousDaysInfo? auspiciousForMonth,
  ) {
    final dayInfo = eventsForMonth[_selectedDay];
    final auspiciousTypes = auspiciousForMonth?.getAuspiciousTypes(_selectedDay!) ?? [];
    final bsDate = NepaliDateService.fromBsDate(_currentYear, _currentMonth, _selectedDay!);
    final adDate = NepaliDateService.bsToAd(bsDate);

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and close
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${NepaliMonth.namesNp[_currentMonth - 1]} $_selectedDay, $_currentYear • ${adDate.day}/${adDate.month}/${adDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _selectedDay = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Events list
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              children: [
                if (dayInfo != null && dayInfo.events.isNotEmpty)
                  ...dayInfo.events.map((event) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              dayInfo.isHoliday ? Icons.celebration : Icons.event,
                              size: 16,
                              color: dayInfo.isHoliday ? Colors.red : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event,
                                style: TextStyle(
                                  color: dayInfo.isHoliday ? Colors.red : null,
                                  fontWeight: dayInfo.isHoliday ? FontWeight.w500 : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                if (auspiciousTypes.isNotEmpty)
                  ...auspiciousTypes.map((type) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                type,
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      )),
                if ((dayInfo == null || dayInfo.events.isEmpty) && auspiciousTypes.isEmpty)
                  Text(
                    'No events',
                    style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayInfo(Map<int, CalendarDayInfo> eventsForMonth) {
    final adDate = NepaliDateService.bsToAd(_today);
    final todayEvents = _currentYear == _today.year && _currentMonth == _today.month
        ? eventsForMonth[_today.day]
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _today.day.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Today: ${NepaliDateService.formatNp(_today)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${NepaliDateService.getWeekdayNp(_today)} (${NepaliDateService.getWeekdayEn(_today)})',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'AD: ${adDate.day}/${adDate.month}/${adDate.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (todayEvents != null && todayEvents.events.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    todayEvents.events.join(' • '),
                    style: TextStyle(
                      fontSize: 12,
                      color: todayEvents.isHoliday ? Colors.red : Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
