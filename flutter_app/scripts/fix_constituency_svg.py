#!/usr/bin/env python3
"""
Fix constituency SVG by:
1. Removing svg: namespace prefixes (flutter_svg doesn't handle them well)
2. Adding distinct colors to each constituency path
3. Keeping all transforms intact
"""
import re
import colorsys
import os

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

def fix_constituency_svg():
    input_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'election', 'nepal_constituencies.svg')

    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove svg: namespace prefixes
    content = re.sub(r'<svg:', '<', content)
    content = re.sub(r'</svg:', '</', content)
    content = re.sub(r'<sodipodi:[^>]*/?>', '', content)
    content = re.sub(r'xmlns:svg="[^"]+"', '', content)
    content = re.sub(r'xmlns:sodipodi="[^"]+"', '', content)
    content = re.sub(r'xmlns:inkscape="[^"]+"', '', content)

    # Find all constituency path IDs (format: district-number like "kathmandu-1")
    constituency_pattern = re.compile(r'\bid="([a-z]+-\d+)"')
    constituency_ids = constituency_pattern.findall(content)
    print(f"Found {len(constituency_ids)} constituency paths")

    # Generate colors
    colors = generate_colors(len(constituency_ids))
    color_map = dict(zip(constituency_ids, colors))

    # Add fill colors to constituency paths
    # Match paths with constituency IDs and update their style
    def add_fill_to_path(match):
        path_content = match.group(1)

        # Check if this path has a constituency ID
        id_match = re.search(r'\bid="([a-z]+-\d+)"', path_content)
        if id_match:
            path_id = id_match.group(1)
            if path_id in color_map:
                color = color_map[path_id]
                # Remove existing fill from style attribute
                path_content = re.sub(r'fill:[^;]+;?', '', path_content)
                path_content = re.sub(r'fill="[^"]*"', '', path_content)
                # Add new fill attribute
                path_content = path_content.rstrip() + f' fill="{color}" stroke="#333" stroke-width="0.3"'

        return f'<path {path_content}/>'

    # Process all path elements
    content = re.sub(r'<path\s+([^>]+?)/>', add_fill_to_path, content)

    with open(input_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Fixed SVG saved to {input_path}")
    print(f"Colored {len(color_map)} constituency paths")

if __name__ == '__main__':
    fix_constituency_svg()
