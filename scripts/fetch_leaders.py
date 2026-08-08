#!/usr/bin/env python3
"""
Fetch Nepal political leaders data from ratemyneta.com API.

This script:
1. Fetches all leaders from the API
2. Normalizes district names to match our districts.json
3. Downloads leader images
4. Generates leaders.json and parties.json

Usage:
    python3 scripts/fetch_leaders.py
"""

import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path
from urllib.parse import urljoin
from typing import Any, Dict, List

import requests


# Configuration
API_BASE = "https://api.ratemyneta.com/api"

# The Flutter app bundles `flutter_app/assets/`, so data must land there.
# Writing to the repo-root `assets/` copy left the app on stale data.
_REPO_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = _REPO_ROOT / "flutter_app" / "assets" / "data"
IMAGES_DIR = _REPO_ROOT / "flutter_app" / "assets" / "images" / "leaders"
DISTRICTS_FILE = _REPO_ROOT / "flutter_app" / "assets" / "data" / "districts.json"

# ratemyneta.com sits behind a CDN that rejects default python-requests
# user-agents and datacenter IPs, so present as a normal browser and retry.
USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
)


_SESSION: "requests.Session | None" = None


def _session() -> requests.Session:
    """A shared requests session with browser-like headers and retry/backoff.

    Reused across calls so connections are pooled and the retry policy (which
    covers the 429s this host issues under load) applies to every request.
    """
    global _SESSION
    if _SESSION is not None:
        return _SESSION

    from requests.adapters import HTTPAdapter
    from urllib3.util.retry import Retry

    session = requests.Session()
    session.headers.update({
        "User-Agent": USER_AGENT,
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "en-US,en;q=0.9",
        "Referer": "https://ratemyneta.com/",
    })
    retry = Retry(
        total=4,
        backoff_factor=2,
        status_forcelist=(403, 429, 500, 502, 503, 504),
        allowed_methods=frozenset(["GET"]),
    )
    session.mount("https://", HTTPAdapter(max_retries=retry))
    session.mount("http://", HTTPAdapter(max_retries=retry))
    _SESSION = session
    return session

# District name normalization mapping (API returns -> our standard name)
DISTRICT_ALIASES = {
    "Kapilvastu": "Kapilbastu",
    "Nawalparasi (East of Bardaghat Susta)": "Nawalparasi (Bardaghat Susta East)",
    "Nawalparasi (West of Bardaghat Susta)": "Nawalparasi (Bardaghat Susta West)",
    "Rukum West": "Western Rukum",
    "Rukum East": "Eastern Rukum",
    "Rukum": "Eastern Rukum",  # Default to Eastern Rukum for ambiguous "Rukum"
    "Dhanusa": "Dhanusha",
    "Mahottari": "Mahottari",
    "Sarlahi": "Sarlahi",
    "Sindhuli": "Sindhuli",
    "Sindhupalchowk": "Sindhupalchok",
    "Kavrepalanchowk": "Kavrepalanchok",
    "Taplejung": "Taplejung",
    "Panchthar": "Panchthar",
    "Ilam": "Ilam",
    "Jhapa": "Jhapa",
    "Morang": "Morang",
    "Sunsari": "Sunsari",
    "Dhankuta": "Dhankuta",
    "Terhathum": "Tehrathum",
    "Sankhuwasabha": "Sankhuwasabha",
    "Bhojpur": "Bhojpur",
    "Khotang": "Khotang",
    "Solukhumbu": "Solukhumbu",
    "Okhaldhunga": "Okhaldhunga",
    "Udayapur": "Udayapur",
    "Saptari": "Saptari",
    "Siraha": "Siraha",
    "Dhanusha": "Dhanusha",
    "Mahottari": "Mahottari",
    "Sarlahi": "Sarlahi",
    "Rautahat": "Rautahat",
    "Bara": "Bara",
    "Parsa": "Parsa",
    "Chitwan": "Chitwan",
    "Makwanpur": "Makwanpur",
    "Dolakha": "Dolakha",
    "Ramechhap": "Ramechhap",
    "Sindhuli": "Sindhuli",
    "Kavrepalanchok": "Kavrepalanchok",
    "Sindhupalchok": "Sindhupalchok",
    "Rasuwa": "Rasuwa",
    "Nuwakot": "Nuwakot",
    "Dhading": "Dhading",
    "Kathmandu": "Kathmandu",
    "Lalitpur": "Lalitpur",
    "Bhaktapur": "Bhaktapur",
    "Kaski": "Kaski",
    "Syangja": "Syangja",
    "Tanahu": "Tanahu",
    "Lamjung": "Lamjung",
    "Gorkha": "Gorkha",
    "Manang": "Manang",
    "Mustang": "Mustang",
    "Parbat": "Parbat",
    "Baglung": "Baglung",
    "Myagdi": "Myagdi",
    "Nawalparasi": "Nawalparasi (Bardaghat Susta West)",  # Default
    "Palpa": "Palpa",
    "Gulmi": "Gulmi",
    "Arghakhanchi": "Arghakhanchi",
    "Syangja": "Syangja",
    "Pyuthan": "Pyuthan",
    "Rolpa": "Rolpa",
    "Rukum": "Eastern Rukum",
    "Eastern Rukum": "Eastern Rukum",
    "Western Rukum": "Western Rukum",
    "Salyan": "Salyan",
    "Dang": "Dang",
    "Bardiya": "Bardiya",
    "Banke": "Banke",
    "Surkhet": "Surkhet",
    "Dailekh": "Dailekh",
    "Jajarkot": "Jajarkot",
    "Dolpa": "Dolpa",
    "Humla": "Humla",
    "Jumla": "Jumla",
    "Mugu": "Mugu",
    "Kalikot": "Kalikot",
    "Kailali": "Kailali",
    "Kanchanpur": "Kanchanpur",
    "Doti": "Doti",
    "Achham": "Achham",
    "Dadeldhura": "Dadeldhura",
    "Baitadi": "Baitadi",
    "Darchula": "Darchula",
    "Bajura": "Bajura",
    "Bajhang": "Bajhang",
    "Kapilvastu": "Kapilvastu",
    "Rupandehi": "Rupandehi",
    " ": None,  # Empty district
    "": None,
    None: None,
}

