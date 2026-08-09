# Nagarik Patro browser extension

Puts Nepali dates next to English ones, on any page, and on Google Calendar.

## Install (unpacked)

1. Open `chrome://extensions`
2. Turn on **Developer mode**
3. **Load unpacked** → select this `chrome_extension/` directory

No build step. There is no bundler, no `package.json`, and no dependency to
install — the source that ships is the source you read.

## What it shows

| Calendar | Precision |
|---|---|
| Bikram Sambat (विक्रम सम्वत्) | Exact, 1970–2250 BS |
| Nepal Sambat (नेपाल सम्वत्) | Exact year |
| Saka Sambat (शक सम्वत्) | Exact |
| Buddha Sambat (बुद्ध सम्वत्) | Exact year, 2069–2083 BS |

Where a calendar cannot be stated exactly for a given date, it is left out
rather than approximated. Nepal Sambat and Buddha Sambat both turn over on
lunar festivals (Mha Puja and Buddha Jayanti), so outside the years whose
festival dates are known, the year is only reported for the months where it is
unambiguous.

## Settings

- **Beside the date** or **on hover only**
- Devanagari (१२३) or Latin (123) numerals
- Nepali or English month names
- How to read `09/08/2026` — month-first, day-first, or skip it entirely
- Which extra calendars appear in the hover card
- Per-site blocklist

## Google Calendar

With the toggle on, each day cell on `calendar.google.com` gains its Bikram
Sambat day number, and the first of each Nepali month is labelled.

The date for a cell is taken from Google's `aria-label` and cross-checked
against its `data-datekey`. When the two disagree — which is what would happen
if Google changed the undocumented `datekey` packing — the cell is left alone.
A calendar showing a wrong date is worse than one showing no Nepali date.

## Where the conversion comes from

`src/bs-data.js` is generated, not hand-written. It is extracted verbatim from
the `nepali_utils` Dart package that the Flutter app itself uses, so the app
and the extension cannot disagree about a date:

```bash
python3 chrome_extension/tools/generate_bs_table.py
```

The JS conversion is diffed against Dart's, day by day, over 1944–2090 — 53,692
days, currently zero mismatches:

```bash
cd flutter_app && dart run tool/dump_dart_bs.dart > /tmp/dart_bs.txt
node chrome_extension/tools/compare_with_dart.mjs /tmp/dart_bs.txt
```

## Tests

```bash
# Conversion, date detection, Google Calendar decoding
node --test 'chrome_extension/test/*.test.mjs'

# The real extension in a real Chromium
xvfb-run -a env NAGARIK_HEADLESS=0 node chrome_extension/test/e2e.mjs
```

The end-to-end run needs Playwright (`npm i -g playwright`). It must run
headed — Chromium does not load extensions in headless mode — and it serves its
fixture over HTTP, because the manifest matches only `http`/`https` and a
`file://` fixture would pass while testing nothing.

## Known limitation

The Google Calendar overlay has been tested against a fixture that replicates
Google's cell structure, not against the live site. Google's markup is
minified and changes without notice; if the overlay stops appearing, that is
the first thing to check.
