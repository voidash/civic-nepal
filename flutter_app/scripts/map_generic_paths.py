#!/usr/bin/env python3
"""
Map generic paths to constituency names based on coordinate analysis.
Also fix extra/invalid constituency IDs.
"""
import re
import os
import colorsys

# Mapping based on coordinate analysis:
# Cluster 9/10 (Kathmandu valley area, x~305-320, y~220-240):
# 10 paths in this area for 9 missing Kathmandu constituencies + 2 bhaktapur
# We need: kathmandu-1 to 7, bhaktapur-1, bhaktapur-2

# Invalid IDs that don't exist officially (need to be removed or renamed)
INVALID_IDS = {
    "kanchanpur-3",  # Only 1 and 2 exist - keep as is, might be drawing error
    "jhapa-5",       # Only 1-4 exist
    "kailali-5",     # Only 1-4 exist
    "mahottari-4",   # Only 1-3 exist
    "parsa-3",       # Only 1-2 exist
    "parsa-4",       # Only 1-2 exist
    "rupandehi-5",   # Only 1-4 exist
    "saptari-4",     # Only 1-3 exist
}

# Based on coordinate proximity analysis, map generic paths to constituencies
# These are best-effort mappings based on position relative to known constituencies
PATH_MAPPINGS = {
    # Kathmandu Valley cluster (x~305-320, y~228-240)
    # We have paths 80-88, 23, 24 in this area - 11 paths
    # Need: kathmandu-1 to kathmandu-7 (7) + bhaktapur-1, bhaktapur-2 (2) = 9
    # Also need kathmandu-10 and maybe dolakha-2
    "path80": "kathmandu-1",
    "path81": "kathmandu-2",
    "path82": "kathmandu-3",
    "path83": "kathmandu-4",
    "path84": "kathmandu-5",
    "path85": "kathmandu-6",
    "path87": "kathmandu-7",
    "path88": "kathmandu-10",
    "path23": "bhaktapur-1",
    "path24": "bhaktapur-2",

    # Upper valley cluster (x~313-318, y~216-228)
    "path187": "dolakha-2",
    "path188": "ramechhap-2",

    # Kanchanpur area (x~40-50, y~156-170)
    # kanchanpur-3 doesn't exist officially, one of these should be kanchanpur-2
    "path196": "kanchanpur-2",
    # path71, path72 might be extras or baitadi-2

    # Achham/Doti/Baitadi area (x~85-90, y~132-140)
    "path176": "baitadi-2",
    "path177": "doti-2",
    # path178, path184 might be extras

    # Banke/Bardiya area (x~93-120, y~190-206)
    "path192": "bardiya-1",
    "path20": "salyan-2",
    # path21 might be extra

    # Rupandehi area (x~200, y~247)
    # path189 is very close to rupandehi-4, might be an extra

    # Chitwan area (x~250-280, y~240-255)
    "path28": "chitwan-3",
    # path181, path186 might be extras related to nawalparasi

    # Makwanpur/Parsa area (x~275-290, y~250-260)
    # path182, path183, path193, path194 - some might be chitwan-3 or extras
    # path197 is near bara/parsa

    # Myagdi/Baglung area (x~180-200, y~170-185) - these are extras/protected areas
    # path179, path180, path195 are in this region

    # Sunsari/Eastern area (x~398-402, y~293-298)
    "path185": "sunsari-5",
    "path190": "khotang-2",
    "path191": "bhojpur-2",
    # path190, path191 might be extras

    # Remaining paths that might be protected areas or boundary elements
    # path71, path72 - Kanchanpur area extras
    # path178, path184 - Achham area extras
    # path21 - Bardiya area extra
    # path181, path186, path29 - Chitwan area extras
    # path182, path183, path193, path194 - Makwanpur area extras
    # path189 - Rupandehi area extra
    # path190, path191 - Sunsari area extras
    # path195 - Myagdi area extra
    # path197 - Bara/Parsa area extra
}


def generate_colors(n):
    """Generate n distinct colors using HSL color space."""
    colors = []
    for i in range(n):
        hue = i / n
        saturation = 0.65 + (i % 3) * 0.1
        lightness = 0.55 + (i % 5) * 0.05
        r, g, b = colorsys.hls_to_rgb(hue, lightness, saturation)
        colors.append(f'#{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}')
    return colors


def apply_mappings():
    input_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'election', 'nepal_constituencies.svg')

    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Apply path mappings
    for old_id, new_id in PATH_MAPPINGS.items():
        pattern = f'id="{old_id}"'
        replacement = f'id="{new_id}"'
        if pattern in content:
            content = content.replace(pattern, replacement)
            print(f"Mapped: {old_id} -> {new_id}")
        else:
            print(f"Not found: {old_id}")

    # Remove/mark invalid constituencies
    # For now, we'll keep them but with a distinct style so they're visible as "extra"

    # Get all constituency IDs for coloring
    constituency_pattern = re.compile(r'\bid="([a-z_]+-\d+)"')
    constituency_ids = list(set(constituency_pattern.findall(content)))
    print(f"\nFound {len(constituency_ids)} constituency IDs")

    # Generate colors
    colors = generate_colors(len(constituency_ids))
    color_map = dict(zip(sorted(constituency_ids), colors))

    # Colorize all paths
    def colorize_path(match):
        path_content = match.group(1)

        id_match = re.search(r'\bid="([a-z_]+-\d+)"', path_content)
        if id_match:
            path_id = id_match.group(1)
            if path_id in color_map:
                color = color_map[path_id]
                # Remove existing fill
                path_content = re.sub(r'style="[^"]*"', '', path_content)
                path_content = re.sub(r'fill="[^"]*"', '', path_content)
                # Add new fill
                path_content = path_content.strip() + f' fill="{color}"'
        else:
            # Generic path without proper ID - color grey
            path_content = re.sub(r'style="[^"]*"', '', path_content)
            path_content = re.sub(r'fill="[^"]*"', '', path_content)
            path_content = path_content.strip() + ' fill="#cccccc"'

        return f'<path {path_content}/>'

    content = re.sub(r'<path\s+([^>]+?)/>', colorize_path, content)

    # Normalize strokes
    content = re.sub(r'stroke="[^"]*"', 'stroke="#ffffff"', content)
    content = re.sub(r'stroke-width="[^"]*"', 'stroke-width="0.5"', content)

    with open(input_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"\nSaved to {input_path}")

    # Report remaining issues
    remaining_generic = re.findall(r'\bid="(path\d+)"', content)
    if remaining_generic:
        print(f"\nRemaining generic paths ({len(remaining_generic)}): {remaining_generic}")


if __name__ == '__main__':
    apply_mappings()
