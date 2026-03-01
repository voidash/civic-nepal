import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A single RONB post with text, timestamp, optional image URL.
class RonbPost {
  final String text;
  final int? timestamp;
  final String? imageUrl;
  final String? postUrl;

  const RonbPost({
    required this.text,
    this.timestamp,
    this.imageUrl,
    this.postUrl,
  });

  DateTime? get dateTimeUtc =>
      timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp! * 1000, isUtc: true) : null;

  /// Nepal is UTC+5:45
  DateTime? get dateTimeNpt {
    final utc = dateTimeUtc;
    if (utc == null) return null;
    return utc.add(const Duration(hours: 5, minutes: 45));
  }

  String get relativeTime {
    final utc = dateTimeUtc;
    if (utc == null) return '';
    final diff = DateTime.now().toUtc().difference(utc);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'timestamp': timestamp,
        'imageUrl': imageUrl,
        'postUrl': postUrl,
      };

  factory RonbPost.fromJson(Map<String, dynamic> json) => RonbPost(
        text: json['text'] as String? ?? '',
        timestamp: json['timestamp'] as int?,
        imageUrl: json['imageUrl'] as String?,
        postUrl: json['postUrl'] as String?,
      );
}

/// Result of a RONB feed fetch.
class RonbFeed {
  final List<RonbPost> posts;
  final DateTime scrapedAt;

  const RonbFeed({required this.posts, required this.scrapedAt});

  Map<String, dynamic> toJson() => {
        'posts': posts.map((p) => p.toJson()).toList(),
        'scrapedAt': scrapedAt.toIso8601String(),
      };

  factory RonbFeed.fromJson(Map<String, dynamic> json) => RonbFeed(
        posts: (json['posts'] as List)
            .map((p) => RonbPost.fromJson(p as Map<String, dynamic>))
            .toList(),
        scrapedAt: DateTime.parse(json['scrapedAt'] as String),
      );
}

/// Service to scrape RONB Facebook page and extract posts.
///
/// Uses Googlebot user agent to get server-rendered HTML with embedded JSON.
/// On web, routes through a CORS proxy. On mobile/desktop, fetches directly.
class RonbService {
  static const String _facebookPage = 'officialroutineofnepalbanda';
  static const String _pageUrl = 'https://www.facebook.com/$_facebookPage/';
  static const String _googlebotUa =
      'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)';

// Bump version when cache format changes (v2: added image extraction)
  static const String _cacheKey = 'ronb_feed_cache_v2';

  /// In-memory image cache (media_id -> bytes).
  /// Persists for app lifetime so images don't re-download on rebuild.
  static final Map<String, Uint8List> _imageCache = {};

