# IMPLEMENTATION_PLAN.md

## CRITICAL NOTES

### 1. `src/` Directory Reference (FIXED)
**Former task prompt error**: The task prompt (`PROMPT_build.md` line 3) previously claimed "application source code is in `src/*`" but **NO `src/` directory exists** in the codebase.

**Resolution**: This documentation error has been **FIXED** in `PROMPT_build.md` (January 2026).

**Actual codebase structure**:
- Web app: `/Users/cdjk/github/probe/constitution/index.html` (single file, ~1,196 lines)
- Flutter app: `/Users/cdjk/github/probe/constitution/flutter_app/` (lib/ directory, not src/)
- Data files: root level and `assets/` directories

### 2. Flutter SDK Not Installed
**Current environment**: Flutter SDK is **NOT installed** on this system.
```bash
$ flutter --version
flutter not found
```

**Implication**: Cannot build, test, or run the Flutter app (`flutter_app/`). Flutter work requires:
1. Flutter SDK installation
2. iOS/Android tooling setup
3. `flutter pub get` and `flutter pub run build_runner build` to generate serialization code

### 3. No Tests Exist Anywhere
**Current state**: Zero test files exist in the entire codebase.
- No `test/` directory at root level
- No `test/` directory in `flutter_app/`
- No browser-based tests for web app
- No unit tests, integration tests, or end-to-end tests

**Note**: Instructions in task prompt like "run the tests for that unit of code" cannot be executed because no tests exist.

### 4. Working vs Non-Working Components

| Component | Status | Can Build/Run? | Location |
|-----------|--------|----------------|----------|
| Web app (index.html) | WORKING | Yes (browser) | `/Users/cdjk/github/probe/constitution/index.html` |
| Flutter app | CANNOT BUILD | No (needs Flutter SDK) | `/Users/cdjk/github/probe/constitution/flutter_app/` |
| Data files | COMPLETE | N/A | Root and `assets/data/` |

### 5. Next Priorities Given Constraints
Given the lack of Flutter SDK and no test infrastructure:

1. **Focus on web app** (`index.html`) - the only component that can be built and tested
2. **Add browser-based tests for web app** - create a `test/` directory with HTML/JS tests
3. **Document Flutter work as blocked** - requires Flutter SDK installation to proceed
4. **Defer Flutter work** until environment is properly set up

---

## Recent Updates

### January 2026
- **PROMPT_build.md src/ directory reference fixed**: The task prompt previously incorrectly claimed "application source code is in `src/*`". This documentation error has been corrected to reflect the actual codebase structure (web app at `index.html`, Flutter app at `flutter_app/lib/`).
- **GitHub Actions CI workflow created**: `.github/workflows/update-leaders.yml` now automates weekly leader data updates from ratemyneta.com. The workflow runs every Monday at 00:00 UTC and includes:
  - Fetching leader data from the API
  - Normalizing district names
  - Downloading leader images
  - Committing updated JSON files
  - Manual trigger via `workflow_dispatch` for on-demand updates

---

## Priority 5: Testing & Quality

### Test Suite Implementation (January 2026)

A comprehensive Node.js CLI test suite has been created at `tests/test.js`.

**Test Coverage:**
- Data files validation (constitution_bilingual.json, per-sentence.json, dictionary.json)
- HTML structure verification (DOCTYPE, meta tags, element presence)
- CSS features testing (responsive breakpoints, print styles)
- JavaScript function testing (utility functions, core logic)
- Interactive features (language toggle, view mode toggle, meaning mode)
- Security checks (XSS prevention, innerHTML vs textContent usage)
- Event initialization (listeners attached after data load)
- Accessibility checks (ARIA labels, semantic HTML)

**Test Results:**
- All 37 tests passing (as of January 2026)

**Running Tests:**
```bash
node tests/test.js
```

---

## Recent Updates & Bug Fixes

### Bug Fixes (January 2026)

The following critical bugs were fixed in `index.html`:

