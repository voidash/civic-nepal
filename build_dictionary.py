#!/usr/bin/env python3
"""
Extract Nepali-English dictionary from aligned sentence pairs.
Processes per-sentence.json and builds dictionary.json incrementally.
Uses TF-IDF weighting for better translation quality.
"""

import json
import re
import math
from collections import defaultdict, Counter
from typing import Dict, List, Tuple, Set

# English stop words to filter out
ENGLISH_STOP_WORDS = {
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'be',
    'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
    'would', 'should', 'could', 'may', 'might', 'must', 'can', 'shall',
    'this', 'that', 'these', 'those', 'it', 'its', 'he', 'she', 'they',
    'we', 'you', 'i', 'me', 'him', 'her', 'them', 'us', 'my', 'your',
    'his', 'their', 'our', 'what', 'which', 'who', 'when', 'where', 'why',
    'how', 'all', 'each', 'every', 'both', 'few', 'more', 'most', 'other',
    'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than',
    'too', 'very', 'any'
}

def tokenize_nepali(text: str) -> List[str]:
    """Tokenize Nepali text - split on whitespace and punctuation."""
    # Remove common Nepali punctuation
    text = re.sub(r'[।॥,;:\(\)\[\]{}\"\'""''`]', ' ', text)
    # Split and filter empty strings
    words = [w.strip() for w in text.split() if w.strip()]
    return words

def tokenize_english(text: str) -> List[str]:
    """Tokenize English text - lowercase and split."""
    # Convert to lowercase
    text = text.lower()
    # Remove punctuation
    text = re.sub(r'[,;:\(\)\[\]{}\"\'""''`]', ' ', text)
    # Split and filter
    words = [w.strip() for w in text.split() if w.strip() and len(w) > 1]
    return words

def extract_sentence_pairs(data: dict) -> List[Tuple[str, str]]:
    """Extract all aligned Nepali-English sentence pairs from the data."""
    pairs = []

    # Preamble
    if 'preamble' in data['constitution']:
        preamble = data['constitution']['preamble']
        if 'aligned_sentences' in preamble:
            for pair in preamble['aligned_sentences']:
                if pair.get('np') and pair.get('en'):
                    pairs.append((pair['np'], pair['en']))

    # Parts and articles
    for part in data['constitution'].get('parts', []):
        for article in part.get('articles', []):
            for content_item in article.get('content', []):
                if 'aligned_sentences' in content_item:
                    for pair in content_item['aligned_sentences']:
                        if pair.get('np') and pair.get('en'):
                            pairs.append((pair['np'], pair['en']))

    return pairs

def build_cooccurrence_matrix(sentence_pairs: List[Tuple[str, str]]) -> Tuple[Dict[str, Counter], Dict[str, int]]:
    """Build word co-occurrence matrix from sentence pairs with TF-IDF support."""
    cooccurrence = defaultdict(Counter)
    document_frequency = defaultdict(int)  # How many sentence pairs contain each English word

    print(f"Processing {len(sentence_pairs)} sentence pairs...")

    for idx, (np_sentence, en_sentence) in enumerate(sentence_pairs):
        if (idx + 1) % 100 == 0:
            print(f"  Processed {idx + 1}/{len(sentence_pairs)} sentences...")

        np_words = tokenize_nepali(np_sentence)
        en_words = tokenize_english(en_sentence)

        # Filter stop words
        en_words = [w for w in en_words if w not in ENGLISH_STOP_WORDS]

        # Track unique English words in this sentence pair for DF calculation
        unique_en_words = set(en_words)
        for en_word in unique_en_words:
            document_frequency[en_word] += 1

        # Count co-occurrences
        for np_word in np_words:
            for en_word in en_words:
                cooccurrence[np_word][en_word] += 1

    print(f"✓ Completed processing {len(sentence_pairs)} sentences")
    return cooccurrence, document_frequency

