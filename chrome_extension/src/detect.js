// Finding Gregorian dates written in running text.
//
// The bar for adding a badge to someone's page is high: a wrong or spurious
// annotation is worse than a missing one. So this only matches dates that
// carry an explicit four-digit year, and refuses anything genuinely ambiguous
// unless the reader has told us how to read it.

const MONTHS = {
  jan: 1, january: 1,
  feb: 2, february: 2,
  mar: 3, march: 3,
  apr: 4, april: 4,
  may: 5,
  jun: 6, june: 6,
  jul: 7, july: 7,
  aug: 8, august: 8,
  sep: 9, sept: 9, september: 9,
  oct: 10, october: 10,
  nov: 11, november: 11,
  dec: 12, december: 12,
};

const MONTH_NAMES = Object.keys(MONTHS).sort((a, b) => b.length - a.length).join('|');

// Order matters: the first pattern to match a span wins, so the unambiguous
// year-first form is tried before the numeric forms that need a convention.
const PATTERNS = [
  {
    // 2026-08-09, 2026/8/9
    name: 'iso',
    re: new RegExp(String.raw`\b(\d{4})([-/])(\d{1,2})\2(\d{1,2})\b`, 'gi'),
    build: (m) => ({ year: +m[1], month: +m[3], day: +m[4] }),
  },
  {
    // 9 August 2026, 9th Aug, 2026
    name: 'day-month-name',
    re: new RegExp(
      String.raw`\b(\d{1,2})(?:st|nd|rd|th)?\s+(${MONTH_NAMES})\.?,?\s+(\d{4})\b`,
      'gi',
    ),
    build: (m) => ({ year: +m[3], month: MONTHS[m[2].toLowerCase()], day: +m[1] }),
  },
  {
    // August 9, 2026 / Aug 9 2026 / August 9th, 2026
    name: 'month-name-day',
    re: new RegExp(
      String.raw`\b(${MONTH_NAMES})\.?\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})\b`,
      'gi',
    ),
    build: (m) => ({ year: +m[3], month: MONTHS[m[1].toLowerCase()], day: +m[2] }),
  },
  {
    // 09/08/2026, 9-8-2026, 9.8.2026 — needs a reading convention.
    name: 'numeric',
    re: new RegExp(String.raw`\b(\d{1,2})([/.-])(\d{1,2})\2(\d{4})\b`, 'gi'),
    build: (m, { dateOrder }) => {
      const a = +m[1];
      const b = +m[3];
      const year = +m[4];
      // One value over 12 can only be the day, whatever the convention.
      if (a > 12 && b <= 12) return { year, month: b, day: a };
      if (b > 12 && a <= 12) return { year, month: a, day: b };
      if (a > 12 && b > 12) return null;
      if (dateOrder === 'dmy') return { year, month: b, day: a };
      if (dateOrder === 'mdy') return { year, month: a, day: b };
      return null; // 'strict': refuse to guess
    },
  },
];

/** True when the triple is a real calendar date. */
export function isRealDate({ year, month, day }) {
  if (!year || !month || !day) return false;
  if (month < 1 || month > 12 || day < 1 || day > 31) return false;
  const lengths = [31, isLeap(year) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  return day <= lengths[month - 1];
}

function isLeap(y) {
  return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0;
}

/**
 * Find every date in a string.
 *
 * Returns `{ start, end, text, date }` in ascending position order, with
 * overlapping matches resolved in favour of the earlier, longer one so that
 * "9 August 2026" is never also reported as a bare numeric date.
 *
 * @param {string} text
 * @param {{dateOrder?: 'dmy'|'mdy'|'strict', minYear?: number, maxYear?: number}} options
 */
export function findDates(text, options = {}) {
  const { dateOrder = 'mdy', minYear = 1913, maxYear = 2200 } = options;
  const found = [];

  for (const pattern of PATTERNS) {
    pattern.re.lastIndex = 0;
    let match;
    while ((match = pattern.re.exec(text)) !== null) {
      const date = pattern.build(match, { dateOrder });
      if (!date || !isRealDate(date)) continue;
      if (date.year < minYear || date.year > maxYear) continue;
      found.push({
        start: match.index,
        end: match.index + match[0].length,
        text: match[0],
        date,
        pattern: pattern.name,
      });
    }
  }

  found.sort((x, y) => x.start - y.start || y.end - x.end);

  const kept = [];
  let consumedTo = -1;
  for (const hit of found) {
    if (hit.start < consumedTo) continue;
    kept.push(hit);
    consumedTo = hit.end;
  }
  return kept;
}

/**
 * Read a date from a machine-readable attribute, e.g. `<time datetime>`.
 * These are authoritative, so no convention is needed.
 */
export function parseMachineDate(value) {
  if (typeof value !== 'string') return null;
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(value.trim());
  if (!m) return null;
  const date = { year: +m[1], month: +m[2], day: +m[3] };
  return isRealDate(date) ? date : null;
}
