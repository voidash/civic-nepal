# Google Calendar Integration + Calendar Views Overhaul

## Overview
Replace the current month-only Nepali calendar with a full-featured calendar app supporting:
- **4 view modes**: Day, Week, Month, Year
- **AD/BS toggle**: Switch date headers between Gregorian and Bikram Sambat
- **Google Calendar sync**: Read/write with OAuth2 on all platforms
- **Unified event display**: Nepali holidays + Google Calendar events in one view

---

## Phase 1: Google Cloud Project Setup (User Action)

### 1.1 Create GCP Project
1. Go to https://console.cloud.google.com → Create new project "Nagarik Patro"
2. Enable **Google Calendar API** (APIs & Services → Library → search "Calendar")
3. Configure **OAuth Consent Screen**:
   - User type: External
   - App name: "Nagarik Patro"
   - Scopes: `calendar.events` + `calendar.calendarlist.readonly`
   - Add test users (your Google account) during development

### 1.2 Create OAuth Client IDs (one per platform)
| Platform | Type in Console | Notes |
|----------|----------------|-------|
| Android | Android | Need SHA-1 fingerprint (`keytool -list -v -keystore ~/.android/debug.keystore`) |
| iOS | iOS | Bundle ID: `com.nepal.constitution.nepalCivic` |
| macOS | iOS (same type) | Same bundle ID as iOS, add URL scheme (reversed client ID) |
| Web | Web application | Add `http://localhost:8080` as authorized origin |
| Windows | Desktop app | Get client ID + client secret (both needed for desktop OAuth) |

### 1.3 Platform Config Files
- **Android**: Download `google-services.json` → `flutter_app/android/app/`
- **iOS**: Download `GoogleService-Info.plist` → Xcode project
- **macOS**: Add URL scheme to `Info.plist`, update entitlements
- **Web**: Add client ID meta tag to `web/index.html`

---

## Phase 2: Dependencies & Models

### 2.1 New pubspec.yaml Dependencies
```yaml
googleapis: ^16.0.0
google_sign_in: ^7.2.0
extension_google_sign_in_as_googleapis_auth: ^3.0.0
```

### 2.2 Calendar Event Model (`lib/models/calendar_event.dart`)
Unified model for both Nepali events and Google Calendar events:

```dart
@freezed
class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent({
    required String id,
    required String title,
    String? titleNp,              // Nepali title (for Nepali events)
    required DateTime startTime,
    DateTime? endTime,
    required bool isAllDay,
    required CalendarEventSource source,
    String? calendarId,           // Google calendar ID
    Color? color,                 // Calendar color from Google
    String? location,
    String? description,
    bool? isHoliday,              // Nepali holiday flag
    AuspiciousType? auspiciousType,
  }) = _CalendarEvent;
}

enum CalendarEventSource { nepali, google, local }
enum AuspiciousType { wedding, bratabandha, pasni }
```

### 2.3 Calendar View State (`lib/models/calendar_view_state.dart`)
```dart
enum CalendarViewMode { day, week, month, year }
enum DateSystem { bs, ad }
```

---

## Phase 3: Google Auth Service

### 3.1 `lib/services/google_auth_service.dart`
- Sign in with `google_sign_in` (Android, iOS, macOS, Web)
- For Windows: manual OAuth2+PKCE via loopback redirect (localhost server → browser → callback)
- Scopes: `calendar.events`, `calendar.calendarlist.readonly`
- Store refresh token in secure storage (`flutter_secure_storage`)
- Expose `AuthClient` for googleapis usage
- Sign out / revoke access

### 3.2 Auth Provider (`lib/providers/google_auth_provider.dart`)
- `@riverpod` provider wrapping `GoogleAuthService`
- Exposes: `isSignedIn`, `signIn()`, `signOut()`, `authClient`
- Persists auth state across app restarts

---

## Phase 4: Google Calendar Sync Service

### 4.1 `lib/services/google_calendar_service.dart`
Core sync logic:

**List calendars:**
- Fetch user's calendar list via `CalendarApi.calendarList.list()`
- Let user toggle which calendars to show (store preferences)
- Cache calendar metadata (id, name, color)

