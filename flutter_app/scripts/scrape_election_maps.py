#!/usr/bin/env python3
"""
Scraper for election.ekantipur.com local body maps and data.
Extracts SVG maps for each district showing municipalities/gaunpalikas.

Usage:
    python scrape_election_maps.py

Output:
    - assets/data/election/local_bodies.json: Metadata for all local bodies
    - assets/data/election/districts/{district_id}.svg: SVG map for each district
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


# Configuration
SCRIPT_DIR = Path(__file__).parent
ASSETS_DIR = SCRIPT_DIR.parent / "assets"
DISTRICTS_JSON = ASSETS_DIR / "data" / "districts.json"
OUTPUT_DIR = ASSETS_DIR / "data" / "election"
SVG_DIR = OUTPUT_DIR / "districts"

HEADERS = {
    'accept': 'text/html,application/xhtml+xml',
    'accept-language': 'en-US,en;q=0.6',
    'user-agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36',
}

BASE_URL = "https://election.ekantipur.com"

# Province URL mapping - all use pradesh-{number} format
PROVINCE_URLS = {
    1: "pradesh-1",
    2: "pradesh-2",
    3: "pradesh-3",
    4: "pradesh-4",
    5: "pradesh-5",
    6: "pradesh-6",
    7: "pradesh-7",
}

# Special URL slug mappings where ekantipur uses different spelling
URL_SLUG_OVERRIDES = {
    "ilam": "illam",
    "kavrepalanchok": "kavrepalanchowk",
    "sindhupalchok": "sindhupalchowk",
    "tanahu": "tanahun",
    "nawalparasi (bardaghat susta east)": "nawalparasi-east",
    "nawalparasi (bardaghat susta west)": "nawalparasi-west",
}


@dataclass
class LocalBody:
    """A local body (municipality or gaunpalika)"""
    id: str
    name: str
    district: str
    province: int


@dataclass
class DistrictMapData:
    """District with its local bodies and SVG info"""
    id: str
    name: str
    nameNp: str
    province: int
    localBodies: list[LocalBody] = field(default_factory=list)
    svgViewBox: str = ""
    hasSvg: bool = False


def district_to_url_slug(district_key: str) -> str:
    """Convert district key to URL slug for ekantipur"""
    # Check for explicit override first
    if district_key.lower() in URL_SLUG_OVERRIDES:
        return URL_SLUG_OVERRIDES[district_key.lower()]

    # Default: lowercase, remove parentheses, replace spaces with hyphens
    slug = district_key.lower()
    slug = re.sub(r'\s*\([^)]*\)', '', slug)
    slug = slug.replace(" ", "-").replace("_", "-")
    return slug


def fetch_district_page(province: int, district_slug: str, lang: str = "eng") -> Optional[str]:
    """Fetch district page HTML"""
    province_url = PROVINCE_URLS.get(province)
    if not province_url:
        return None

    url = f"{BASE_URL}/{province_url}/district-{district_slug}?lng={lang}"
    try:
        response = requests.get(url, headers=HEADERS, timeout=30)
        response.raise_for_status()
        return response.text
    except requests.RequestException as e:
        print(f"    Error fetching {url}: {e}")
        return None


def parse_district_page(html: str, district_key: str, district_info: dict) -> Optional[DistrictMapData]:
    """Parse district page and extract SVG + local bodies"""
    soup = BeautifulSoup(html, 'html.parser')

    # Find the SVG element
    svg = soup.find('svg')
    if not svg:
        return None

    # Extract viewBox
    viewbox = svg.get('viewBox', '') or ""
    if isinstance(viewbox, list):
        viewbox = viewbox[0] if viewbox else ""

    # Extract local bodies from paths with IDs
    local_bodies = []
    for path in svg.find_all('path'):
        path_id = path.get('id')
        if path_id and path_id not in ['location_map', '']:
            if isinstance(path_id, list):
                path_id = path_id[0]
            # Convert ID to readable name
            lb_name = path_id.replace("_", " ").replace("-", " ").title()

            local_body = LocalBody(
                id=str(path_id),
                name=lb_name,
                district=district_info['name'],
                province=district_info['province']
            )
            local_bodies.append(local_body)

    district = DistrictMapData(
        id=district_key,
        name=district_info['name'],
        nameNp=district_info.get('nameNp', ''),
        province=district_info['province'],
        localBodies=local_bodies,
        svgViewBox=str(viewbox),
        hasSvg=True
    )

    # Save SVG file
    save_svg(district_key, svg)

    return district


def save_svg(district_id: str, svg_element) -> None:
    """Save SVG element to file"""
    SVG_DIR.mkdir(parents=True, exist_ok=True)

    svg_str = str(svg_element)

    # Remove pt units for better Flutter compatibility
    svg_str = re.sub(r'width="([0-9.]+)pt"', r'width="\1"', svg_str)
    svg_str = re.sub(r'height="([0-9.]+)pt"', r'height="\1"', svg_str)

    svg_path = SVG_DIR / f"{district_id}.svg"
    with open(svg_path, 'w', encoding='utf-8') as f:
        f.write(svg_str)


def scrape_all():
    """Main scraping function"""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    SVG_DIR.mkdir(parents=True, exist_ok=True)

    # Load existing districts data
    if not DISTRICTS_JSON.exists():
        print(f"Error: {DISTRICTS_JSON} not found")
        return

    with open(DISTRICTS_JSON, 'r', encoding='utf-8') as f:
        districts_data = json.load(f)

    print(f"Loaded {len(districts_data)} districts from {DISTRICTS_JSON}")

    # Progress tracking
    progress_file = OUTPUT_DIR / ".scraper_progress.json"
    completed = set()

    if progress_file.exists():
        with open(progress_file, 'r') as f:
            progress = json.load(f)
            completed = set(progress.get('completed', []))
            print(f"Resuming. Already completed: {len(completed)} districts")

    all_results = []
    total = len(districts_data)

    for idx, (district_key, district_info) in enumerate(districts_data.items(), 1):
        if district_key in completed:
            print(f"[{idx}/{total}] Skipping {district_info['name']} (already done)")
            continue

        print(f"[{idx}/{total}] Fetching {district_info['name']} (Province {district_info['province']})...")

        # Generate URL slug
        slug = district_to_url_slug(district_key)

        # Fetch the page
        html = fetch_district_page(district_info['province'], slug)
        if not html:
            print(f"    Failed to fetch - trying alternate slug...")
            # Try alternate slug formats
            alt_slug = district_info['name'].lower().replace(" ", "-")
            html = fetch_district_page(district_info['province'], alt_slug)

        if not html:
            print(f"    Skipping - could not fetch page")
            continue

        # Parse and extract data
        result = parse_district_page(html, district_key, district_info)
        if result:
            all_results.append(result)
            print(f"    Found {len(result.localBodies)} local bodies")
            completed.add(district_key)
        else:
            print(f"    No SVG found on page")

        # Save progress
        with open(progress_file, 'w') as f:
            json.dump({'completed': list(completed)}, f)

        # Rate limiting - be nice to the server
        time.sleep(0.5 + random.random() * 0.5)

    # Save final output
    output_data = {
        "version": "1.0",
        "source": "election.ekantipur.com",
        "scraped_at": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
        "totalDistricts": len(all_results),
        "totalLocalBodies": sum(len(d.localBodies) for d in all_results),
        "districts": {d.id: asdict(d) for d in all_results}
    }

    output_file = OUTPUT_DIR / "local_bodies.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)

    print(f"\nSaved {len(all_results)} districts to {output_file}")
    print(f"Saved {len(all_results)} SVG files to {SVG_DIR}")

    # Cleanup progress file on success
    if len(all_results) == total:
        progress_file.unlink(missing_ok=True)

    # Summary by province
    print("\n" + "=" * 60)
    print("SUMMARY BY PROVINCE")
    print("=" * 60)
    for prov in range(1, 8):
        prov_districts = [d for d in all_results if d.province == prov]
        prov_lbs = sum(len(d.localBodies) for d in prov_districts)
        print(f"Province {prov}: {len(prov_districts)} districts, {prov_lbs} local bodies")


if __name__ == "__main__":
    print("=" * 60)
    print("Ekantipur Election Maps Scraper")
    print("Extracting local body SVG maps for all 77 districts")
    print("=" * 60)
    print()

    scrape_all()
