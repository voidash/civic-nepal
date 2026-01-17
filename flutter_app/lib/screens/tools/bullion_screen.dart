import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gold & Silver'),
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
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_data == null || _data!.isEmpty) {
      return const Center(child: Text('No data available'));
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
                'Source: $_source',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            const SizedBox(height: 16),

            // Today's prices
            Text(
              'Today (${today.bsDate})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Gold card
            _buildPriceCard(
              context,
              icon: Icons.circle,
              iconColor: const Color(0xFFFFD700),
              title: 'Gold (Hallmark)',
              titleNp: 'सुन (हलमार्क)',
              price: today.goldHallmark,
              previousPrice: yesterday?.goldHallmark,
              unit: 'per tola',
            ),
            const SizedBox(height: 12),

            // Silver card
            _buildPriceCard(
              context,
              icon: Icons.circle,
              iconColor: const Color(0xFFC0C0C0),
              title: 'Silver',
              titleNp: 'चाँदी',
              price: today.silver,
              previousPrice: yesterday?.silver,
              unit: 'per tola',
            ),

            const SizedBox(height: 24),

            // Weekly history
            Text(
              'This Week',
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
                        const Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: Text(
                            'Gold',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[700]),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Silver',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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
                                flex: 2,
                                child: Text(
                                  day.bsDate,
                                  style: TextStyle(
                                    color: day == today ? Theme.of(context).colorScheme.primary : null,
                                    fontWeight: day == today ? FontWeight.w600 : null,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _formatPrice(day.goldHallmark),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _formatPrice(day.silver),
                                  textAlign: TextAlign.right,
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
  final double goldHallmark;
  final double goldTejabi;
  final double silver;

  BullionDay({
    required this.date,
    required this.bsDate,
    required this.goldHallmark,
    required this.goldTejabi,
    required this.silver,
  });

  factory BullionDay.fromJson(String date, Map<String, dynamic> json) {
    return BullionDay(
      date: date,
      bsDate: json['bs'] as String? ?? date,
      goldHallmark: (json['g_ha'] as num?)?.toDouble() ?? 0,
      goldTejabi: (json['g_te'] as num?)?.toDouble() ?? 0,
      silver: (json['t_ha'] as num?)?.toDouble() ?? 0, // t_ha appears to be silver
    );
  }
}
