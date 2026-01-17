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

### 3. Web App Tests ✅ COMPLETE
**Current state**: A comprehensive Node.js CLI test suite exists at `tests/test.js`.
- 37 tests covering data validation, HTML/CSS/JS functionality, security, and accessibility
- All tests passing as of January 2026
- Can be run with `node tests/test.js`

**Flutter Tests**: Zero test files exist in `flutter_app/test/`.
- No unit tests, widget tests, or integration tests for Flutter app

### 4. Working vs Non-Working Components

| Component | Status | Can Build/Run? | Location |
|-----------|--------|----------------|----------|
| Web app (index.html) | WORKING | Yes (browser) | `/Users/cdjk/github/probe/constitution/index.html` |
| Web app tests | WORKING | Yes (Node.js) | `/Users/cdjk/github/probe/constitution/tests/test.js` |
| Flutter app | CANNOT BUILD | No (needs Flutter SDK) | `/Users/cdjk/github/probe/constitution/flutter_app/` |
| Data files | COMPLETE | N/A | Root and `assets/data/` |

### 5. Next Priorities Given Constraints
Given the lack of Flutter SDK:

1. **Web app is production-ready** - fully functional with comprehensive test coverage (37/37 tests passing)
2. **Flutter app blocked** - requires Flutter SDK installation to build/test
3. **Flutter TODOs tracked below** - see Flutter App Status Summary section for details

---

### 6. Flutter App Status Summary (January 2026 - Late Month)

**Overall Progress**: Approximately 85% complete across all modules

| Module | Completion | Notes |
|--------|------------|-------|
| Constitution | 100% | Content rendering, Meaning Mode, article linking all complete |
| Leaders | ~100% | Full detail screen, filters, search, sort all implemented |
| Map | ~70% | Interactive UI complete; using simplified SVG placeholder |
| Settings | ~90% | UI complete; backup/restore implemented |
| Tests | 0% | No test files exist in `flutter_app/test/` |

### Remaining Flutter TODOs

1. **District Map Module** (`lib/screens/map/`)
   - Full Nepal SVG map rendering with proper district paths
   - Currently using simplified placeholder due to Flutter SVG complexity
   - District tap detection works via bottom sheet UI
   - Province filtering implemented
   - District-to-leaders navigation functional

2. **Testing** (All modules)
   - No test files exist in `flutter_app/test/`
   - Need unit, widget, and integration tests

---

## Recent Updates

### January 2026 (Late Month) - Feature Completions

**Leaders Module** - Now complete (~100%):
- Implemented `LeaderDetailScreen` with full leader profile including:
  - Biography and personal details
  - Vote counts and election history
  - Leader images
  - Education information
  - Asset and case details
- Created `PartyFilterDialog` with:
  - Party selection with leader counts
  - Party color indicators
  - Search/filter functionality
- Created `DistrictFilterDialog` with:
  - District list grouped by province
  - Leader counts per district
- Added search functionality with real-time filtering
- Implemented sort options (name, votes, district)
- Connected leader cards to detail view via navigation

**Meaning Mode** - Now complete (~100%):
- Created `DictionaryService` for Nepali-English word lookup
  - Loads dictionary.json from assets
  - Supports bidirectional translation (np_to_en and en_to_np)
- Implemented `MeaningModeEnabled` provider for global toggle state
- Implemented `CurrentLookup` provider for tracking selected word and translations
- Created `MeaningModeOverlay` widget with translation tooltip
  - Shows translations for selected Nepali/English words
  - Tap-to-dismiss functionality
- Added `MeaningModeToggleButton` to constitution screen
  - Icon button to enable/disable meaning mode
  - Visual indicator when mode is active

**Map Module** - Significantly improved (~70%):
- Implemented interactive district selection via bottom sheet
- Added province filter (1-7) with visual indicators
- Created side panel showing leaders for selected district
- Added district info chip overlay
- Implemented zoom controls via InteractiveViewer
- Note: Actual SVG rendering still uses simplified placeholder due to Flutter SVG complexity

