import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/nepali_date_service.dart';
import '../../widgets/home_title.dart';

/// Screen for converting between BS and AD dates
class DateConverterScreen extends StatefulWidget {
  const DateConverterScreen({super.key});

  @override
  State<DateConverterScreen> createState() => _DateConverterScreenState();
}

class _DateConverterScreenState extends State<DateConverterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // BS to AD state
  int _bsYear = 2081;
  int _bsMonth = 1;
  int _bsDay = 1;
  DateTime? _convertedAd;
  String? _bsError;

  // AD to BS state
  DateTime _adDate = DateTime.now();
  NepaliDateTime? _convertedBs;
  String? _adError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize with today's date
    final today = NepaliDateService.today();
    _bsYear = today.year;
    _bsMonth = today.month;
    _bsDay = today.day;
    _convertBsToAd();
    _convertAdToBs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _convertBsToAd() {
    setState(() {
      _bsError = null;
      _convertedAd = null;

      if (!NepaliDateService.isValidBsDate(_bsYear, _bsMonth, _bsDay)) {
        _bsError = 'Invalid BS date';
        return;
      }

      try {
        final bs = NepaliDateService.fromBsDate(_bsYear, _bsMonth, _bsDay);
        _convertedAd = NepaliDateService.bsToAd(bs);
      } catch (e) {
        _bsError = e.toString();
      }
    });
  }

  void _convertAdToBs() {
    setState(() {
      _adError = null;
      _convertedBs = null;

      try {
        _convertedBs = NepaliDateService.adToBs(_adDate);
      } catch (e) {
        _adError = e.toString();
      }
    });
  }

  Future<void> _selectAdDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _adDate,
      firstDate: DateTime(1944),
      lastDate: DateTime(2033),
    );
    if (picked != null) {
      setState(() => _adDate = picked);
      _convertAdToBs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(child: Text(l10n.dateConverter)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.bsToAd),
            Tab(text: l10n.adToBs),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBsToAdTab(),
          _buildAdToBsTab(),
        ],
      ),
    );
  }

  Widget _buildBsToAdTab() {
    final (minYear, maxYear) = NepaliDateService.supportedYearRange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Bikram Sambat → Gregorian',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Text('बिक्रम सम्बत → ग्रेगोरियन'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Year selector
          _buildDropdownRow(
            label: 'Year (वर्ष)',
            value: _bsYear,
            items: List.generate(
              maxYear - minYear + 1,
              (i) => minYear + i,
            ),
            onChanged: (value) {
              setState(() => _bsYear = value!);
              _convertBsToAd();
            },
          ),
          const SizedBox(height: 16),

          // Month selector
          _buildMonthSelector(),
          const SizedBox(height: 16),

          // Day selector
          _buildDropdownRow(
            label: 'Day (दिन)',
            value: _bsDay,
            items: List.generate(
              NepaliDateService.isValidBsDate(_bsYear, _bsMonth, 1)
                  ? NepaliDateService.getDaysInMonth(_bsYear, _bsMonth)
                  : 32,
              (i) => i + 1,
            ),
            onChanged: (value) {
              setState(() => _bsDay = value!);
              _convertBsToAd();
            },
          ),
          const SizedBox(height: 32),

          // Result
          _buildResultCard(
            title: 'Gregorian Date (AD)',
            error: _bsError,
            child: _convertedAd == null
                ? null
                : Column(
                    children: [
                      Text(
                        _formatAdDate(_convertedAd!),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDayName(_convertedAd!),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdToBsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Gregorian → Bikram Sambat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Text('ग्रेगोरियन → बिक्रम सम्बत'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Date picker
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(_formatAdDate(_adDate)),
              subtitle: Text(_getDayName(_adDate)),
              trailing: const Icon(Icons.edit),
              onTap: _selectAdDate,
            ),
          ),
          const SizedBox(height: 32),

          // Result
          _buildResultCard(
            title: 'Bikram Sambat (BS)',
            error: _adError,
            child: _convertedBs == null
                ? null
                : Column(
                    children: [
                      Text(
                        NepaliDateService.formatEn(_convertedBs!),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NepaliDateService.formatNp(_convertedBs!),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NepaliDateService.getWeekdayNp(_convertedBs!),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: items.contains(value) ? value : items.first,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v.toString()),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      children: [
        const SizedBox(
          width: 120,
          child: Text(
            'Month (महिना)',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _bsMonth,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: List.generate(
              12,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text('${NepaliMonth.names[i]} (${NepaliMonth.namesNp[i]})'),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _bsMonth = value!;
                // Adjust day if it exceeds the month's days
                final maxDay = NepaliDateService.getDaysInMonth(_bsYear, _bsMonth);
                if (_bsDay > maxDay) _bsDay = maxDay;
              });
              _convertBsToAd();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard({
    required String title,
    required String? error,
    required Widget? child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(
                error,
                style: const TextStyle(color: Colors.red),
              )
            else if (child != null)
              child
            else
              const Text('Select a date'),
          ],
        ),
      ),
    );
  }

  String _formatAdDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String _getDayName(DateTime date) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[date.weekday - 1];
  }
}
