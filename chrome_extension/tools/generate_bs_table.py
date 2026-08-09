#!/usr/bin/env python3
"""Generate `chrome_extension/src/bs-data.js` from the nepali_utils package.

The Bikram Sambat calendar has no closed-form rule — month lengths are set by
astronomical calculation and published per year — so any implementation is a
lookup table. Rather than transcribe one (and risk a typo nobody would notice
until a festival landed on the wrong day), the table is extracted from the
`nepali_utils` Dart package the Flutter app already depends on.

Every row is checked: the twelve month lengths must sum to the stated year
length, and the years must form an unbroken run.

Usage:
    python3 chrome_extension/tools/generate_bs_table.py
"""

import glob
import pathlib
import re
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
OUTPUT = REPO_ROOT / "chrome_extension" / "src" / "bs-data.js"


def find_source() -> pathlib.Path:
    """Locate nepali_date_time.dart in the pub cache."""
    pattern = str(
        pathlib.Path.home()
        / ".pub-cache/hosted/pub.dev/nepali_utils-*/lib/src/nepali_date_time.dart"
    )
    matches = sorted(glob.glob(pattern))
    if not matches:
        sys.exit(
            "Could not find nepali_utils in the pub cache.\n"
            "Run `flutter pub get` in flutter_app/ first."
        )
    return pathlib.Path(matches[-1])


def parse(source: str) -> dict[int, list[int]]:
    try:
        body = source.split("const Map<int, List<int>> _nepaliYears = {")[1].split("};")[0]
    except IndexError:
        sys.exit("The _nepaliYears table is not where it used to be in nepali_utils.")

    table: dict[int, list[int]] = {}
    for year, values in re.findall(r"(\d{4}):\s*\[([\d,\s]+)\]", body):
        numbers = [int(v) for v in values.split(",") if v.strip()]
        if len(numbers) != 13:
            sys.exit(f"BS {year}: expected 13 values, got {len(numbers)}")
        if sum(numbers[1:]) != numbers[0]:
            sys.exit(
                f"BS {year}: months sum to {sum(numbers[1:])} "
                f"but the year is declared as {numbers[0]}"
            )
        table[int(year)] = numbers

    years = sorted(table)
    if years != list(range(years[0], years[-1] + 1)):
        sys.exit("The year range has a gap in it.")
    return table


def render(table: dict[int, list[int]]) -> str:
    years = sorted(table)
    lines = [
        "// AUTO-GENERATED — do not edit by hand.",
        "// Regenerate with: python3 chrome_extension/tools/generate_bs_table.py",
        "//",
        "// Bikram Sambat month lengths, extracted verbatim from the nepali_utils",
        "// Dart package that the app itself uses, so the extension and the app can",
        "// never disagree about a date.",
        "//",
        "// Each row is [daysInYear, Baisakh, Jestha, ... Chaitra].",
        "",
        "export const BS_EPOCH_AD = { year: 1913, month: 4, day: 13 }; // = BS 1970-01-01",
        f"export const BS_MIN_YEAR = {years[0]};",
        f"export const BS_MAX_YEAR = {years[-1]};",
        "",
        "export const BS_YEARS = {",
    ]
    lines += [f"  {y}: [{', '.join(str(n) for n in table[y])}]," for y in years]
    lines.append("};")
    return "\n".join(lines) + "\n"


def main() -> int:
    source = find_source()
    table = parse(source.read_text())
    OUTPUT.write_text(render(table))
    years = sorted(table)
    print(f"Read {source}")
    print(f"Wrote {len(table)} years ({years[0]}-{years[-1]}) to {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