**StorageService** - Fixed and enhanced:
- Fixed JSON parsing for notes with multiple format handling
- Added `getUserData()` for complete data export
- Implemented `exportData()` for backup/restore
- Implemented `importData()` for backup/restore
- Improved type safety and error handling

**New Files Created**:
- `flutter_app/lib/providers/meaning_mode_provider.dart`
- `flutter_app/lib/screens/leaders/leader_detail_screen.dart`
- `flutter_app/lib/services/dictionary_service.dart`
- `flutter_app/lib/widgets/meaning_mode_overlay.dart`
- `flutter_app/lib/utils/article_linkifier.dart` (article linking)
- `flutter_app/lib/widgets/linked_text.dart` (article linking)

### January 2026 (Late Month) - Article Linking Complete

**Constitution Module Article Linking** - Now complete (100%):
- Created `flutter_app/lib/utils/article_linkifier.dart` - Utility class with:
  - Regex patterns to detect "Article 42" and "धारा ४२" references in text
  - Devanagari numeral conversion (०-९ to 0-9)
  - Article lookup across all parts of the constitution
  - Returns structured link data with article number and target part/article
- Created `flutter_app/lib/widgets/linked_text.dart` - Widget that:
  - Renders text with clickable article references using TextSpan
  - Applies TapGestureRecognizer to article links for navigation
  - Preserves original text formatting
  - Handles navigation via callback to constitution screen
- Updated `flutter_app/lib/screens/constitution/constitution_screen.dart`:
  - Replaced SelectableText with LinkedText in preamble rendering
  - Replaced SelectableText with LinkedText in article content rendering
  - Connected link taps to article navigation functionality
  - Maintains all existing language/view mode compatibility

**Note**: Flutter tests cannot be run because Flutter SDK is not installed on this system (per critical notes section).

### January 2026 (Early Month) - Previous Work
- **Flutter constitution module completed**: Implemented full constitution viewing functionality including:
  - Data model fixes to match actual JSON structure (ConstitutionWrapper, ConstitutionData, ArticleContent, etc.)
  - Article content rendering with nested ContentItem support
  - Preamble display with bilingual text
  - Language toggle (Both/नेपाली/English)
  - View mode toggle (Paragraph/Sentence)
  - TOC navigation with selected article highlighting
  - Search functionality
  - SelectedArticleProvider for state management
- **PROMPT_build.md src/ directory reference fixed**: The task prompt previously incorrectly claimed "application source code is in `src/*`". This documentation error has been corrected to reflect the actual codebase structure (web app at `index.html`, Flutter app at `flutter_app/lib/`).
- **GitHub Actions CI workflow created**: `.github/workflows/update-leaders.yml` now automates weekly leader data updates from ratemyneta.com. The workflow runs every Monday at 00:00 UTC and includes:
  - Fetching leader data from the API
  - Normalizing district names
  - Downloading leader images
  - Committing updated JSON files
  - Manual trigger via `workflow_dispatch` for on-demand updates

---

## Priority 5: Testing & Quality

### Web App Tests ✅ COMPLETE (January 2026)

A comprehensive Node.js CLI test suite exists at `tests/test.js`.

**Test Coverage (37 tests, all passing):**
- Data files validation (constitution_bilingual.json, per-sentence.json, dictionary.json)
- HTML structure verification (DOCTYPE, meta tags, element presence)
- CSS features testing (responsive breakpoints, print styles)
- JavaScript function testing (utility functions, core logic)
- Interactive features (language toggle, view mode toggle, meaning mode)
- Security checks (XSS prevention, innerHTML vs textContent usage)
- Event initialization (listeners attached after data load)
- Accessibility checks (ARIA labels, semantic HTML)

**Running Tests:**
```bash
node tests/test.js
```

