// Shared settings, with the defaults in one place so the content script,
// options page and popup cannot drift apart.

export const DEFAULTS = {
  /** Master switch. */
  enabled: true,

  /**
   * 'inline' puts a small badge immediately after the date.
   * 'hover'  leaves the page untouched until the date is hovered.
   */
  displayMode: 'inline',

  /** Script used for the Bikram Sambat badge. */
  numerals: 'devanagari', // 'devanagari' | 'latin'

  /** Language of month names in the badge. */
  language: 'nepali', // 'nepali' | 'english'

  /**
   * How to read 09/08/2026.
   * 'strict' annotates only dates that cannot be misread.
   */
  dateOrder: 'mdy', // 'mdy' | 'dmy' | 'strict'

  /** Extra calendars shown in the hover card. */
  showNepalSambat: true,
  showSaka: true,
  showBuddhaSambat: true,
  showWeekday: true,

  /** Rewrite the day numbers on calendar.google.com into Bikram Sambat. */
  googleCalendarBs: true,

  /** Hosts the extension leaves alone entirely. */
  blocklist: [],

  /** Safety valve for pathological pages. */
  maxAnnotationsPerPage: 400,
};

const AREA = 'sync';

/** Load settings merged over the defaults. */
export async function loadSettings() {
  try {
    const stored = await chrome.storage[AREA].get(Object.keys(DEFAULTS));
    return { ...DEFAULTS, ...stored };
  } catch {
    return { ...DEFAULTS };
  }
}

export async function saveSettings(patch) {
  await chrome.storage[AREA].set(patch);
}

/** Call `fn` whenever any setting changes. */
export function onSettingsChanged(fn) {
  chrome.storage.onChanged.addListener((changes, area) => {
    if (area === AREA) fn(changes);
  });
}

/** True when the extension should stay out of this host's way. */
export function isBlocked(settings, hostname) {
  return (settings.blocklist || []).some(
    (entry) => hostname === entry || hostname.endsWith(`.${entry}`),
  );
}
