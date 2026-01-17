#!/usr/bin/env python3
"""
Scraper for ramropatro.com calendar data.
Fetches events, holidays, and auspicious dates (lagan, sahit) for Nepali calendar.

Usage:
    python scrape_ramropatro.py

Output:
    - nepali_calendar_events.json: Events and holidays for each month
    - nepali_calendar_auspicious.json: Auspicious dates (bibaha lagan, pasni, bratabandha)
"""

import json
import re
import time
import random
import requests
from pathlib import Path
from typing import Optional
from dataclasses import dataclass, asdict


# Configuration
START_YEAR = 2068
START_MONTH = 1
END_YEAR = 2084
END_MONTH = 12

OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "data"

HEADERS = {
    'accept': '*/*',
    'accept-language': 'en-US,en;q=0.6',
    'user-agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36',
    'x-requested-with': 'XMLHttpRequest',
    'referer': 'https://ramropatro.com/',
}

BASE_URL = "https://ramropatro.com"


@dataclass
class DayEvent:
    """Event/holiday for a specific day"""
    day: int
    events: list[str]
    is_holiday: bool


@dataclass
class MonthEvents:
    """All events for a month"""
    year: int
    month: int
    days: list[DayEvent]


@dataclass
class AuspiciousDates:
    """Auspicious dates for a month"""
    year: int
    month: int
    bibaha_lagan: list[int]  # Wedding dates
    bratabandha: list[int]   # Sacred thread ceremony
    pasni: list[int]         # Rice feeding ceremony


def strip_html_tags(html: str) -> str:
    """Remove HTML tags from string"""
    clean = re.sub(r'<[^>]+>', '', html)
    return clean.strip()


def parse_month_events(html: str, year: int, month: int) -> MonthEvents:
    """
    Parse getMonth API response.
    Format: "1 Event1, Event2<br/>2 Event3<br/><font color='red'>3 Holiday Event</font><br/>"
    """
    days = []

    # Split by <br/> or <br>
    lines = re.split(r'<br\s*/?>', html)

    for line in lines:
        line = line.strip()
        if not line:
            continue

        # Check if it's a holiday (wrapped in red font tag)
        is_holiday = 'color' in line.lower() and ('red' in line.lower() or 'holiday' in line.lower())

        # Remove font tags but keep content
        clean_line = strip_html_tags(line)
        if not clean_line:
            continue

        # Extract day number from beginning
        match = re.match(r'^(\d+)\s+(.+)$', clean_line)
        if match:
            day = int(match.group(1))
            events_str = match.group(2)

            # Split events by comma
            events = [e.strip() for e in events_str.split(',') if e.strip()]

            # Check for holiday markers in event text
            if any('holiday' in e.lower() for e in events):
                is_holiday = True

            days.append(DayEvent(day=day, events=events, is_holiday=is_holiday))

    return MonthEvents(year=year, month=month, days=days)


def parse_auspicious_dates(html: str, year: int, month: int) -> AuspiciousDates:
    """
    Parse getMBP API response.
    Format: "<span>Bibah Lagan:-</span><br/>21, 22, 27<br/><br/>..."
    """
    bibaha = []
    bratabandha = []
    pasni = []

    # Extract Bibaha Lagan dates
    bibaha_match = re.search(r'bibah[a]?\s*lagan[^<]*</span>\s*<br/?>\s*([^<]+)', html, re.IGNORECASE)
    if bibaha_match:
        dates_str = bibaha_match.group(1)
        bibaha = extract_numbers(dates_str)

    # Extract Bratabandha dates
    brata_match = re.search(r'bratabandha[^<]*</span>\s*<br/?>\s*([^<]+)', html, re.IGNORECASE)
    if brata_match:
        dates_str = brata_match.group(1)
        bratabandha = extract_numbers(dates_str)

    # Extract Pasni dates
    pasni_match = re.search(r'pasni[^<]*</span>\s*<br/?>\s*([^<]+)', html, re.IGNORECASE)
    if pasni_match:
        dates_str = pasni_match.group(1)
        pasni = extract_numbers(dates_str)

    return AuspiciousDates(
        year=year,
        month=month,
        bibaha_lagan=bibaha,
        bratabandha=bratabandha,
        pasni=pasni
    )


def extract_numbers(text: str) -> list[int]:
    """Extract numbers from comma-separated string"""
    if '*na' in text.lower() or 'not available' in text.lower():
        return []

    numbers = re.findall(r'\d+', text)
    return [int(n) for n in numbers if 1 <= int(n) <= 32]