  /// Fetch the RONB feed.
  ///
  /// Strategy for snappiness:
  /// 1. If cache exists, return it immediately (even if stale)
  /// 2. Caller can then call fetchFeed(forceRefresh: true) in background
  ///
  /// On web: Facebook requires Googlebot UA which browsers can't set on
  /// cross-origin requests. Falls back to bundled JSON asset.
  ///
  /// [forceRefresh] bypasses cache age check.
  /// [maxAge] is how old cached data can be before auto re-fetching (default 30 min).
  static Future<RonbFeed> fetchFeed({
    bool forceRefresh = false,
    Duration maxAge = const Duration(minutes: 30),
  }) async {
    // Web: can't scrape Facebook (CORS + Googlebot UA required).
    // Fall back to bundled JSON asset.
    if (kIsWeb) {
      return _loadBundledFeed();
    }

    // Check cache first
    if (!forceRefresh) {
      final cached = await _loadCache();
      if (cached != null) {
        final age = DateTime.now().toUtc().difference(cached.scrapedAt);
        if (age < maxAge) {
          return cached;
        }
      }
    }

    // Scrape fresh data
    try {
      final html = await _fetchPage();
      final posts = _extractPosts(html);
      final feed = RonbFeed(posts: posts, scrapedAt: DateTime.now().toUtc());
      await _saveCache(feed);
      return feed;
    } catch (e) {
      // If scrape fails, return stale cache if available
      final cached = await _loadCache();
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Load pre-scraped feed from bundled assets (for web).
  static Future<RonbFeed> _loadBundledFeed() async {
    final jsonStr = await rootBundle.loadString('assets/data/ronb_feed.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final posts = (data['posts'] as List).map((p) {
      final post = p as Map<String, dynamic>;
      return RonbPost(
        text: post['text'] as String? ?? '',
        timestamp: post['timestamp'] as int?,
        imageUrl: null, // Bundled feed has no accessible image URLs
        postUrl: post['url'] as String?,
      );
    }).toList();
    final scrapedAt = DateTime.tryParse(data['scraped_at'] as String? ?? '') ?? DateTime.now().toUtc();
    return RonbFeed(posts: posts, scrapedAt: scrapedAt);
  }

  /// Get cached feed immediately (no network). Returns null if no cache.
  static Future<RonbFeed?> getCachedFeed() => _loadCache();

  /// Fetch image bytes for a lookaside URL.
  ///
  /// Facebook lookaside URLs require Googlebot UA to return actual image data.
  /// Normal requests get an HTML redirect to login page.
  /// Results are cached in memory for app lifetime.
  static Future<Uint8List?> fetchImage(String url) async {
    // Extract media_id for cache key
    final mediaId = RegExp(r'media_id=(\d+)').firstMatch(url)?.group(1) ?? url;

    // Check memory cache
    if (_imageCache.containsKey(mediaId)) {
      return _imageCache[mediaId];
    }

    // Web has no image URLs (bundled feed), so this is native-only
    if (kIsWeb) return null;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': _googlebotUa},
      ).timeout(const Duration(seconds: 15));

      final ct = response.headers['content-type'] ?? '';
      if (response.statusCode == 200 && ct.contains('image')) {
        _imageCache[mediaId] = response.bodyBytes;
        return response.bodyBytes;
      }
    } catch (_) {
      // Image fetch failure is non-fatal
    }
    return null;
  }

  /// Fetch the Facebook page HTML with Googlebot UA.
  static Future<String> _fetchPage() async {
    final response = await http.get(
      Uri.parse(_pageUrl),
      headers: {'User-Agent': _googlebotUa},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Facebook returned ${response.statusCode}');
    }
    return response.body;
  }

  /// Extract posts from Facebook HTML.
  ///
  /// Facebook embeds post data as JSON in the page source.
  /// URLs are escaped as \/ in the JSON. We extract messages, timestamps,
  /// and images, then pair by proximity in the HTML string.
  static List<RonbPost> _extractPosts(String html) {
    // Extract messages: "message":{"text":"..."}
    final msgPattern = RegExp(r'"message":\{"text":"((?:[^"\\]|\\.){5,5000})"\}');
    // Extract timestamps: "creation_time":1234567890
    final tsPattern = RegExp(r'"creation_time":(\d{10})');
    // Extract photo_image URIs (Facebook escapes / as \/ in JSON)
    // Matches both escaped and unescaped forms
    final imgPattern = RegExp(
      r'"photo_image":\{"uri":"(https?:[^"]+?media_id=\d+[^"]*)"',
    );
    // Extract post URLs
    final urlPattern = RegExp(
      r'"url":"(https?:[^"]*' + _facebookPage + r'[/\\]posts[/\\][^"]+)"',
    );

    // Collect all matches with positions
    final messages = <({String text, int pos})>[];
    for (final m in msgPattern.allMatches(html)) {
      final raw = m.group(1)!;
      final cleaned = _cleanText(raw);
      if (cleaned.isNotEmpty) {
        messages.add((text: cleaned, pos: m.start));
      }
    }

    final timestamps = <({int ts, int pos})>[];
    for (final m in tsPattern.allMatches(html)) {
      timestamps.add((ts: int.parse(m.group(1)!), pos: m.start));
    }

    final images = <({String url, int pos})>[];
    for (final m in imgPattern.allMatches(html)) {
      var url = m.group(1)!;
      // Unescape \/ to /
      url = url.replaceAll(r'\/', '/');
      images.add((url: url, pos: m.start));
    }

    final postUrls = <({String url, int pos})>[];
    for (final m in urlPattern.allMatches(html)) {
      var url = m.group(1)!;
      url = url.replaceAll(r'\/', '/');
      postUrls.add((url: url, pos: m.start));
    }

    // Pair each message with nearest timestamp and nearest image
    final seenTexts = <String>{};
    final posts = <RonbPost>[];

    for (final msg in messages) {
      // Deduplicate by first 100 chars
      final key = msg.text.length > 100 ? msg.text.substring(0, 100) : msg.text;
      if (seenTexts.contains(key)) continue;
      seenTexts.add(key);

      // Find nearest timestamp
      int? nearestTs;
      var minDist = double.infinity;
      for (final ts in timestamps) {
        final dist = (ts.pos - msg.pos).abs().toDouble();
        if (dist < minDist) {
          minDist = dist;
          nearestTs = ts.ts;
        }
      }

      // Find nearest image - deduplicate by media_id, pick closest
      String? nearestImg;
      var minImgDist = double.infinity;
      for (final img in images) {
        final dist = (img.pos - msg.pos).abs().toDouble();
        if (dist < minImgDist) {
          minImgDist = dist;
          nearestImg = img.url;
        }
      }

      // Sanity check: if image is too far away (>50k chars), probably not related
      if (minImgDist > 50000) {
        nearestImg = null;
      }

      // Find nearest post URL
      String? nearestUrl;
      var minUrlDist = double.infinity;
      for (final u in postUrls) {
        final dist = (u.pos - msg.pos).abs().toDouble();
        if (dist < minUrlDist) {
          minUrlDist = dist;
          nearestUrl = u.url;
        }
      }

      posts.add(RonbPost(
        text: msg.text,
        timestamp: nearestTs,
        imageUrl: nearestImg,
        postUrl: nearestUrl,
      ));
    }

    // Sort by timestamp descending (newest first)
    posts.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));
    return posts;
  }

  /// Decode escaped unicode from Facebook JSON.
  static String _cleanText(String raw) {
    var text = raw.replaceAll(r'\n', '\n');
    text = text.replaceAll(r'\"', '"');
    text = text.replaceAll(r'\/', '/');
    text = text.replaceAll(r'\\', r'\');

    // Decode \uXXXX sequences
    text = text.replaceAllMapped(
      RegExp(r'\\u([0-9a-fA-F]{4})'),
      (m) {
        final codePoint = int.tryParse(m.group(1)!, radix: 16);
        if (codePoint != null) {
          return String.fromCharCode(codePoint);
        }
        return m.group(0)!;
      },
    );

    // Handle surrogate pairs
    text = text.replaceAllMapped(
      RegExp(r'([\uD800-\uDBFF])([\uDC00-\uDFFF])'),
      (m) {
        final high = m.group(1)!.codeUnitAt(0);
        final low = m.group(2)!.codeUnitAt(0);
        final codePoint = 0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00);
        return String.fromCharCode(codePoint);
      },
    );

    return text.trim();
  }

  /// Load cached feed from SharedPreferences.
  static Future<RonbFeed?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      return RonbFeed.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Save feed to SharedPreferences cache.
  static Future<void> _saveCache(RonbFeed feed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(feed.toJson()));
    } catch (_) {
      // Caching failure is non-fatal
    }
  }
}
