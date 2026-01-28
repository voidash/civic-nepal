import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';

/// Parses SVG paths and provides hit testing for districts
class SvgPathParser {
  final Map<String, Path> _districtPaths = {};
  double _svgWidth = 1224.992;
  double _svgHeight = 817.002;
  double _viewBoxMinX = 0;
  double _viewBoxMinY = 0;
  bool _isLoaded = false;

  SvgPathParser({
    double? svgWidth,
    double? svgHeight,
  }) {
    if (svgWidth != null) _svgWidth = svgWidth;
    if (svgHeight != null) _svgHeight = svgHeight;
  }

  bool get isLoaded => _isLoaded;
  double get svgWidth => _svgWidth;
  double get svgHeight => _svgHeight;

  /// Load and parse the SVG file
  Future<void> loadSvg(String assetPath) async {
    if (_isLoaded) return;

    try {
      final svgString = await rootBundle.loadString(assetPath);
      _parseSvgDimensions(svgString);
      _parseSvgPaths(svgString);
      _isLoaded = true;
      print('SVG loaded: $assetPath');
      print('ViewBox: $_viewBoxMinX, $_viewBoxMinY, $_svgWidth x $_svgHeight');
      print('Paths loaded: ${_districtPaths.length} - ${_districtPaths.keys.take(5).toList()}...');
    } catch (e) {
      print('Error loading SVG: $e');
      rethrow;
    }
  }

  /// Parse SVG dimensions from viewBox or width/height attributes
  void _parseSvgDimensions(String svgString) {
    // Try viewBox first: viewbox="minX minY width height"
    final viewBoxRegex = RegExp(r'viewbox="([^"]+)"', caseSensitive: false);
    final viewBoxMatch = viewBoxRegex.firstMatch(svgString);
    if (viewBoxMatch != null) {
      final parts = viewBoxMatch.group(1)?.split(RegExp(r'[\s,]+'));
      if (parts != null && parts.length >= 4) {
        final minX = double.tryParse(parts[0]);
        final minY = double.tryParse(parts[1]);
        final w = double.tryParse(parts[2]);
        final h = double.tryParse(parts[3]);
        if (minX != null && minY != null && w != null && h != null) {
          _viewBoxMinX = minX;
          _viewBoxMinY = minY;
          _svgWidth = w;
          _svgHeight = h;
          return;
        }
      }
    }

    // Fallback to width/height attributes
    final widthRegex = RegExp(r'width="([0-9.]+)"');
    final heightRegex = RegExp(r'height="([0-9.]+)"');
    final widthMatch = widthRegex.firstMatch(svgString);
    final heightMatch = heightRegex.firstMatch(svgString);
    if (widthMatch != null && heightMatch != null) {
      final w = double.tryParse(widthMatch.group(1) ?? '');
      final h = double.tryParse(heightMatch.group(1) ?? '');
      if (w != null && h != null) {
        _svgWidth = w;
        _svgHeight = h;
      }
    }
  }

  void _parseSvgPaths(String svgString) {
    // Regex to extract path elements - handles id and d in any order
    // Matches both <path ...> and <path .../> (self-closing)
    final pathRegex = RegExp(r'<path\s+([^>]+?)/?>');
    final idRegex = RegExp(r'\bid="([^"]+)"');
    final dRegex = RegExp(r'\bd="([^"]+)"');

    for (final match in pathRegex.allMatches(svgString)) {
      final pathAttrs = match.group(1);
      if (pathAttrs == null) continue;

      final idMatch = idRegex.firstMatch(pathAttrs);
      final dMatch = dRegex.firstMatch(pathAttrs);

      if (idMatch != null && dMatch != null) {
        final id = idMatch.group(1);
        final pathData = dMatch.group(1);

        if (id != null && pathData != null && id != 'districts' && !id.startsWith('SVG_')) {
          try {
            final path = parseSvgPathData(pathData);
            _districtPaths[id] = path;
          } catch (e) {
            print('Error parsing path for $id: $e');
          }
        }
      }
    }
  }

  /// Find which district contains the given point
  /// [point] should be in SVG coordinate space
  String? hitTest(Offset point) {
    print('HitTest at SVG point: $point');
    for (final entry in _districtPaths.entries) {
      if (entry.value.contains(point)) {
        print('HitTest found: ${entry.key}');
        return entry.key;
      }
    }
    print('HitTest: no match found');
    return null;
  }

  /// Convert screen coordinates to SVG coordinates
  Offset screenToSvg(Offset screenPoint, Size screenSize) {
    final scaleX = _svgWidth / screenSize.width;
    final scaleY = _svgHeight / screenSize.height;
    final scale = scaleX > scaleY ? scaleX : scaleY;

    // Center the SVG in the available space
    final scaledWidth = _svgWidth / scale;
    final scaledHeight = _svgHeight / scale;
    final offsetX = (screenSize.width - scaledWidth) / 2;
    final offsetY = (screenSize.height - scaledHeight) / 2;

    // Convert to SVG coordinates, accounting for viewBox offset
    final svgPoint = Offset(
      (screenPoint.dx - offsetX) * scale + _viewBoxMinX,
      (screenPoint.dy - offsetY) * scale + _viewBoxMinY,
    );
    print('screenToSvg: screen=$screenPoint, size=$screenSize, scale=$scale, svgPoint=$svgPoint');
    return svgPoint;
  }

  /// Get all district IDs
  List<String> get districtIds => _districtPaths.keys.toList();
}

/// Parse SVG path data string into a Flutter Path
Path parseSvgPathData(String pathData) {
  final path = Path();
  final pathProxy = _PathProxy(path);
  writeSvgPathDataToPath(pathData, pathProxy);
  return path;
}

class _PathProxy extends PathProxy {
  final Path path;

  _PathProxy(this.path);

  @override
  void close() => path.close();

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) {
    path.cubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
}
