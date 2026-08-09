// First-class Bikram Sambat on calendar.google.com.
//
// Google Calendar's class names are minified and change without notice, so
// nothing here depends on them. It keys off two things Google has kept stable
// for years because its own accessibility support depends on them:
//
//   * `data-datekey` on each day cell, a bit-packed Gregorian date;
//   * `aria-label` carrying the same date in words.
//
// The two are cross-checked where both exist. Where the structure is not what
// we expect, the cell is left completely alone — a calendar showing the wrong
// day is far worse than one showing no Bikram Sambat at all.

const DONE = 'nagarikGcalDone';

export function isGoogleCalendar(hostname) {
  return hostname === 'calendar.google.com';
}

/**
 * Decode Google Calendar's `data-datekey`.
 *
 * The value packs the date into a single integer:
 *   bits 0-4   day of month
 *   bits 5-8   month, 1-12
 *   bits 9+    years since 1970
 *
 * Returns null for values that do not decode to a sane date, which is what
 * keeps a format change from silently producing wrong dates.
 */
export function decodeDateKey(value) {
  const key = Number(value);
  if (!Number.isInteger(key) || key <= 0) return null;

  const day = key & 0x1f;
  const month = (key >> 5) & 0x0f;
  const year = (key >> 9) + 1970;

  if (day < 1 || day > 31) return null;
  if (month < 1 || month > 12) return null;
  if (year < 1970 || year > 2200) return null;
  return { year, month, day };
}

/**
 * The Gregorian date a cell is really showing.
 *
 * `aria-label` is the authority: it is written for screen readers, so it says
 * the date in words and cannot be misread. `data-datekey` is only a
 * corroborating source, because its month field is undocumented — were Google
 * to change its base, the day would still line up and every annotation would
 * be silently a month out. So when both exist and disagree, nothing is shown.
 *
 * @param {Element} cell
 * @param {(text: string) => {year:number,month:number,day:number}|null} parseLabel
 */
export function cellDate(cell, parseLabel) {
  const fromKey = decodeDateKey(cell.getAttribute('data-datekey'));
  const label = cell.getAttribute('aria-label') || cell.querySelector('[aria-label]')?.getAttribute('aria-label');
  const fromLabel = label ? parseLabel(label) : null;

  if (fromKey && fromLabel) {
    const agree =
      fromKey.year === fromLabel.year &&
      fromKey.month === fromLabel.month &&
      fromKey.day === fromLabel.day;
    return agree ? fromKey : null;
  }
  return fromLabel ?? fromKey;
}

/** The element inside a day cell that holds the Gregorian day number. */
function findDayNumberElement(cell) {
  // Deepest element whose entire text is the day number: that is the label,
  // not a container that happens to start with it.
  const candidates = cell.querySelectorAll('*');
  for (const el of candidates) {
    const text = el.textContent.trim();
    if (!/^\d{1,2}$/.test(text)) continue;
    if (el.querySelector('*')) continue;
    return el;
  }
  return null;
}

/**
 * Rewrite one day cell to lead with its Bikram Sambat day.
 * Returns true when the cell was changed.
 */
export function annotateCell(cell, { cal, parseLabel, numerals = 'devanagari' }) {
  if (cell.dataset[DONE] === 'true') return false;

  const date = cellDate(cell, parseLabel);
  if (!date) return false;

  const bs = cal.adToBs(date.year, date.month, date.day);
  if (!bs) return false;

  const dayEl = findDayNumberElement(cell);
  if (!dayEl) return false;

  // The cell must actually be showing the day we decoded. If it is not, the
  // DOM is not what this code was written against, so stop.
  if (Number(dayEl.textContent.trim()) !== date.day) return false;

  cell.dataset[DONE] = 'true';

  const digits = (n) => (numerals === 'devanagari' ? cal.toNepaliDigits(n) : String(n));

  const bsEl = document.createElement('span');
  bsEl.className = 'nagarik-gcal-bs';
  bsEl.textContent = digits(bs.day);
  // Baisakh 1 is the Nepali new year; showing the month there makes the
  // month boundary legible without a second row of labels.
  if (bs.day === 1) {
    bsEl.textContent = `${digits(bs.day)} ${cal.BS_MONTHS_NP[bs.month - 1]}`;
    bsEl.classList.add('nagarik-gcal-bs--month-start');
  }
  bsEl.title = `${cal.formatBs(bs)} (${date.year}-${date.month}-${date.day})`;

  dayEl.classList.add('nagarik-gcal-ad');
  dayEl.after(bsEl);
  return true;
}

/** Annotate every day cell currently in the DOM. */
export function annotateAll(root, context) {
  let count = 0;
  for (const cell of root.querySelectorAll('[data-datekey]')) {
    if (annotateCell(cell, context)) count += 1;
  }
  return count;
}

/**
 * Watch the calendar and keep annotating as the user moves between views.
 * Google re-renders the grid wholesale, so this is a debounced full pass
 * rather than an attempt to track individual cells.
 */
export function start({ cal, settings, parseLabel }) {
  const context = { cal, numerals: settings.numerals, parseLabel };
  const run = () => annotateAll(document.body, context);

  run();

  let timer = null;
  new MutationObserver(() => {
    if (timer) return;
    timer = setTimeout(() => {
      timer = null;
      run();
    }, 250);
  }).observe(document.body, { childList: true, subtree: true });
}
