#!/usr/bin/env python3
"""
Final cleanup of constituency SVG:
1. Color remaining generic paths as light grey (these are extras)
2. Ensure all constituency paths have distinct colors
3. Report final statistics
"""
import re
import os
import colorsys

OFFICIAL_CONSTITUENCIES = {
    "taplejung-1", "panchthar-1", "ilam-1", "ilam-2", "jhapa-1", "jhapa-2",
    "jhapa-3", "jhapa-4", "morang-1", "morang-2", "morang-3", "morang-4",
    "morang-5", "morang-6", "sunsari-1", "sunsari-2", "sunsari-3", "sunsari-4",
    "sunsari-5", "dhankuta-1", "terhathum-1", "sankhuwasabha-1", "bhojpur-1",
    "bhojpur-2", "solukhumbu-1", "okhaldhunga-1", "khotang-1", "khotang-2",
    "udayapur-1", "udayapur-2",
    "saptari-1", "saptari-2", "saptari-3", "siraha-1", "siraha-2", "siraha-3",
    "siraha-4", "dhanusa-1", "dhanusa-2", "dhanusa-3", "dhanusa-4", "mahottari-1",
    "mahottari-2", "mahottari-3", "sarlahi-1", "sarlahi-2", "sarlahi-3", "sarlahi-4",
    "rautahat-1", "rautahat-2", "rautahat-3", "rautahat-4", "bara-1", "bara-2",
    "bara-3", "bara-4", "parsa-1", "parsa-2",
    "dolakha-1", "dolakha-2", "sindhupalchok-1", "sindhupalchok-2", "rasuwa-1",
    "dhading-1", "dhading-2", "nuwakot-1", "nuwakot-2", "kathmandu-1", "kathmandu-2",
    "kathmandu-3", "kathmandu-4", "kathmandu-5", "kathmandu-6", "kathmandu-7",
    "kathmandu-8", "kathmandu-9", "kathmandu-10", "bhaktapur-1", "bhaktapur-2",
    "lalitpur-1", "lalitpur-2", "lalitpur-3", "kavrepalanchok-1", "kavrepalanchok-2",
    "ramechhap-1", "ramechhap-2", "sindhuli-1", "sindhuli-2", "makwanpur-1",
    "makwanpur-2", "chitwan-1", "chitwan-2", "chitwan-3",
    "gorkha-1", "gorkha-2", "lamjung-1", "tanahun-1", "tanahun-2", "syangja-1",
    "syangja-2", "kaski-1", "kaski-2", "kaski-3", "manang-1", "mustang-1",
    "myagdi-1", "parbat-1", "baglung-1", "baglung-2", "nawalparasi_east-1",
    "nawalparasi_east-2",
    "rupandehi-1", "rupandehi-2", "rupandehi-3", "rupandehi-4", "kapilvastu-1",
    "kapilvastu-2", "kapilvastu-3", "palpa-1", "palpa-2", "arghakhanchi-1",
    "gulmi-1", "gulmi-2", "rolpa-1", "pyuthan-1", "rukum_east-1", "dang-1",
    "dang-2", "dang-3", "banke-1", "banke-2", "banke-3", "bardiya-1", "bardiya-2",
    "nawalparasi_west-1", "nawalparasi_west-2",
    "dolpa-1", "mugu-1", "humla-1", "jumla-1", "kalikot-1", "dailekh-1",
    "dailekh-2", "jajarkot-1", "rukum_west-1", "salyan-1", "salyan-2", "surkhet-1",
    "surkhet-2",
    "bajura-1", "bajhang-1", "darchula-1", "baitadi-1", "baitadi-2", "dadeldhura-1",
    "doti-1", "doti-2", "achham-1", "achham-2", "kailali-1", "kailali-2", "kailali-3",
    "kailali-4", "kanchanpur-1", "kanchanpur-2",
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


def finalize():
    input_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'election', 'nepal_constituencies.svg')

    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract all IDs
    path_pattern = re.compile(r'<path\s+([^>]+)/>')
    id_pattern = re.compile(r'\bid="([^"]+)"')

    all_ids = set()
    for match in path_pattern.finditer(content):
        attrs = match.group(1)
        id_match = id_pattern.search(attrs)
        if id_match:
            all_ids.add(id_match.group(1))

    # Categorize
    official_found = all_ids & OFFICIAL_CONSTITUENCIES
    generic_ids = {i for i in all_ids if re.match(r'^path\d+', i)}
    extra_ids = all_ids - OFFICIAL_CONSTITUENCIES - generic_ids

    print(f"Total paths: {len(all_ids)}")
    print(f"Official constituencies found: {len(official_found)}/165")
    print(f"Generic paths (extras): {len(generic_ids)}")
    print(f"Non-official constituency IDs: {len(extra_ids)}")

    missing = OFFICIAL_CONSTITUENCIES - official_found
    if missing:
        print(f"\nMissing official constituencies ({len(missing)}):")
        for m in sorted(missing):
            print(f"  - {m}")

    if extra_ids:
        print(f"\nNon-official constituency IDs:")
        for e in sorted(extra_ids):
            print(f"  - {e}")

    # Generate colors for official constituencies
    colors = generate_colors(165)
    color_map = dict(zip(sorted(OFFICIAL_CONSTITUENCIES), colors))

    # Colorize paths
    def colorize_path(match):
        path_content = match.group(1)

        id_match = re.search(r'\bid="([^"]+)"', path_content)
        if not id_match:
            return f'<path {path_content}/>'

        path_id = id_match.group(1)

        # Remove existing fill/style
        path_content = re.sub(r'\s*style="[^"]*"', '', path_content)
        path_content = re.sub(r'\s*fill="[^"]*"', '', path_content)

        if path_id in color_map:
            # Official constituency - use assigned color
            color = color_map[path_id]
            path_content = path_content.strip() + f' fill="{color}"'
        elif re.match(r'^path\d+', path_id):
            # Generic path - light grey, slightly transparent
            path_content = path_content.strip() + ' fill="#e0e0e0"'
        else:
            # Extra non-official constituency - yellow to mark as unusual
            path_content = path_content.strip() + ' fill="#ffcc00"'

        return f'<path {path_content}/>'

    content = re.sub(r'<path\s+([^>]+?)/>', colorize_path, content)

    # Ensure uniform strokes
    content = re.sub(r'\s*stroke="[^"]*"', '', content)
    content = re.sub(r'\s*stroke-width="[^"]*"', '', content)

    # Add stroke to all paths
    def add_stroke(match):
        path_content = match.group(1)
        if 'stroke=' not in path_content:
            path_content = path_content.strip() + ' stroke="#ffffff" stroke-width="0.5"'
        return f'<path {path_content}/>'

    content = re.sub(r'<path\s+([^>]+?)/>', add_stroke, content)

    with open(input_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"\nSaved finalized SVG to {input_path}")


if __name__ == '__main__':
    finalize()