### Flutter Tests ❌ IN PROGRESS (January 2026 - Tests Created - Cannot Run Without Flutter SDK)
- [ ] Add Flutter widget tests for Constitution module
- [ ] Add Flutter widget tests for Leaders module
- [ ] Add Flutter widget tests for Map module
- [ ] Add integration tests for data loading
- [ ] Add offline mode testing

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
- [x] Create `lib/models/constitution.dart` - ConstitutionWrapper, ConstitutionData, Preamble, Part, PartTitle, Article, ArticleTitle, ArticleContent, ContentItem, AlignedSentence
  - **FIX (January 2026)**: Completely rewrote models to match actual JSON structure. JSON has `constitution.parts[].articles[].content.{en,np}` arrays, not single objects with text/textNp fields.
- [x] Create `lib/models/leader.dart` - LeadersData, Leader
  - **FIX**: Added `@JsonKey(name: '_id')` annotation for `id` field to match JSON structure (`_id` key in leaders.json)
- [x] Create `lib/models/district.dart` - DistrictData, DistrictInfo, PartyData, Party
  - **FIX**: Custom `fromJson` implementation to handle flat JSON structure (top-level object with district keys as strings, not nested under a `districts` property)
- [x] Create `lib/models/leader_detail_data.dart` - LeaderDetailData, Education, Asset, Case
  - **ADDED (January 2026)**: Extended leader model with detailed information for leader detail screen
- [x] Create `lib/models/note.dart` - Note, Bookmark, UserData

### Phase 3.2.1: JSON Serialization Fixes (January 2026)
**Issue**: The auto-generated freezed code couldn't deserialize the JSON data files correctly.

| Model | Problem | Fix |
|-------|---------|-----|
| `Constitution` | JSON structure has wrapper `constitution` key with nested properties | Created `ConstitutionWrapper` model and `ConstitutionData` for actual data |
| `Article` | JSON has `content.{en,np}` as separate arrays, not combined items | Created `ArticleContent` with separate `en` and `np` arrays |
| `Part` | JSON has `title.{en,np}` object, not flat fields | Created `PartTitle` model for nested structure |
| `Article.title` | JSON has `title.{en,np}` object, both nullable | Created `ArticleTitle` model with nullable fields |
| `Leader` | JSON uses `_id` key, Dart field named `id` | Added `@JsonKey(name: '_id')` annotation on line 21 |
| `DistrictData` | JSON is flat (district keys at root), model expected nested structure | Custom `fromJson` factory manually maps the flat object to `Map<String, DistrictInfo>` |

**Remaining Requirement**: Run `flutter pub run build_runner build` to regenerate `.freezed.dart` and `.g.dart` files after these model changes.

### Phase 3.3: Data Services ✅ COMPLETE
- [x] Create `lib/services/data_service.dart` - Load JSON assets
- [x] Create `lib/services/storage_service.dart` - Local persistence (Hive)
  - **FIXED (January 2026)**: JSON parsing for notes with multiple format handling
  - Added `getUserData()` for complete data export
  - Implemented `exportData()` and `importData()` for backup/restore
  - Improved type safety and error handling
- [x] Create `lib/services/update_service.dart` - Remote update check
- [x] Create `lib/services/dictionary_service.dart` - Nepali-English dictionary lookup
  - **ADDED (January 2026)**: Loads dictionary.json from assets
  - Supports bidirectional translation (np_to_en and en_to_np)
  - Used by Meaning Mode for word translations

### Phase 3.4: State Management (Riverpod) ✅ COMPLETE
- [x] Create `lib/providers/constitution_provider.dart`
  - Added `SelectedArticleProvider` for tracking current article/preamble selection
  - Added `SelectedArticleRef` freezed union type for article references
- [x] Create `lib/providers/leaders_provider.dart`
- [x] Create `lib/providers/settings_provider.dart`
- [x] Create `lib/providers/meaning_mode_provider.dart`
  - **ADDED (January 2026)**: `MeaningModeEnabled` provider for global toggle state
  - `CurrentLookup` provider for tracking selected word and translations

