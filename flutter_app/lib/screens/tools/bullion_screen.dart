import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../l10n/app_localizations.dart';
import '../../widgets/home_title.dart';

class BullionScreen extends StatefulWidget {
  const BullionScreen({super.key});

  @override
  State<BullionScreen> createState() => _BullionScreenState();
}

class _BullionScreenState extends State<BullionScreen> {
  List<BullionDay>? _data;
  String? _source;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.nepalipatro.com.np/v3/bullions?timeframe=week'),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final dataMap = json['data'] as Map<String, dynamic>;

        final days = <BullionDay>[];
        dataMap.forEach((date, values) {
          days.add(BullionDay.fromJson(date, values as Map<String, dynamic>));
        });

        // Sort by date descending
        days.sort((a, b) => b.date.compareTo(a.date));

        setState(() {
          _source = json['source'] as String?;
          _data = days;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(child: Text(l10n.goldSilver)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_data == null || _data!.isEmpty) {
      return Center(child: Text(l10n.noData));
    }

    final today = _data!.first;
    final yesterday = _data!.length > 1 ? _data![1] : null;

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source info
            if (_source != null)
              Text(
                l10n.source(_source!),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            const SizedBox(height: 16),

            // Today's prices
            Text(
              '${l10n.today} (${today.bsDate})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Gold Hallmark card
            _buildPriceCard(
              context,
              icon: Icons.circle,
              iconColor: const Color(0xFFFFD700),
              title: l10n.goldHallmark,
              titleNp: 'सुन (हलमार्क)',
              price: today.goldHallmarkTola,
              previousPrice: yesterday?.goldHallmarkTola,
              unit: l10n.perTola,
            ),
            const SizedBox(height: 12),

            // Gold Tejabi card
            _buildPriceCard(
              context,
              icon: Icons.circle,
              iconColor: const Color(0xFFDAA520),
              title: l10n.goldTejabi,
              titleNp: 'सुन (तेजाबी)',
              price: today.goldTejabiTola,
              previousPrice: yesterday?.goldTejabiTola,
              unit: l10n.perTola,
            ),
            const SizedBox(height: 12),

            // Silver card
            _buildPriceCard(
              context,
              icon: Icons.circle,
              iconColor: const Color(0xFFC0C0C0),
              title: l10n.silver,
              titleNp: 'चाँदी',
              price: today.silverTola,
              previousPrice: yesterday?.silverTola,
              unit: l10n.perTola,
            ),

            const SizedBox(height: 24),

            // Weekly history
            Text(
              l10n.thisWeek,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // History table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(flex: 3, child: Text(l10n.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Expanded(
                          flex: 2,
                          child: Text(
                            l10n.hallmark,
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[700], fontSize: 13),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            l10n.tejabi,
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800], fontSize: 13),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            l10n.silver,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    // Data rows
                    ..._data!.map((day) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  day.bsDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: day == today ? Theme.of(context).colorScheme.primary : null,
                                    fontWeight: day == today ? FontWeight.w600 : null,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatPrice(day.goldHallmarkTola),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatPrice(day.goldTejabiTola),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatPrice(day.silverTola),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String titleNp,
    required double price,
    double? previousPrice,
    required String unit,
  }) {
    final change = previousPrice != null ? price - previousPrice : 0.0;
    final changePercent = previousPrice != null && previousPrice > 0
        ? (change / previousPrice) * 100
        : 0.0;
    final isUp = change > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    titleNp,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Price and change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs ${_formatPrice(price)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                if (change != 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: isUp ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      Text(
                        '${change.abs().toStringAsFixed(0)} (${changePercent.abs().toStringAsFixed(2)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUp ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return price.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return price.toStringAsFixed(2);
  }
}

class BullionDay {
  final String date;
  final String bsDate;
  // Per tola prices
  final double goldHallmarkTola;
  final double goldTejabiTola;
  final double silverTola;
  // Per 10gm prices
  final double goldHallmark10g;
  final double goldTejabi10g;
  final double silver10g;

  BullionDay({
    required this.date,
    required this.bsDate,
    required this.goldHallmarkTola,
    required this.goldTejabiTola,
    required this.silverTola,
    required this.goldHallmark10g,
    required this.goldTejabi10g,
    required this.silver10g,
  });

  factory BullionDay.fromJson(String date, Map<String, dynamic> json) {
    return BullionDay(
      date: date,
      bsDate: json['bs'] as String? ?? date,
      // t_* = per tola prices
      goldHallmarkTola: (json['t_ha'] as num?)?.toDouble() ?? 0,
      goldTejabiTola: (json['t_te'] as num?)?.toDouble() ?? 0,
      silverTola: (json['t_s'] as num?)?.toDouble() ?? 0,
      // g_* = per 10gm prices
      goldHallmark10g: (json['g_ha'] as num?)?.toDouble() ?? 0,
      goldTejabi10g: (json['g_te'] as num?)?.toDouble() ?? 0,
      silver10g: (json['g_s'] as num?)?.toDouble() ?? 0,
    );
  }
}
