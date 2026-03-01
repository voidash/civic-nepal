#!/usr/bin/env python3
"""
Extract BS calendar month-length tables from nepali_utils Dart package.

Reads _nepaliYears map from nepali_date_time.dart and outputs structured JSON
for consumption by native macOS (Swift) and Windows (C#) apps.

Source: nepali_utils 3.0.8 — pub.dev/packages/nepali_utils
"""

import json
import re
import sys
from pathlib import Path

DART_SOURCE = Path.home() / ".pub-cache/hosted/pub.dev/nepali_utils-3.0.8/lib/src/nepali_date_time.dart"
OUTPUT = Path(__file__).resolve().parent.parent / "data" / "bs_calendar_data.json"

# Matches lines like: 1969: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
YEAR_PATTERN = re.compile(r"^\s*(\d{4}):\s*\[([^\]]+)\]")


def parse_nepali_years(dart_path: Path) -> dict[str, list[int]]:
    if not dart_path.exists():
        print(f"ERROR: Dart source not found at {dart_path}", file=sys.stderr)
        print("Install nepali_utils 3.0.8: flutter pub add nepali_utils", file=sys.stderr)
        sys.exit(1)

    years: dict[str, list[int]] = {}
    in_map = False

    with open(dart_path, "r") as f:
        for line in f:
            stripped = line.strip()

            if "_nepaliYears" in stripped and "{" in stripped:
                in_map = True
                continue

            if in_map and stripped == "};":
                break

            if not in_map:
                continue

            match = YEAR_PATTERN.match(stripped)
            if match:
                year_str = match.group(1)
                values = [int(v.strip()) for v in match.group(2).split(",")]
                if len(values) != 13:
                    print(
                        f"WARNING: Year {year_str} has {len(values)} values (expected 13)",
                        file=sys.stderr,
                    )
                years[year_str] = values

    if not years:
        print("ERROR: No year data found in Dart source", file=sys.stderr)
        sys.exit(1)

    return years


def validate_years(years: dict[str, list[int]]) -> None:
    """Sanity-check extracted data against known invariants."""
    year_keys = sorted(int(k) for k in years)

    # Must be contiguous range
    expected = list(range(year_keys[0], year_keys[-1] + 1))
    if year_keys != expected:
        missing = set(expected) - set(year_keys)
        print(f"WARNING: Missing years: {sorted(missing)}", file=sys.stderr)

    for year_str, values in years.items():
        total = values[0]
        month_sum = sum(values[1:])
        if total != month_sum:
            print(
                f"WARNING: Year {year_str} total={total} but months sum to {month_sum}",
                file=sys.stderr,
            )

    # Known anomaly: year 2200 has placeholder data
    if "2200" in years:
        v = years["2200"]
        if v == [372, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31]:
            print(
                "NOTE: Year 2200 has placeholder data (all 31s). This is expected.",
                file=sys.stderr,
            )

    print(f"Extracted {len(years)} years: BS {year_keys[0]}–{year_keys[-1]}", file=sys.stderr)


def build_output(years: dict[str, list[int]]) -> dict:
    return {
        "meta": {
            "source": "nepali_utils 3.0.8",
            "extracted_by": "scripts/extract_bs_calendar_data.py",
            "reference_ad": "1913-04-13",
            "reference_bs": {"year": 1970, "month": 1, "day": 1},
            "year_range": [
                min(int(k) for k in years),
                max(int(k) for k in years),
            ],
            "nepal_tz_offset_seconds": 20700,
        },
        "month_names_en": [
            "Baisakh", "Jestha", "Ashadh", "Shrawan",
            "Bhadra", "Ashwin", "Kartik", "Mangsir",
            "Poush", "Magh", "Falgun", "Chaitra",
        ],
        "month_names_np": [
            "बैशाख", "जेठ", "असार", "श्रावण",
            "भाद्र", "आश्विन", "कार्तिक", "मंसिर",
            "पौष", "माघ", "फागुन", "चैत्र",
        ],
        "weekday_names_en": [
            "Sunday", "Monday", "Tuesday", "Wednesday",
            "Thursday", "Friday", "Saturday",
        ],
        "weekday_names_np": [
            "आइतबार", "सोमबार", "मंगलबार", "बुधबार",
            "बिहीबार", "शुक्रबार", "शनिबार",
        ],
        "weekday_names_np_short": ["आ", "सो", "मं", "बु", "बि", "शु", "श"],
        "years": years,
    }


def main() -> None:
    print(f"Reading Dart source: {DART_SOURCE}", file=sys.stderr)
    years = parse_nepali_years(DART_SOURCE)
    validate_years(years)

    output = build_output(years)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT, "w") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"Written to: {OUTPUT}", file=sys.stderr)

    # Quick verification
    data = json.loads(OUTPUT.read_text())
    assert len(data["years"]) == len(years)
    print("Verification passed.", file=sys.stderr)


if __name__ == "__main__":
    main()
