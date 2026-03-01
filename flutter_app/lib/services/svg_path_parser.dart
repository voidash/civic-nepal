import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:polylabel/polylabel.dart';

/// Parses SVG paths and provides hit testing for districts
class SvgPathParser {
  final Map<String, Path> _districtPaths = {};
  final Map<String, Offset> _pathCenters = {};
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
  double get viewBoxMinX => _viewBoxMinX;
  double get viewBoxMinY => _viewBoxMinY;

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
            // Calculate visual center (point inside the path)
            _pathCenters[id] = _findVisualCenter(path);
          } catch (e) {
            print('Error parsing path for $id: $e');
          }
        }
      }
    }
  }

  /// Find the "pole of inaccessibility" using polylabel algorithm
  /// Returns the point inside the polygon furthest from any edge
  Offset _findVisualCenter(Path path) {
    final bounds = path.getBounds();

    // Extract polygon points from path by sampling along the boundary
    final polygon = _pathToPolygon(path, bounds);

    if (polygon.isEmpty || polygon.length < 3) {
      return bounds.center;
    }

    try {
      // Use polylabel to find the optimal label position
      final result = polylabel([polygon]);
      return Offset(result.point.x.toDouble(), result.point.y.toDouble());
    } catch (e) {
      // Fallback to bounds center if polylabel fails
      return bounds.center;
    }
  }

  /// Convert a Path to a polygon (list of points) by sampling the boundary
  List<Point<num>> _pathToPolygon(Path path, Rect bounds) {
    final points = <Point<num>>[];

    // Sample points along the path boundary
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      final length = metric.length;
      // Sample every 2 units or at least 50 points
      final step = length / 50 > 2 ? length / 50 : 2;

      for (double d = 0; d < length; d += step) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) {
          points.add(Point(tangent.position.dx, tangent.position.dy));
        }
      }
    }

    return points;
  }

  /// Get the center point of a path in SVG coordinates
  Offset? getPathCenter(String pathId) => _pathCenters[pathId];

  /// Get all path centers
  Map<String, Offset> get pathCenters => Map.unmodifiable(_pathCenters);

  /// Get the bounding box of a path
  Rect? getPathBounds(String pathId) {
    final path = _districtPaths[pathId];
    return path?.getBounds();
  }

  // Cache clearance values
  final Map<String, double> _labelClearances = {};

  /// Get the minimum distance from center to any edge (label clearance)
  double? getLabelClearance(String pathId) {
    if (_labelClearances.containsKey(pathId)) {
      return _labelClearances[pathId];
    }

    final path = _districtPaths[pathId];
    if (path == null) return null;

    final polygon = _pathToPolygon(path, path.getBounds());
    if (polygon.length < 3) return null;

    try {
      final result = polylabel([polygon]);
      _labelClearances[pathId] = result.distance.toDouble();
      return result.distance.toDouble();
    } catch (e) {
      return null;
    }
  }

  /// Convert SVG coordinates to screen coordinates
  /// Uses BoxFit.contain logic to match how SvgPicture displays
  Offset svgToScreen(Offset svgPoint, Size screenSize) {
    // Calculate scale to fit SVG in screen while preserving aspect ratio (BoxFit.contain)
    final scaleX = screenSize.width / _svgWidth;
    final scaleY = screenSize.height / _svgHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY; // Use smaller scale to fit

    // Calculate the actual displayed size
    final displayedWidth = _svgWidth * scale;
    final displayedHeight = _svgHeight * scale;

    // Calculate centering offsets
    final offsetX = (screenSize.width - displayedWidth) / 2;
    final offsetY = (screenSize.height - displayedHeight) / 2;

    return Offset(
      (svgPoint.dx - _viewBoxMinX) * scale + offsetX,
      (svgPoint.dy - _viewBoxMinY) * scale + offsetY,
    );
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
