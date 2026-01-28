#!/usr/bin/env python3
"""
Identify generic paths by analyzing their positions and finding neighbors.
"""
import re
import os
import math

def get_path_bbox(path_d):
    """Extract bounding box from path data."""
    # Extract all coordinates
    coords = re.findall(r'[-+]?\d*\.?\d+', path_d)
    if len(coords) < 4:
        return None

    # Parse as pairs of x,y
    xs = []
    ys = []
    i = 0
    while i < len(coords) - 1:
        try:
            x = float(coords[i])
            y = float(coords[i+1])
            xs.append(x)
            ys.append(y)
            i += 2
        except:
            i += 1

    if not xs or not ys:
        return None

    return {
        'min_x': min(xs),
        'max_x': max(xs),
        'min_y': min(ys),
        'max_y': max(ys),
        'center_x': sum(xs) / len(xs),
        'center_y': sum(ys) / len(ys),
    }


def extract_all_paths(svg_content):
    """Extract all path IDs and their bounding boxes."""
    path_pattern = re.compile(r'<path\s+([^>]+)/>')
    id_pattern = re.compile(r'\bid="([^"]+)"')
    d_pattern = re.compile(r'\bd="([^"]+)"')

    paths = {}
    for match in path_pattern.finditer(svg_content):
        attrs = match.group(1)
        id_match = id_pattern.search(attrs)
        d_match = d_pattern.search(attrs)

        if id_match and d_match:
            path_id = id_match.group(1)
            path_d = d_match.group(1)
            bbox = get_path_bbox(path_d)
            if bbox:
                paths[path_id] = bbox

    return paths


def find_neighbors(target_bbox, all_paths, exclude_ids, max_distance=30):
    """Find paths that are close to the target."""
    neighbors = []
    tx, ty = target_bbox['center_x'], target_bbox['center_y']

    for pid, bbox in all_paths.items():
        if pid in exclude_ids:
            continue

        # Check if bounding boxes overlap or are close
        px, py = bbox['center_x'], bbox['center_y']
        dist = math.sqrt((tx - px)**2 + (ty - py)**2)

        if dist < max_distance:
            neighbors.append((pid, dist))

    return sorted(neighbors, key=lambda x: x[1])


def main():
    input_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'election', 'nepal_constituencies.svg')

    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()

    paths = extract_all_paths(content)

    # Identify generic paths
    generic_ids = set()
    constituency_ids = set()
    for pid in paths:
        if re.match(r'^path\d+', pid):
            generic_ids.add(pid)
        elif re.match(r'^[a-z_]+-\d+$', pid):
            constituency_ids.add(pid)

    print(f"Total paths: {len(paths)}")
    print(f"Generic paths: {len(generic_ids)}")
    print(f"Constituency paths: {len(constituency_ids)}")
    print()

    # Group generic paths by coordinate clusters
    print("=" * 60)
    print("GENERIC PATHS GROUPED BY LOCATION:")
    print("=" * 60)

    # Cluster by proximity
    clusters = []
    used = set()

    for gid in sorted(generic_ids):
        if gid in used:
            continue

        bbox = paths[gid]
        cluster = [gid]
        used.add(gid)

        # Find other generic paths nearby
        for other_gid in generic_ids:
            if other_gid in used:
                continue
            other_bbox = paths[other_gid]
            dist = math.sqrt((bbox['center_x'] - other_bbox['center_x'])**2 +
                           (bbox['center_y'] - other_bbox['center_y'])**2)
            if dist < 15:
                cluster.append(other_gid)
                used.add(other_gid)

        clusters.append(cluster)

    # Sort clusters by average position (west to east, north to south)
    def cluster_pos(cluster):
        avg_x = sum(paths[pid]['center_x'] for pid in cluster) / len(cluster)
        avg_y = sum(paths[pid]['center_y'] for pid in cluster) / len(cluster)
        return (avg_x, avg_y)

    clusters.sort(key=cluster_pos)

    for i, cluster in enumerate(clusters):
        bbox = paths[cluster[0]]
        avg_x = sum(paths[pid]['center_x'] for pid in cluster) / len(cluster)
        avg_y = sum(paths[pid]['center_y'] for pid in cluster) / len(cluster)

        print(f"\nCluster {i+1} at ({avg_x:.1f}, {avg_y:.1f}) - {len(cluster)} path(s):")
        print(f"  Paths: {', '.join(cluster)}")

        # Find neighboring constituencies
        neighbors = find_neighbors({'center_x': avg_x, 'center_y': avg_y},
                                   paths, generic_ids, max_distance=50)

        if neighbors:
            print(f"  Nearby constituencies:")
            for n, dist in neighbors[:8]:
                print(f"    - {n} (dist: {dist:.1f})")

    # Show missing constituencies for reference
    missing = {
        "baitadi-2", "bardiya-1", "bhaktapur-1", "bhaktapur-2", "bhojpur-2",
        "chitwan-3", "dolakha-2", "doti-2", "kanchanpur-2", "kathmandu-1",
        "kathmandu-10", "kathmandu-2", "kathmandu-3", "kathmandu-4", "kathmandu-5",
        "kathmandu-6", "kathmandu-7", "khotang-2", "ramechhap-2", "salyan-2", "sunsari-5"
    }

    print("\n" + "=" * 60)
    print("MISSING CONSTITUENCIES (21):")
    print("=" * 60)
    for m in sorted(missing):
        print(f"  - {m}")

    # Check which existing constituencies are near the expected locations
    print("\n" + "=" * 60)
    print("LOCATION ANALYSIS FOR MISSING CONSTITUENCIES:")
    print("=" * 60)

    # Find existing constituencies with same district name
    district_constituencies = {}
    for cid in constituency_ids:
        parts = cid.rsplit('-', 1)
        if len(parts) == 2:
            district = parts[0]
            num = int(parts[1])
            if district not in district_constituencies:
                district_constituencies[district] = []
            district_constituencies[district].append((cid, num, paths[cid]))

    # For each missing, show where existing ones are
    for m in sorted(missing):
        parts = m.rsplit('-', 1)
        district = parts[0]
        if district in district_constituencies:
            existing = district_constituencies[district]
            print(f"\n{m}:")
            print(f"  Existing {district} constituencies:")
            for cid, num, bbox in sorted(existing, key=lambda x: x[1]):
                print(f"    {cid}: center=({bbox['center_x']:.1f}, {bbox['center_y']:.1f})")

            # Find generic paths near this district
            avg_x = sum(e[2]['center_x'] for e in existing) / len(existing)
            avg_y = sum(e[2]['center_y'] for e in existing) / len(existing)

            nearby_generic = []
            for gid in generic_ids:
                gbbox = paths[gid]
                dist = math.sqrt((avg_x - gbbox['center_x'])**2 + (avg_y - gbbox['center_y'])**2)
                if dist < 80:
                    nearby_generic.append((gid, dist, gbbox))

            if nearby_generic:
                nearby_generic.sort(key=lambda x: x[1])
                print(f"  Nearby generic paths:")
                for gid, dist, gbbox in nearby_generic[:5]:
                    print(f"    {gid}: center=({gbbox['center_x']:.1f}, {gbbox['center_y']:.1f}), dist={dist:.1f}")


if __name__ == '__main__':
    main()
