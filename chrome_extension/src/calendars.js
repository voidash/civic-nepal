// Calendar conversions for the dates Nepal actually uses.
//
// Everything here works on plain civil (year, month, day) triples and never
// touches the Date object's timezone handling. A date written on a web page is
// a calendar date, not an instant, so converting it through a local-time Date
// would shift it by a day for anyone east or west of the author.
//
// Accuracy, stated honestly, because a civic tool that quietly guesses is
// worse than one that says it does not know:
//
//   Bikram Sambat  exact, from the month-length table the app itself uses.
//   Nepal Sambat   exact year; the month/day are lunar and are not computed.
//   Saka Sambat    exact, arithmetic calendar.
//   Buddha Sambat  exact year within the range of known Buddha Jayanti dates.

import { BS_YEARS, BS_MIN_YEAR, BS_MAX_YEAR } from './bs-data.js';

// BS 1970-01-01 falls on AD 1913-04-13.
const BS_EPOCH_DAYS = daysFromCivil(1913, 4, 13);
const BS_EPOCH_YEAR = 1970;

export const BS_MONTHS_EN = [
  'Baisakh', 'Jestha', 'Ashadh', 'Shrawan',
  'Bhadra', 'Ashwin', 'Kartik', 'Mangsir',
  'Poush', 'Magh', 'Falgun', 'Chaitra',
];

export const BS_MONTHS_NP = [
  'बैशाख', 'जेठ', 'असार', 'श्रावण',
  'भाद्र', 'आश्विन', 'कार्तिक', 'मंसिर',
  'पौष', 'माघ', 'फागुन', 'चैत्र',
];

export const WEEKDAYS_NP = [
  'आइतबार', 'सोमबार', 'मंगलबार', 'बुधबार', 'बिहीबार', 'शुक्रबार', 'शनिबार',
];

export const WEEKDAYS_EN = [
  'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
];

const NP_DIGITS = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];

/** Render a number in Devanagari digits. */
export function toNepaliDigits(value) {
  return String(value).replace(/\d/g, (d) => NP_DIGITS[Number(d)]);
}

// ── Civil date arithmetic ────────────────────────────────────────────────
// Howard Hinnant's days_from_civil / civil_from_days. Exact for any
// proleptic Gregorian date, with no floating point and no timezone.

