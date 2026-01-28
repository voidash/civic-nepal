#!/usr/bin/env python3
"""
Scraper to combine:
1. Wikipedia SVG constituency map (boundaries)
2. Ratemyneta API (candidate data)

Creates a unified dataset for the Flutter app.

Usage:
    python scrape_constituencies.py

Output:
    - assets/data/election/constituencies.json
    - assets/data/election/constituency_map.svg (cleaned)
"""

import json
import re
import time
import random
from pathlib import Path
from dataclasses import dataclass, asdict, field
from typing import Optional
from bs4 import BeautifulSoup
import requests
from xml.etree import ElementTree as ET


# Configuration
SCRIPT_DIR = Path(__file__).parent
ASSETS_DIR = SCRIPT_DIR.parent / "assets"
OUTPUT_DIR = ASSETS_DIR / "data" / "election"

HEADERS = {
    'accept': 'application/json',
    'user-agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36',
}

WIKIPEDIA_SVG_URL = "https://upload.wikimedia.org/wikipedia/commons/f/f4/Nepal_Constituency_Map.svg"
RATEMYNETA_API = "https://api.ratemyneta.com/api/election"


@dataclass
class Candidate:
    """Election candidate"""
    id: str
    name: str
    party: str
    partySymbol: str = ""
    imageUrl: str = ""
    votes: int = 0


@dataclass
class Constituency:
    """Federal election constituency"""
    id: str
    name: str  # e.g., "Kathmandu-1"
    number: int
    district: str
    districtId: str
    province: int
    svgPathId: str = ""
    candidates: list[Candidate] = field(default_factory=list)


@dataclass
class ConstituencyData:
    """All constituency data"""
    version: str
    source: str
    totalConstituencies: int
    constituencies: dict  # district -> list of constituencies


def normalize_constituency_name(label: str) -> tuple[str, int]:
    """Convert SVG label to district name and number.
    'Ilam 1' -> ('Ilam', 1)
    'Dhankuta' -> ('Dhankuta', 1)
    """
    # Handle numbered constituencies
    match = re.match(r'^(.+?)\s*(\d+)$', label.strip())
    if match:
        return match.group(1).strip(), int(match.group(2))
    # Single constituency districts
    return label.strip(), 1


def fetch_svg() -> str:
    """Fetch Wikipedia SVG (or use local cache)"""
    cache_file = Path("/tmp/nepal_constituency.svg")

    # Use cache if exists
    if cache_file.exists():
        print("Using cached Wikipedia SVG...")
        return cache_file.read_text()

    print("Fetching Wikipedia constituency SVG...")
    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'image/svg+xml,*/*',
    }
    response = requests.get(WIKIPEDIA_SVG_URL, headers=headers, timeout=30)
    response.raise_for_status()

    # Cache for future use
    cache_file.write_text(response.text)
    return response.text


def parse_svg(svg_content: str) -> dict[str, dict]:
    """Parse SVG and extract constituency paths with labels"""
    # Parse SVG
    soup = BeautifulSoup(svg_content, 'lxml-xml')

    constituencies = {}

    # Find all groups with inkscape:label
    ns = {
        'inkscape': 'http://www.inkscape.org/namespaces/inkscape',
        'svg': 'http://www.w3.org/2000/svg'
    }

    # Find all elements with inkscape:label
    for elem in soup.find_all(attrs={'inkscape:label': True}):
        label = elem.get('inkscape:label', '')

        # Skip non-constituency labels
        if label in ['Protected Areas', 'Koshi', 'Bagmati', 'Gandaki', 'Lumbini', 'Karnali', 'Sudurpashchim', 'Madhesh']:
            continue

        # Get path data - element can be a path directly or a group containing a path
        if elem.name == 'path':
            path = elem
        else:
            path = elem.find('path')

        if path:
            path_d = path.get('d', '')
            path_id = path.get('id', '')

            district, number = normalize_constituency_name(label)
            const_name = f"{district}-{number}"

            constituencies[const_name] = {
                'label': label,
                'district': district,
                'number': number,
                'pathId': path_id,
                'pathD': path_d,
            }

    return constituencies


def fetch_ratemyneta_data() -> dict:
    """Fetch all constituency and candidate data from ratemyneta"""
    cache_file = Path("/tmp/ratemyneta_constituencies.json")

    # Use cache if exists
    if cache_file.exists():
        print("Using cached ratemyneta data...")
        with open(cache_file, 'r', encoding='utf-8') as f:
            return json.load(f)

    print("Fetching ratemyneta data...")

    all_data = {}

    # Get provinces
    provinces_url = f"{RATEMYNETA_API}/provinces"
    resp = requests.get(provinces_url, headers=HEADERS, timeout=30)
    provinces = resp.json()['data']

    for province_name in provinces:
        print(f"  Province: {province_name}")

        # Get districts for this province
        districts_url = f"{RATEMYNETA_API}/provinces/{province_name}/districts"
        resp = requests.get(districts_url, headers=HEADERS, timeout=30)
        districts = resp.json()['data']

        for district in districts:
            district_name = district['name']
            district_id = district['_id']
            province_num = list(provinces).index(province_name) + 1

            # Get constituencies for this district
            const_url = f"{RATEMYNETA_API}/districts/{district_id}/constituencies"
            resp = requests.get(const_url, headers=HEADERS, timeout=30)
            constituencies = resp.json()['data']

            for const in constituencies:
                const_name = const['name']  # e.g., "Kathmandu-1"
                const_id = const['_id']
                const_number = const.get('number', 1)

                # Get candidates for this constituency
                cand_url = f"{RATEMYNETA_API}/constituencies/{const_id}/candidates"
                try:
                    resp = requests.get(cand_url, headers=HEADERS, timeout=30)
                    candidates_raw = resp.json()['data']
                except Exception:
                    candidates_raw = []

                candidates = []
                for c in candidates_raw:
                    cand_info = c.get('candidate') or c.get('leader', {})
                    party_info = c.get('partyId', {})

                    if cand_info:
                        candidates.append({
                            'id': c.get('_id', ''),
                            'name': cand_info.get('name', ''),
                            'party': c.get('party', ''),
                            'partySymbol': party_info.get('partyElectionSymbol', '') if isinstance(party_info, dict) else '',
                            'imageUrl': cand_info.get('imageUrl', ''),
                            'votes': c.get('votes', 0),
                        })

                all_data[const_name] = {
                    'id': const_id,
                    'name': const_name,
                    'number': const_number,
                    'district': district_name,
                    'districtId': district_id,
                    'province': province_num,
                    'candidates': candidates,
                }

            # Rate limiting
            time.sleep(0.2)

    # Cache for future use
    with open(cache_file, 'w', encoding='utf-8') as f:
        json.dump(all_data, f, ensure_ascii=False, indent=2)

    return all_data


