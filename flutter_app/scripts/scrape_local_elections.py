#!/usr/bin/env python3
"""
Scraper for ekantipur local body election results.
Fetches Mayor, Deputy Mayor, Chairperson, Vice-Chairperson for all 753 local bodies.

Usage:
    python scrape_local_elections.py

Output:
    - assets/data/election/local_election_results.json
"""

import json
import re
import time
import random
from pathlib import Path
from dataclasses import dataclass, asdict, field
from typing import Optional, List
from bs4 import BeautifulSoup
import requests


# Configuration
SCRIPT_DIR = Path(__file__).parent
ASSETS_DIR = SCRIPT_DIR.parent / "assets"
OUTPUT_DIR = ASSETS_DIR / "data" / "election"

HEADERS = {
    'accept': 'text/html,application/xhtml+xml',
    'accept-language': 'en-US,en;q=0.6',
    'user-agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36',
}

BASE_URL = "https://election.ekantipur.com"
DISTRICTS_JSON_URL = f"{BASE_URL}/json/districts.json?v=2022.030"
LOCATION_SUMMARY_URL = f"{BASE_URL}/locationsummary/{{loc_id}}/eng"


@dataclass
class ElectedOfficial:
    """An elected local official"""
    name: str
    nameNp: str
    position: str  # Mayor, Deputy Mayor, Chairperson, Vice-Chairperson
    party: str
    votes: int
    imageUrl: str = ""
    partySymbol: str = ""


@dataclass
class LocalBodyResult:
    """Election results for a local body"""
    id: str
    locId: str
    name: str
    nameNp: str
    district: str
    province: int
    type: str  # municipality, metropolitan, sub-metropolitan, rural-municipality
    officials: List[ElectedOfficial] = field(default_factory=list)


def fetch_districts_data() -> dict:
    """Fetch all districts and local bodies from ekantipur"""
    cache_file = Path("/tmp/ekantipur_districts.json")

    if cache_file.exists():
        print("Using cached districts data...")
        with open(cache_file, 'r') as f:
            return json.load(f)

    print("Fetching districts data from ekantipur...")
    response = requests.get(DISTRICTS_JSON_URL, headers=HEADERS, timeout=30)
    response.raise_for_status()
    data = response.json()

    with open(cache_file, 'w') as f:
        json.dump(data, f)

    return data


def determine_local_body_type(name: str) -> str:
    """Determine the type of local body from its name"""
    name_lower = name.lower()
    if 'metropolitan' in name_lower:
        if 'sub' in name_lower:
            return 'sub-metropolitan'
        return 'metropolitan'
    elif 'municipality' in name_lower:
        return 'municipality'
    elif 'rural' in name_lower or 'gaunpalika' in name_lower:
        return 'rural-municipality'
    return 'municipality'  # default


def parse_location_summary(html: str, loc_id: str, local_body_info: dict) -> Optional[LocalBodyResult]:
    """Parse the location summary HTML and extract election results"""
    soup = BeautifulSoup(html, 'html.parser')

    officials = []

    # Find all position sections (Mayor, Deputy Mayor, Chairperson, etc.)
    cards = soup.find_all('div', class_='card')

    for card in cards:
        # Get position title
        title_elem = card.find('h6', class_='card-title')
        if not title_elem:
            continue

        position = title_elem.get_text(strip=True)

        # Find all candidates in this position
        candidates = card.find_all('li', class_='list-group-item')

        for candidate in candidates:
            # Check if elected
            elected_badge = candidate.find('span', class_='badge', string=lambda t: t and 'Elected' in t)
            if not elected_badge:
                # Also check for the checkmark badge
                check_badge = candidate.find('span', class_='badge-circle')
                if not check_badge:
                    continue  # Skip non-elected candidates

            # Get candidate name
            name_elem = candidate.find('div', class_='candidate-name')
            name_np = name_elem.get_text(strip=True) if name_elem else ""

            # Get party
            party_elem = candidate.find('div', class_='candidate-party-name')
            party = ""
            if party_elem:
                party_link = party_elem.find('a')
                party = party_link.get_text(strip=True) if party_link else party_elem.get_text(strip=True)

            # Get votes
            votes_elem = candidate.find('div', class_='vote-numbers')
            votes = 0
            if votes_elem:
                votes_text = votes_elem.get_text(strip=True).replace(',', '')
                try:
                    votes = int(votes_text)
                except ValueError:
                    pass

            # Get image URL
            img_elem = candidate.find('img', src=True)
            image_url = ""
            if img_elem:
                src = img_elem.get('src', '')
                if 'candidates/' in src:
                    image_url = src

            # Get party symbol
            party_symbol = ""
            election_icon = candidate.find('div', class_='election-icon')
            if election_icon:
                party_img = election_icon.find('img', src=True)
                if party_img:
                    party_symbol = party_img.get('src', '')

            official = ElectedOfficial(
                name=name_np,  # We'll transliterate later if needed
                nameNp=name_np,
                position=position,
                party=party,
                votes=votes,
                imageUrl=image_url,
                partySymbol=party_symbol,
            )
            officials.append(official)

    if not officials:
        return None

    return LocalBodyResult(
        id=local_body_info['id'],
        locId=loc_id,
        name=local_body_info['eng'],
        nameNp=local_body_info['nep'],
        district=local_body_info.get('district', ''),
        province=local_body_info.get('province', 0),
        type=determine_local_body_type(local_body_info['eng']),
        officials=officials,
    )