# SVG ID to district name mapping (lowercase SVG ID -> proper name)
SVG_TO_NAME = {}


def load_districts() -> Dict[str, Dict[str, Any]]:
    """Load districts mapping from districts.json."""
    if not DISTRICTS_FILE.exists():
        print(f"Warning: {DISTRICTS_FILE} not found. District mapping disabled.")
        return {}

    with open(DISTRICTS_FILE) as f:
        districts = json.load(f)

    # Build SVG ID to name mapping
    for svg_id, info in districts.items():
        SVG_TO_NAME[svg_id.lower()] = info["name"]

    return districts


def normalize_district(district: str) -> str | None:
    """Normalize district name to match our districts.json format."""
    if not district:
        return None

    # First check if it already matches a district name
    for svg_id, name in SVG_TO_NAME.items():
        if district.lower() == name.lower():
            return name

    # Check aliases
    for alias, standard in DISTRICT_ALIASES.items():
        if alias and district.lower() == alias.lower():
            return standard

    # Try partial match (for cases like "Kathmandu" vs "Kathmandu District")
    district_lower = district.lower().replace(" district", "").strip()
    for svg_id, name in SVG_TO_NAME.items():
        if district_lower in name.lower() or name.lower() in district_lower:
            return name

    # If no match found, return the original (may need manual correction)
    print(f"Warning: Could not normalize district: '{district}'", file=sys.stderr)
    return district


def fetch_leaders() -> List[Dict[str, Any]]:
    """Fetch all leaders from the API."""
    print(f"Fetching leaders from {API_BASE}/leaders...")

    try:
        response = _session().get(f"{API_BASE}/leaders", timeout=30)
        response.raise_for_status()
        result = response.json()

        # API returns { "success": true, "data": [...], "message": "..." }
        if isinstance(result, dict):
            if "data" in result and isinstance(result["data"], list):
                return result["data"]
            elif "leaders" in result and isinstance(result["leaders"], list):
                return result["leaders"]
            else:
                print(f"Unexpected dict keys: {list(result.keys())}", file=sys.stderr)
                return []
        elif isinstance(result, list):
            return result
        else:
            print(f"Unexpected response format: {type(result)}", file=sys.stderr)
            return []

    except requests.RequestException as e:
        print(f"Error fetching leaders: {e}", file=sys.stderr)
        return []


def download_image(url: str, leader_id: str) -> str:
    """Download a leader image and return its bundled asset path.

    Images must be local: the remote hosts send no CORS headers, so on the web
    build every remote photo fails to load and the leader falls back to
    initials. Downloads are incremental — an image already on disk is reused —
    so repeated runs converge on a complete set even though the upstream host
    rate-limits (HTTP 429) a full sweep.
    """
    if not url:
        return None

    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    image_path = IMAGES_DIR / f"{leader_id}.jpg"
    asset_path = f"assets/images/leaders/{leader_id}.jpg"

    # Already fetched on an earlier run — don't re-download.
    if image_path.exists() and image_path.stat().st_size > 0:
        return asset_path

    try:
        response = _session().get(url, timeout=30, stream=True)
        response.raise_for_status()

        with open(image_path, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)

        # Reject error pages saved as images.
        if image_path.stat().st_size < 1024:
            image_path.unlink(missing_ok=True)
            print(f"Warning: image for {leader_id} too small, discarding", file=sys.stderr)
            return None

        # Be a polite client; this host throttles aggressive sweeps.
        time.sleep(0.3)
        return asset_path

    except requests.RequestException as e:
        print(f"Warning: Failed to download image for {leader_id}: {e}", file=sys.stderr)
        return None