/** Days since 1970-01-01 for a proleptic Gregorian date. */
export function daysFromCivil(y, m, d) {
  y -= m <= 2 ? 1 : 0;
  const era = Math.floor((y >= 0 ? y : y - 399) / 400);
  const yoe = y - era * 400;                                    // [0, 399]
  const doy = Math.floor((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1;
  const doe = yoe * 365 + Math.floor(yoe / 4) - Math.floor(yoe / 100) + doy;
  return era * 146097 + doe - 719468;
}

/** Inverse of daysFromCivil. */
export function civilFromDays(z) {
  z += 719468;
  const era = Math.floor((z >= 0 ? z : z - 146096) / 146097);
  const doe = z - era * 146097;                                 // [0, 146096]
  const yoe = Math.floor(
    (doe - Math.floor(doe / 1460) + Math.floor(doe / 36524) - Math.floor(doe / 146096)) / 365,
  );
  const y = yoe + era * 400;
  const doy = doe - (365 * yoe + Math.floor(yoe / 4) - Math.floor(yoe / 100));
  const mp = Math.floor((5 * doy + 2) / 153);
  const d = doy - Math.floor((153 * mp + 2) / 5) + 1;
  const m = mp + (mp < 10 ? 3 : -9);
  return { year: y + (m <= 2 ? 1 : 0), month: m, day: d };
}

/** Day of week, 0 = Sunday. */
export function weekdayOf(y, m, d) {
  const z = daysFromCivil(y, m, d);
  return ((z + 4) % 7 + 7) % 7;
}

// ── Bikram Sambat ────────────────────────────────────────────────────────

/**
 * Convert a Gregorian date to Bikram Sambat.
 * Returns null outside the range the month-length table covers.
 */
export function adToBs(y, m, d) {
  let remaining = daysFromCivil(y, m, d) - BS_EPOCH_DAYS;
  if (remaining < 0) return null;

  let bsYear = BS_EPOCH_YEAR;
  let daysInYear = BS_YEARS[bsYear]?.[0];
  while (daysInYear !== undefined && remaining >= daysInYear) {
    remaining -= daysInYear;
    bsYear += 1;
    daysInYear = BS_YEARS[bsYear]?.[0];
  }
  if (daysInYear === undefined) return null;

  let bsMonth = 1;
  let daysInMonth = BS_YEARS[bsYear][bsMonth];
  while (remaining >= daysInMonth) {
    remaining -= daysInMonth;
    bsMonth += 1;
    daysInMonth = BS_YEARS[bsYear][bsMonth];
  }

  return { year: bsYear, month: bsMonth, day: remaining + 1 };
}

/** Convert a Bikram Sambat date to Gregorian, or null if out of range. */
export function bsToAd(bsYear, bsMonth, bsDay) {
  if (bsYear < BS_EPOCH_YEAR || bsYear > BS_MAX_YEAR) return null;
  if (bsMonth < 1 || bsMonth > 12) return null;
  const months = BS_YEARS[bsYear];
  if (!months || bsDay < 1 || bsDay > months[bsMonth]) return null;

  let days = 0;
  for (let y = BS_EPOCH_YEAR; y < bsYear; y += 1) days += BS_YEARS[y][0];
  for (let m = 1; m < bsMonth; m += 1) days += months[m];
  days += bsDay - 1;

  return civilFromDays(BS_EPOCH_DAYS + days);
}

/** Number of days in a Bikram Sambat month. */
export function bsDaysInMonth(bsYear, bsMonth) {
  return BS_YEARS[bsYear]?.[bsMonth] ?? null;
}

export { BS_MIN_YEAR, BS_MAX_YEAR };

// ── Nepal Sambat ─────────────────────────────────────────────────────────
//
// The Newar calendar. Its year rolls over on Mha Puja (Kartik Shukla
// Pratipada, the day after Laxmi Puja), which is a lunar date and so moves
// within Kartik — and occasionally into Mangsir — from year to year.
//
// Across every anchor in the app's calendar data the offset is constant:
// Nepal Sambat = Bikram Sambat - 936 once Mha Puja has passed. What varies is
// only where in the BS year that boundary sits, so the boundary is tabulated
// rather than computed. Outside the tabulated range the year is still exact
// for most of the calendar, because Baisakh–Ashwin always precede Mha Puja and
// Poush–Chaitra always follow it; only Kartik and Mangsir are undecidable, and
// those return null instead of a guess.

const NS_OFFSET = 936;

/** Mha Puja, as [BS month, BS day], keyed by BS year. */
const MHA_PUJA_BS = {
  2068: [7, 10], 2069: [7, 29], 2070: [7, 18], 2071: [7, 7],
  2072: [7, 26], 2073: [7, 15], 2074: [7, 3], 2075: [7, 22],
  2076: [7, 11], 2077: [8, 1], 2078: [7, 19], 2079: [7, 9],
  2080: [7, 28], 2081: [7, 17], 2082: [7, 5], 2083: [7, 24],
};

/**
 * Nepal Sambat year for a Bikram Sambat date.
 * Returns null when the date falls in Kartik or Mangsir of a year whose Mha
 * Puja is not known.
 */
export function nepalSambatYear(bsYear, bsMonth, bsDay) {
  const mhaPuja = MHA_PUJA_BS[bsYear];
  if (mhaPuja) {
    const [month, day] = mhaPuja;
    const afterMhaPuja = bsMonth > month || (bsMonth === month && bsDay >= day);
    return bsYear - NS_OFFSET - (afterMhaPuja ? 0 : 1);
  }
  // Baisakh–Ashwin is always before Mha Puja; Poush–Chaitra always after.
  if (bsMonth <= 6) return bsYear - NS_OFFSET - 1;
  if (bsMonth >= 9) return bsYear - NS_OFFSET;
  return null;
}

// ── Saka Sambat ──────────────────────────────────────────────────────────
//
// The Indian national calendar, which shows up on printed Nepali patros.
// Chaitra 1 is 22 March, or 21 March in a Gregorian leap year.

export const SAKA_MONTHS_EN = [
  'Chaitra', 'Vaishakha', 'Jyaishtha', 'Ashadha',
  'Shravana', 'Bhadra', 'Ashvina', 'Kartika',
  'Agrahayana', 'Pausha', 'Magha', 'Phalguna',
];

export const SAKA_MONTHS_NP = [
  'चैत्र', 'वैशाख', 'ज्येष्ठ', 'आषाढ',
  'श्रावण', 'भाद्र', 'आश्विन', 'कार्तिक',
  'अग्रहायण', 'पौष', 'माघ', 'फाल्गुन',
];

function isGregorianLeap(y) {
  return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0;
}

/** Convert a Gregorian date to the Saka calendar. */
export function adToSaka(y, m, d) {
  const leap = isGregorianLeap(y);
  const newYear = daysFromCivil(y, 3, leap ? 21 : 22);
  const today = daysFromCivil(y, m, d);

  let sakaYear = y - 78;
  let dayOfYear;
  if (today >= newYear) {
    dayOfYear = today - newYear;
  } else {
    // Still in the Saka year that began last March.
    sakaYear -= 1;
    const prevLeap = isGregorianLeap(y - 1);
    dayOfYear = today - daysFromCivil(y - 1, 3, prevLeap ? 21 : 22);
  }

  // Chaitra runs 30 days, or 31 when the Saka year opened in a Gregorian leap
  // year. The next five months are 31 days, the last six 30.
  const chaitra = isGregorianLeap(sakaYear + 78) ? 31 : 30;
  const monthLengths = [chaitra, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 30];

  let month = 0;
  while (month < 11 && dayOfYear >= monthLengths[month]) {
    dayOfYear -= monthLengths[month];
    month += 1;
  }
  return { year: sakaYear, month: month + 1, day: dayOfYear + 1 };
}

// ── Buddha Sambat ────────────────────────────────────────────────────────
//
// The Buddhist Era as reckoned in Nepal, where the year turns on Buddha
// Jayanti (Baisakh Purnima) rather than on 1 January. Dates come from the
// app's calendar data; outside that range the year is not reported, since the
// +543/+544 boundary would be a guess.

/** Buddha Jayanti, as [BS month, BS day], keyed by BS year. */
const BUDDHA_JAYANTI_BS = {
  2069: [1, 24], 2070: [2, 11], 2071: [1, 31], 2072: [1, 21],
  2073: [2, 8], 2074: [1, 27], 2075: [1, 17], 2076: [2, 4],
  2077: [1, 25], 2078: [2, 12], 2079: [2, 2], 2080: [1, 22],
  2081: [2, 10], 2082: [1, 29], 2083: [1, 18],
};

/**
 * Buddha Sambat year, or null when Buddha Jayanti for that year is unknown.
 * `adYear` is the Gregorian year the date falls in.
 */
export function buddhaSambatYear(adYear, bsYear, bsMonth, bsDay) {
  const jayanti = BUDDHA_JAYANTI_BS[bsYear];
  if (!jayanti) return null;
  const [month, day] = jayanti;
  const after = bsMonth > month || (bsMonth === month && bsDay >= day);
  return adYear + (after ? 544 : 543);
}

// ── Combined view ────────────────────────────────────────────────────────

/**
 * Every calendar we can state confidently for one Gregorian date.
 * Returns null if the date falls outside the Bikram Sambat table.
 */
export function describeDate(y, m, d) {
  const bs = adToBs(y, m, d);
  if (!bs) return null;

  return {
    ad: { year: y, month: m, day: d },
    weekday: weekdayOf(y, m, d),
    bs,
    nepalSambat: nepalSambatYear(bs.year, bs.month, bs.day),
    saka: adToSaka(y, m, d),
    buddhaSambat: buddhaSambatYear(y, bs.year, bs.month, bs.day),
  };
}

/** Short Bikram Sambat label, e.g. "२५ साउन २०८३" or "25 Shrawan 2083". */
export function formatBs(bs, { nepali = true } = {}) {
  if (nepali) {
    return `${toNepaliDigits(bs.day)} ${BS_MONTHS_NP[bs.month - 1]} ${toNepaliDigits(bs.year)}`;
  }
  return `${bs.day} ${BS_MONTHS_EN[bs.month - 1]} ${bs.year}`;
}