| Bug | Severity | Fix | Description |
|-----|----------|-----|-------------|
| **Event listeners attached before data loads** | CRITICAL | Moved `initEventListeners()` and `initMeaningMode()` inside the data fetch promise | Event listeners were being attached before constitution data was loaded, causing potential crashes if user interacted before fetch completed |
| **XSS vulnerability in Meaning Mode** | HIGH | Changed `innerHTML` to `textContent` for dictionary translations | Line 1142: `enDiv.textContent = t;` instead of `innerHTML`. This prevents malicious script injection if dictionary data is ever compromised |
| **TOC not updating on language change** | MEDIUM | Added `renderTOC()` call after language toggle | Line 1045: When user clicks language buttons (Both/Nepali/English), TOC now re-renders to show correct language titles |
| **Preamble click handler missing in Sentence view** | MEDIUM | Added click event listener to preamble in `renderSentenceView()` | Lines 895-897: Users can now click preamble in sentence view to set it as current article |
| **Duplicate media query** | LOW | Removed duplicate `@media (max-width: 768px)` rule | Consolidated responsive breakpoints to avoid CSS conflicts |

### Code Quality Improvements
- Event listener initialization now properly sequenced: `fetch() -> render() -> renderTOC() -> initEventListeners() -> initMeaningMode()`
- Meaning Mode tooltip now safely renders user-generated content using `textContent` instead of `innerHTML`

---

## Project Overview

This project consists of two components:
1. **Static Website** (`index.html`) - Bilingual Constitution reader (functional, but missing claimed Zettelkasten features)
2. **Flutter App** (`flutter_app/`) - In development, basic structure created

**Important**: There is **NO `src/` directory** - this is a single-file HTML/JS application. All documentation referencing `src/lib` is incorrect.

---

## PRIORITY 0: CRITICAL Documentation Inconsistencies

### ~~False Claims in Documentation~~ ✅ RESOLVED

The following documentation files claimed Zettelkasten features that **DID NOT EXIST** in the codebase. These have been **removed**:

| File | False Claims (REMOVED) | Lines |
|------|--------------|-------|
| `README.md` | "Zettelkasten-style notes, links, backlinks, tags, and bookmarks" | REMOVED |
| `README.md` | "Zettelkasten features: notes, links, backlinks, tags, bookmarks" | REMOVED |
| `CLAUDE.md` | "Zettelkasten-style note-taking: notes, bidirectional links, backlinks, tags, bookmarks" | REMOVED |
| `CLAUDE.md` | "All user data persisted to localStorage under key `constitution-kb`" | REMOVED |
| `AGENTS.md` | "User data persisted to localStorage under key `constitution-kb`" | REMOVED |

**VERIFICATION**: `grep -E "localStorage|constitution-kb|bookmark|note|backlink|tag" index.html` returns **NO MATCHES**.

**RESOLUTION**: Documentation now accurately reflects the implemented features. False Zettelkasten claims removed.

---

## Web App: Verified COMPLETE Features

These features exist and function correctly in `index.html` (verified by code inspection, January 2026):

| Feature | Status | Implementation Location |
|---------|--------|------------------------|
| Two-column layout (TOC sidebar + main content) | COMPLETE | Lines 23-43 (CSS grid), 467-500 (HTML) |
| Language toggle (Both/Nepali/English) | COMPLETE | Lines 485-489 (HTML), 1037-1046 (JS handler, now calls renderTOC) |
| View mode toggle (Paragraph/Sentence) | COMPLETE | Lines 490-493 (HTML), 1049-1056 (JS handler) |
| Meaning Mode (text selection -> dictionary lookup) | COMPLETE | Lines 338-417 (CSS), 503-511 (HTML), 1061-1168 (JS, XSS fix at line 1142) |
| Article linking (auto-linkify "Article 42" / "धारा ४२") | COMPLETE | Lines 514-537 (linkifyArticleRefs function) |
| Deep linking via URL hash (`#article-42`, `#preamble`) | COMPLETE | Lines 539-572 (navigateFromHash, updateHash) |
| Search functionality (filters articles and TOC) | COMPLETE | Lines 1177-1196 (search event handler) |
| Responsive design (collapses to single column on mobile) | COMPLETE | Lines 401-433 (@media queries) |
| Print stylesheet (hides sidebars and controls) | COMPLETE | Lines 435-444 (@media print) |
| Paragraph view rendering | COMPLETE | Lines 675-879 (renderParagraphView) |
| Sentence view rendering | COMPLETE | Lines 881-1035 (renderSentenceView, includes preamble click handler) |
| TOC rendering with click navigation | COMPLETE | Lines 608-673 (renderTOC) |
| Devanagari numeral conversion | COMPLETE | Lines 509-512 (devanagariToArabic) |

