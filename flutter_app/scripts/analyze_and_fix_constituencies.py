#!/usr/bin/env python3
"""
Analyze and fix constituency SVG:
1. Extract all path IDs
2. Fix spelling variations
3. Add -1 suffix to single-constituency districts
4. Identify generic paths and their neighbors
5. Colorize all paths
"""
import re
import os
import colorsys
from collections import defaultdict

# Official 165 constituencies
OFFICIAL_CONSTITUENCIES = {
    # Province 1
    "taplejung-1", "panchthar-1", "ilam-1", "ilam-2", "jhapa-1", "jhapa-2",
    "jhapa-3", "jhapa-4", "morang-1", "morang-2", "morang-3", "morang-4",
    "morang-5", "morang-6", "sunsari-1", "sunsari-2", "sunsari-3", "sunsari-4",
    "sunsari-5", "dhankuta-1", "terhathum-1", "sankhuwasabha-1", "bhojpur-1",
    "bhojpur-2", "solukhumbu-1", "okhaldhunga-1", "khotang-1", "khotang-2",
    "udayapur-1", "udayapur-2",
    # Province 2 (Madhesh)
    "saptari-1", "saptari-2", "saptari-3", "siraha-1", "siraha-2", "siraha-3",
    "siraha-4", "dhanusa-1", "dhanusa-2", "dhanusa-3", "dhanusa-4", "mahottari-1",
    "mahottari-2", "mahottari-3", "sarlahi-1", "sarlahi-2", "sarlahi-3", "sarlahi-4",
    "rautahat-1", "rautahat-2", "rautahat-3", "rautahat-4", "bara-1", "bara-2",
    "bara-3", "bara-4", "parsa-1", "parsa-2",
    # Province 3 (Bagmati)
    "dolakha-1", "dolakha-2", "sindhupalchok-1", "sindhupalchok-2", "rasuwa-1",
    "dhading-1", "dhading-2", "nuwakot-1", "nuwakot-2", "kathmandu-1", "kathmandu-2",
    "kathmandu-3", "kathmandu-4", "kathmandu-5", "kathmandu-6", "kathmandu-7",
    "kathmandu-8", "kathmandu-9", "kathmandu-10", "bhaktapur-1", "bhaktapur-2",
    "lalitpur-1", "lalitpur-2", "lalitpur-3", "kavrepalanchok-1", "kavrepalanchok-2",
    "ramechhap-1", "ramechhap-2", "sindhuli-1", "sindhuli-2", "makwanpur-1",
    "makwanpur-2", "chitwan-1", "chitwan-2", "chitwan-3",
    # Province 4 (Gandaki)
    "gorkha-1", "gorkha-2", "lamjung-1", "tanahun-1", "tanahun-2", "syangja-1",
    "syangja-2", "kaski-1", "kaski-2", "kaski-3", "manang-1", "mustang-1",
    "myagdi-1", "parbat-1", "baglung-1", "baglung-2", "nawalparasi_east-1",
    "nawalparasi_east-2",
    # Province 5 (Lumbini)
    "rupandehi-1", "rupandehi-2", "rupandehi-3", "rupandehi-4", "kapilvastu-1",
    "kapilvastu-2", "kapilvastu-3", "palpa-1", "palpa-2", "arghakhanchi-1",
    "gulmi-1", "gulmi-2", "rolpa-1", "pyuthan-1", "rukum_east-1", "dang-1",
    "dang-2", "dang-3", "banke-1", "banke-2", "banke-3", "bardiya-1", "bardiya-2",
    "nawalparasi_west-1", "nawalparasi_west-2",
    # Province 6 (Karnali)
    "dolpa-1", "mugu-1", "humla-1", "jumla-1", "kalikot-1", "dailekh-1",
    "dailekh-2", "jajarkot-1", "rukum_west-1", "salyan-1", "salyan-2", "surkhet-1",
    "surkhet-2",
    # Province 7 (Sudurpashchim)
    "bajura-1", "bajhang-1", "darchula-1", "baitadi-1", "baitadi-2", "dadeldhura-1",
    "doti-1", "doti-2", "achham-1", "achham-2", "kailali-1", "kailali-2", "kailali-3",
    "kailali-4", "kanchanpur-1", "kanchanpur-2",
}

