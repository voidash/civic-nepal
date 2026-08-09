import test from 'node:test';
import assert from 'node:assert/strict';

import { findDates, parseMachineDate, isRealDate } from '../src/detect.js';

const dates = (text, opts) => findDates(text, opts).map((h) => ({ text: h.text, ...h.date }));

test('ISO dates', () => {
  assert.deepEqual(dates('Filed on 2026-08-09 in Kathmandu'), [
    { text: '2026-08-09', year: 2026, month: 8, day: 9 },
  ]);
  assert.deepEqual(dates('2026/8/9'), [{ text: '2026/8/9', year: 2026, month: 8, day: 9 }]);
});

test('month-name forms, either order', () => {
  assert.deepEqual(dates('August 9, 2026'), [
    { text: 'August 9, 2026', year: 2026, month: 8, day: 9 },
  ]);
  assert.deepEqual(dates('9 August 2026'), [
    { text: '9 August 2026', year: 2026, month: 8, day: 9 },
  ]);
  assert.deepEqual(dates('Sept 1st, 2026'), [
    { text: 'Sept 1st, 2026', year: 2026, month: 9, day: 1 },
  ]);
  assert.deepEqual(dates('23rd Dec. 2025'), [
    { text: '23rd Dec. 2025', year: 2025, month: 12, day: 23 },
  ]);
});

test('a long form is matched once, not also as a numeric date', () => {
  const hits = findDates('Published August 9, 2026 today');
  assert.equal(hits.length, 1);
  assert.equal(hits[0].pattern, 'month-name-day');
});

test('numeric dates follow the configured order', () => {
  assert.deepEqual(dates('09/08/2026', { dateOrder: 'mdy' }), [
    { text: '09/08/2026', year: 2026, month: 9, day: 8 },
  ]);
  assert.deepEqual(dates('09/08/2026', { dateOrder: 'dmy' }), [
    { text: '09/08/2026', year: 2026, month: 8, day: 9 },
  ]);
});

test('strict order skips what it cannot read', () => {
  assert.deepEqual(dates('09/08/2026', { dateOrder: 'strict' }), []);
  // Unambiguous even in strict mode: 25 cannot be a month.
  assert.deepEqual(dates('25/08/2026', { dateOrder: 'strict' }), [
    { text: '25/08/2026', year: 2026, month: 8, day: 25 },
  ]);
});

test('a value over 12 pins the day whatever the setting', () => {
  assert.deepEqual(dates('13/08/2026', { dateOrder: 'mdy' }), [
    { text: '13/08/2026', year: 2026, month: 8, day: 13 },
  ]);
});

test('impossible dates are rejected', () => {
  assert.deepEqual(dates('2026-02-30'), []);
  assert.deepEqual(dates('2026-13-01'), []);
  assert.deepEqual(dates('February 30, 2026'), []);
  assert.deepEqual(dates('2024-02-29'), [
    { text: '2024-02-29', year: 2024, month: 2, day: 29 },
  ], 'leap day is real');
  assert.deepEqual(dates('2026-02-29'), [], 'but not in a common year');
});

test('non-dates are left alone', () => {
  assert.deepEqual(dates('version 1.2.3'), []);
  assert.deepEqual(dates('call 9851-000-000'), []);
  assert.deepEqual(dates('the 2026 budget'), []);
  assert.deepEqual(dates('scores were 10/10'), []);
});

test('years outside the convertible range are ignored', () => {
  assert.deepEqual(dates('1850-01-01'), []);
  assert.deepEqual(dates('2400-01-01'), []);
});

test('several dates in one string, in order', () => {
  const hits = dates('From 2026-01-01 to 15 March 2026 and 2026/12/31');
  assert.deepEqual(hits.map((h) => h.month), [1, 3, 12]);
});

test('overlapping matches keep the earlier, longer one', () => {
  const hits = findDates('Due 2026-08-09 sharp');
  assert.equal(hits.length, 1);
  assert.equal(hits[0].text, '2026-08-09');
});

test('machine-readable datetime attributes', () => {
  assert.deepEqual(parseMachineDate('2026-08-09T14:30:00+05:45'), {
    year: 2026, month: 8, day: 9,
  });
  assert.deepEqual(parseMachineDate('2026-08-09'), { year: 2026, month: 8, day: 9 });
  assert.equal(parseMachineDate('yesterday'), null);
  assert.equal(parseMachineDate(null), null);
  assert.equal(parseMachineDate('2026-02-30'), null);
});

test('isRealDate', () => {
  assert.ok(isRealDate({ year: 2026, month: 8, day: 9 }));
  assert.ok(!isRealDate({ year: 2026, month: 4, day: 31 }));
  assert.ok(!isRealDate({ year: 2026, month: 0, day: 1 }));
});
