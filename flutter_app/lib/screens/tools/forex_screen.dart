import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../l10n/app_localizations.dart';
import '../../widgets/home_title.dart';

class ForexScreen extends StatefulWidget {
  const ForexScreen({super.key});

  @override
  State<ForexScreen> createState() => _ForexScreenState();
}

class _ForexScreenState extends State<ForexScreen> {
  List<ForexRate>? _rates;
  String? _date;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.nepalipatro.com.np/forex?web=true'),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>;
        setState(() {
          _date = json['date'] as String?;
          _rates = data.map((e) => ForexRate.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load rates';
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
        title: HomeTitle(child: Text(l10n.forexRates)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRates,
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
              onPressed: _fetchRates,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_rates == null || _rates!.isEmpty) {
      return Center(child: Text(l10n.noData));
    }

    return Column(
      children: [
        // Header with date
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            children: [
              Text(
                l10n.nrbRates,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_date != null)
                Text(
                  _date!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
            ],
          ),
        ),
        // Column headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(flex: 2, child: Text(l10n.currency, style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text(l10n.buy, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              Expanded(child: Text(l10n.sell, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            ],
          ),
        ),
        // Rates list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchRates,
            child: ListView.separated(
              itemCount: _rates!.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final rate = _rates![index];
                return _buildRateRow(rate);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRateRow(ForexRate rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Flag/Code
          Container(
            width: 40,
            height: 28,
            decoration: BoxDecoration(
              color: _getCurrencyColor(rate.code),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                rate.code,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Currency name
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rate.currency,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (rate.unit != 1)
                  Text(
                    'Per ${rate.unit} units',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          // Buying rate
          Expanded(
            child: Text(
              'Rs ${rate.buying.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          // Selling rate
          Expanded(
            child: Text(
              'Rs ${rate.selling.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCurrencyColor(String code) {
    final colors = {
      'USD': const Color(0xFF2E7D32),
      'EUR': const Color(0xFF1565C0),
      'GBP': const Color(0xFF6A1B9A),
      'INR': const Color(0xFFFF6F00),
      'JPY': const Color(0xFFC62828),
      'CNY': const Color(0xFFD32F2F),
      'AUD': const Color(0xFF00695C),
      'CAD': const Color(0xFFD84315),
      'CHF': const Color(0xFF37474F),
      'SGD': const Color(0xFFAD1457),
    };
    return colors[code] ?? Colors.blueGrey;
  }
}

class ForexRate {
  final String code;
  final String currency;
  final double buying;
  final double selling;
  final int unit;
  final String type;

  ForexRate({
    required this.code,
    required this.currency,
    required this.buying,
    required this.selling,
    required this.unit,
    required this.type,
  });

  factory ForexRate.fromJson(Map<String, dynamic> json) {
    return ForexRate(
      code: json['code'] as String,
      currency: json['currency'] as String,
      buying: (json['buying'] as num).toDouble(),
      selling: (json['selling'] as num).toDouble(),
      unit: json['unit'] as int,
      type: json['type'] as String,
    );
  }
}