def merge_data(svg_data: dict, api_data: dict) -> dict:
    """Merge SVG paths with API candidate data"""
    merged = {}

    # SVG to API spelling corrections
    svg_spelling_map = {
        'kavre': 'kavrepalanchok',
        'tanahu': 'tanahun',
        'makawanpur': 'makwanpur',
        'pancthar': 'panchthar',
        'tehrathum': 'terhathum',
        'kathmandu-valley': 'kathmandu',  # Special case
    }

    # Normalize names for matching
    def normalize(name):
        normalized = name.lower().replace(' ', '-').replace('--', '-')
        # Apply spelling corrections
        for wrong, correct in svg_spelling_map.items():
            if normalized.startswith(wrong + '-'):
                normalized = normalized.replace(wrong, correct, 1)
        return normalized

    svg_lookup = {normalize(k): v for k, v in svg_data.items()}

    for const_name, api_info in api_data.items():
        normalized = normalize(const_name)

        # Find matching SVG data
        svg_info = svg_lookup.get(normalized, {})

        merged[const_name] = {
            **api_info,
            'svgPathId': svg_info.get('pathId', ''),
            'svgPathD': svg_info.get('pathD', ''),
        }

    # Report unmatched
    unmatched_svg = set(svg_lookup.keys()) - {normalize(k) for k in api_data.keys()}
    if unmatched_svg:
        print(f"\nUnmatched SVG constituencies: {len(unmatched_svg)}")
        for name in sorted(unmatched_svg)[:10]:
            print(f"  - {name}")

    return merged


def create_clean_svg(svg_content: str, merged_data: dict, output_path: Path):
    """Create a cleaned SVG with proper IDs for Flutter"""
    soup = BeautifulSoup(svg_content, 'lxml-xml')

    # Update path IDs to match constituency names
    for elem in soup.find_all(attrs={'inkscape:label': True}):
        label = elem.get('inkscape:label', '')
        district, number = normalize_constituency_name(label)
        const_name = f"{district}-{number}"

        # Element can be a path directly or a group containing a path
        if elem.name == 'path':
            path = elem
        else:
            path = elem.find('path')

        if path:
            # Set ID to normalized constituency name
            new_id = const_name.lower().replace(' ', '-')
            path['id'] = new_id

    # Remove inkscape-specific attributes for cleaner SVG
    for elem in soup.find_all(True):
        attrs_to_remove = [k for k in elem.attrs if k.startswith('inkscape:') or k.startswith('sodipodi:')]
        for attr in attrs_to_remove:
            del elem[attr]

    # Save cleaned SVG
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(str(soup))

    print(f"Saved cleaned SVG to {output_path}")


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("Constituency Data Scraper")
    print("Combining Wikipedia SVG + Ratemyneta API")
    print("=" * 60)
    print()

    # Fetch SVG
    svg_content = fetch_svg()
    svg_data = parse_svg(svg_content)
    print(f"Found {len(svg_data)} constituencies in SVG")

    # Fetch API data
    api_data = fetch_ratemyneta_data()
    print(f"Found {len(api_data)} constituencies in ratemyneta")

    # Merge
    merged = merge_data(svg_data, api_data)
    print(f"Merged: {len(merged)} constituencies")

    # Group by district
    by_district = {}
    for const_name, data in merged.items():
        district = data['district']
        if district not in by_district:
            by_district[district] = []
        by_district[district].append(data)

    # Sort constituencies within each district
    for district in by_district:
        by_district[district].sort(key=lambda x: x['number'])

    # Save JSON
    output_data = {
        'version': '1.0',
        'source': 'Wikipedia SVG + ratemyneta.com API',
        'scraped_at': time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
        'totalConstituencies': len(merged),
        'districts': by_district,
    }

    json_path = OUTPUT_DIR / 'constituencies.json'
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)
    print(f"\nSaved data to {json_path}")

    # Create cleaned SVG
    svg_path = OUTPUT_DIR / 'nepal_constituencies.svg'
    create_clean_svg(svg_content, merged, svg_path)

    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    total_candidates = sum(len(c['candidates']) for c in merged.values())
    print(f"Total constituencies: {len(merged)}")
    print(f"Total districts: {len(by_district)}")
    print(f"Total candidates: {total_candidates}")


if __name__ == "__main__":
    main()