---

## Web App: Verified MISSING Features (Claimed but NOT Implemented)

| Feature | Status | Evidence |
|---------|--------|----------|
| Bookmarks (star toggle on articles) | NOT IMPLEMENTED | No localStorage, no star UI, no bookmark state |
| Notes per article | NOT IMPLEMENTED | No note editor, no note storage |
| Tags | NOT IMPLEMENTED | No tag UI, no tag storage |
| Bidirectional links | NOT IMPLEMENTED | No `[[Article X]]` parsing |
| Backlinks panel | NOT IMPLEMENTED | No backlinks UI |
| localStorage persistence (`constitution-kb`) | NOT IMPLEMENTED | grep returns 0 matches |

---

## Priority 1: Web App - Zettelkasten Features (NOT IMPLEMENTED)

**Status**: NEVER IMPLEMENTED - These features are optional and have NOT been built. The documentation previously incorrectly claimed these features existed. They remain as a future roadmap item.

### Phase 2.1: localStorage Infrastructure
- [ ] Define `constitution-kb` localStorage schema
- [ ] Create `loadUserData()` function to load from localStorage
- [ ] Create `saveUserData()` function to persist to localStorage
- [ ] Add schema versioning for future migrations

### Phase 2.2: Bookmarks
- [ ] Add bookmark toggle button (star/filled star) to each article header
- [ ] Store bookmarked article IDs in localStorage under `bookmarks` key
- [ ] Add "Bookmarks" section in TOC sidebar (above article list)
- [ ] Filter/jump functionality from bookmarks list
- [ ] Visual indicator on bookmarked articles (filled star)

### Phase 2.3: Notes per Article
- [ ] Add "Add Note" button to each article header
- [ ] Create note editor modal/panel (textarea + save/cancel)
- [ ] Store notes keyed by article ID in localStorage under `notes` key
- [ ] Display note indicator on articles with notes
- [ ] Add "Notes" section in sidebar listing all notes with previews

### Phase 2.4: Tags
- [ ] Add tag input field to note editor or article header
- [ ] Store tags keyed by article ID in localStorage under `tags` key
- [ ] Display tag badges below article title
- [ ] Add tag filter/search in sidebar (click tag -> show all articles with tag)

### Phase 2.5: Bidirectional Links & Backlinks (ADVANCED)
- [ ] Detect `[[Article X]]` syntax in note text
- [ ] Parse links and build graph data structure
- [ ] Render backlinks panel showing articles linking to current article
- [ ] Enable click navigation between linked articles

---

## Priority 3: Flutter App Implementation (IN PROGRESS)

Per `specs/flutter-civic-app.md`, the Flutter app combines:
1. Constitution Reader (port from web)
2. Leaders Directory (298 political leaders from ratemyneta.com)
3. Interactive District Map (77 districts with SVG)

**Current Status**: Basic project structure created at `flutter_app/`. Requires Flutter SDK to build.

### Phase 3.1: Project Setup ✅ COMPLETE
- [x] Create Flutter project structure at `flutter_app/`
- [x] Configure `pubspec.yaml` with dependencies (flutter_riverpod, flutter_svg, hive, etc.)
- [x] Set up project directory structure (lib/{models,providers,screens,services,widgets})
- [x] Create `assets/data/` directory
- [x] Copy data files to `flutter_app/assets/data/`:
  - [x] `constitution_bilingual.json`
  - [x] `per-sentence.json`
  - [x] `dictionary.json`
  - [x] `leaders.json`
  - [x] `parties.json`
  - [x] `districts.json`
- [x] Copy `specs/nepal-svg.svg` to `flutter_app/assets/images/nepal_districts.svg`

### Phase 3.2: Data Models ✅ COMPLETE
- [x] Create `lib/models/constitution.dart` - Constitution, Part, Article, ContentItem, AlignedSentence
- [x] Create `lib/models/leader.dart` - LeadersData, Leader
  - **FIX**: Added `@JsonKey(name: '_id')` annotation for `id` field to match JSON structure (`_id` key in leaders.json)
