#!/usr/bin/env python3
"""
Scrape RONB (Routine of Nepal Banda) Facebook page posts.

Uses Googlebot UA to get server-rendered page with embedded JSON post data.
Outputs structured JSON with post text, timestamps, images, and links.

Usage:
    python3 scripts/scrape_ronb.py                    # Output to stdout
    python3 scripts/scrape_ronb.py -o data/ronb.json  # Output to file
    python3 scripts/scrape_ronb.py --pretty            # Pretty print
"""

import argparse
import json
import re
import sys
import urllib.request
from datetime import datetime, timezone, timedelta

FACEBOOK_PAGE = "officialroutineofnepalbanda"
PAGE_URL = f"https://www.facebook.com/{FACEBOOK_PAGE}/"
NEPAL_TZ = timezone(timedelta(hours=5, minutes=45))

GOOGLEBOT_UA = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"


def fetch_page(url: str) -> str:
    """Fetch Facebook page HTML using Googlebot user agent."""
    req = urllib.request.Request(url, headers={"User-Agent": GOOGLEBOT_UA})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read().decode("utf-8", errors="replace")


def clean_text(raw: str) -> str:
    """Decode escaped unicode from Facebook JSON."""
    try:
        text = raw.encode("utf-8", errors="replace").decode("unicode_escape", errors="replace")
        # Fix surrogate pairs
        text = text.encode("utf-16", "surrogatepass").decode("utf-16", "replace")
    except Exception:
        text = raw
    return text.strip()


def extract_posts(html: str) -> list[dict]:
    """Extract post data from Facebook page HTML."""
    posts = []

    # Facebook embeds post data as JSON in the page source.
    # Strategy: find all "creation_story" objects which contain post text and metadata.

    # Extract (message_text, creation_time, post_id) tuples
    # We need to correlate them. The most reliable approach is to find
    # JSON-like structures containing both message and timestamp.

    # Extract post URLs
    url_pattern = re.compile(r'"url":"(https://www\.facebook\.com/' + FACEBOOK_PAGE + r'/posts/[^"]+)"')
    post_urls = url_pattern.findall(html)

    # Extract messages and timestamps separately, then pair by proximity
    msg_pattern = re.compile(r'"message":\{"text":"((?:[^"\\]|\\.){5,5000})"\}')
    ts_pattern = re.compile(r'"creation_time":(\d{10})')

    messages = []
    for m in msg_pattern.finditer(html):
        messages.append({
            "text": clean_text(m.group(1)),
            "pos": m.start(),
        })

    timestamps = []
    for m in ts_pattern.finditer(html):
        timestamps.append({
            "ts": int(m.group(1)),
            "pos": m.start(),
        })

    # Pair each message with the nearest timestamp
    seen_texts = set()
    for msg in messages:
        text = msg["text"]

        # Deduplicate (Facebook sometimes repeats posts in different formats)
        text_key = text[:100]
        if text_key in seen_texts:
            continue
        seen_texts.add(text_key)

        # Find nearest timestamp
        nearest_ts = None
        min_dist = float("inf")
        for ts in timestamps:
            dist = abs(ts["pos"] - msg["pos"])
            if dist < min_dist:
                min_dist = dist
                nearest_ts = ts["ts"]

        # Find nearest post URL
        nearest_url = None
        min_url_dist = float("inf")
        for url in post_urls:
            # Find position of this URL in HTML
            url_pos = html.find(url)
            if url_pos >= 0:
                dist = abs(url_pos - msg["pos"])
                if dist < min_url_dist:
                    min_url_dist = dist
                    nearest_url = url

        post = {
            "text": text,
            "timestamp": nearest_ts,
            "datetime_utc": datetime.fromtimestamp(nearest_ts, tz=timezone.utc).isoformat() if nearest_ts else None,
            "datetime_npt": datetime.fromtimestamp(nearest_ts, tz=NEPAL_TZ).strftime("%Y-%m-%d %H:%M") if nearest_ts else None,
            "url": nearest_url,
        }

        posts.append(post)

    # Sort by timestamp descending (newest first)
    posts.sort(key=lambda p: p.get("timestamp") or 0, reverse=True)

    return posts


def main():
    parser = argparse.ArgumentParser(description="Scrape RONB Facebook page")
    parser.add_argument("-o", "--output", help="Output file path (default: stdout)")
    parser.add_argument("--pretty", action="store_true", help="Pretty print JSON")
    args = parser.parse_args()

    print(f"Fetching {PAGE_URL}...", file=sys.stderr)
    html = fetch_page(PAGE_URL)
    print(f"Page size: {len(html):,} bytes", file=sys.stderr)

    posts = extract_posts(html)
    print(f"Extracted {len(posts)} posts", file=sys.stderr)

    result = {
        "source": "facebook",
        "page": FACEBOOK_PAGE,
        "page_url": PAGE_URL,
        "scraped_at": datetime.now(tz=timezone.utc).isoformat(),
        "scraped_at_npt": datetime.now(tz=NEPAL_TZ).strftime("%Y-%m-%d %H:%M"),
        "post_count": len(posts),
        "posts": posts,
    }

    indent = 2 if args.pretty else None
    output = json.dumps(result, ensure_ascii=False, indent=indent)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output)
        print(f"Written to {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
