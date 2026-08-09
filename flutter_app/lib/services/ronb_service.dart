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

/// Service that supplies the RONB news feed.
///
/// The feed is scraped server-side every ~10 minutes by the `update-ronb`
/// workflow and published to the repository's `data` branch, so the app just
/// downloads a few KB of JSON instead of parsing a 2MB Facebook page. That is
/// the only path that works on web at all: scraping Facebook directly needs a
/// Googlebot user agent, which a browser cannot set cross-origin.
///
/// Native platforms keep the direct scrape as a fallback for when the
/// published feed is unreachable.
class RonbService {
  static const String _facebookPage = 'officialroutineofnepalbanda';
  static const String _pageUrl = 'https://www.facebook.com/$_facebookPage/';
  static const String _googlebotUa =
      'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)';

  /// Pre-scraped feed. raw.githubusercontent.com allows cross-origin reads and
  /// caches for 5 minutes, which suits the publish cadence.
  static const String _publishedFeedUrl =
      'https://raw.githubusercontent.com/voidash/civic-nepal/data/ronb_feed.json';

// Bump version when cache format changes (v2: added image extraction)
  static const String _cacheKey = 'ronb_feed_cache_v2';

  /// In-memory image cache (media_id -> bytes).
  /// Persists for app lifetime so images don't re-download on rebuild.
  static final Map<String, Uint8List> _imageCache = {};

  /// Fetch the RONB feed.
  ///
  /// Order of preference:
  ///  1. Cache, if younger than [maxAge] and [forceRefresh] is not set.
  ///  2. The published feed — small, current, and the only option on web.
  ///  3. A direct Facebook scrape (native only).
  ///  4. Stale cache, then the bundled asset, so the screen is never empty.
  ///
  /// [maxAge] defaults to 15 minutes to sit just above the ~10 minute publish
  /// interval.
  static Future<RonbFeed> fetchFeed({
    bool forceRefresh = false,
    Duration maxAge = const Duration(minutes: 15),
  }) async {
    if (!forceRefresh) {
      final cached = await _loadCache();
      if (cached != null &&
          DateTime.now().toUtc().difference(cached.scrapedAt) < maxAge) {
        return cached;
      }
    }

    final published = await _fetchPublishedFeed();
    if (published != null) {
      await _saveCache(published);
      return published;
    }

    // Browsers cannot set the Googlebot user agent on a cross-origin request,
    // so the direct scrape is native-only.
    if (!kIsWeb) {
      try {
        final feed = RonbFeed(
          posts: _extractPosts(await _fetchPage()),
          scrapedAt: DateTime.now().toUtc(),
        );
        await _saveCache(feed);
        return feed;
      } catch (_) {
        // Fall through to the offline fallbacks below.
      }
    }

    return await _loadCache() ?? await _loadBundledFeed();
  }

  /// Download the pre-scraped feed. Returns null if it cannot be reached.
  static Future<RonbFeed?> _fetchPublishedFeed() async {
    try {
      final response = await http
          .get(Uri.parse(_publishedFeedUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      // bodyBytes rather than body: the feed is largely Devanagari and the
      // default latin1 decode would mangle it.
      return _parseScrapedFeed(
        json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Load the copy bundled at build time — first launch, and offline.
  static Future<RonbFeed> _loadBundledFeed() async {
    final jsonStr = await rootBundle.loadString('assets/data/ronb_feed.json');
    return _parseScrapedFeed(json.decode(jsonStr) as Map<String, dynamic>);
  }

  /// True for an image we re-host ourselves, as opposed to a Facebook URL.
  static bool isMirrored(String? url) =>
      url != null && url.startsWith('https://raw.githubusercontent.com/');

  /// Parse the format written by `scripts/scrape_ronb.py`.
  static RonbFeed _parseScrapedFeed(Map<String, dynamic> data) {
    final posts = (data['posts'] as List? ?? []).map((p) {
      final post = p as Map<String, dynamic>;
      final imageUrl = post['imageUrl'] as String?;
      return RonbPost(
        text: post['text'] as String? ?? '',
        timestamp: post['timestamp'] as int?,
        // The published feed points at images mirrored onto the data branch,
        // which any browser can load. Facebook's own lookaside URLs only
        // return bytes to a Googlebot user agent, so those stay native-only.
        imageUrl: (kIsWeb && !isMirrored(imageUrl)) ? null : imageUrl,
        postUrl: post['url'] as String?,
      );
    }).toList();
    return RonbFeed(
      posts: posts,
      scrapedAt: DateTime.tryParse(data['scraped_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
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
