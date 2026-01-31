#!/usr/bin/env python3
"""
Process OSM data for Flutter app map layers.
Extracts schools, colleges, government offices, and roads.
"""

import json
from pathlib import Path
from collections import defaultdict

# Nepal's bounding box for validation
NEPAL_BOUNDS = {
    'min_lat': 26.3,
    'max_lat': 30.5,
    'min_lon': 80.0,
    'max_lon': 88.2
}

def is_in_nepal(lat, lon):
    """Check if coordinates are within Nepal's bounds."""
    return (NEPAL_BOUNDS['min_lat'] <= lat <= NEPAL_BOUNDS['max_lat'] and
            NEPAL_BOUNDS['min_lon'] <= lon <= NEPAL_BOUNDS['max_lon'])

def process_points(input_file, output_file, category):
    """Process point-based OSM data (schools, colleges, government)."""
    with open(input_file, 'r') as f:
        data = json.load(f)

    processed = []
    for element in data.get('elements', []):
        # Get coordinates - either directly or from center
        if element['type'] == 'node':
            lat = element.get('lat')
            lon = element.get('lon')
        else:
            # Way with center
            center = element.get('center', {})
            lat = center.get('lat')
            lon = center.get('lon')

        if lat is None or lon is None:
            continue

        if not is_in_nepal(lat, lon):
            continue

        tags = element.get('tags', {})

        # Extract name (prefer English, then Nepali, then any)
        name = tags.get('name:en') or tags.get('name') or tags.get('name:ne') or ''

        item = {
            'id': element['id'],
            'lat': round(lat, 6),
            'lon': round(lon, 6),
            'name': name,
        }

        # Add category-specific fields
        if category == 'school':
            item['type'] = tags.get('school:type', tags.get('isced:level', ''))
            if tags.get('operator:type'):
                item['operator'] = tags.get('operator:type')
        elif category == 'college':
            item['type'] = 'university' if tags.get('amenity') == 'university' else 'college'
        elif category == 'government':
            item['type'] = tags.get('government', tags.get('office', 'government'))
            if tags.get('admin_level'):
                item['admin_level'] = tags.get('admin_level')

        processed.append(item)

    # Sort by name for easier lookup
    processed.sort(key=lambda x: x.get('name', ''))

    output = {
        'type': category,
        'count': len(processed),
        'source': 'OpenStreetMap',
        'timestamp': data.get('osm3s', {}).get('timestamp_osm_base', ''),
        'items': processed
    }

    with open(output_file, 'w') as f:
        json.dump(output, f, ensure_ascii=False, separators=(',', ':'))

    print(f"{category}: {len(processed)} items -> {output_file}")
    return len(processed)

def simplify_line(coords, tolerance=0.001):
    """
    Douglas-Peucker line simplification.
    tolerance is in degrees (~111m per 0.001 degree at equator)
    """
    if len(coords) <= 2:
        return coords

    def perpendicular_distance(point, line_start, line_end):
        """Calculate perpendicular distance from point to line."""
        x, y = point
        x1, y1 = line_start
        x2, y2 = line_end

        dx = x2 - x1
        dy = y2 - y1

        if dx == 0 and dy == 0:
            return ((x - x1) ** 2 + (y - y1) ** 2) ** 0.5

        t = max(0, min(1, ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)))
        proj_x = x1 + t * dx
        proj_y = y1 + t * dy

        return ((x - proj_x) ** 2 + (y - proj_y) ** 2) ** 0.5

    # Find point with max distance
    max_dist = 0
    max_idx = 0
    for i in range(1, len(coords) - 1):
        dist = perpendicular_distance(coords[i], coords[0], coords[-1])
        if dist > max_dist:
            max_dist = dist
            max_idx = i

    # If max distance > tolerance, recursively simplify
    if max_dist > tolerance:
        left = simplify_line(coords[:max_idx + 1], tolerance)
        right = simplify_line(coords[max_idx:], tolerance)
        return left[:-1] + right
    else:
        return [coords[0], coords[-1]]

def process_roads(input_file, output_file):
    """Process road data from OSM."""
    with open(input_file, 'r') as f:
        data = json.load(f)

    roads_by_type = defaultdict(list)

    for element in data.get('elements', []):
        if element['type'] != 'way':
            continue

        geometry = element.get('geometry', [])
        if not geometry:
            continue

        tags = element.get('tags', {})
        highway_type = tags.get('highway', 'road')
        name = tags.get('name:en') or tags.get('name') or tags.get('ref') or ''
        ref = tags.get('ref', '')

        # Extract coordinates
        coords = [(round(p['lon'], 5), round(p['lat'], 5)) for p in geometry
                  if is_in_nepal(p['lat'], p['lon'])]

        if len(coords) < 2:
            continue

        # Simplify geometry to reduce size
        # More aggressive for secondary roads
        tolerance = 0.0005 if highway_type == 'trunk' else 0.001 if highway_type == 'primary' else 0.002
        simplified = simplify_line(coords, tolerance)

        road = {
            'id': element['id'],
            'name': name,
            'ref': ref,
            'coords': simplified
        }

        roads_by_type[highway_type].append(road)

    # Calculate stats
    total_roads = sum(len(roads) for roads in roads_by_type.values())
    total_points = sum(
        sum(len(r['coords']) for r in roads)
        for roads in roads_by_type.values()
    )

    output = {
        'type': 'roads',
        'source': 'OpenStreetMap',
        'timestamp': data.get('osm3s', {}).get('timestamp_osm_base', ''),
        'stats': {
            'total_roads': total_roads,
            'total_points': total_points,
            'by_type': {k: len(v) for k, v in roads_by_type.items()}
        },
        'roads': dict(roads_by_type)
    }

    with open(output_file, 'w') as f:
        json.dump(output, f, ensure_ascii=False, separators=(',', ':'))

    print(f"Roads: {total_roads} roads, {total_points} points -> {output_file}")
    file_size = Path(output_file).stat().st_size / 1024 / 1024
    print(f"  File size: {file_size:.2f} MB")
    return total_roads

def main():
    output_dir = Path('/Users/cdjk/github/probe/constitution/flutter_app/assets/data/osm')
    output_dir.mkdir(parents=True, exist_ok=True)

    print("Processing OSM data for Nepal...\n")

    # Process schools
    process_points(
        '/tmp/nepal_schools_raw.json',
        output_dir / 'schools.json',
        'school'
    )

    # Process colleges
    process_points(
        '/tmp/nepal_colleges_raw.json',
        output_dir / 'colleges.json',
        'college'
    )

    # Process government offices
    process_points(
        '/tmp/nepal_government_raw.json',
        output_dir / 'government.json',
        'government'
    )

    # Process roads
    process_roads(
        '/tmp/nepal_roads_raw.json',
        output_dir / 'roads.json'
    )

    print("\nDone! Files saved to:", output_dir)

    # Print file sizes
    print("\nFile sizes:")
    for f in output_dir.glob('*.json'):
        size = f.stat().st_size / 1024
        print(f"  {f.name}: {size:.1f} KB")

if __name__ == '__main__':
    main()