def fetch_month_events(year: int, month: int) -> Optional[str]:
    """Fetch month events from ramropatro API"""
    url = f"{BASE_URL}/getMonth"
    params = {
        'year': year,
        'month': month,
        'a': random.random()  # Cache buster
    }

    try:
        response = requests.get(url, params=params, headers=HEADERS, timeout=30)
        response.raise_for_status()
        return response.text
    except requests.RequestException as e:
        print(f"  Error fetching events for {year}/{month}: {e}")
        return None


def fetch_auspicious_dates(year: int, month: int) -> Optional[str]:
    """Fetch auspicious dates from ramropatro API"""
    url = f"{BASE_URL}/getMBP"
    params = {
        'year': year,
        'month': month,
        'a': random.random()
    }

    try:
        response = requests.get(url, params=params, headers=HEADERS, timeout=30)
        response.raise_for_status()
        return response.text
    except requests.RequestException as e:
        print(f"  Error fetching auspicious dates for {year}/{month}: {e}")
        return None


def scrape_all():
    """Main scraping function"""
    all_events = {}
    all_auspicious = {}

    # Ensure output directory exists
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Progress file for resumption
    progress_file = OUTPUT_DIR / ".scraper_progress.json"

    # Load existing progress if any
    if progress_file.exists():
        with open(progress_file, 'r') as f:
            progress = json.load(f)
            all_events = progress.get('events', {})
            all_auspicious = progress.get('auspicious', {})
            print(f"Resuming from previous run. Already have {len(all_events)} months.")

    total_months = (END_YEAR - START_YEAR) * 12 + (END_MONTH - START_MONTH + 1)
    current = 0

    for year in range(START_YEAR, END_YEAR + 1):
        start_m = START_MONTH if year == START_YEAR else 1
        end_m = END_MONTH if year == END_YEAR else 12

        for month in range(start_m, end_m + 1):
            current += 1
            key = f"{year}-{month:02d}"

            # Skip if already fetched
            if key in all_events and key in all_auspicious:
                print(f"[{current}/{total_months}] Skipping {year}/{month} (already fetched)")
                continue

            print(f"[{current}/{total_months}] Fetching {year}/{month}...")

            # Fetch events
            if key not in all_events:
                events_html = fetch_month_events(year, month)
                if events_html:
                    month_events = parse_month_events(events_html, year, month)
                    all_events[key] = asdict(month_events)
                    print(f"  Found {len(month_events.days)} days with events")

            # Fetch auspicious dates
            if key not in all_auspicious:
                auspicious_html = fetch_auspicious_dates(year, month)
                if auspicious_html:
                    auspicious = parse_auspicious_dates(auspicious_html, year, month)
                    all_auspicious[key] = asdict(auspicious)
                    bibaha_count = len(auspicious.bibaha_lagan)
                    print(f"  Found {bibaha_count} bibaha lagan dates")

            # Save progress periodically
            if current % 10 == 0:
                save_progress(progress_file, all_events, all_auspicious)

            # Rate limiting - be nice to the server
            time.sleep(0.5 + random.random() * 0.5)

    # Final save
    save_progress(progress_file, all_events, all_auspicious)

    # Save final output files
    events_file = OUTPUT_DIR / "nepali_calendar_events.json"
    auspicious_file = OUTPUT_DIR / "nepali_calendar_auspicious.json"

    with open(events_file, 'w', encoding='utf-8') as f:
        json.dump(all_events, f, ensure_ascii=False, indent=2)
    print(f"\nSaved events to {events_file}")

    with open(auspicious_file, 'w', encoding='utf-8') as f:
        json.dump(all_auspicious, f, ensure_ascii=False, indent=2)
    print(f"Saved auspicious dates to {auspicious_file}")

    # Clean up progress file
    progress_file.unlink(missing_ok=True)

    print(f"\nDone! Scraped {len(all_events)} months from {START_YEAR}/{START_MONTH} to {END_YEAR}/{END_MONTH}")


def save_progress(progress_file: Path, events: dict, auspicious: dict):
    """Save progress to allow resumption"""
    with open(progress_file, 'w', encoding='utf-8') as f:
        json.dump({'events': events, 'auspicious': auspicious}, f, ensure_ascii=False)


if __name__ == "__main__":
    print("=" * 60)
    print("Ramropatro Calendar Scraper")
    print(f"Scraping from BS {START_YEAR}/{START_MONTH} to {END_YEAR}/{END_MONTH}")
    print("=" * 60)
    print()

    scrape_all()
