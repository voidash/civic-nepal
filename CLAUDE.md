# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Static website for Nepal's Constitution in bilingual format (Nepali + English). No build system - just JSON data files and a single-page HTML/JS application.

## Development

Run local server:
```bash
python3 -m http.server 8000
```
Then open http://localhost:8000

## Architecture

### Data Files
- `constitution_bilingual.json` - Paragraph-level bilingual data (35 parts, 308 articles, 100% Nepali/95.8% English coverage)
- `per-sentence.json` - Sentence-level aligned pairs for 1:1 Nepali↔English alignment
- `dictionary.json` - Nepali-English dictionary (~2,581 words) with TF-IDF weighted translations

### Dictionary Build Scripts
- `build_dictionary.py` - Statistical TF-IDF approach using word co-occurrence from aligned sentences
- `build_dictionary_llm.py` - LLM-based approach using `crush run` to extract translations (saves progress to `.dictionary_progress.json`)

Regenerate dictionary:
```bash
python3 build_dictionary.py
```

### Website (`index.html`)
Single-file vanilla JS application with:
- Two-column layout: TOC sidebar, main content area
- Language toggle (Both/Nepali/English) and view mode toggle (Paragraph/Sentence)
- **Meaning Mode**: Highlight any Nepali word to see English translations from dictionary
- Deep linking via URL hash (`#article-42`, `#preamble`)

### Data Structure
```
constitution.parts[].articles[].content.np/en[]
  - type: "subsection" | "text"
  - identifier: "(१)" or "(1)"
  - text: string
  - items: [] (nested sub-items)
```

Sentence-level data uses `aligned_sentences: [{np, en}]` arrays.

## Key Implementation Details

- No framework/build tooling - edit `index.html` directly
- CSS is embedded in `<style>`, JS in `<script>`
- Responsive grid layout collapses to single column on mobile
- Print stylesheet hides sidebars and controls
- Nepali text split by Devanagari danda (।), English by standard sentence terminators
