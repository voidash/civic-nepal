import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'district_map_screen.g.dart';

/// District map screen with interactive SVG
class DistrictMapScreen extends ConsumerWidget {
  const DistrictMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nepal Districts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              // Zoom in
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              // Zoom out
            },
          ),
        ],
      ),
      body: const InteractiveMap(),
    );
  }
}

/// Interactive SVG map widget
class InteractiveMap extends StatelessWidget {
  const InteractiveMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<String>(
        future: _loadSvg(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('Error loading map: ${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Text('Map data not available');
          }

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: SvgPicture.string(
              snapshot.data!,
              width: 400,
              height: 500,
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }

  Future<String> _loadSvg() async {
    // For now, return a placeholder
    // In production, this would load from assets
    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 500">
  <rect width="400" height="500" fill="#f0f0f0"/>
  <text x="200" y="250" text-anchor="middle" font-size="24">
    Nepal Map
  </text>
  <text x="200" y="280" text-anchor="middle" font-size="14">
    (SVG will be loaded from assets)
  </text>
</svg>
''';
  }
}
