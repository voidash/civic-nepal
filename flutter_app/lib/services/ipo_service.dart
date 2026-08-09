import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ipo.dart';

/// Service for fetching IPO and stock market data
class IpoService {
  static const String _cdscUrl = 'https://cdsc.com.np/ipolist';
  static const String _merolaganiUrl = 'https://merolagani.com/LatestMarket.aspx';
  static const String _shareSansarUrl = 'https://www.sharesansar.com/live-trading';
  static const String _seenIposKey = 'seen_ipo_ids';
  static const String _cachedIposKey = 'cached_ipos';
  static const String _cachedStocksKey = 'cached_stocks';
  static const String _lastFetchTimeKey = 'last_ipo_fetch_time';
  static const String _notifiedEventsKey = 'notified_ipo_events';

  /// Notification event types
  static const String eventNew = 'new';
  static const String eventOpening = 'opening';
  static const String eventClosing = 'closing';

  /// Market snapshot scraped server-side every ~10 minutes by the
  /// `update-live-data` workflow. raw.githubusercontent serves it with
  /// `access-control-allow-origin: *`, so unlike the sources themselves it is
  /// readable from a browser.
  static const String _publishedMarketUrl =
      'https://raw.githubusercontent.com/voidash/civic-nepal/data/market.json';

  /// CORS proxies, kept only as a native-side fallback.
  ///
  /// These are third-party services that go down without warning, and both had:
  /// api.allorigins.win returns 520 and corsproxy.io returns 403, which is what
  /// left the IPO and shares screen blank on the web.
  static const List<String> _corsProxies = [
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?',
  ];

  /// Current proxy index for rotation on failure
  static int _currentProxyIndex = 0;

  /// Get URL with CORS proxy for web platform
  static String _getProxiedUrl(String url, {int? proxyIndex}) {
    if (kIsWeb) {
      final index = proxyIndex ?? _currentProxyIndex;
      final proxy = _corsProxies[index % _corsProxies.length];
      return '$proxy${Uri.encodeComponent(url)}';
    }
    return url;
  }

