#!/usr/bin/env python3
"""
Clean up the constituency SVG to keep only constituency paths.
Removes:
- svg: namespace prefixes (flutter_svg doesn't handle them)
- layer12 (protected areas)
- All paths that don't match constituency pattern (district-number)
- Kathmandu inset elements
Adds:
- Distinct colors to each constituency
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

def clean_constituency_svg():
    input_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'election', 'nepal_constituencies.svg')

    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove svg: namespace prefixes
    content = re.sub(r'<svg:', '<', content)
    content = re.sub(r'</svg:', '</', content)
    content = re.sub(r'xmlns:svg="[^"]+"', '', content)
    content = re.sub(r'xmlns:sodipodi="[^"]+"', '', content)
    content = re.sub(r'xmlns:inkscape="[^"]+"', '', content)
    content = re.sub(r'<sodipodi:[^>]*/?>', '', content)

    # Remove all non-constituency paths
    # Constituency IDs match pattern: lowercase-letters followed by dash and digits
    def keep_constituency_paths(match):
        path_content = match.group(1)
        id_match = re.search(r'\bid="([^"]+)"', path_content)
        if id_match:
            path_id = id_match.group(1)
            # Keep only paths that match constituency pattern (e.g., "jhapa-1", "kathmandu-3")
            if re.match(r'^[a-z]+-\d+$', path_id):
                return match.group(0)  # Keep this path
        # Remove this path (protected areas, inset duplicate paths, etc.)
        return ''

    content = re.sub(r'<path\s+([^>]+?)/>', keep_constituency_paths, content)

    # Keep transforms on groups - they position the constituencies correctly

    # Remove empty g elements
    for _ in range(5):  # Multiple passes to clean nested empty groups
        content = re.sub(r'<g[^>]*>\s*</g>', '', content)

    # Now find all remaining constituency paths and add colors
    constituency_pattern = re.compile(r'\bid="([a-z]+-\d+)"')
    constituency_ids = constituency_pattern.findall(content)
    print(f"Found {len(constituency_ids)} constituency paths after cleanup")

    # Generate colors
    colors = generate_colors(len(constituency_ids))
    color_map = dict(zip(constituency_ids, colors))

    # Add fill colors to constituency paths
    def add_fill_to_path(match):
        path_content = match.group(1)

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

    content = re.sub(r'<path\s+([^>]+?)/>', add_fill_to_path, content)

    # Clean up excessive whitespace
    content = re.sub(r'\n\s*\n', '\n', content)
    content = re.sub(r'  +', ' ', content)

    with open(input_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Cleaned SVG saved to {input_path}")
    print(f"Colored {len(color_map)} constituency paths")

    # Verify by checking what's left
    with open(input_path, 'r', encoding='utf-8') as f:
        final_content = f.read()

    remaining_paths = len(re.findall(r'<path\s', final_content))
    print(f"Total paths remaining: {remaining_paths}")

if __name__ == '__main__':
    clean_constituency_svg()
