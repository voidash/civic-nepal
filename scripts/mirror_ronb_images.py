#!/usr/bin/env python3
"""
Mirror RONB post images so browsers can actually display them.

Facebook's lookaside URLs only return image bytes to a Googlebot user agent —
a normal browser gets an HTML login redirect instead, which is why an <img>
tag pointing at them renders nothing. A browser cannot send a custom user
agent on an image request, so the web build simply had no images at all.

This downloads each image once with the right user agent and rewrites the feed
to point at the copy published on the data branch, which raw.githubusercontent
serves as `image/jpeg` with `access-control-allow-origin: *`.

Images already present are not re-downloaded, and images no longer referenced
by the feed are removed, so the published set tracks the current posts without
re-uploading a couple of megabytes every ten minutes.

Usage:
    python3 scripts/mirror_ronb_images.py ronb_feed.json \
        --image-dir images --base-url https://raw.githubusercontent.com/o/r/data
"""

import argparse
import io
import json
import re
import sys
import time
from pathlib import Path

import requests
from PIL import Image

GOOGLEBOT_UA = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"

# Anything smaller than this is an error page, not a photo.
MIN_IMAGE_BYTES = 1024

# Facebook hands back originals — up to 1700px and 700KB each. That is a lot of
# mobile data for a news feed thumbnail, so they are downscaled before being
# published.
MAX_EDGE = 900
JPEG_QUALITY = 80


def media_id(url: str) -> str | None:
    """The image's Facebook media id, from either URL form.

    Also matches a URL this script has already rewritten, so running twice over
    the same feed reuses the mirrored file instead of failing to find a
    `media_id` query parameter and dropping the image.
    """
    url = url or ""
    match = re.search(r"media_id=(\d+)", url)
    if match:
        return match.group(1)
    match = re.search(r"/(\d+)\.jpg$", url)
    return match.group(1) if match else None


def download(session: requests.Session, url: str, dest: Path) -> bool:
    """Fetch one image. Returns True only when a real image landed on disk."""
    try:
        response = session.get(url, timeout=30)
    except requests.RequestException as exc:
        print(f"  {dest.name}: {exc}", file=sys.stderr)
        return False

    content_type = response.headers.get("content-type", "")
    if response.status_code != 200 or not content_type.startswith("image/"):
        # Without the Googlebot UA this is where an HTML redirect shows up.
        print(f"  {dest.name}: HTTP {response.status_code} {content_type}", file=sys.stderr)
        return False
    if len(response.content) < MIN_IMAGE_BYTES:
        print(f"  {dest.name}: only {len(response.content)} bytes", file=sys.stderr)
        return False

    try:
        image = Image.open(io.BytesIO(response.content))
        image = image.convert("RGB")
        image.thumbnail((MAX_EDGE, MAX_EDGE), Image.LANCZOS)
        image.save(dest, "JPEG", quality=JPEG_QUALITY, optimize=True, progressive=True)
    except Exception as exc:                                    # noqa: BLE001
        # Unreadable bytes are not worth publishing.
        print(f"  {dest.name}: could not decode ({exc})", file=sys.stderr)
        return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="Mirror RONB images")
    parser.add_argument("feed", help="ronb_feed.json to rewrite in place")
    parser.add_argument("--image-dir", required=True)
    parser.add_argument("--base-url", required=True,
                        help="Public URL the image directory is served from")
    args = parser.parse_args()

    feed_path = Path(args.feed)
    feed = json.loads(feed_path.read_text(encoding="utf-8"))
    image_dir = Path(args.image_dir)
    image_dir.mkdir(parents=True, exist_ok=True)

    session = requests.Session()
    session.headers.update({"User-Agent": GOOGLEBOT_UA})

    base_url = args.base_url.rstrip("/")
    referenced: set[str] = set()
    downloaded = reused = failed = 0

    for post in feed.get("posts", []):
        source = post.get("imageUrl")
        ident = media_id(source) if source else None
        if not ident:
            post["imageUrl"] = None
            continue

        filename = f"{ident}.jpg"
        destination = image_dir / filename

        if destination.exists() and destination.stat().st_size >= MIN_IMAGE_BYTES:
            reused += 1
        elif download(session, source, destination):
            downloaded += 1
            time.sleep(0.3)          # be a polite scraper
        else:
            failed += 1
            post["imageUrl"] = None
            continue

        referenced.add(filename)
        post["imageUrl"] = f"{base_url}/{image_dir.name}/{filename}"

    # Drop images belonging to posts that have scrolled out of the feed.
    pruned = 0
    for existing in image_dir.glob("*.jpg"):
        if existing.name not in referenced:
            existing.unlink()
            pruned += 1

    feed_path.write_text(
        json.dumps(feed, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(
        f"images: {downloaded} downloaded, {reused} reused, {failed} failed, "
        f"{pruned} pruned",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