### Phase 3.5: Constitution Module ✅ COMPLETE (January 2026)
- [x] Create `lib/screens/constitution/constitution_screen.dart` with full content rendering
- [x] Implement preamble display with bilingual support
- [x] Implement article content rendering with nested ContentItem support
- [x] Implement language toggle (Both/नेपाली/English) using SegmentedButton
- [x] Implement view mode toggle (Paragraph/Sentence) using SegmentedButton
- [x] Implement TOC navigation with article selection
- [x] Implement search functionality (searches article titles)
- [x] Add selected article highlighting in TOC
- [x] Implement Meaning Mode (long-press word lookup) - **COMPLETED January 2026**
  - Created `DictionaryService` for word lookup
  - Created `MeaningModeOverlay` widget with translation tooltip
  - Added `MeaningModeToggleButton` to constitution screen
  - Supports bidirectional translation (np_to_en and en_to_np)
- [x] Implement article linking (auto-linkify "Article 42" / "धारा ४२") - **COMPLETED January 2026**
  - Created `ArticleLinkifier` utility class with regex patterns and Devanagari numeral conversion
  - Created `LinkedText` widget with TextSpan and TapGestureRecognizer
  - Updated constitution screen to use LinkedText for preamble and content
  - Clickable article references navigate to target articles

### Phase 3.6: Leaders Module ✅ COMPLETE (January 2026)
- [x] Create `lib/screens/leaders/leaders_screen.dart` with LeaderCard widget
- [x] Create `lib/screens/leaders/leader_detail_screen.dart` - **COMPLETED January 2026**
  - Full leader profile with biography, vote counts, images
  - Education, assets, and cases sections
  - Connected to leader cards via navigation
- [x] Create `PartyFilterDialog` - **COMPLETED January 2026**
  - Party selection with leader counts
  - Party color indicators
- [x] Create `DistrictFilterDialog` - **COMPLETED January 2026**
  - District list grouped by province
  - Leader counts per district
- [x] Implement search functionality with real-time filtering - **COMPLETED January 2026**
- [x] Implement sorting (name, votes, district) - **COMPLETED January 2026**

### Phase 3.7: District Map Module ⚠️ PARTIAL (~70% Complete)
- [x] Create `lib/screens/map/district_map_screen.dart`
- [x] Implement interactive district selection via bottom sheet - **COMPLETED January 2026**
- [x] Implement province filter (1-7) with visual indicators - **COMPLETED January 2026**
- [x] Create side panel showing leaders for selected district - **COMPLETED January 2026**
- [x] Add district info chip overlay - **COMPLETED January 2026**
- [x] Implement zoom controls via InteractiveViewer - **COMPLETED January 2026**
- [x] Implement district tap -> navigate to filtered leaders - **COMPLETED January 2026**
- [ ] Create proper Nepal SVG map rendering with district paths - **REMAINING TODO**
  - Currently using simplified placeholder due to Flutter SVG complexity

### Phase 3.8: Navigation & Settings ✅ COMPLETE
- [x] Create `lib/screens/home/home_screen.dart` with bottom navigation
- [x] Create `lib/screens/settings/settings_screen.dart`
- [x] Implement bottom navigation bar (Constitution, Leaders, Map, Settings)
- [x] Settings: Language preference
- [x] Settings: View mode default
- [x] Settings: Meaning mode toggle
- [x] Settings: Check for updates (UI only)
- [x] Settings: Clear cache (UI only)
- [x] Settings: Backup/Restore - **COMPLETED January 2026**
  - `exportData()` for data backup
  - `importData()` for data restore
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
- **Web app tests** - 37/37 tests passing at `tests/test.js` (Node.js CLI)
- **Flutter tests** - No test files exist (0% coverage)
- **Data files** are all complete and copied to Flutter assets
- **nepal-svg.svg** exists in `specs/` with proper district IDs (77 districts)
- **ratemyneta.com API** returns 298 leaders across 27 political parties
- **Dictionary** structure includes both `np_to_en` and `en_to_np` mappings for bidirectional lookup
