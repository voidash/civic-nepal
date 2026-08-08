#!/usr/bin/env python3
"""Transliterate leftover Latin proper nouns in Nepali calendar event names.

`nepali_calendar_events.json` carries an `events_np` list per day, produced by a
machine translation that only replaced common words. Proper nouns were left in
Roman script, so 28% of Nepali festival names read as half-English:

    "Harisayani एकादशी"      instead of  "हरिशयनी एकादशी"
    "Putrada एकादशी व्रत"     instead of  "पुत्रदा एकादशी व्रत"
    "Smartaharuko Mohini..."  instead of  "स्मार्तहरूको मोहिनी..."

The same name is also spelled several ways across years (Mokshyada / Moksyada /
Mokhchyada / Mokhshyada), so this doubles as a spelling normaliser.

Scope and safety
----------------
Only TRANSLITERATION is done here — Roman Nepali/Sanskrit rendered into
Devanagari. Entries whose Devanagari form is standard and unambiguous live in
CONFIDENT. Everything else is left untouched and reported by `--report`, most
notably the entries that embed whole English *clauses* ("Public holiday for
Womens only in Ktm Valley"). Those need translation, not transliteration, and a
native speaker should write them.

Usage:
    python3 scripts/fix_event_transliteration.py --report   # what is left over
    python3 scripts/fix_event_transliteration.py --dry-run
    python3 scripts/fix_event_transliteration.py
"""

import json
import re
import sys
from collections import Counter
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

TARGETS = [
    REPO_ROOT / "data" / "nepali_calendar_events.json",
    REPO_ROOT / "flutter_app" / "assets" / "data" / "nepali_calendar_events.json",
]