  /// Try fetching with fallback proxies
  static Future<http.Response?> _fetchWithProxyFallback(String url) async {
    if (!kIsWeb) {
      return await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml',
        },
      ).timeout(const Duration(seconds: 30));
    }

    // Try each proxy until one works
    for (int i = 0; i < _corsProxies.length; i++) {
      try {
        final proxyIndex = (_currentProxyIndex + i) % _corsProxies.length;
        final proxiedUrl = _getProxiedUrl(url, proxyIndex: proxyIndex);
        final response = await http.get(
          Uri.parse(proxiedUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
            'Accept': 'text/html,application/xhtml+xml',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          // Remember this proxy worked
          _currentProxyIndex = proxyIndex;
          return response;
        }
      } catch (e) {
        // Try next proxy
        continue;
      }
    }
    return null;
  }

  /// Fetch IPO list from CDSC
  static Future<List<Ipo>> fetchIpoList() async {
    // Prefer the feed scraped server-side by the `update-live-data` workflow.
    // CDSC populates its table with JavaScript, so parsing the HTML in the app
    // finds an empty tbody even when the request succeeds — and on the web the
    // request cannot succeed at all without a CORS proxy.
    final published = await _fetchPublishedMarket();
    if (published != null) {
      final ipos = (published['ipos'] as List? ?? [])
          .map((e) => _ipoFromPublished(e as Map<String, dynamic>))
          .whereType<Ipo>()
          .toList();
      await _cacheIpos(ipos);
      return ipos;
    }

    // Native can still scrape directly if the feed is unreachable.
    if (!kIsWeb) {
      try {
        final response = await _fetchWithProxyFallback(_cdscUrl);
        if (response != null && response.statusCode == 200) {
          final ipos = _parseIpoHtml(response.body);
          if (ipos.isNotEmpty) {
            await _cacheIpos(ipos);
            return ipos;
          }
        }
      } catch (_) {
        // Fall through to the cache.
      }
    }
    return getCachedIpos();
  }

  /// Published market snapshot, or null when it cannot be reached.
  ///
  /// Cached for the lifetime of the call chain so fetching IPOs and stock
  /// prices back to back does not download the same document twice.
  static Future<Map<String, dynamic>?> _fetchPublishedMarket() async {
    final cached = _marketSnapshot;
    if (cached != null &&
        DateTime.now().difference(_marketFetchedAt!) < const Duration(minutes: 2)) {
      return cached;
    }
    try {
      final response = await http
          .get(Uri.parse(_publishedMarketUrl))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      final decoded =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      _marketSnapshot = decoded;
      _marketFetchedAt = DateTime.now();
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _marketSnapshot;
  static DateTime? _marketFetchedAt;

  static Ipo? _ipoFromPublished(Map<String, dynamic> json) {
    DateTime parseDate(String? value) =>
        DateTime.tryParse(value ?? '') ?? DateTime.now();
    try {
      return Ipo(
        companyName: json['companyName'] as String? ?? '',
        symbol: json['symbol'] as String? ?? '',
        issueType: json['issueType'] as String? ?? '',
        issueManager: json['issueManager'] as String? ?? '',
        issuedUnits: (json['issuedUnits'] as num?)?.toInt() ?? 0,
        numberOfApplications: (json['numberOfApplications'] as num?)?.toInt() ?? 0,
        appliedUnits: (json['appliedUnits'] as num?)?.toInt() ?? 0,
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        openDate: parseDate(json['openDate'] as String?),
        closeDate: parseDate(json['closeDate'] as String?),
        lastUpdate: parseDate(json['lastUpdate'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  static StockPrice? _stockFromPublished(Map<String, dynamic> json) {
    double asDouble(Object? v) => (v as num?)?.toDouble() ?? 0;
    final symbol = json['symbol'] as String?;
    if (symbol == null || symbol.isEmpty) return null;
    return StockPrice(
      symbol: symbol,
      companyName: json['companyName'] as String? ?? symbol,
      ltp: asDouble(json['ltp']),
      change: asDouble(json['change']),
      changePercent: asDouble(json['changePercent']),
      open: asDouble(json['open']),
      high: asDouble(json['high']),
      low: asDouble(json['low']),
      volume: (json['volume'] as num?)?.toInt() ?? 0,
      previousClose: asDouble(json['previousClose']),
    );
  }

  /// Parse IPO data from CDSC HTML
  static List<Ipo> _parseIpoHtml(String html) {
    final document = html_parser.parse(html);
    final ipos = <Ipo>[];

    // Find the IPO table - it has headers: S.N, Company Name, Issue Manager, etc.
    final tables = document.querySelectorAll('table');

    for (final table in tables) {
      final rows = table.querySelectorAll('tbody tr');

      for (final row in rows) {
        final cells = row.querySelectorAll('td');
        // Need at least 10 cells (indices 0-9)
        if (cells.length >= 10) {
          try {
            // Extract company name and symbol from second cell (index 1)
            // Columns: S.N(0), Company(1), IssueManager(2), IssuedUnit(3),
            //          Applications(4), AppliedUnit(5), Amount(6), Open(7), Close(8), LastUpdate(9)
            final companyCell = cells[1].text.trim();
            final companyParts = _parseCompanyName(companyCell);

            final ipo = Ipo(
              companyName: companyParts['name'] ?? companyCell,
              symbol: companyParts['symbol'] ?? '',
              issueType: companyParts['type'] ?? 'IPO',
              issueManager: cells[2].text.trim(),
              issuedUnits: _parseNumber(cells[3].text),
              numberOfApplications: _parseNumber(cells[4].text),
              appliedUnits: _parseNumber(cells[5].text),
              amount: _parseNumber(cells[6].text),
              openDate: _parseDate(cells[7].text),
              closeDate: _parseDate(cells[8].text),
              lastUpdate: _parseDateTime(cells[9].text),
            );
            ipos.add(ipo);
          } catch (e) {
            // Skip malformed rows
            continue;
          }
        }
      }
    }

    return ipos;
  }

  /// Parse company name to extract name, symbol, and type
  static Map<String, String> _parseCompanyName(String text) {
    // Format: "Company Name - SYMBOL (IPO - For General Public)"
    final result = <String, String>{};

    // Extract symbol
    final symbolMatch = RegExp(r'-\s*([A-Z]+)\s*\(').firstMatch(text);
    if (symbolMatch != null) {
      result['symbol'] = symbolMatch.group(1) ?? '';
    }

    // Extract type
    final typeMatch = RegExp(r'\(([^)]+)\)').firstMatch(text);
    if (typeMatch != null) {
      result['type'] = typeMatch.group(1) ?? 'IPO';
    }

    // Extract name (everything before the dash)
    final nameMatch = RegExp(r'^(.+?)\s*-').firstMatch(text);
    if (nameMatch != null) {
      result['name'] = nameMatch.group(1)?.trim() ?? text;
    } else {
      result['name'] = text.split('(').first.trim();
    }

    return result;
  }

  /// Parse number from string, handling commas
  static int _parseNumber(String text) {
    final cleaned = text.replaceAll(RegExp(r'[,\s]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  /// Parse date from string (YYYY-MM-DD format)
  static DateTime _parseDate(String text) {
    try {
      final parts = text.trim().split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}
    return DateTime.now();
  }

  /// Parse datetime from string
  static DateTime _parseDateTime(String text) {
    try {
      // Format: "2026-01-17 17:48:04"
      return DateTime.parse(text.trim());
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Fetch stock prices - tries ShareSansar first, then Merolagani
  static Future<List<StockPrice>> fetchStockPrices() async {
    // The published snapshot is the only path that works on the web, and is
    // cheaper than parsing an 800KB page everywhere else.
    final published = await _fetchPublishedMarket();
    if (published != null) {
      final stocks = (published['stocks'] as List? ?? [])
          .map((e) => _stockFromPublished(e as Map<String, dynamic>))
          .whereType<StockPrice>()
          .toList();
      if (stocks.isNotEmpty) {
        await _cacheStocks(stocks);
        return stocks;
      }
      // NEPSE is shut at weekends and overnight; show the last known prices.
      final cached = await getCachedStocks();
      if (cached.isNotEmpty) return cached;
    }

    if (kIsWeb) return getCachedStocks();

    // Try ShareSansar first
    try {
      final stocks = await _fetchFromShareSansar();
      if (stocks.isNotEmpty) {
        await _cacheStocks(stocks);
        return stocks;
      }
    } catch (e) {
      // ShareSansar failed, try Merolagani
    }

    // Fallback to Merolagani
    try {
      final response = await _fetchWithProxyFallback(_merolaganiUrl);

      if (response != null && response.statusCode == 200) {
        final stocks = _parseStockHtml(response.body);
        if (stocks.isNotEmpty) {
          await _cacheStocks(stocks);
          return stocks;
        }
      }
    } catch (e) {
      // Both sources failed
    }

    // Return cached data as last resort
    return await getCachedStocks();
  }

  /// Fetch from ShareSansar
  static Future<List<StockPrice>> _fetchFromShareSansar() async {
    final response = await _fetchWithProxyFallback(_shareSansarUrl);

    if (response != null && response.statusCode == 200) {
      return _parseShareSansarHtml(response.body);
    }
    return [];
  }

  /// Parse ShareSansar HTML
  static List<StockPrice> _parseShareSansarHtml(String html) {
    final document = html_parser.parse(html);
    final stocks = <StockPrice>[];

    // ShareSansar uses table with class 'table'
    final table = document.querySelector('table.table');
    if (table == null) return [];

    final rows = table.querySelectorAll('tbody tr');
    for (final row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.length >= 9) {
        try {
          // ShareSansar columns: Symbol, LTP, Change%, High, Low, Open, Qty, Turnover, Previous Close
          final symbolCell = cells[0];
          final anchor = symbolCell.querySelector('a');
          final symbol = anchor?.text.trim() ?? symbolCell.text.trim();
          final companyName = anchor?.attributes['title'] ?? symbol;

          final ltp = _parseDouble(cells[1].text);
          final changePercent = _parseDouble(cells[2].text.replaceAll('%', ''));
          final high = _parseDouble(cells[3].text);
          final low = _parseDouble(cells[4].text);
          final open = _parseDouble(cells[5].text);
          final volume = _parseNumber(cells[6].text);
          final previousClose = _parseDouble(cells[8].text);

          final change = ltp - previousClose;

          if (symbol.isNotEmpty && ltp > 0) {
            stocks.add(StockPrice(
              symbol: symbol,
              companyName: companyName,
              ltp: ltp,
              change: change,
              changePercent: changePercent,
              open: open,
              high: high,
              low: low,
              volume: volume,
              previousClose: previousClose,
            ));
          }
        } catch (e) {
          continue;
        }
      }
    }

    return stocks;
  }

  /// Parse stock data from Merolagani HTML
  static List<StockPrice> _parseStockHtml(String html) {
    final document = html_parser.parse(html);
    final stocks = <StockPrice>[];

    // Find the live trading table
    final table = document.querySelector('#live-trading');
    if (table == null) {
      // Try alternate selector
      final tables = document.querySelectorAll('table');
      for (final t in tables) {
        if (t.text.contains('Symbol') && t.text.contains('LTP')) {
          _parseTableRows(t, stocks);
          break;
        }
      }
    } else {
      _parseTableRows(table, stocks);
    }

    return stocks;
  }

  static void _parseTableRows(dynamic table, List<StockPrice> stocks) {
    final rows = table.querySelectorAll('tbody tr');

    for (final row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.length >= 8) {
        try {
          final symbol = cells[0].text.trim();
          final ltp = _parseDouble(cells[1].text);
          final changePercent = _parseDouble(cells[2].text.replaceAll('%', ''));
          final open = _parseDouble(cells[3].text);
          final high = _parseDouble(cells[4].text);
          final low = _parseDouble(cells[5].text);
          final volume = _parseNumber(cells[6].text);
          final previousClose = _parseDouble(cells[7].text);

          // Get company name from tooltip or title attribute
          final anchor = cells[0].querySelector('a');
          final companyName = anchor?.attributes['title'] ?? symbol;

          final change = ltp - previousClose;

          stocks.add(StockPrice(
            symbol: symbol,
            companyName: companyName,
            ltp: ltp,
            change: change,
            changePercent: changePercent,
            open: open,
            high: high,
            low: low,
            volume: volume,
            previousClose: previousClose,
          ));
        } catch (e) {
          continue;
        }
      }
    }
  }

  static double _parseDouble(String text) {
    final cleaned = text.replaceAll(RegExp(r'[,\s]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Cache IPOs locally
  static Future<void> _cacheIpos(List<Ipo> ipos) async {
    final prefs = await SharedPreferences.getInstance();
    final json = ipos.map((i) => i.toJson()).toList();
    await prefs.setString(_cachedIposKey, jsonEncode(json));
    await prefs.setInt(_lastFetchTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached IPOs
  static Future<List<Ipo>> getCachedIpos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cachedIposKey);
      if (cached != null) {
        final json = jsonDecode(cached) as List;
        return json.map((j) => Ipo.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Cache stocks locally
  static Future<void> _cacheStocks(List<StockPrice> stocks) async {
    final prefs = await SharedPreferences.getInstance();
    final json = stocks.map((s) => s.toJson()).toList();
    await prefs.setString(_cachedStocksKey, jsonEncode(json));
  }

  /// Get cached stocks
  static Future<List<StockPrice>> getCachedStocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cachedStocksKey);
      if (cached != null) {
        final json = jsonDecode(cached) as List;
        return json.map((j) => StockPrice.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Check for new IPOs that haven't been seen
  static Future<List<Ipo>> getNewIpos(List<Ipo> currentIpos) async {
    final prefs = await SharedPreferences.getInstance();
    final seenIds = prefs.getStringList(_seenIposKey) ?? [];

    final newIpos = currentIpos.where((ipo) {
      final id = '${ipo.symbol}_${ipo.openDate.toIso8601String()}';
      return !seenIds.contains(id);
    }).toList();

    return newIpos;
  }

  /// Mark IPOs as seen
  static Future<void> markIposAsSeen(List<Ipo> ipos) async {
    final prefs = await SharedPreferences.getInstance();
    final seenIds = prefs.getStringList(_seenIposKey) ?? [];

    for (final ipo in ipos) {
      final id = '${ipo.symbol}_${ipo.openDate.toIso8601String()}';
      if (!seenIds.contains(id)) {
        seenIds.add(id);
      }
    }

    await prefs.setStringList(_seenIposKey, seenIds);
  }

  /// Check if IPO is opening soon (within 3 days)
  static bool isOpeningSoon(Ipo ipo) {
    final now = DateTime.now();
    final daysUntilOpen = ipo.openDate.difference(now).inDays;
    return daysUntilOpen >= 0 && daysUntilOpen <= 3;
  }

  /// Check if IPO is currently open
  static bool isCurrentlyOpen(Ipo ipo) {
    final now = DateTime.now();
    return now.isAfter(ipo.openDate) && now.isBefore(ipo.closeDate.add(const Duration(days: 1)));
  }

  /// Get time since last fetch
  static Future<Duration?> getTimeSinceLastFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getInt(_lastFetchTimeKey);
    if (lastFetch != null) {
      return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastFetch));
    }
    return null;
  }

  /// Get unique ID for an IPO (symbol + open date)
  static String getIpoId(Ipo ipo) {
    return '${ipo.symbol}_${ipo.openDate.toIso8601String().split('T')[0]}';
  }

  /// Check if a notification event was already sent for an IPO
  static Future<bool> wasEventNotified(Ipo ipo, String eventType) async {
    final prefs = await SharedPreferences.getInstance();
    final notifiedJson = prefs.getString(_notifiedEventsKey);
    if (notifiedJson == null) return false;

    try {
      final notified = jsonDecode(notifiedJson) as Map<String, dynamic>;
      final ipoId = getIpoId(ipo);
      final events = notified[ipoId] as List<dynamic>?;
      return events?.contains(eventType) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark a notification event as sent for an IPO
  static Future<void> markEventNotified(Ipo ipo, String eventType) async {
    final prefs = await SharedPreferences.getInstance();
    final notifiedJson = prefs.getString(_notifiedEventsKey);

    Map<String, dynamic> notified = {};
    if (notifiedJson != null) {
      try {
        notified = jsonDecode(notifiedJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    final ipoId = getIpoId(ipo);
    final events = (notified[ipoId] as List<dynamic>?)?.cast<String>() ?? <String>[];
    if (!events.contains(eventType)) {
      events.add(eventType);
    }
    notified[ipoId] = events;

    await prefs.setString(_notifiedEventsKey, jsonEncode(notified));
  }

  /// Clean up old notification records (IPOs older than 30 days)
  static Future<void> cleanupOldNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notifiedJson = prefs.getString(_notifiedEventsKey);
    if (notifiedJson == null) return;

    try {
      final notified = jsonDecode(notifiedJson) as Map<String, dynamic>;
      final cutoff = DateTime.now().subtract(const Duration(days: 30));

      notified.removeWhere((ipoId, _) {
        // Extract date from ID (format: SYMBOL_YYYY-MM-DD)
        final parts = ipoId.split('_');
        if (parts.length < 2) return true;
        try {
          final date = DateTime.parse(parts.last);
          return date.isBefore(cutoff);
        } catch (_) {
          return true;
        }
      });

      await prefs.setString(_notifiedEventsKey, jsonEncode(notified));
    } catch (_) {}
  }
}
