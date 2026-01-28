#!/usr/bin/env python3
"""
Colorize the constituency SVG with distinct colors for each path.
"""
import re
import colorsys
import os

def generate_colors(n):
    """Generate n distinct colors using HSL color space."""
    colors = []
    for i in range(n):
        hue = i / n
        saturation = 0.55 + (i % 3) * 0.15  # 0.55-0.85
        lightness = 0.50 + (i % 5) * 0.08   # 0.50-0.82
        r, g, b = colorsys.hls_to_rgb(hue, lightness, saturation)
        colors.append(f'#{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}')
    return colors

def colorize_svg():
    input_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'election', 'nepal_constituencies.svg')

    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all path elements with IDs
    path_ids = re.findall(r'<path[^>]*\bid="([^"]+)"', content)
    print(f"Found {len(path_ids)} paths with IDs")

    # Generate colors
    colors = generate_colors(len(path_ids))
    color_map = dict(zip(path_ids, colors))

    # Add fill colors to paths
    def add_fill_to_path(match):
        path_tag = match.group(0)

        # Extract ID
        id_match = re.search(r'\bid="([^"]+)"', path_tag)
        if id_match:
            path_id = id_match.group(1)
            if path_id in color_map:
                color = color_map[path_id]

                # Remove existing fill and stroke styles
                path_tag = re.sub(r'\s*fill="[^"]*"', '', path_tag)
                path_tag = re.sub(r'\s*stroke="[^"]*"', '', path_tag)
                path_tag = re.sub(r'\s*stroke-width="[^"]*"', '', path_tag)

                # Also clean fill/stroke from style attribute if present
                def clean_style(style_match):
                    style = style_match.group(1)
                    style = re.sub(r'fill:[^;]+;?', '', style)
                    style = re.sub(r'stroke:[^;]+;?', '', style)
                    style = re.sub(r'stroke-width:[^;]+;?', '', style)
                    if style.strip():
                        return f'style="{style}"'
                    return ''
                path_tag = re.sub(r'style="([^"]*)"', clean_style, path_tag)

                # Add new fill and stroke before the closing
                if path_tag.endswith('/>'):
                    path_tag = path_tag[:-2] + f' fill="{color}" stroke="#444" stroke-width="0.5"/>'
                elif path_tag.endswith('>'):
                    path_tag = path_tag[:-1] + f' fill="{color}" stroke="#444" stroke-width="0.5">'

        return path_tag

    content = re.sub(r'<path[^>]+>', add_fill_to_path, content)

    with open(input_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Colorized SVG saved to {input_path}")
    print(f"Applied {len(color_map)} colors")

if __name__ == '__main__':
    colorize_svg()
