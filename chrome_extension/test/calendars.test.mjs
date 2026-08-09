// Run with: node --test chrome_extension/test/
import test from 'node:test';
import assert from 'node:assert/strict';

import {
  adToBs,
  bsToAd,
  adToSaka,
  nepalSambatYear,
  buddhaSambatYear,
  describeDate,
  weekdayOf,
  daysFromCivil,
  civilFromDays,
  toNepaliDigits,
  formatBs,
} from '../src/calendars.js';

const bs = (y, m, d) => ({ year: y, month: m, day: d });

test('civil day arithmetic round-trips', () => {
  for (const [y, m, d] of [[1913, 4, 13], [2000, 2, 29], [2026, 8, 9], [2100, 3, 1]]) {
    assert.deepEqual(civilFromDays(daysFromCivil(y, m, d)), { year: y, month: m, day: d });
  }
});

test('the epoch maps to BS 1970-01-01', () => {
  assert.deepEqual(adToBs(1913, 4, 13), bs(1970, 1, 1));
});

test('known Bikram Sambat new years', () => {
  // Baisakh 1 is the Nepali new year; these are widely published dates.
  assert.deepEqual(adToBs(2025, 4, 14), bs(2082, 1, 1));
  assert.deepEqual(adToBs(2026, 4, 14), bs(2083, 1, 1));
  assert.deepEqual(adToBs(2024, 4, 13), bs(2081, 1, 1));
});

test('bsToAd inverts adToBs', () => {
  assert.deepEqual(bsToAd(2082, 1, 1), { year: 2025, month: 4, day: 14 });
  assert.deepEqual(bsToAd(2083, 4, 24), { year: 2026, month: 8, day: 9 });
});

test('out-of-range dates return null rather than a wrong answer', () => {
  assert.equal(adToBs(1900, 1, 1), null);
  assert.equal(bsToAd(2300, 1, 1), null);
  assert.equal(bsToAd(2082, 13, 1), null);
  assert.equal(bsToAd(2082, 1, 40), null);
});

test('weekday matches the Gregorian calendar', () => {
  assert.equal(weekdayOf(2026, 8, 9), 0);  // Sunday
  assert.equal(weekdayOf(2025, 10, 22), 3); // Wednesday
});

test('Nepal Sambat turns over on Mha Puja', () => {
  // Nepal Sambat 1146 began on 22 October 2025.
  assert.equal(nepalSambatYear(2082, 7, 4), 1145);
  assert.equal(nepalSambatYear(2082, 7, 5), 1146);
  assert.equal(nepalSambatYear(2082, 12, 30), 1146);
});

test('Nepal Sambat is refused where Mha Puja is unknown and it matters', () => {
  // Baisakh always precedes Mha Puja, Poush always follows it.
  assert.equal(nepalSambatYear(2100, 1, 1), 2100 - 937);
  assert.equal(nepalSambatYear(2100, 10, 1), 2100 - 936);
  // Kartik in an untabulated year cannot be decided.
  assert.equal(nepalSambatYear(2100, 7, 15), null);
});

test('Buddha Sambat turns over on Buddha Jayanti', () => {
  // Buddha Jayanti 2082 fell on 12 May 2025, opening Buddha Sambat 2569.
  assert.equal(buddhaSambatYear(2025, 2082, 1, 28), 2568);
  assert.equal(buddhaSambatYear(2025, 2082, 1, 29), 2569);
  assert.equal(buddhaSambatYear(2030, 2200, 1, 1), null, 'unknown year must not guess');
});

test('Saka Sambat matches published values', () => {
  // 1 January 2026 is Pausha 11, 1947 Saka.
  assert.deepEqual(adToSaka(2026, 1, 1), { year: 1947, month: 10, day: 11 });
  // Saka new year: 22 March in a common year.
  assert.deepEqual(adToSaka(2026, 3, 22), { year: 1948, month: 1, day: 1 });
  // 21 March in a Gregorian leap year.
  assert.deepEqual(adToSaka(2028, 3, 21), { year: 1950, month: 1, day: 1 });
});

test('describeDate reports every calendar at once', () => {
  const info = describeDate(2026, 8, 9);
  assert.deepEqual(info.bs, bs(2083, 4, 24));
  assert.equal(info.nepalSambat, 1146);
  assert.equal(info.buddhaSambat, 2570);
  assert.equal(info.weekday, 0);
});

test('Devanagari numerals', () => {
  assert.equal(toNepaliDigits(2083), '२०८३');
  assert.equal(toNepaliDigits(0), '०');
  assert.equal(formatBs(bs(2083, 4, 24)), '२४ श्रावण २०८३');
  assert.equal(formatBs(bs(2083, 4, 24), { nepali: false }), '24 Shrawan 2083');
});

test('every day of a Bikram Sambat year round-trips', () => {
  for (let month = 1; month <= 12; month += 1) {
    for (let day = 1; day <= 32; day += 1) {
      const ad = bsToAd(2083, month, day);
      if (!ad) continue;
      assert.deepEqual(
        adToBs(ad.year, ad.month, ad.day),
        bs(2083, month, day),
        `BS 2083-${month}-${day}`,
      );
    }
  }
});
