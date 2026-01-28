#!/usr/bin/env python3
"""
Colorize remaining grey paths to match their nearest constituency neighbor.
"""
import re
import os
import math

def get_path_center(path_d):
    """Get approximate center from path data."""
    coords = re.findall(r'[-+]?\d*\.?\d+', path_d[:1000])
    if len(coords) < 4:
        return None

    xs, ys = [], []
    i = 0
    while i < len(coords) - 1:
        try:
            xs.append(float(coords[i]))
            ys.append(float(coords[i+1]))
            i += 2
        except:
            i += 1

    if not xs:
        return None
    return (sum(xs)/len(xs), sum(ys)/len(ys))


def extract_paths_with_colors(content):
    """Extract path info including current fill color."""
    path_pattern = re.compile(r'<path\s+([^>]+)/>')
    id_pattern = re.compile(r'\bid="([^"]+)"')
    d_pattern = re.compile(r'\bd="([^"]+)"')
    fill_pattern = re.compile(r'fill="([^"]+)"')

    paths = {}
    for match in path_pattern.finditer(content):
        attrs = match.group(1)
        id_match = id_pattern.search(attrs)
        d_match = d_pattern.search(attrs)
        fill_match = fill_pattern.search(attrs)

        if id_match and d_match:
            path_id = id_match.group(1)
            center = get_path_center(d_match.group(1))
            fill = fill_match.group(1) if fill_match else None
            if center:
                paths[path_id] = {
                    'center': center,
                    'fill': fill
                }
    return paths


def find_nearest_colored(target_center, paths):
    """Find the nearest path with a proper color (not grey/yellow)."""
    tx, ty = target_center
    best_dist = float('inf')
    best_color = None

    for pid, info in paths.items():
        fill = info['fill']
        # Skip grey, yellow, and paths without fill
        if not fill or fill in ['#e0e0e0', '#ffcc00', '#cccccc']:
            continue

        px, py = info['center']
        dist = math.sqrt((tx - px)**2 + (ty - py)**2)
        if dist < best_dist:
            best_dist = dist
            best_color = fill

    return best_color


def colorize_remaining():
    input_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'election', 'nepal_constituencies.svg')

    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()

    paths = extract_paths_with_colors(content)

    # Find paths that need colorization (grey or yellow)
    needs_color = {}
    for pid, info in paths.items():
        if info['fill'] in ['#e0e0e0', '#ffcc00', '#cccccc', None]:
            needs_color[pid] = info

    print(f"Found {len(needs_color)} paths needing colorization")

    # Map each to nearest colored neighbor
    color_assignments = {}
    for pid, info in needs_color.items():
        nearest_color = find_nearest_colored(info['center'], paths)
        if nearest_color:
            color_assignments[pid] = nearest_color
            print(f"  {pid} -> {nearest_color}")

    # Apply colors
    def apply_color(match):
        path_content = match.group(1)
        id_match = re.search(r'\bid="([^"]+)"', path_content)

        if id_match:
            path_id = id_match.group(1)
            if path_id in color_assignments:
                # Remove old fill and add new one
                path_content = re.sub(r'\s*fill="[^"]*"', '', path_content)
                path_content = path_content.strip() + f' fill="{color_assignments[path_id]}"'

        return f'<path {path_content}/>'

    content = re.sub(r'<path\s+([^>]+?)/>', apply_color, content)

    with open(input_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"\nColorized {len(color_assignments)} paths")
    print(f"Saved to {input_path}")


if __name__ == '__main__':
    colorize_remaining()
