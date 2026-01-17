#!/usr/bin/env python3
"""
Build Nepali-English dictionary using crush run.
Processes paragraphs in chunks for efficiency.
"""

import json
import subprocess
import sys
import time
from pathlib import Path

CHUNK_SIZE = 10  # paragraphs per API call
DICTIONARY_FILE = Path("dictionary.json")
PROGRESS_FILE = Path(".dictionary_progress.json")

PROMPT_TEMPLATE = '''You are building a Nepali-English dictionary from Nepal's Constitution.

Below are {count} aligned paragraph pairs (Nepali and English translations).

{paragraphs}

Extract word-level translations from these paragraphs.

Rules:
1. Extract individual words only, not phrases
2. Use root/base forms (e.g., गर्छ -> गर्नु)
3. Skip particles: को, मा, ले, लाई, र, छ, हो, थियो
4. Only include confident translations from context
5. Include important legal/political/constitutional terms

Return ONLY a valid JSON array:
[{{"np": "नेपाली", "en": "english"}}, ...]

No markdown code blocks, no explanation, just the raw JSON array.'''


def load_progress():
    if PROGRESS_FILE.exists():
        with open(PROGRESS_FILE) as f:
            return json.load(f)
    return {"processed_chunks": 0, "dictionary": {}}


def save_progress(progress):
    with open(PROGRESS_FILE, "w") as f:
        json.dump(progress, f, ensure_ascii=False)


def save_dictionary(dictionary):
    sorted_dict = {}
    for word in sorted(dictionary.keys()):
        translations = sorted(dictionary[word], key=lambda x: -x.get("frequency", 1))
        sorted_dict[word] = translations

    with open(DICTIONARY_FILE, "w", encoding="utf-8") as f:
        json.dump(sorted_dict, f, ensure_ascii=False, indent=2)


def extract_paragraphs(data):
    """Extract paragraph pairs from constitution."""
    paragraphs = []

    # Preamble
    preamble = data["constitution"].get("preamble", {})
    if preamble.get("np") and preamble.get("en"):
        paragraphs.append({
            "np": preamble["np"][:1500],
            "en": preamble["en"][:1500]
        })

    # Parts and articles
    for part in data["constitution"].get("parts", []):
        # Part title
        if part.get("title", {}).get("np") and part.get("title", {}).get("en"):
            paragraphs.append({
                "np": part["title"]["np"],
                "en": part["title"]["en"]
            })

        for article in part.get("articles", []):
            # Article title
            if article.get("title", {}).get("np") and article.get("title", {}).get("en"):
                paragraphs.append({
                    "np": article["title"]["np"],
                    "en": article["title"]["en"]
                })

            # Article content
            np_texts = []
            en_texts = []

            for item in article.get("content", {}).get("np", []):
                if item.get("text"):
                    np_texts.append(item["text"])
                for sub in item.get("items", []):
                    if sub.get("text"):
                        np_texts.append(sub["text"])

            for item in article.get("content", {}).get("en", []):
                if item.get("text"):
                    en_texts.append(item["text"])
                for sub in item.get("items", []):
                    if sub.get("text"):
                        en_texts.append(sub["text"])

            if np_texts and en_texts:
                paragraphs.append({
                    "np": " ".join(np_texts)[:1500],
                    "en": " ".join(en_texts)[:1500]
                })

    return paragraphs


def call_crush(prompt):
    """Call crush run and parse JSON response."""
    try:
        result = subprocess.run(
            ["crush", "run", "--quiet", prompt],
            capture_output=True,
            text=True,
            timeout=180
        )

        output = result.stdout.strip()
        if not output:
            return []

        # Clean markdown if present
        if "```json" in output:
            output = output.split("```json")[1].split("```")[0]
        elif "```" in output:
            parts = output.split("```")
            if len(parts) >= 2:
                output = parts[1]

        output = output.strip()

        # Find JSON array
        start = output.find("[")
        end = output.rfind("]") + 1
        if start >= 0 and end > start:
            output = output[start:end]

        return json.loads(output)

    except subprocess.TimeoutExpired:
        print("  ⚠ Timeout", file=sys.stderr)
        return []
    except json.JSONDecodeError as e:
        print(f"  ⚠ JSON error: {e}", file=sys.stderr)
        return []
    except Exception as e:
        print(f"  ⚠ Error: {e}", file=sys.stderr)
        return []


def format_chunk(paragraphs):
    """Format paragraphs for prompt."""
    parts = []
    for i, p in enumerate(paragraphs, 1):
        parts.append(f"[{i}]\nNP: {p['np']}\nEN: {p['en']}")
    return "\n\n".join(parts)


def merge_entries(dictionary, entries):
    """Merge entries into dictionary."""
    added = 0
    for entry in entries:
        np_word = entry.get("np", "").strip()
        en_word = entry.get("en", "").strip()

        if not np_word or not en_word or len(np_word) < 2 or len(en_word) < 2:
            continue

        if np_word not in dictionary:
            dictionary[np_word] = []

        existing = [t["word"].lower() for t in dictionary[np_word]]
        if en_word.lower() not in existing:
            dictionary[np_word].append({"word": en_word, "frequency": 1})
            added += 1
        else:
            for t in dictionary[np_word]:
                if t["word"].lower() == en_word.lower():
                    t["frequency"] += 1
                    break

    return dictionary, added


def main():
    print("=" * 60)
    print("NEPALI-ENGLISH DICTIONARY BUILDER")
    print("=" * 60)

    # Load data
    print("\n1. Loading constitution...")
    with open("constitution_bilingual.json", encoding="utf-8") as f:
        data = json.load(f)

    paragraphs = extract_paragraphs(data)
    print(f"   {len(paragraphs)} paragraph pairs")

    # Load progress
    progress = load_progress()
    start_chunk = progress["processed_chunks"]
    dictionary = progress["dictionary"]
    print(f"   Resume from chunk {start_chunk}, {len(dictionary)} words")

    # Chunk
    chunks = [paragraphs[i:i+CHUNK_SIZE] for i in range(0, len(paragraphs), CHUNK_SIZE)]
    total = len(chunks)

    print(f"\n2. Processing {total} chunks...")

    for idx in range(start_chunk, total):
        chunk = chunks[idx]
        print(f"\n   [{idx+1}/{total}] {len(chunk)} paragraphs...", end=" ", flush=True)

        formatted = format_chunk(chunk)
        prompt = PROMPT_TEMPLATE.format(count=len(chunk), paragraphs=formatted)

        entries = call_crush(prompt)

        if entries:
            dictionary, added = merge_entries(dictionary, entries)
            print(f"✓ +{added} words ({len(dictionary)} total)")
        else:
            print("⚠ no entries")

        # Save
        progress["processed_chunks"] = idx + 1
        progress["dictionary"] = dictionary
        save_progress(progress)
        save_dictionary(dictionary)

        time.sleep(0.5)

    print("\n" + "=" * 60)
    print(f"DONE! {len(dictionary)} words in dictionary.json")
    print("=" * 60)

    # Sample
    print("\nSamples:")
    for word, trans in list(dictionary.items())[:20]:
        t = ", ".join([x["word"] for x in trans[:3]])
        print(f"  {word}: {t}")


if __name__ == "__main__":
    main()
