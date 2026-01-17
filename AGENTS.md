# AGENTS.md

Operational guide for building and running this project. Keep this file brief (~60 lines max).

## Build & Run

Run local server:
```bash
python3 -m http.server 8000
```
Then open http://localhost:8000

## Validation

Run these after implementing to get immediate feedback:

- No build step required (static HTML/JS)
- Open browser console to check for JS errors
- Test language toggles and view mode switches manually

## Operational Notes

- This is a single-file vanilla JS application (`index.html`)
- No framework or build tooling - edit `index.html` directly
- CSS is embedded in `<style>`, JS in `<script>`
- Data files: `constitution_bilingual.json`, `per-sentence.json`, `dictionary.json`

## Codebase Patterns

- Deep linking via URL hash (`#article-42`, `#preamble`)
- Language toggle state: `currentLang` ('both', 'nepali', 'english')
- View mode state: `currentView` ('paragraph', 'sentence')
- Nepali text split by Devanagari danda (।)
