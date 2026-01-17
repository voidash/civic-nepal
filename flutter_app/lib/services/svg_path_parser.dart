import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';

/// Parses SVG paths and provides hit testing for districts
class SvgPathParser {
  final Map<String, Path> _districtPaths = {};
  final double _svgWidth;
  final double _svgHeight;
  bool _isLoaded = false;

  SvgPathParser({
    double svgWidth = 1224.992,
    double svgHeight = 817.002,
  })  : _svgWidth = svgWidth,
        _svgHeight = svgHeight;

  bool get isLoaded => _isLoaded;
  double get svgWidth => _svgWidth;
  double get svgHeight => _svgHeight;

  /// Load and parse the SVG file
  Future<void> loadSvg(String assetPath) async {
    if (_isLoaded) return;

    try {
      final svgString = await rootBundle.loadString(assetPath);
      _parseSvgPaths(svgString);
      _isLoaded = true;
    } catch (e) {
      print('Error loading SVG: $e');
    }
  }

  void _parseSvgPaths(String svgString) {
    // Simple regex to extract path elements with id and d attributes
    final pathRegex = RegExp(r'<path\s+id="([^"]+)"\s+d="([^"]+)"', multiLine: true);

    for (final match in pathRegex.allMatches(svgString)) {
      final id = match.group(1);
      final pathData = match.group(2);

      if (id != null && pathData != null && id != 'districts') {
        try {
          final path = parseSvgPathData(pathData);
          _districtPaths[id] = path;
        } catch (e) {
          print('Error parsing path for $id: $e');
        }
      }
    }
  }

  /// Find which district contains the given point
  /// [point] should be in SVG coordinate space
  String? hitTest(Offset point) {
    for (final entry in _districtPaths.entries) {
      if (entry.value.contains(point)) {
        return entry.key;
      }
    }
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

    return Offset(
      (screenPoint.dx - offsetX) * scale,
      (screenPoint.dy - offsetY) * scale,
    );
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
