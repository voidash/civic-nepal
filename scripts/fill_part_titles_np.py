#!/usr/bin/env python3
"""Fill in the missing Nepali (Devanagari) part titles of the Constitution.

`constitution_bilingual.json` and `per-sentence.json` shipped with `title.np`
empty for all 35 parts, so the table of contents — the navigation backbone of
the whole document — rendered in English even in the Nepali UI.

The headings below are the भाग titles of नेपालको संविधान (२०७२), keyed by part
number and cross-checked against the English title already present in the data;
the script refuses to write if that cross-check fails.

Usage:
    python3 scripts/fill_part_titles_np.py [--check]
"""

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

TARGETS = [
    REPO_ROOT / "constitution_bilingual.json",
    REPO_ROOT / "per-sentence.json",
    REPO_ROOT / "flutter_app" / "assets" / "data" / "constitution_bilingual.json",
    REPO_ROOT / "flutter_app" / "assets" / "data" / "per-sentence.json",
]

# part number -> (Nepali title, distinctive substring of the expected English title)
PART_TITLES_NP = {
    1:  ("प्रारम्भिक", "Preliminary"),
    2:  ("नागरिकता", "Citizenship"),
    3:  ("मौलिक हक तथा कर्तव्य", "Fundamental Rights"),
    4:  ("राज्यका निर्देशक सिद्धान्त, नीति तथा दायित्व", "Directive Principles"),
    5:  ("राज्यको संरचना र राज्यशक्तिको बाँडफाँट", "Structure of State"),
    6:  ("राष्ट्रपति र उपराष्ट्रपति", "President and Vice-President"),
    7:  ("संघीय कार्यपालिका", "Federal Executive"),
    8:  ("संघीय व्यवस्थापिका", "Federal Legislature"),
    9:  ("संघीय व्यवस्थापन कार्यविधि", "Federal Legislative"),
    10: ("संघीय आर्थिक कार्यप्रणाली", "Federal Financial"),
    11: ("न्यायपालिका", "Judiciary"),
    12: ("महान्यायाधिवक्ता", "Attorney General"),
    13: ("प्रदेश कार्यपालिका", "State Executive"),
    14: ("प्रदेश व्यवस्थापिका", "State Legislature"),
    15: ("प्रदेश व्यवस्थापन कार्यविधि", "State Legislative"),
    16: ("प्रदेश आर्थिक कार्यप्रणाली", "State Financial"),
    17: ("स्थानीय कार्यपालिका", "Local Executive"),
    18: ("स्थानीय व्यवस्थापिका", "Local Legislature"),
    19: ("स्थानीय आर्थिक कार्यप्रणाली", "Local Financial"),
    20: ("संघ, प्रदेश र स्थानीय तह बीचको अन्तरसम्बन्ध", "Interrelations between"),
    21: ("अख्तियार दुरुपयोग अनुसन्धान आयोग", "Abuse of Authority"),
    22: ("महालेखा परीक्षक", "Auditor General"),
    23: ("लोक सेवा आयोग", "Public Service Commission"),
    24: ("निर्वाचन आयोग", "Election Commission"),
    25: ("राष्ट्रिय मानव अधिकार आयोग", "National Human Rights Commission"),
    26: ("राष्ट्रिय प्राकृतिक स्रोत तथा वित्त आयोग", "Natural Resources and Fiscal"),
    27: ("अन्य आयोग", "Other Commissions"),
    28: ("राष्ट्रिय सुरक्षा सम्बन्धी व्यवस्था", "National Security"),
    29: ("राजनीतिक दल सम्बन्धी व्यवस्था", "Political Parties"),
    30: ("सङ्कटकालीन अधिकार", "Emergency Power"),
    31: ("संविधान संशोधन", "Amendment to the Constitution"),
    32: ("विविध", "Miscellaneous"),
    33: ("संक्रमणकालीन व्यवस्था", "Transitional Provisions"),
    34: ("परिभाषा र व्याख्या", "Definitions and Interpretations"),
    35: ("संक्षिप्त नाम, प्रारम्भ र खारेजी", "Short Title"),
}


def process(path: Path, check_only: bool) -> int:
    if not path.exists():
        print(f"skip (missing): {path}")
        return 0

    data = json.loads(path.read_text(encoding="utf-8"))
    parts = data["constitution"]["parts"]

    changed = 0
    for part in parts:
        number = part.get("number")
        entry = PART_TITLES_NP.get(number)
        if entry is None:
            print(f"  ! no Nepali title known for part {number}", file=sys.stderr)
            continue

        np_title, expected_en = entry
        actual_en = (part.get("title", {}).get("en") or "")
        if expected_en.lower() not in actual_en.lower():
            raise SystemExit(
                f"ABORT {path.name}: part {number} English title is "
                f"{actual_en!r}, expected it to contain {expected_en!r}. "
                "The mapping and the data disagree — refusing to write."
            )

        if (part["title"].get("np") or "").strip():
            continue  # already populated; never overwrite existing text

        if not check_only:
            part["title"]["np"] = np_title
        changed += 1

    if changed and not check_only:
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
    print(f"{'would fill' if check_only else 'filled'} {changed:2d} part titles in {path.relative_to(REPO_ROOT)}")
    return changed


def main() -> None:
    check_only = "--check" in sys.argv
    total = sum(process(p, check_only) for p in TARGETS)
    print(f"\n{'Would update' if check_only else 'Updated'} {total} part titles across {len(TARGETS)} files.")


if __name__ == "__main__":
    main()