def scrape_all():
    """Main scraping function"""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Fetch districts data
    districts_data = fetch_districts_data()

    # Count total local bodies
    total_local_bodies = 0
    for province_id, districts in districts_data.items():
        for district_id, district_info in districts.items():
            total_local_bodies += len(district_info.get('locations', []))

    print(f"Found {total_local_bodies} local bodies across 7 provinces")

    # Progress tracking
    progress_file = OUTPUT_DIR / ".local_elections_progress.json"
    completed = set()
    all_results = []

    if progress_file.exists():
        with open(progress_file, 'r') as f:
            progress = json.load(f)
            completed = set(progress.get('completed', []))
            all_results = progress.get('results', [])
            print(f"Resuming. Already completed: {len(completed)} local bodies")

    current = 0
    for province_id, districts in districts_data.items():
        province_num = int(province_id)

        for district_id, district_info in districts.items():
            district_name = district_info.get('eng', district_id)

            for local_body in district_info.get('locations', []):
                current += 1
                loc_id = local_body.get('loc_id', '')
                local_body_id = local_body.get('id', '')

                if loc_id in completed:
                    continue

                # Add context to local body info
                local_body['district'] = district_name
                local_body['province'] = province_num

                print(f"[{current}/{total_local_bodies}] {local_body['eng']} ({district_name})...")

                try:
                    # Fetch location summary
                    url = LOCATION_SUMMARY_URL.format(loc_id=loc_id)
                    response = requests.get(url, headers=HEADERS, timeout=30)
                    response.raise_for_status()

                    # Parse results
                    result = parse_location_summary(response.text, loc_id, local_body)
                    if result:
                        all_results.append(asdict(result))
                        print(f"    Found {len(result.officials)} elected officials")
                    else:
                        print(f"    No results found")

                    completed.add(loc_id)

                except requests.RequestException as e:
                    print(f"    Error: {e}")

                # Save progress periodically
                if len(completed) % 20 == 0:
                    with open(progress_file, 'w') as f:
                        json.dump({
                            'completed': list(completed),
                            'results': all_results,
                        }, f)

                # Rate limiting
                time.sleep(0.3 + random.random() * 0.2)

    # Save final output
    output_data = {
        "version": "1.0",
        "source": "election.ekantipur.com",
        "election_year": "2079",
        "scraped_at": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
        "totalLocalBodies": len(all_results),
        "localBodies": all_results,
    }

    output_file = OUTPUT_DIR / "local_election_results.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)

    print(f"\nSaved {len(all_results)} local body results to {output_file}")

    # Cleanup progress file
    if progress_file.exists():
        progress_file.unlink()

    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)

    # Count by province
    by_province = {}
    for result in all_results:
        prov = result.get('province', 0)
        by_province[prov] = by_province.get(prov, 0) + 1

    for prov in sorted(by_province.keys()):
        print(f"Province {prov}: {by_province[prov]} local bodies")

    # Count total officials
    total_officials = sum(len(r.get('officials', [])) for r in all_results)
    print(f"\nTotal elected officials: {total_officials}")


if __name__ == "__main__":
    print("=" * 60)
    print("Ekantipur Local Election Results Scraper")
    print("Fetching Mayor/Deputy Mayor/Chairperson results")
    print("=" * 60)
    print()

    scrape_all()
