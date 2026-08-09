#!/usr/bin/env python3
"""
Scrape RONB (Routine of Nepal Banda) Facebook page posts.

Facebook serves a fully server-rendered page to Googlebot, with the post data
embedded as JSON inside the HTML. We request with a Googlebot UA and pull the
post text, timestamps, images and permalinks back out of that JSON.

Everything in the embedded blob is JSON-escaped, so `/` arrives as `\\/` and all
non-ASCII arrives as `\\uXXXX` surrogate pairs. Unescaping is done by handing the
raw capture to `json.loads`, which is the only thing that gets surrogate pairs
right.

Usage:
    python3 scripts/scrape_ronb.py                      # stdout
    python3 scripts/scrape_ronb.py -o data/ronb.json    # to file
    python3 scripts/scrape_ronb.py --pretty             # readable
    python3 scripts/scrape_ronb.py --min-posts 5        # fail if fewer
"""

import argparse
import json
import re
import sys
from datetime import datetime, timezone, timedelta

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

FACEBOOK_PAGE = "officialroutineofnepalbanda"
PAGE_URL = f"https://www.facebook.com/{FACEBOOK_PAGE}/"
NEPAL_TZ = timezone(timedelta(hours=5, minutes=45))

GOOGLEBOT_UA = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"

# Every post is introduced by an object carrying its id next to its creation
# time. This pair is the anchor everything else hangs off: it appears exactly
# once per post and gives both a stable identity and an exact timestamp.
_POST_RE = re.compile(r'"post_id":"(\d+)","creation_time":(\d{10})')
# The id is then repeated throughout the blocks that render that post.
_POST_ID_RE = re.compile(r'"post_id":"(\d+)"')
# Post text lives in "message":{"text":"..."}.
_MSG_RE = re.compile(r'"message":\{"text":"((?:[^"\\]|\\.){5,5000})"\}')
# Attached photo. The URI is JSON-escaped, so `/` shows up as `\/`.
_IMG_RE = re.compile(r'"photo_image":\{"uri":"(https?:[^"]+?media_id=\d+[^"]*)"')


def _session() -> requests.Session:
    """Session with retries — Facebook rate-limits CI runner IP ranges."""
    session = requests.Session()
    retry = Retry(
        total=4,
        backoff_factor=2,
        status_forcelist=(403, 429, 500, 502, 503, 504),
        allowed_methods=("GET",),
    )
    session.mount("https://", HTTPAdapter(max_retries=retry))
    session.headers.update({
        "User-Agent": GOOGLEBOT_UA,
        "Accept-Language": "en-US,en;q=0.9,ne;q=0.8",
    })
    return session


def fetch_page(url: str) -> str:
    resp = _session().get(url, timeout=30)
    resp.raise_for_status()
    return resp.text


def unescape(raw: str) -> str:
    """Unescape a JSON string body.

    The previous implementation round-tripped through `unicode_escape`, which
    mangles anything outside latin-1 and leaves `\\/` untouched — that is why
    scraped posts used to read "Pic\\/Story". Re-quoting and letting the JSON
    parser do it handles escapes and surrogate pairs correctly.
    """
    try:
        return json.loads(f'"{raw}"').strip()
    except (json.JSONDecodeError, ValueError):
        # Truncated capture: fall back to the escapes that matter most.
        text = raw.replace(r"\/", "/").replace(r"\"", '"').replace(r"\n", "\n")
        return text.strip()


def extract_posts(html: str) -> list[dict]:
    """Pull posts out of the embedded JSON, keyed by post id.

    Facebook renders each post more than once (different layout variants) and
    does not keep a post's fields inside one object we can match whole. What it
    does do is repeat the post's id in every block belonging to that post, so
    each message and image is attributed to the nearest post-id occurrence.
    That is what makes the mapping 1:1 — pairing on raw proximity alone used to
    hand the same photo to two neighbouring posts.
    """
    # Canonical id -> creation time. One entry per post.
    creation_times = {pid: int(ts) for pid, ts in _POST_RE.findall(html)}
    if not creation_times:
        return []

    anchors = [
        (m.start(), m.group(1))
        for m in _POST_ID_RE.finditer(html)
        if m.group(1) in creation_times
    ]

    def owner(pos: int) -> str:
        """Id of the post whose block this offset falls closest to."""
        return min(anchors, key=lambda a: abs(a[0] - pos))[1]

    texts: dict[str, str] = {}
    for m in _MSG_RE.finditer(html):
        text = unescape(m.group(1))
        if text:
            texts.setdefault(owner(m.start()), text)

    images: dict[str, str] = {}
    for m in _IMG_RE.finditer(html):
        images.setdefault(owner(m.start()), m.group(1).replace(r"\/", "/"))

    posts = []
    for post_id, ts in creation_times.items():
        text = texts.get(post_id)
        if not text:
            # Photo-only or video-only post with no caption; nothing to show.
            continue
        posts.append({
            "id": post_id,
            "text": text,
            "timestamp": ts,
            "datetime_utc": datetime.fromtimestamp(ts, tz=timezone.utc).isoformat(),
            "datetime_npt": datetime.fromtimestamp(ts, tz=NEPAL_TZ).strftime("%Y-%m-%d %H:%M"),
            "url": f"https://www.facebook.com/{FACEBOOK_PAGE}/posts/{post_id}",
            "imageUrl": images.get(post_id),
        })

    posts.sort(key=lambda p: p["timestamp"], reverse=True)
    return posts


def main() -> int:
    parser = argparse.ArgumentParser(description="Scrape RONB Facebook page")
    parser.add_argument("-o", "--output", help="Output file path (default: stdout)")
    parser.add_argument("--pretty", action="store_true", help="Pretty print JSON")
    parser.add_argument(
        "--min-posts",
        type=int,
        default=0,
        help="Exit non-zero if fewer than this many posts were found, so a "
             "blocked scrape fails the job instead of publishing an empty feed",
    )
    args = parser.parse_args()

    print(f"Fetching {PAGE_URL}...", file=sys.stderr)
    html = fetch_page(PAGE_URL)
    print(f"Page size: {len(html):,} bytes", file=sys.stderr)

    posts = extract_posts(html)
    with_url = sum(1 for p in posts if p["url"])
    with_img = sum(1 for p in posts if p["imageUrl"])
    print(
        f"Extracted {len(posts)} posts ({with_url} with permalink, {with_img} with image)",
        file=sys.stderr,
    )

    if len(posts) < args.min_posts:
        print(
            f"ERROR: only {len(posts)} posts, expected at least {args.min_posts}. "
            "Refusing to write a degraded feed.",
            file=sys.stderr,
        )
        return 1

    result = {
        "source": "facebook",
        "page": FACEBOOK_PAGE,
        "page_url": PAGE_URL,
        "scraped_at": datetime.now(tz=timezone.utc).isoformat(),
        "scraped_at_npt": datetime.now(tz=NEPAL_TZ).strftime("%Y-%m-%d %H:%M"),
        "post_count": len(posts),
        "posts": posts,
    }

    output = json.dumps(result, ensure_ascii=False, indent=2 if args.pretty else None)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output)
        print(f"Written to {args.output}", file=sys.stderr)
    else:
        print(output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