# Spelling corrections mapping (wrong -> correct)
SPELLING_FIXES = {
    "kavre-1": "kavrepalanchok-1",
    "kavre-2": "kavrepalanchok-2",
    "makawanpur-1": "makwanpur-1",
    "makawanpur-2": "makwanpur-2",
    "tanahu-1": "tanahun-1",
    "tanahu-2": "tanahun-2",
    "pancthar-1": "panchthar-1",
    "pancthar": "panchthar-1",
    # Dhanusa spelling
    "dhanusha-1": "dhanusa-1",
    "dhanusha-2": "dhanusa-2",
    "dhanusha-3": "dhanusa-3",
    "dhanusha-4": "dhanusa-4",
    # Terhathum spelling
    "tehrathum": "terhathum-1",
    # Nawalparasi underscore vs hyphen
    "nawalparasi-east-1": "nawalparasi_east-1",
    "nawalparasi-east-2": "nawalparasi_east-2",
    "nawalparasi-west-1": "nawalparasi_west-1",
    "nawalparasi-west-2": "nawalparasi_west-2",
    # Rukum underscore and -1 suffix
    "rukum-east": "rukum_east-1",
    "rukum-west": "rukum_west-1",
    # Single-name districts that need fixes
    "baitadi": "baitadi-1",
    "bhojpur": "bhojpur-1",
    "dolakha": "dolakha-1",
    "doti": "doti-1",
    "khotang": "khotang-1",
    "lamjung": "lamjung-1",
    "ramechhap": "ramechhap-1",
    "rolpa": "rolpa-1",
    "salyan": "salyan-1",
    # Extra constituencies that don't exist - mark for removal
    # "jhapa-5": None,  # Only jhapa-1 to jhapa-4 exist
    # "kailali-5": None,
    # etc.
}

# Single-constituency districts that need -1 suffix
SINGLE_DISTRICTS = {
    "taplejung", "panchthar", "dhankuta", "terhathum", "sankhuwasabha",
    "solukhumbu", "okhaldhunga", "rasuwa", "manang", "mustang", "myagdi",
    "parbat", "arghakhanchi", "pyuthan", "dolpa", "mugu", "humla", "jumla",
    "kalikot", "jajarkot", "bajura", "bajhang", "darchula", "dadeldhura"
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


def extract_path_info(svg_content):
    """Extract all path IDs and their approximate bounding boxes."""
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

            # Extract first coordinates from path data to get approximate position
            coords = re.findall(r'[-+]?\d*\.?\d+', path_d[:500])
            if len(coords) >= 2:
                x = float(coords[0])
                y = float(coords[1])
                paths[path_id] = {'x': x, 'y': y, 'd': path_d[:100]}

    return paths


def analyze_svg():
    """Analyze the SVG and report issues."""
    input_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'election', 'nepal_constituencies.svg')

    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()

    paths = extract_path_info(content)

    print(f"Total paths found: {len(paths)}")
    print()

    # Categorize paths
    proper_ids = []
    generic_ids = []
    misspelled = []
    needs_suffix = []

    for path_id in paths:
        if path_id in SPELLING_FIXES:
            misspelled.append(path_id)
        elif path_id in SINGLE_DISTRICTS:
            needs_suffix.append(path_id)
        elif re.match(r'^[a-z_]+-\d+$', path_id):
            proper_ids.append(path_id)
        elif re.match(r'^[a-z_]+$', path_id):
            # Single word like "taplejung" without -1
            if path_id in SINGLE_DISTRICTS:
                needs_suffix.append(path_id)
            else:
                proper_ids.append(path_id)  # Might need investigation
        else:
            generic_ids.append(path_id)

    print(f"Proper constituency IDs: {len(proper_ids)}")
    print(f"Misspelled IDs to fix: {len(misspelled)} - {misspelled}")
    print(f"Need -1 suffix: {len(needs_suffix)} - {needs_suffix}")
    print(f"Generic IDs (need identification): {len(generic_ids)}")
    print()

    if generic_ids:
        print("Generic path IDs and their approximate positions:")
        for gid in sorted(generic_ids):
            info = paths[gid]
            print(f"  {gid}: x={info['x']:.1f}, y={info['y']:.1f}")

    print()

    # Check what's missing from official list
    current_ids = set()
    for pid in proper_ids:
        current_ids.add(pid)
    for old, new in SPELLING_FIXES.items():
        if old in misspelled:
            current_ids.add(new)
    for pid in needs_suffix:
        current_ids.add(f"{pid}-1")

    missing = OFFICIAL_CONSTITUENCIES - current_ids
    extra = current_ids - OFFICIAL_CONSTITUENCIES

    print(f"Missing from official list ({len(missing)}):")
    for m in sorted(missing):
        print(f"  {m}")

    print()
    print(f"Extra (not in official list) ({len(extra)}):")
    for e in sorted(extra):
        print(f"  {e}")

    return paths, generic_ids, misspelled, needs_suffix