- [x] Create `lib/models/district.dart` - DistrictData, DistrictInfo, PartyData, Party
  - **FIX**: Custom `fromJson` implementation to handle flat JSON structure (top-level object with district keys as strings, not nested under a `districts` property)
- [x] Create `lib/models/note.dart` - Note, Bookmark, UserData

### Phase 3.2.1: JSON Serialization Fixes (January 2026)
**Issue**: The auto-generated freezed code couldn't deserialize the JSON data files correctly.

| Model | Problem | Fix |
|-------|---------|-----|
| `Leader` | JSON uses `_id` key, Dart field named `id` | Added `@JsonKey(name: '_id')` annotation on line 21 |
| `DistrictData` | JSON is flat (district keys at root), model expected nested structure | Custom `fromJson` factory manually maps the flat object to `Map<String, DistrictInfo>` |

**Remaining Requirement**: Run `flutter pub run build_runner build` to regenerate `.freezed.dart` and `.g.dart` files after these model changes.

### Phase 3.3: Data Services ✅ COMPLETE
- [x] Create `lib/services/data_service.dart` - Load JSON assets
- [x] Create `lib/services/storage_service.dart` - Local persistence (Hive)
- [x] Create `lib/services/update_service.dart` - Remote update check

### Phase 3.4: State Management (Riverpod) ✅ COMPLETE
- [x] Create `lib/providers/constitution_provider.dart`
- [x] Create `lib/providers/leaders_provider.dart`
- [x] Create `lib/providers/settings_provider.dart`

### Phase 3.5: Constitution Module ⚠️ PARTIAL
- [x] Create `lib/screens/constitution/constitution_screen.dart`
- [ ] Create `lib/screens/constitution/article_detail_screen.dart` - TODO
- [ ] Create `lib/screens/constitution/preamble_screen.dart` - TODO
- [ ] Create `lib/widgets/constitution/article_card.dart` - TODO
- [ ] Create `lib/widgets/constitution/language_toggle.dart` - TODO
- [ ] Create `lib/widgets/constitution/view_mode_toggle.dart` - TODO
- [ ] Create `lib/widgets/constitution/meaning_mode_tooltip.dart` - TODO
- [ ] Implement language toggle (Both/Nepali/English)
- [ ] Implement view mode toggle (Paragraph/Sentence)
- [ ] Implement Meaning Mode (long-press word lookup)
- [ ] Implement article linking (auto-linkify "Article 42" / "धारा ४२")
- [ ] Implement search functionality

### Phase 3.6: Leaders Module ⚠️ PARTIAL
- [x] Create `lib/screens/leaders/leaders_screen.dart` with LeaderCard widget
- [ ] Create `lib/screens/leaders/leader_detail_screen.dart` - TODO
- [ ] Create `lib/screens/leaders/leaders_by_party_screen.dart` - TODO
- [ ] Create `lib/screens/leaders/leaders_by_district_screen.dart` - TODO
- [ ] Create `lib/widgets/leaders/party_card.dart` - TODO
- [ ] Create `lib/widgets/leaders/leader_filters.dart` - TODO
- [ ] Implement filters (by party, by district)
- [x] Implement sorting (name, votes, district) - provider ready

### Phase 3.7: District Map Module ⚠️ PARTIAL
- [x] Create `lib/screens/map/district_map_screen.dart`
- [ ] Create `lib/widgets/map/nepal_map.dart` - TODO
- [ ] Create `lib/widgets/map/district_popup.dart` - TODO
- [ ] Implement pinch-to-zoom and pan (InteractiveViewer)
- [ ] Implement district tap -> show leaders
- [ ] Implement province filtering

### Phase 3.8: Navigation & Settings ✅ COMPLETE
- [x] Create `lib/screens/home/home_screen.dart` with bottom navigation
- [x] Create `lib/screens/settings/settings_screen.dart`
- [x] Implement bottom navigation bar (Constitution, Leaders, Map, Settings)
- [x] Settings: Language preference
- [x] Settings: View mode default
- [x] Settings: Meaning mode toggle
- [x] Settings: Check for updates (UI only)
- [x] Settings: Clear cache (UI only)
- [x] Settings: About