# Roman token -> Devanagari. Keys are matched case-insensitively as whole words.
#
# These are the recurring festival/observance names of the Bikram Sambat
# calendar; the Devanagari spellings are the standard ones used by Nepali
# patros. Variant Roman spellings of one name all map to a single form, which
# also removes the year-to-year inconsistency in the source data.
CONFIDENT = {
    # ---- the twenty-four Ekadashi ----
    "putrada": "पुत्रदा",
    "nirjala": "निर्जला",
    "yogini": "योगिनी", "yogani": "योगिनी",
    "mohini": "मोहिनी",
    "safala": "सफला", "saphala": "सफला",
    "aamalaki": "आमलकी", "aamlaki": "आमलकी",
    "ajaa": "अजा", "aja": "अजा",
    "baruthini": "वरूथिनी",
    "harisayani": "हरिशयनी",
    "indira": "इन्दिरा",
    "kamada": "कामदा", "kaamada": "कामदा", "kaamadaa": "कामदा",
    "kamika": "कामिका",
    "apara": "अपरा", "aparaa": "अपरा", "apar": "अपरा",
    "mokshyada": "मोक्षदा", "moksyada": "मोक्षदा", "mokhchyada": "मोक्षदा",
    "mokhshyada": "मोक्षदा", "mokchhyada": "मोक्षदा",
    "papangkusha": "पापाङ्कुशा", "papankusha": "पापाङ्कुशा", "pampakusha": "पापाङ्कुशा",
    "haribodhini": "हरिबोधिनी", "haribodhani": "हरिबोधिनी",
    "haripariwartini": "हरिपरिवर्तिनी", "hariparwartini": "हरिपरिवर्तिनी",
    "haripariwartani": "हरिपरिवर्तिनी", "hariparwatini": "हरिपरिवर्तिनी",
    "padmini": "पद्मिनी", "padhmini": "पद्मिनी",
    "parama": "परमा", "paramaa": "परमा",
    "shatila": "षट्तिला", "shattila": "षट्तिला", "shadtila": "षट्तिला",
    "paapmochini": "पापमोचिनी", "paapmochani": "पापमोचिनी",
    "mochini": "पापमोचिनी", "mochani": "पापमोचिनी",
    "jaya": "जया",
    "rama": "रमा",
    "utpatika": "उत्पन्ना", "uttpatika": "उत्पन्ना", "upatika": "उत्पन्ना",
    "upattika": "उत्पन्ना", "utpattika": "उत्पन्ना",

    # ---- sect qualifiers that prefix many observances ----
    "smartaharuko": "स्मार्तहरूको", "smartharuko": "स्मार्तहरूको",
    "smartako": "स्मार्तको", "smartko": "स्मार्तको", "smarta": "स्मार्त",
    "baishnabharuko": "वैष्णवहरूको", "baisnabharuko": "वैष्णवहरूको",
    "baishnabko": "वैष्णवको", "baishnab": "वैष्णव", "baisnab": "वैष्णव",
    "baishanab": "वैष्णव", "biashnab": "वैष्णव",
    "haruko": "हरूको",
    "brat": "व्रत", "brata": "व्रत", "bratam": "व्रत",

    # ---- other recurring names ----
    "bhanu": "भानु",
    "dhanwantari": "धन्वन्तरी",
    "chandi": "चण्डी",
    "kaag": "काग",
    "kojagrat": "कोजाग्रत",
    "mahabir": "महावीर", "mahavir": "महावीर",
    "nanak": "नानक", "gurunanak": "गुरुनानक",
    "guru": "गुरु",
    "snan": "स्नान", "snaan": "स्नान",
    "chaite": "चैते", "chaitey": "चैते", "chaiti": "चैते",
    "tika": "टीका",
    "saune": "साउने",
    "basanta": "बसन्त",
    "sita": "सीता",
    "ram": "राम",
    "barah": "वराह", "baraha": "वराह",
    "gautam": "गौतम",
    "ghyalpo": "ग्याल्पो",
    "shadananda": "षडानन्द", "shadanand": "षडानन्द",
    "bhima": "भीम",
    "shree": "श्री",
    "falgu": "फाल्गु",
    "terai": "तराई",
    "saparu": "सापारु",
    "byas": "व्यास",
    "govinda": "गोविन्द", "gobinda": "गोविन्द", "gowinda": "गोविन्द",
    "kalki": "कल्की",
    "kurma": "कूर्म",
    "matsya": "मत्स्य",
    "baman": "वामन",
    "narshinha": "नरसिंह", "narsinha": "नरसिंह", "nrisimha": "नरसिंह",
    "narasimha": "नरसिंह",
    "shankaracharya": "शंकराचार्य",
    "nimbakarcharya": "निम्बार्काचार्य",
    "gorakhnath": "गोरखनाथ",
    "bhairab": "भैरव", "bairab": "भैरव",
    "indrajatra": "इन्द्रजात्रा", "indrajatraa": "इन्द्रजात्रा",
    "ghodejatra": "घोडेजात्रा",
    "jatra": "जात्रा", "yatra": "यात्रा", "rathyatra": "रथयात्रा",
    "rath": "रथ",
    "swasthani": "स्वस्थानी",
    "motiram": "मोतिराम",
    "lekhnath": "लेखनाथ",
    "prithivi": "पृथ्वी",
    "shani": "शनि",
    "kabir": "कबीर",
    "sonam": "सोनाम",
    "lochhar": "ल्होछार",
    "tamang": "तामाङ", "tamu": "तमु",
    "newar": "नेवार", "newars": "नेवार",
    "yamari": "यमरी", "yomaripunhi": "योमरी पुन्ही",
    "punhi": "पुन्ही",
    "bungadhya": "बुंगद्य",
    "kumari": "कुमारी",
    "indra": "इन्द्र",
    "indreshwor": "इन्द्रेश्वर",
    "dhaneshwar": "धनेश्वर",
    "goswami": "गोस्वामी",
    "tulashidash": "तुलसीदास", "tulashi": "तुलसी",
    "geeta": "गीता",
    "saptami": "सप्तमी", "sasthi": "षष्ठी", "panchami": "पञ्चमी",
    "chaturthi": "चतुर्थी", "chaturdashi": "चतुर्दशी", "dashami": "दशमी",
    "nawami": "नवमी", "ditiya": "द्वितीया", "chauthi": "चौथी",
    "shiromani": "शिरोमणि",
    "siruwa": "सिरुवा",
    "masta": "मष्टा",
    "panauti": "पनौती",
    "bhaktapur": "भक्तपुर",
    "lalitpur": "ललितपुर",
    "kathmandu": "काठमाडौं", "ktm": "काठमाडौं", "bkt": "भक्तपुर",
    "jhapa": "झापा",
    "madhesh": "मधेश",
    "nepal": "नेपाल",
    "singh": "सिंह", "sinha": "सिंह",
    "moti": "मोति",
    "dhan": "धन",
    "kukur": "कुकुर", "kukkur": "कुकुर",
    "puja": "पूजा",
    "janma": "जन्म",
    "diwas": "दिवस",
    "unmulan": "उन्मूलन",
    "bhedbhav": "भेदभाव",
    "chuwachut": "छुवाछूत",
    "jatiya": "जातीय",
    "nijamati": "निजामती",
    "tatha": "तथा",
    "lagi": "लागि",
    "din": "दिन",
    "ko": "को", "ka": "का", "ma": "मा",
    "suru": "सुरु", "aarambha": "आरम्भ", "samapti": "समाप्ति",
    "parba": "पर्व", "parwa": "पर्व", "pawani": "पावनी",
    "bijaya": "विजया", "bijay": "विजया",
    "paap": "पाप",
    "tol": "टोल",
    "kali": "काली", "kalipithma": "कालीपीठमा", "pithma": "पीठमा",
    "shankranti": "सङ्क्रान्ति", "shakranti": "सङ्क्रान्ति",
    "shangkranti": "सङ्क्रान्ति", "shrankranti": "सङ्क्रान्ति",
    "nepali": "नेपाली",
    "sikh": "सिख", "sikhs": "सिख", "shikhs": "सिख",
    "jain": "जैन", "jains": "जैन",
    "pahadi": "पहाडी",
    "brahmachari": "ब्रह्मचारी", "bramhachari": "ब्रह्मचारी",
    "adhyaguru": "आद्यगुरु", "aadhyaguru": "आद्यगुरु",
    "shashidhar": "शशिधर", "sashidhar": "शशिधर",
    "sarashwoti": "सरस्वती",
    "bishwa": "विश्व",
    "nawa": "नव",
    "katin": "कातिन",
    "nhwan": "न्हवं", "nhawa": "न्हवं",
    "sighaya": "सिघःया",
    "gaiyamauni": "गाईजात्रा",
    "matamaha": "मातामह",
    "darsha": "दर्श", "darshasradda": "दर्श श्राद्ध", "shraddam": "श्राद्ध",
    "uthaune": "उठाउने", "thadyaune": "ठड्याउने",
    "lingo": "लिङ्गो",
    "shikha": "शिखा",
    "vastu": "वास्तु",
    "bajra": "वज्र",
    "padhyasambhav": "पद्मसम्भव",
    "saptarshipuja": "सप्तर्षि पूजा",
    "kabi": "कवि",
    "baisakh": "बैशाख",
    "shrawan": "श्रावण",
    "sombar": "सोमबार",
    "crow": "काग", "dog": "कुकुर", "dogs": "कुकुर",
}