def fix_svg():
    """Fix all issues in the SVG."""
    input_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'election', 'nepal_constituencies.svg')

    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 1. Fix spelling variations
    for old_id, new_id in SPELLING_FIXES.items():
        content = re.sub(f'id="{old_id}"', f'id="{new_id}"', content)
        print(f"Fixed spelling: {old_id} -> {new_id}")

    # 2. Add -1 suffix to single-constituency districts
    for district in SINGLE_DISTRICTS:
        # Match exact district name (not already suffixed)
        pattern = f'id="{district}"(?!-)'
        replacement = f'id="{district}-1"'
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            print(f"Added suffix: {district} -> {district}-1")

    # 3. Normalize all strokes to white
    content = re.sub(r'stroke="[^"]*"', 'stroke="#ffffff"', content)
    content = re.sub(r'stroke-width="[^"]*"', 'stroke-width="0.5"', content)

    # 4. Get all constituency IDs for coloring
    constituency_pattern = re.compile(r'\bid="([a-z_]+-\d+)"')
    constituency_ids = list(set(constituency_pattern.findall(content)))
    print(f"\nFound {len(constituency_ids)} constituency IDs to colorize")

    # 5. Generate and apply colors
    colors = generate_colors(len(constituency_ids))
    color_map = dict(zip(sorted(constituency_ids), colors))

    def colorize_path(match):
        path_content = match.group(1)

        id_match = re.search(r'\bid="([a-z_]+-\d+)"', path_content)
        if id_match:
            path_id = id_match.group(1)
            if path_id in color_map:
                color = color_map[path_id]
                # Remove existing fill from style
                path_content = re.sub(r'style="[^"]*fill:[^;"]*;?[^"]*"', '', path_content)
                path_content = re.sub(r'fill="[^"]*"', '', path_content)
                # Add new fill
                path_content = path_content.strip() + f' fill="{color}"'

        return f'<path {path_content}/>'

    content = re.sub(r'<path\s+([^>]+?)/>', colorize_path, content)

    # Save
    with open(input_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"\nSaved fixed SVG to {input_path}")

    # Report remaining generic paths
    generic_pattern = re.compile(r'\bid="(path\d+[^"]*)"')
    remaining_generic = generic_pattern.findall(content)
    if remaining_generic:
        print(f"\nRemaining generic paths ({len(remaining_generic)}): {remaining_generic[:10]}...")


if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == '--fix':
        fix_svg()
    else:
        analyze_svg()
        print("\nRun with --fix to apply fixes")
