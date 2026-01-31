#!/usr/bin/env python3
"""
Simplify Nepal constituencies SVG to a lightweight JSON format.
Uses Douglas-Peucker algorithm to reduce path complexity.
"""

import re
import json
import math
from pathlib import Path


def parse_svg_path(d: str) -> list[list[float]]:
    """Parse SVG path d attribute to list of [x, y] points."""
    points = []
    current_x, current_y = 0.0, 0.0

    # Split into commands
    commands = re.findall(r'([MLZmlz])\s*([-\d.,\s]*)', d)

    for cmd, coords_str in commands:
        if cmd in ('Z', 'z'):
            continue

        # Parse coordinate pairs
        coords = re.findall(r'([-\d.]+)', coords_str)

        i = 0
        while i < len(coords) - 1:
            x, y = float(coords[i]), float(coords[i + 1])

            if cmd == 'M':  # Absolute moveto
                current_x, current_y = x, y
            elif cmd == 'm':  # Relative moveto
                current_x += x
                current_y += y
            elif cmd == 'L':  # Absolute lineto
                current_x, current_y = x, y
            elif cmd == 'l':  # Relative lineto
                current_x += x
                current_y += y

            points.append([round(current_x, 2), round(current_y, 2)])
            i += 2

    return points


def douglas_peucker(points: list[list[float]], epsilon: float) -> list[list[float]]:
    """Simplify path using Douglas-Peucker algorithm."""
    if len(points) < 3:
        return points

    # Find point with max distance from line between first and last
    start, end = points[0], points[-1]
    max_dist = 0
    max_idx = 0

    for i in range(1, len(points) - 1):
        dist = perpendicular_distance(points[i], start, end)
        if dist > max_dist:
            max_dist = dist
            max_idx = i

    # If max distance > epsilon, recursively simplify
    if max_dist > epsilon:
        left = douglas_peucker(points[:max_idx + 1], epsilon)
        right = douglas_peucker(points[max_idx:], epsilon)
        return left[:-1] + right
    else:
        return [start, end]


def perpendicular_distance(point: list[float], line_start: list[float], line_end: list[float]) -> float:
    """Calculate perpendicular distance from point to line."""
    x, y = point
    x1, y1 = line_start
    x2, y2 = line_end

    dx = x2 - x1
    dy = y2 - y1

    if dx == 0 and dy == 0:
        return math.sqrt((x - x1) ** 2 + (y - y1) ** 2)

    t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)
    t = max(0, min(1, t))

    proj_x = x1 + t * dx
    proj_y = y1 + t * dy

    return math.sqrt((x - proj_x) ** 2 + (y - proj_y) ** 2)


def calculate_centroid(points: list[list[float]]) -> tuple[float, float]:
    """Calculate centroid of polygon."""
    if not points:
        return (0, 0)
    sum_x = sum(p[0] for p in points)
    sum_y = sum(p[1] for p in points)
    n = len(points)
    return (round(sum_x / n, 2), round(sum_y / n, 2))


def main():
    svg_path = Path(__file__).parent.parent / 'assets/data/election/nepal_constituencies.svg'
    output_path = Path(__file__).parent.parent / 'assets/data/election/constituencies_geo.json'

    with open(svg_path) as f:
        svg_content = f.read()

    # Extract viewBox
    viewbox_match = re.search(r'viewBox="([^"]+)"', svg_content)
    if viewbox_match:
        viewbox = [float(x) for x in viewbox_match.group(1).split()]
    else:
        viewbox = [0, 0, 500, 500]

    # Extract paths with IDs
    path_pattern = r'<path[^>]*id="([^"]+)"[^>]*d="([^"]+)"[^>]*/>'
    matches = re.findall(path_pattern, svg_content)

    # Also try alternate pattern where d comes before id
    path_pattern2 = r'<path[^>]*d="([^"]+)"[^>]*id="([^"]+)"[^>]*/>'
    matches2 = re.findall(path_pattern2, svg_content)
    matches2 = [(id, d) for d, id in matches2]

    all_matches = matches + matches2

    constituencies = []
    total_original = 0
    total_simplified = 0

    # Epsilon for simplification (adjust based on viewBox size)
    epsilon = 0.5  # About 0.1% of 500-unit viewBox

    for path_id, d in all_matches:
        # Skip unnamed paths
        if path_id.startswith('path') or path_id.startswith('svg'):
            continue

        points = parse_svg_path(d)
        total_original += len(points)

        if len(points) < 3:
            continue

        simplified = douglas_peucker(points, epsilon)
        total_simplified += len(simplified)

        # Parse constituency name from ID (e.g., "kathmandu-1" -> {"district": "Kathmandu", "number": 1})
        parts = path_id.rsplit('-', 1)
        if len(parts) == 2:
            district = parts[0].replace('_', ' ').title()
            try:
                number = int(parts[1])
            except ValueError:
                number = 0
        else:
            district = path_id.replace('_', ' ').title()
            number = 0

        centroid = calculate_centroid(simplified)

        constituencies.append({
            'id': path_id,
            'name': f"{district}-{number}" if number > 0 else district,
            'district': district,
            'number': number,
            'centroid': list(centroid),
            'path': simplified
        })

    # Sort by district and number
    constituencies.sort(key=lambda c: (c['district'], c['number']))

    output = {
        'viewBox': viewbox,
        'count': len(constituencies),
        'constituencies': constituencies
    }

    with open(output_path, 'w') as f:
        json.dump(output, f, separators=(',', ':'))

    original_size = svg_path.stat().st_size / 1024
    output_size = output_path.stat().st_size / 1024

    print(f"Extracted {len(constituencies)} constituencies")
    print(f"Original points: {total_original:,}")
    print(f"Simplified points: {total_simplified:,}")
    print(f"Point reduction: {(1 - total_simplified/total_original)*100:.1f}%")
    print(f"Original SVG: {original_size:.1f} KB")
    print(f"Output JSON: {output_size:.1f} KB")
    print(f"Size reduction: {(1 - output_size/original_size)*100:.1f}%")


if __name__ == '__main__':
    main()
