# Data Update Scripts

This directory contains scripts for updating dynamic JSON data files.

## Files Overview

| File | Update Frequency | Method |
|------|-----------------|--------|
| `ministers.json` | On cabinet reshuffle | `update_ministers.py` |
| `nepali_calendar_events.json` | Yearly | Manual |
| `nepali_calendar_auspicious.json` | Yearly | Manual |
| `leaders.json` | After elections | Manual |
| `gov_services.json` | Occasionally | Manual |

## Scripts

### `update_ministers.py`

Scrapes current cabinet ministers from opmcm.gov.np.

```bash
# Run manually
cd flutter_app
python scripts/update_ministers.py
```

**Note:** Web scraping can break if the website structure changes. If the script fails, update the data manually.

## GitHub Actions

The `.github/workflows/update-data.yml` workflow:

- Runs weekly on Sunday at midnight UTC
- Can be triggered manually from GitHub Actions tab
- Commits changes automatically if data was updated

### Manual Trigger

1. Go to GitHub → Actions → "Update Dynamic Data"
2. Click "Run workflow"
3. Select what to update (all, ministers, or calendar)

## How the App Uses Remote Data

The `RemoteDataService` in the Flutter app:

1. **First load**: Uses bundled assets from `assets/data/`
2. **Background check**: Fetches `data_version.json` from GitHub
3. **If newer version exists**: Downloads and caches the updated file
4. **Subsequent loads**: Uses cached data if available

### Configuration

Update the GitHub repo URL in:
- `scripts/data_config.json` - `remote_base_url`
- `lib/services/remote_data_service.dart` - `_remoteBaseUrl`

## Version Tracking

The `data_version.json` file tracks versions of each data file:

```json
{
  "files": {
    "ministers.json": {
      "version": 1,
      "updated": "2025-01-18"
    }
  }
}
```

Increment the version number when updating a file to trigger app updates.

## Manual Data Updates

For files that need manual updates:

1. Edit the JSON file in `assets/data/`
2. Increment the version in `data_version.json`
3. Commit and push

Example:
```bash
# Edit gov_services.json
vim assets/data/gov_services.json

# Update version
python -c "
import json
with open('assets/data/data_version.json', 'r') as f:
    data = json.load(f)
data['files']['gov_services.json']['version'] += 1
data['files']['gov_services.json']['updated'] = '$(date +%Y-%m-%d)'
with open('assets/data/data_version.json', 'w') as f:
    json.dump(data, f, indent=2)
"

# Commit
git add assets/data/
git commit -m "chore: update gov_services.json"
git push
```

## Testing Remote Updates

To test if the app fetches updates correctly:

1. Increment a version in `data_version.json`
2. Push to GitHub
3. In the app, the `RemoteDataService` will detect the new version
4. Data will be fetched and cached

To force refresh in-app (for debugging):
```dart
await RemoteDataService.forceRefreshAll();
```

To clear cache:
```dart
await RemoteDataService.clearCache();
```
