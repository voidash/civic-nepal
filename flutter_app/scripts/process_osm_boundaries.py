#!/usr/bin/env python3
"""
Process OSM boundary data for Nepal into compact GeoJSON format.
"""

import json
from pathlib import Path

def simplify_line(coords, tolerance=0.005):
    """Douglas-Peucker line simplification."""
    if len(coords) <= 2:
        return coords

    def perpendicular_distance(point, line_start, line_end):
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

    max_dist = 0
    max_idx = 0
    for i in range(1, len(coords) - 1):
        dist = perpendicular_distance(coords[i], coords[0], coords[-1])
        if dist > max_dist:
            max_dist = dist
            max_idx = i

    if max_dist > tolerance:
        left = simplify_line(coords[:max_idx + 1], tolerance)
        right = simplify_line(coords[max_idx:], tolerance)
        return left[:-1] + right
    else:
        return [coords[0], coords[-1]]


def extract_boundary_coords(element):
    """Extract coordinates from OSM relation geometry."""
    coords = []

    if 'members' in element:
        for member in element.get('members', []):
            if member.get('type') == 'way' and member.get('role') == 'outer':
                geom = member.get('geometry', [])
                for point in geom:
                    if 'lat' in point and 'lon' in point:
                        coords.append([round(point['lon'], 5), round(point['lat'], 5)])

    return coords


def process_boundaries(input_file, admin_level):
    """Process OSM boundary data."""
    with open(input_file, 'r') as f:
        data = json.load(f)

    features = []

    for element in data.get('elements', []):
        if element.get('type') != 'relation':
            continue

        tags = element.get('tags', {})

        # Get name
        name_en = tags.get('name:en', tags.get('name', ''))
        name_ne = tags.get('name:ne', tags.get('name', ''))

        # Extract all outer way coordinates
        all_coords = []
        for member in element.get('members', []):
            if member.get('type') == 'way' and member.get('role') in ('outer', None):
                geom = member.get('geometry', [])
                way_coords = []
                for point in geom:
                    if 'lat' in point and 'lon' in point:
                        way_coords.append([round(point['lon'], 5), round(point['lat'], 5)])
                if way_coords:
                    all_coords.append(way_coords)

        if not all_coords:
            continue

        # Simplify each ring
        simplified_rings = []
        for ring in all_coords:
            if len(ring) > 2:
                # Simplify with tolerance based on admin level
                tolerance = 0.002 if admin_level == 2 else 0.003 if admin_level == 4 else 0.004
                simplified = simplify_line(ring, tolerance)
                if len(simplified) >= 3:
                    simplified_rings.append(simplified)

        if not simplified_rings:
            continue

        feature = {
            'id': element['id'],
            'name': name_en,
            'name_ne': name_ne,
            'admin_level': admin_level,
            'rings': simplified_rings
        }

        # Add province number for admin_level 4
        if admin_level == 4:
            # Extract province number from name or ref
            ref = tags.get('ref', '')
            if ref.isdigit():
                feature['province'] = int(ref)

        features.append(feature)
        print(f"  {name_en}: {sum(len(r) for r in simplified_rings)} points")

    return features


def main():
    output_dir = Path('/Users/cdjk/github/probe/constitution/flutter_app/assets/data/osm')
    output_dir.mkdir(parents=True, exist_ok=True)

    print("Processing Nepal boundaries from OSM...\n")

    # Process country boundary
    print("Country boundary:")
    country = process_boundaries('/tmp/nepal_boundary.json', 2)

    # Process province boundaries
    print("\nProvince boundaries:")
    provinces = process_boundaries('/tmp/nepal_provinces.json', 4)

    # Process district boundaries
    print("\nDistrict boundaries:")
    districts = process_boundaries('/tmp/nepal_districts_osm.json', 6)

    # Combine into single file
    output = {
        'source': 'OpenStreetMap',
        'country': country,
        'provinces': provinces,
        'districts': districts,
        'stats': {
            'country_points': sum(sum(len(r) for r in f['rings']) for f in country),
            'province_count': len(provinces),
            'province_points': sum(sum(len(r) for r in f['rings']) for f in provinces),
            'district_count': len(districts),
            'district_points': sum(sum(len(r) for r in f['rings']) for f in districts),
        }
    }

    output_file = output_dir / 'boundaries.json'
    with open(output_file, 'w') as f:
        json.dump(output, f, ensure_ascii=False, separators=(',', ':'))

    file_size = output_file.stat().st_size / 1024
    print(f"\nSaved to {output_file}")
    print(f"File size: {file_size:.1f} KB")
    print(f"\nStats:")
    print(f"  Country: {output['stats']['country_points']} points")
    print(f"  Provinces: {output['stats']['province_count']} ({output['stats']['province_points']} points)")
    print(f"  Districts: {output['stats']['district_count']} ({output['stats']['district_points']} points)")


if __name__ == '__main__':
    main()