**Fetch events (incremental sync):**
1. First sync: `events.list(calendarId, singleEvents: true)` → paginate all → store `nextSyncToken`
2. Subsequent syncs: pass `syncToken` → get only changed/deleted events
3. Handle `410 Gone` → wipe cache, full re-sync
4. Time window: fetch current month ± 3 months (expand as user navigates)

**Create/Update/Delete events:**
- `events.insert(calendarId, event)` → create
- `events.update(calendarId, eventId, event)` → update
- `events.delete(calendarId, eventId)` → delete
- Optimistic UI updates + rollback on failure

### 4.2 Local Cache (`lib/services/calendar_cache_service.dart`)
- Use Hive box `'google_calendar_events'` for event storage
- Key: `eventId` → serialized `CalendarEvent`
- Separate box `'calendar_sync_meta'` for sync tokens + last sync time
- Index by date for fast day/week/month queries

### 4.3 Sync Provider (`lib/providers/calendar_sync_provider.dart`)
- `@riverpod` provider that merges Nepali events + Google events
- Auto-sync on app foreground (if stale > 15 min)
- Pull-to-refresh trigger
- `eventsForDate(DateTime)` → `List<CalendarEvent>` (merged, sorted by time)
- `eventsForRange(DateTime start, DateTime end)` → for week/month views

---

## Phase 5: Calendar Views UI

### 5.1 New Calendar Screen (`lib/screens/calendar/calendar_screen.dart`)
**Replaces** the existing `NepaliCalendarScreen`. Single entry point for all views.

**AppBar:**
- Left: View mode selector (Day | Week | Month | Year) — segmented button
- Center: Current date/range label (toggles between AD and BS)
- Right: AD/BS toggle button, Today button, navigation arrows (< >)
- Actions: Sync indicator, "+" create event button

**Toolbar Row (below AppBar):**
- Calendar selector chips (which Google calendars to show)
- Nepali events toggle

### 5.2 Month View (`lib/screens/calendar/month_view.dart`)
Based on the screenshot you provided:
- 7-column grid (Sun–Sat)
- Each cell shows: date number + list of events with times
- Events are color-coded by calendar source
- Overflow: "+N more" when events don't fit
- Today highlighted with colored circle on date number
- Nepali holidays in red, auspicious days with indicator
- Click day → expand to day view (or show day detail panel)
- AD dates shown as small secondary text when in BS mode (and vice versa)

### 5.3 Week View (`lib/screens/calendar/week_view.dart`)
macOS Calendar style:
- 7 day columns
- Vertical time axis (scrollable, 24h or configurable range)
- All-day events strip at top
- Timed events as positioned blocks (height = duration)
- Half-hour grid lines
- Current time indicator (red line)
- Drag to create events (if signed in)
- Click event to view/edit

### 5.4 Day View (`lib/screens/calendar/day_view.dart`)
Single day, full detail:
- All-day events at top
- Hourly time slots (scrollable)
- Events as positioned blocks (wider than week view)
- Current time indicator
- Nepali event details panel (holidays, auspicious info)
- Click empty slot to create event

### 5.5 Year View (`lib/screens/calendar/year_view.dart`)
12-month overview:
- 4×3 grid of mini-month calendars
- Each mini-month shows day numbers only
- Today highlighted
- Holidays marked in red
- Days with events have dot indicators
- Click month → navigate to month view for that month

### 5.6 AD/BS Toggle Behavior
- **Month view header**: "माघ २०८२" (BS) ↔ "February 2026" (AD)
- **Week view header**: "माघ ५–११, २०८२" (BS) ↔ "Feb 17–23, 2026" (AD)
- **Day view header**: "माघ ६, २०८२ बुधबार" (BS) ↔ "Wednesday, Feb 18, 2026" (AD)
- **Grid day numbers**: Show primary system large, secondary small
- **Year view**: Month names change (बैशाख–चैत्र vs Jan–Dec)
- Stored in settings provider, persists across sessions

---

## Phase 6: Event Creation/Editing

### 6.1 Event Editor (`lib/screens/calendar/event_editor.dart`)
Modal bottom sheet or full-screen dialog:
- Title field
- Date/time pickers (with AD/BS aware picker)
- All-day toggle
- Calendar selector (which Google calendar to save to)
- Location field
- Description field
- Save / Cancel / Delete buttons
- Validation: title required, end time > start time

