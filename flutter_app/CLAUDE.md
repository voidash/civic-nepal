# CLAUDE.md - Flutter App

This file provides guidance to Claude Code when working with this Flutter codebase.

## Project Overview

**Nagarik Calendar** - A comprehensive Nepali civic app with:
- Nepali Calendar with events and auspicious days
- Nepal's Constitution (bilingual: Nepali + English)
- Political leaders directory
- Interactive maps (districts, constituencies, local bodies)
- Civic tools (Photo Merger, Image/PDF Compressor, Date Converter, Unicode Converter)
- Government services information
- IPO/Shares, Forex, Gold prices

## Quick Start

```bash
# Fetch the Lua 5.4 sources the lua_engine plugin compiles against.
# Required for Android / macOS / Windows builds — they are gitignored, not
# vendored, so without this the native build fails on a missing lua.h.
# Web builds do not need it.
../scripts/fetch_lua.sh

# Install dependencies
flutter pub get

# Generate code (required after cloning)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run on web
flutter run -d chrome
```

## Architecture

### State Management
- **Riverpod** with code generation (`@riverpod` annotations)
- Providers in `lib/providers/`
- Generated files: `*.g.dart` (DO NOT edit manually)

### Routing
- **go_router** for navigation
- Routes defined in `lib/app.dart`
- Hash URLs on web for direct navigation support

### Data Models
- **Freezed** for immutable models with `@freezed` annotations
- Models in `lib/models/`
- Generated files: `*.freezed.dart`, `*.g.dart`

### Localization
- Translations in `assets/translations/ui_strings.csv`
- Generated to `lib/l10n/app_localizations.dart`
- Support for English (en) and Nepali (ne)

## Directory Structure

```
lib/
├── app.dart              # Router configuration
├── main.dart             # App entry point, theme, initialization
├── l10n/                 # Localization
├── models/               # Data models (freezed)
├── providers/            # Riverpod providers
├── screens/              # UI screens by feature
│   ├── constitution/     # Constitution reader
│   ├── government/       # How Nepal Works
│   ├── home/             # Home screen with widgets
│   ├── leaders/          # Political leaders
│   ├── map/              # Interactive maps
│   ├── settings/         # App settings
│   └── tools/            # Utility tools
├── services/             # Business logic, API clients
├── utils/                # Helper utilities
└── widgets/              # Reusable UI components

assets/
├── data/                 # JSON data files
│   ├── election/         # Electoral maps, constituencies
│   └── osm/              # OpenStreetMap boundary data
├── images/               # Static images, SVGs
└── translations/         # CSV translation files

scripts/                  # Python scripts for data processing
```

## Key Files

| File | Purpose |
|------|---------|
| `lib/app.dart` | All routes defined here |
| `lib/main.dart` | Theme, MaterialApp setup |
| `lib/providers/settings_provider.dart` | App settings (language, theme) |
| `assets/data/osm/boundaries.json` | Nepal boundary data (official from nationalgeoportal.gov.np) |
| `assets/translations/ui_strings.csv` | UI string translations |

## Code Generation

Generated files are gitignored. After cloning or modifying annotated files:

```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch mode (during development)
dart run build_runner watch --delete-conflicting-outputs
```

### What triggers regeneration:
- `@riverpod` annotated providers → `*.g.dart`
- `@freezed` annotated models → `*.freezed.dart`, `*.g.dart`
- `@JsonSerializable` models → `*.g.dart`

## Map System

Three map types:
1. **District Map** (`/map/districts`) - GeoJSON-based, shows all 77 districts
2. **Federal Map** (`/map/federal`) - Lightweight JSON, 165 constituencies
3. **Nepal Map** (`/map/nepal`) - OSM data with toggleable layers (schools, roads, peaks, etc.)

### Map Data Sources
- `boundaries.json` - Nepal official boundary from nationalgeoportal.gov.np
- `constituencies_geo.json` - Federal constituency polygons
- `districts_geo.json` - District boundaries
- `osm/*.json` - OpenStreetMap POI data (schools, colleges, etc.)

## Platform-Specific Code

Conditional imports for web vs mobile:
- `lib/services/pdf_service.dart` → `pdf_service_web.dart` / `pdf_service_mobile.dart`
- `lib/services/image_service.dart` → `image_service_web.dart` / `image_service_mobile.dart`

## Data Scripts (Python)

Located in `scripts/`:
- `fetch_osm_features.py` - Fetch cities, peaks from OpenStreetMap
- `process_osm_boundaries.py` - Process OSM boundary data
- `scrape_constituencies.py` - Scrape constituency data
- `update_ministers.py` - Update ministers data

## Testing

```bash
flutter test
```

## Building

```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# Web
flutter build web

# iOS
flutter build ios
```

## Common Tasks

### Adding a new screen
1. Create screen in `lib/screens/<feature>/`
2. Add route in `lib/app.dart`
3. Add translations to `assets/translations/ui_strings.csv`
4. Run `dart run build_runner build` if using providers

### Adding a new provider
1. Create provider in `lib/providers/` with `@riverpod` annotation
2. Run `dart run build_runner build`
3. Import and use `ref.watch(myProvider)`

### Updating translations
1. Edit `assets/translations/ui_strings.csv`
2. Regenerate: The app loads translations at runtime

### Updating map boundaries
1. Fetch from Nepal National Geoportal or OSM
2. Process with scripts in `scripts/`
3. Save to `assets/data/osm/` or `assets/data/election/`

## Important Notes

- **DO NOT** edit `*.g.dart` or `*.freezed.dart` files manually
- **DO NOT** commit generated files (they're gitignored)
- Map boundary data uses Nepal's official boundary including Kalapani-Limpiyadhura-Lipulekh
- Web uses hash URLs (`/#/path`) for reliable direct navigation