def generate_dictionary(cooccurrence: Dict[str, Counter],
                       document_frequency: Dict[str, int],
                       total_docs: int,
                       min_cooccurrence: int = 2,
                       max_translations: int = 5) -> Dict[str, List[Dict]]:
    """Generate dictionary from co-occurrence matrix using TF-IDF scoring."""
    dictionary = {}

    for np_word, en_counter in cooccurrence.items():
        # Skip very short words (likely punctuation artifacts)
        if len(np_word) < 2:
            continue

        # Calculate TF-IDF scores for each English translation
        tfidf_scores = {}
        for en_word, count in en_counter.items():
            # TF: term frequency (normalized by total co-occurrences for this Nepali word)
            tf = count / sum(en_counter.values())

            # IDF: inverse document frequency
            df = document_frequency.get(en_word, 1)
            idf = math.log(total_docs / df)

            # TF-IDF score
            tfidf_scores[en_word] = tf * idf

        # Sort by TF-IDF score (descending)
        sorted_translations = sorted(tfidf_scores.items(), key=lambda x: x[1], reverse=True)

        # Get top translations
        translations = []
        for en_word, tfidf_score in sorted_translations[:max_translations]:
            count = en_counter[en_word]
            if count >= min_cooccurrence:
                translations.append({
                    "word": en_word,
                    "frequency": count,
                    "tfidf": round(tfidf_score, 3),
                    "confidence": round(count / sum(en_counter.values()), 3)
                })

        if translations:
            dictionary[np_word] = translations

    return dictionary

def save_dictionary_incremental(dictionary: Dict, output_file: str, batch_size: int = 100):
    """Save dictionary to JSON file incrementally."""
    print(f"\nSaving dictionary to {output_file}...")

    sorted_words = sorted(dictionary.keys())
    total = len(sorted_words)

    result = {}

    for idx, word in enumerate(sorted_words):
        result[word] = dictionary[word]

        if (idx + 1) % batch_size == 0:
            print(f"  Saved {idx + 1}/{total} entries...")

    # Write final result
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(f"✓ Dictionary saved: {total} Nepali words with translations")

def generate_stats(dictionary: Dict):
    """Print dictionary statistics."""
    total_words = len(dictionary)
    total_translations = sum(len(translations) for translations in dictionary.values())
    avg_translations = total_translations / total_words if total_words > 0 else 0

    print("\n" + "="*60)
    print("DICTIONARY STATISTICS")
    print("="*60)
    print(f"Total Nepali words: {total_words}")
    print(f"Total translations: {total_translations}")
    print(f"Avg translations per word: {avg_translations:.2f}")

    # Sample entries
    print("\nSample entries:")
    for word, translations in list(dictionary.items())[:10]:
        print(f"\n{word}:")
        for t in translations[:3]:
            print(f"  → {t['word']} (tfidf: {t['tfidf']}, freq: {t['frequency']}, conf: {t['confidence']})")

def main():
    print("="*60)
    print("NEPALI-ENGLISH DICTIONARY BUILDER")
    print("="*60)

    # Load data
    print("\n1. Loading per-sentence.json...")
    with open('per-sentence.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    print("✓ Loaded constitution data")

    # Extract sentence pairs
    print("\n2. Extracting sentence pairs...")
    sentence_pairs = extract_sentence_pairs(data)
    print(f"✓ Found {len(sentence_pairs)} aligned sentence pairs")

    # Build co-occurrence matrix
    print("\n3. Building word co-occurrence matrix...")
    cooccurrence, document_frequency = build_cooccurrence_matrix(sentence_pairs)
    print(f"✓ Found {len(cooccurrence)} unique Nepali words")

    # Generate dictionary
    print("\n4. Generating dictionary with TF-IDF scoring...")
    dictionary = generate_dictionary(
        cooccurrence,
        document_frequency,
        total_docs=len(sentence_pairs),
        min_cooccurrence=2,
        max_translations=5
    )

    # Save dictionary
    print("\n5. Saving dictionary...")
    save_dictionary_incremental(dictionary, 'dictionary.json', batch_size=100)

    # Print stats
    generate_stats(dictionary)

    print("\n" + "="*60)
    print("✓ COMPLETE")
    print("="*60)

if __name__ == "__main__":
    main()