# The original translation substituted Devanagari *inside* Roman words, gluing
# the two scripts together mid-token: "Holiday" became "होलीday", "Magh Snan"
# became "माघsnan". Word-boundary matching cannot see these, so they are
# repaired as substrings first. Longest keys are applied first.
GLUED = {
    "माघeShangranti": "माघे सङ्क्रान्ति",
    "माघesankranti": "माघे सङ्क्रान्ति",
    "माघeShankranti": "माघे सङ्क्रान्ति",
    "माघe Shangranti": "माघे सङ्क्रान्ति",
    "माघe Shankranti": "माघे सङ्क्रान्ति",
    "माघe": "माघे",
    "माघsnan": "माघ स्नान",
    "होलीkarambha": "होली आरम्भ",
    "ekadashibratam": "एकादशी व्रत",
    "व्रतa": "व्रत",
    "व्रतam": "व्रत",
    "स्मार्तानाम": "स्मार्तहरूको",
    "Baishabanam": "वैष्णवहरूको",
    "Baishnabanam": "वैष्णवहरूको",
}

WORD_RE = re.compile(r"[A-Za-z][A-Za-z']*")
LATIN_RE = re.compile(r"[A-Za-z]")


def transliterate(text: str) -> str:
    out = text
    for glued, fixed in sorted(GLUED.items(), key=lambda kv: -len(kv[0])):
        out = out.replace(glued, fixed)

    def repl(match: "re.Match[str]") -> str:
        word = match.group(0)
        return CONFIDENT.get(word.lower(), word)

    out = WORD_RE.sub(repl, out)
    # Collapse whitespace and stray space-before-punctuation the substitutions
    # may have left behind.
    out = re.sub(r"\s{2,}", " ", out)
    out = re.sub(r"\s+([),।])", r"\1", out)
    return out.strip()


def walk(data: dict):
    """Yield every (day_dict, index, event_string) in events_np."""
    for month in data.values():
        if not isinstance(month, dict):
            continue
        for day in month.get("days", []) or []:
            for i, event in enumerate(day.get("events_np", []) or []):
                yield day, i, event


def report(path: Path) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    leftover = Counter()
    still_mixed = Counter()
    for _, _, event in walk(data):
        fixed = transliterate(event)
        if LATIN_RE.search(fixed):
            still_mixed[fixed] += 1
            for word in WORD_RE.findall(fixed):
                leftover[word.lower()] += 1

    print(f"--- {path.relative_to(REPO_ROOT)} ---")
    print(f"strings still containing Latin after mapping: {len(still_mixed)}")
    print(f"distinct unmapped tokens: {len(leftover)}\n")
    print("Most common unmapped tokens (these need translation, not transliteration):")
    for word, count in leftover.most_common(40):
        print(f"  {word:22} {count}")
    print("\nExample strings still needing a native speaker:")
    for text, count in still_mixed.most_common(15):
        print(f"  {count:3}  {text}")


def apply(path: Path, dry_run: bool) -> None:
    if not path.exists():
        print(f"skip (missing): {path}")
        return

    data = json.loads(path.read_text(encoding="utf-8"))
    changed = 0
    fully_fixed = 0
    for day, i, event in walk(data):
        fixed = transliterate(event)
        if fixed == event:
            continue
        changed += 1
        if not LATIN_RE.search(fixed):
            fully_fixed += 1
        if not dry_run:
            day["events_np"][i] = fixed

    if changed and not dry_run:
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )

    verb = "would rewrite" if dry_run else "rewrote"
    print(
        f"{verb} {changed} event names in {path.relative_to(REPO_ROOT)} "
        f"({fully_fixed} now fully Devanagari)"
    )


def main() -> None:
    if "--report" in sys.argv:
        report(TARGETS[-1])
        return
    dry_run = "--dry-run" in sys.argv
    for path in TARGETS:
        apply(path, dry_run)


if __name__ == "__main__":
    main()
