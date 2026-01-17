#!/usr/bin/env python3
"""
Script to update ministers.json from opmcm.gov.np
Run periodically via GitHub Actions or manually when cabinet changes.

Usage:
    python scripts/update_ministers.py
"""

import json
import re
import sys
from datetime import datetime
from pathlib import Path

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print("Installing required packages...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "requests", "beautifulsoup4"])
    import requests
    from bs4 import BeautifulSoup


MINISTERS_URL = "https://opmcm.gov.np/pages/ministers-pages/"
OUTPUT_PATH = Path(__file__).parent.parent / "assets" / "data" / "ministers.json"


def fetch_ministers():
    """Fetch current ministers from opmcm.gov.np"""
    print(f"Fetching ministers from {MINISTERS_URL}...")

    headers = {
        'User-Agent': 'Mozilla/5.0 (compatible; NepalCivicApp/1.0; +https://github.com/user/nepal-civic)'
    }

    response = requests.get(MINISTERS_URL, headers=headers, timeout=30)
    response.raise_for_status()

    soup = BeautifulSoup(response.content, 'html.parser')

    ministers = []

    # Look for minister entries - structure may vary
    # Try common patterns
    entries = soup.find_all('div', class_=re.compile(r'minister|member|card|profile', re.I))

    if not entries:
        # Try table format
        tables = soup.find_all('table')
        for table in tables:
            rows = table.find_all('tr')
            for row in rows[1:]:  # Skip header
                cols = row.find_all(['td', 'th'])
                if len(cols) >= 2:
                    name = cols[0].get_text(strip=True) if cols else ""
                    ministry = cols[-1].get_text(strip=True) if len(cols) > 1 else ""
                    if name and not name.isdigit():
                        ministers.append({
                            "name": name,
                            "nameNp": "",  # Would need translation
                            "position": "Minister",
                            "positionNp": "मन्त्री",
                            "ministries": [m.strip() for m in ministry.split(';') if m.strip()],
                            "ministriesNp": []
                        })

    # If still no ministers found, try generic list items
    if not ministers:
        items = soup.find_all(['li', 'article', 'section'])
        for item in items:
            text = item.get_text(strip=True)
            # Look for patterns like "Name - Ministry" or "Name, Ministry"
            if '-' in text or ',' in text:
                parts = re.split(r'[-,]', text, 1)
                if len(parts) == 2:
                    name, ministry = parts[0].strip(), parts[1].strip()
                    if len(name) > 3 and len(name) < 50:  # Reasonable name length
                        ministers.append({
                            "name": name,
                            "nameNp": "",
                            "position": "Minister",
                            "positionNp": "मन्त्री",
                            "ministries": [ministry],
                            "ministriesNp": []
                        })

    return ministers


def load_existing():
    """Load existing ministers.json to preserve structure and Nepali translations"""
    if OUTPUT_PATH.exists():
        with open(OUTPUT_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    return None


def merge_ministers(new_ministers, existing_data):
    """Merge new ministers with existing data, preserving Nepali translations"""
    if not existing_data or not new_ministers:
        return new_ministers

    # Create lookup by name
    existing_by_name = {m['name']: m for m in existing_data.get('cabinet', [])}

    merged = []
    for minister in new_ministers:
        name = minister['name']
        if name in existing_by_name:
            # Preserve Nepali translations from existing
            existing = existing_by_name[name]
            minister['nameNp'] = existing.get('nameNp', '')
            minister['ministriesNp'] = existing.get('ministriesNp', [])
        merged.append(minister)

    return merged


def update_ministers_json(ministers):
    """Update the ministers.json file"""
    existing = load_existing()

    # Preserve government structure and legislative process from existing
    if existing:
        data = {
            "lastUpdated": datetime.now().strftime("%Y-%m"),
            "source": MINISTERS_URL,
            "cabinet": ministers if ministers else existing.get('cabinet', []),
            "governmentStructure": existing.get('governmentStructure', {}),
            "legislativeProcess": existing.get('legislativeProcess', {})
        }
    else:
        data = {
            "lastUpdated": datetime.now().strftime("%Y-%m"),
            "source": MINISTERS_URL,
            "cabinet": ministers
        }

    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Updated {OUTPUT_PATH}")
    print(f"Total ministers: {len(ministers)}")


def main():
    try:
        ministers = fetch_ministers()

        if ministers:
            existing = load_existing()
            ministers = merge_ministers(ministers, existing)
            update_ministers_json(ministers)
            print("Ministers updated successfully!")
        else:
            print("Warning: No ministers found. Website structure may have changed.")
            print("Manual update may be required.")
            # Don't overwrite existing data if scraping fails

    except requests.RequestException as e:
        print(f"Error fetching ministers: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