def generate_parties(leaders: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Generate parties.json from leaders data."""
    parties: Dict[str, Dict[str, Any]] = {}

    # Party colors (distinct colors for major parties)
    PARTY_COLORS = {
        "Nepali Congress": "#00A0DD",
        "Nepal Communist Party (UML)": "#0A4D3C",
        "Nepal Communist Party (Maoist Center)": "#D32F2F",
        "Rastriya Swotantra Party": "#FF6B35",
        "Rastriya Prajatantra Party": "#9C27B0",
        "Communist Party of Nepal (Unified Socialist)": "#E91E63",
        "Independent": "#607D8B",
        "People's Socialist Party": "#FF9800",
        "Janamat Party": "#4CAF50",
        "Janata Samajbadi Party Nepal": "#8BC34A",
        "Loktantrik Samajwadi Party Nepal": "#CDDC39",
        "Nagarik Unmukti Party": "#00BCD4",
    }

    for leader in leaders:
        party = leader.get("party", "Unknown")
        party_id = party.lower().replace(" ", "-").replace("(", "").replace(")", "").replace("'", "")

        if party not in parties:
            parties[party] = {
                "id": party_id,
                "name": party,
                "shortName": get_short_name(party),
                "color": PARTY_COLORS.get(party, "#757575"),
                "leaderCount": 0,
            }

        parties[party]["leaderCount"] += 1

    # Sort by leader count
    return sorted(parties.values(), key=lambda x: x["leaderCount"], reverse=True)


def get_short_name(party: str) -> str:
    """Get short name for a party."""
    short_names = {
        "Nepali Congress": "NC",
        "Nepal Communist Party (UML)": "UML",
        "Nepal Communist Party (Maoist Center)": "Maoist Center",
        "Rastriya Swotantra Party": "RSP",
        "Rastriya Prajatantra Party": "RPP",
        "Communist Party of Nepal (Unified Socialist)": "Unified Socialist",
        "People's Socialist Party": "PSP",
        "Janamat Party": "Janamat",
        "Janata Samajbadi Party Nepal": "JSPN",
        "Loktantrik Samajwadi Party Nepal": "LSPN",
        "Nagarik Unmukti Party": "NUP",
        "Independent": "Ind",
    }
    return short_names.get(party, party[:20])


def main():
    """Main entry point."""
    # Load district mapping
    load_districts()
    print(f"Loaded {len(SVG_TO_NAME)} district mappings")

    # Fetch leaders
    leaders = fetch_leaders()
    print(f"Fetched {len(leaders)} leaders")

    if not leaders:
        # ratemyneta.com blocks datacenter IPs, so a scheduled CI run can fail
        # for reasons unrelated to this repo. Skip quietly (keeping the existing
        # committed data) unless --strict was requested.
        strict = "--strict" in sys.argv
        print(
            "No leaders fetched — upstream API unreachable. "
            f"{'Failing (--strict).' if strict else 'Keeping existing data.'}",
            file=sys.stderr,
        )
        sys.exit(1 if strict else 0)

    # Normalize leader data
    normalized_leaders = []
    for leader in leaders:
        normalized = {
            "_id": leader.get("_id", ""),
            "name": leader.get("name", ""),
            "party": leader.get("party", "Unknown"),
            "position": leader.get("position", ""),
            "district": normalize_district(leader.get("district", "")),
            "biography": leader.get("biography", ""),
            "imageUrl": leader.get("imageUrl", ""),
            "featured": leader.get("featured", False),
            "upvotes": leader.get("upvotes", 0),
            "downvotes": leader.get("downvotes", 0),
            "totalVotes": leader.get("totalVotes", 0) or (
                leader.get("upvotes", 0) + leader.get("downvotes", 0)
            ),
        }

        # Download image if URL exists
        if leader.get("imageUrl"):
            local_path = download_image(leader["imageUrl"], leader["_id"])
            if local_path:
                normalized["imageUrl"] = local_path

        normalized_leaders.append(normalized)

    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Generate version string (today's date)
    version = datetime.now().strftime("%Y-%m-%d")

    # Write leaders.json
    leaders_output = {
        "version": version,
        "count": len(normalized_leaders),
        "leaders": normalized_leaders,
    }

    leaders_file = OUTPUT_DIR / "leaders.json"
    with open(leaders_file, "w") as f:
        json.dump(leaders_output, f, indent=2, ensure_ascii=False)
    print(f"Written {leaders_file}")

    # Write parties.json
    parties = generate_parties(normalized_leaders)
    parties_output = {
        "version": version,
        "count": len(parties),
        "parties": parties,
    }

    parties_file = OUTPUT_DIR / "parties.json"
    with open(parties_file, "w") as f:
        json.dump(parties_output, f, indent=2, ensure_ascii=False)
    print(f"Written {parties_file}")

    # Print summary
    print("\n=== Summary ===")
    print(f"Total leaders: {len(normalized_leaders)}")
    print(f"Total parties: {len(parties)}")
    print(f"Images downloaded: {IMAGES_DIR}")

    # Print parties by leader count
    print("\n=== Parties by Leader Count ===")
    for party in sorted(parties, key=lambda x: x["leaderCount"], reverse=True)[:10]:
        print(f"  {party['name']}: {party['leaderCount']}")


if __name__ == "__main__":
    main()
