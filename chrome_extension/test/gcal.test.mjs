import test from 'node:test';
import assert from 'node:assert/strict';

import { decodeDateKey, cellDate, isGoogleCalendar } from '../src/gcal.js';
import { findDates } from '../src/detect.js';

const parseLabel = (label) => findDates(label, { dateOrder: 'mdy' })[0]?.date ?? null;

/** Minimal stand-in for the bits of Element that gcal.js touches. */
function fakeCell({ datekey, ariaLabel }) {
  const attrs = {};
  if (datekey !== undefined) attrs['data-datekey'] = String(datekey);
  if (ariaLabel !== undefined) attrs['aria-label'] = ariaLabel;
  return {
    getAttribute: (name) => attrs[name] ?? null,
    querySelector: () => null,
  };
}

const encode = (y, m, d) => ((y - 1970) << 9) | (m << 5) | d;

test('host matching is exact', () => {
  assert.ok(isGoogleCalendar('calendar.google.com'));
  assert.ok(!isGoogleCalendar('calendar.google.com.evil.test'));
  assert.ok(!isGoogleCalendar('mail.google.com'));
});

test('datekey decodes to its date', () => {
  assert.deepEqual(decodeDateKey(encode(2026, 8, 9)), { year: 2026, month: 8, day: 9 });
  assert.deepEqual(decodeDateKey(encode(2025, 12, 31)), { year: 2025, month: 12, day: 31 });
});

test('nonsense datekeys are rejected', () => {
  assert.equal(decodeDateKey(null), null);
  assert.equal(decodeDateKey('abc'), null);
  assert.equal(decodeDateKey(0), null);
  assert.equal(decodeDateKey(encode(2026, 0, 9)), null, 'month 0 must not pass');
  assert.equal(decodeDateKey(encode(2026, 8, 0)), null, 'day 0 must not pass');
});

test('aria-label and datekey agreeing gives the date', () => {
  const cell = fakeCell({ datekey: encode(2026, 8, 9), ariaLabel: 'August 9, 2026' });
  assert.deepEqual(cellDate(cell, parseLabel), { year: 2026, month: 8, day: 9 });
});

test('disagreement yields nothing rather than a wrong date', () => {
  // This is the case that matters: if Google ever changed the month base, the
  // day would still match and every date would be silently a month out.
  const cell = fakeCell({ datekey: encode(2026, 7, 9), ariaLabel: 'August 9, 2026' });
  assert.equal(cellDate(cell, parseLabel), null);
});

test('either source alone is accepted', () => {
  assert.deepEqual(
    cellDate(fakeCell({ ariaLabel: '9 August 2026' }), parseLabel),
    { year: 2026, month: 8, day: 9 },
  );
  assert.deepEqual(
    cellDate(fakeCell({ datekey: encode(2026, 8, 9) }), parseLabel),
    { year: 2026, month: 8, day: 9 },
  );
});

test('a cell with neither source gives nothing', () => {
  assert.equal(cellDate(fakeCell({}), parseLabel), null);
  assert.equal(cellDate(fakeCell({ ariaLabel: 'Create event' }), parseLabel), null);
});
