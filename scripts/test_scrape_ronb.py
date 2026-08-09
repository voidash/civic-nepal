#!/usr/bin/env python3
"""Regression tests for the RONB scraper.

Run with:  python3 scripts/test_scrape_ronb.py

These cover the two failures that made the shipped feed wrong for months
without anything erroring out:

  * every post came back with `url: null`, because the permalink pattern
    expected literal `/` where Facebook's embedded JSON escapes it as `\\/`;
  * nearest-offset pairing handed one photo to two adjacent posts.

Both produced a perfectly well-formed feed, so only a test that inspects the
extracted values catches them coming back.
"""

import unittest

from scrape_ronb import FACEBOOK_PAGE, extract_posts, unescape


def _block(post_id: str, ts: int, message: str, media_id: str | None) -> str:
    """One post, shaped like Facebook's embedded JSON.

    The id is repeated around the payload the way the real page repeats it,
    since that adjacency is what the extractor keys off.
    """
    photo = (
        '"photo_image":{"uri":"https:\\/\\/lookaside.fbsbx.com\\/lookaside'
        f'\\/crawler\\/media\\/?media_id={media_id}","width":720}},'
        if media_id
        else ""
    )
    return (
        f'{{"post_id":"{post_id}","creation_time":{ts},"cix_screen":null}},'
        f'{{"post_id":"{post_id}","message":{{"text":"{message}"}},'
        f'{photo}'
        f'"actors":[{{"name":"RONB"}}],"post_id":"{post_id}"}},'
    )


class UnescapeTest(unittest.TestCase):
    def test_unescapes_solidus(self):
        # The old implementation left this as "Pic\/Story".
        self.assertEqual(unescape(r"Pic\/Story: Raj\/Roshan"), "Pic/Story: Raj/Roshan")

    def test_decodes_devanagari(self):
        self.assertEqual(unescape(r"नयाँ"), "नयाँ")

    def test_decodes_surrogate_pairs(self):
        # Emoji arrive as a UTF-16 surrogate pair; decoding each half alone
        # yields two replacement characters instead of the emoji.
        self.assertEqual(unescape(r"🙏"), "🙏")

    def test_survives_truncated_escape(self):
        # A capture cut mid-escape must still return usable text.
        self.assertEqual(unescape(r"hello\/world\u12"), "hello/world\\u12")


class ExtractPostsTest(unittest.TestCase):
    def setUp(self):
        self.html = (
            _block("111", 1786252802, r"नयाँ post one", "900")
            + _block("222", 1786251348, "post two, no photo", None)
            + _block("333", 1786248186, "post three", "901")
        )
        self.posts = extract_posts(self.html)

    def test_extracts_every_post(self):
        self.assertEqual(len(self.posts), 3)

    def test_sorted_newest_first(self):
        self.assertEqual([p["id"] for p in self.posts], ["111", "222", "333"])

    def test_builds_permalink_from_post_id(self):
        self.assertEqual(
            self.posts[0]["url"],
            f"https://www.facebook.com/{FACEBOOK_PAGE}/posts/111",
        )

    def test_images_are_not_shared_between_posts(self):
        images = [p["imageUrl"] for p in self.posts if p["imageUrl"]]
        self.assertEqual(len(images), 2)
        self.assertEqual(len(set(images)), 2, "a photo was attributed to two posts")

    def test_post_without_photo_has_no_image(self):
        by_id = {p["id"]: p for p in self.posts}
        self.assertIsNone(by_id["222"]["imageUrl"])
        self.assertIn("media_id=900", by_id["111"]["imageUrl"])
        self.assertIn("media_id=901", by_id["333"]["imageUrl"])

    def test_text_is_unescaped(self):
        self.assertTrue(self.posts[0]["text"].startswith("नयाँ"))

    def test_timestamps_are_paired_with_the_right_post(self):
        by_id = {p["id"]: p for p in self.posts}
        self.assertEqual(by_id["222"]["timestamp"], 1786251348)
        self.assertEqual(by_id["222"]["datetime_npt"], "2026-08-09 10:40")

    def test_post_with_no_message_is_skipped(self):
        html = '{"post_id":"444","creation_time":1786252802,"cix_screen":null},'
        self.assertEqual(extract_posts(html), [])

    def test_empty_page_yields_nothing(self):
        self.assertEqual(extract_posts("<html>blocked</html>"), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