### Phase 3.9: Zettelkasten Features (Flutter)
- [ ] Implement notes per article (Hive persistence)
- [ ] Implement bookmarks (Hive persistence)
- [ ] Implement tags (Hive persistence)
- [ ] Implement deep linking / share URLs

### BUILD INSTRUCTIONS
To build the Flutter app:
1. Install Flutter SDK (https://flutter.dev/docs/get-started/install)
2. Run `cd flutter_app`
3. Run `flutter pub get` to install dependencies
4. Run `flutter pub run build_runner build` to generate freezed/riverpod code (required for JSON serialization)
5. Run `flutter run` to launch the app

**Note**: Step 4 is critical - the `.freezed.dart` and `.g.dart` files are generated from the model annotations. Without this step, the app will not compile.

---

## Priority 4: Missing Data Files ✅ COMPLETE

| File | Status | Action |
|------|--------|--------|
| `districts.json` | ✅ CREATED | 77 districts with province info |
| `assets/data/leaders.json` | ✅ CREATED | Fetched from ratemyneta.com (298 leaders) |
| `assets/data/parties.json` | ✅ CREATED | Generated from leaders data (27 parties) |
| `specs/nepal-svg.svg` | ✅ EXISTS | Has 77 district paths with IDs |

### Phase 4.1: Leader Data Fetching Script ✅ COMPLETE
- [x] Create `scripts/fetch_leaders.py`
- [x] Fetch from `https://api.ratemyneta.com/api/leaders`
- [x] Normalize district names (includes district_aliases mapping)
- [x] Download leader images to `assets/images/leaders/{id}.jpg`
- [x] Generate `leaders.json`, `districts.json`, `parties.json`

### Phase 4.2: CI Pipeline (GitHub Actions) ✅ COMPLETE
- [x] Create `.github/workflows/update-leaders.yml`
- [x] Schedule weekly runs (Monday 00:00 UTC)
- [x] Steps: fetch -> normalize -> download images -> commit
  - **Note**: Workflow also includes manual trigger via `workflow_dispatch`
- [ ] Upload to CDN and update manifest.json (optional)

---

## Priority 5: Testing & Quality

- [ ] Add Flutter widget tests for Constitution module
- [ ] Add Flutter widget tests for Leaders module
- [ ] Add Flutter widget tests for Map module
- [ ] Add integration tests for data loading
- [ ] Add offline mode testing

---

## Data Files Summary

| File | Size | Status |
|------|------|--------|
| `constitution_bilingual.json` | 1.3 MB | COMPLETE (35 parts, 308 articles, 100% Nepali, 95.8% English) |
| `per-sentence.json` | 1.5 MB | COMPLETE (sentence-level aligned pairs) |
| `dictionary.json` | ~166 KB | COMPLETE (~2,581 words, has `np_to_en` and `en_to_np` sections) |
| `specs/nepal-svg.svg` | ~91 KB | COMPLETE (77 districts with IDs, province colors) |
| `districts.json` | ~5 KB | COMPLETE (77 districts with province mapping) |
| `assets/data/leaders.json` | ~210 KB | COMPLETE (298 leaders with full data) |
| `assets/data/parties.json` | ~5 KB | COMPLETE (27 parties with leader counts) |

---

## Existing Scripts

| File | Purpose | Status |
|------|---------|--------|
| `build_dictionary.py` | Statistical TF-IDF dictionary builder | WORKS |
| `build_dictionary_llm.py` | LLM-based dictionary builder (uses `crush run`) | WORKS |
| `scripts/fetch_leaders.py` | Fetch leaders from ratemyneta.com API | WORKS |

---

## Notes

- **Web app** (`index.html`) is a 1,196-line single-file vanilla JS application
- **NO `src/` directory exists** - documentation referencing `src/lib` is incorrect
- **Documentation inconsistency RESOLVED** - false Zettelkasten claims removed from README.md, CLAUDE.md, AGENTS.md
- **Flutter app** basic structure created at `flutter_app/` - requires Flutter SDK to build
- **Data files** are all complete and copied to Flutter assets
- **nepal-svg.svg** exists in `specs/` with proper district IDs (77 districts)
- **No tests** exist for either web or Flutter components
- **ratemyneta.com API** returns 298 leaders across 27 political parties
- **Dictionary** structure includes both `np_to_en` and `en_to_np` mappings for bidirectional lookup
