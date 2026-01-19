# Nepal Civic

A Flutter app providing civic information for Nepal - constitution, government structure, leaders, district map, and utility tools.

## Features

### Core Modules
- **Constitution** - Bilingual (Nepali/English) constitution with article navigation and meaning mode
- **How Nepal Works** - Interactive guide to Nepal's government structure
- **Leaders** - Directory of political leaders with photos and details
- **District Map** - Interactive SVG map of Nepal's 77 districts

### Utility Tools
- **Nepali Calendar** - Bikram Sambat calendar with events and holidays
- **Photo Merger** - Merge front/back citizenship photos into single image
- **Image Compressor** - Compress images to under 500KB
- **Date Converter** - Convert between BS and AD dates
- **Forex Rates** - Nepal Rastra Bank exchange rates
- **Gold/Silver Prices** - Current bullion prices
- **IPO Information** - Active IPO listings
- **Government Services** - Directory of official government websites

## Getting Started

```bash
# Install dependencies
flutter pub get

# Generate code (Riverpod, Freezed, JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run

# Run on web
flutter run -d chrome

# Build for web
flutter build web --base-href /civic-nepal/
```

## URL Routes (Web)

| Route | Screen |
|-------|--------|
| `/home` | Home |
| `/calendar` | Nepali Calendar |
| `/ipo` | IPO/Shares |
| `/rights` | Constitution (nav) |
| `/constitutional-rights` | Constitution (full) |
| `/how-nepal-works` | Government Structure |
| `/map` | District Map |
| `/leaders` | Leaders Directory |
| `/leaders/:id` | Leader Detail |
| `/photo-merger` | Citizenship Photo Merger |
| `/photo-compress` | Image Compressor |
| `/date-converter` | Date Converter |
| `/forex` | Forex Rates |
| `/gold-price` | Gold/Silver Prices |
| `/settings` | Settings |

## Project Structure

```
lib/
├── l10n/                 # Localization (en, ne, new)
├── models/               # Data models (Freezed)
├── providers/            # Riverpod providers
├── screens/
│   ├── constitution/     # Constitution viewer
│   ├── government/       # How Nepal Works
│   ├── home/             # Home screen
│   ├── leaders/          # Leaders module
│   ├── map/              # District map
│   ├── settings/         # App settings
│   └── tools/            # Utility tools
├── services/             # API and local services
├── utils/                # Helper utilities
├── app.dart              # Router configuration
└── main.dart             # App entry point

assets/
├── data/                 # JSON data files
├── images/               # Images and SVGs
└── translations/         # ARB translation files
```

## Technologies

- **Flutter 3.27+** - UI framework
- **Riverpod** - State management
- **GoRouter** - Navigation with URL support
- **Freezed** - Immutable data classes
- **Hive** - Local storage
- **flutter_svg** - SVG rendering for map

## Supported Platforms

- Android
- iOS
- Web (with URL routing)