### 6.2 Quick Event Creation
- Tap empty time slot in Day/Week view → pre-filled with that time
- Tap "+" button → blank event form
- Long-press day in Month view → create all-day event for that day

---

## Phase 7: Settings Integration

### 7.1 Calendar Settings (in existing Settings screen)
New section "Calendar":
- **Google Account**: Sign in / Sign out / account email
- **Calendars**: Toggle which Google calendars to display
- **Default View**: Day / Week / Month / Year
- **Default Date System**: AD / BS
- **Week Start**: Sunday / Monday
- **Show Nepali Events**: Toggle
- **Show Auspicious Days**: Toggle
- **Sync Frequency**: 15 min / 30 min / 1 hour / Manual only

---

## File Changes Summary

### New Files (17)
```
lib/models/calendar_event.dart          — Unified event model (Freezed)
lib/models/calendar_view_state.dart     — View mode + date system enums
lib/services/google_auth_service.dart   — Google Sign-In + OAuth
lib/services/google_calendar_service.dart — Calendar API sync
lib/services/calendar_cache_service.dart — Hive-based event cache
lib/services/calendar_event_merger.dart — Merge Nepali + Google events
lib/providers/google_auth_provider.dart — Auth state provider
lib/providers/calendar_sync_provider.dart — Merged events provider
lib/providers/calendar_view_provider.dart — View mode + date system state
lib/screens/calendar/calendar_screen.dart — Main calendar screen
lib/screens/calendar/month_view.dart    — Month grid view
lib/screens/calendar/week_view.dart     — Week timeline view
lib/screens/calendar/day_view.dart      — Day timeline view
lib/screens/calendar/year_view.dart     — Year overview
lib/screens/calendar/event_editor.dart  — Create/edit event dialog
lib/screens/calendar/event_detail.dart  — Event detail view
lib/widgets/calendar_day_cell.dart      — Reusable day cell widget
```

### Modified Files (7)
```
pubspec.yaml                            — Add googleapis, google_sign_in packages
lib/app.dart                            — Replace /calendar route → new CalendarScreen
lib/screens/settings/settings_screen.dart — Add Calendar settings section
lib/providers/settings_provider.dart    — Add calendar preferences
lib/screens/home/web_home_screen.dart   — Update to use new calendar components
lib/models/pinnable_item.dart           — Update calendar pinnable
web/index.html                          — Google Sign-In meta tag for web
```

### Platform Config Changes
```
android/app/google-services.json        — Google services config
ios/Runner/GoogleService-Info.plist     — Google services config
macos/Runner/Info.plist                 — Add URL scheme for Google Sign-In
macos/Runner/Release.entitlements       — Ensure network.client entitlement
windows/runner/main.cpp                 — No change needed (OAuth via browser)
```

---

## Implementation Order

1. **Models + enums** — CalendarEvent, CalendarViewMode, DateSystem
2. **Google Auth Service** — Sign in/out working on macOS first
3. **Google Calendar Service** — Fetch events, cache in Hive
4. **Calendar Event Merger** — Combine Nepali events + Google events
5. **Providers** — Auth, sync, view state
6. **Month View** — Rebuild from scratch with event time slots (like screenshot)
7. **Day View** — Hourly timeline
8. **Week View** — 7-column hourly timeline
9. **Year View** — 12 mini-month grid
10. **Calendar Screen** — Shell with view switcher, AD/BS toggle, navigation
11. **Event Editor** — Create/edit/delete Google events
12. **Settings** — Calendar preferences section
13. **Route + home screen** — Wire everything up
14. **Platform testing** — Test on each platform

---

## Risk Callouts

1. **Windows Google Sign-In**: No official `google_sign_in` support. Need manual OAuth2+PKCE via loopback localhost server. This is the trickiest platform.
2. **Google OAuth Verification**: Sensitive scopes require Google review before >100 users. Needed for production release.
3. **Web token expiry**: Access tokens expire after 1 hour on web, no auto-refresh. Must handle re-auth gracefully.
4. **Recurring events**: Handled by `singleEvents: true` in API calls (expands recurring events to individual instances). But editing one instance of a recurring event is complex.
5. **Timezone handling**: Google Calendar events have timezone info. Nepal is UTC+5:45. Must handle timezone-aware display correctly.
