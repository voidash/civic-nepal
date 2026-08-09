// Diff the extension's JS date conversion against the Flutter app's Dart one,
// day by day.
//
// The two implementations are independent — same table, separately written
// arithmetic — so agreeing on every day across a century and a half is strong
// evidence that neither has an off-by-one hiding in it.
//
//   cd flutter_app && dart run tool/dump_dart_bs.dart > /tmp/dart_bs.txt
//   node chrome_extension/tools/compare_with_dart.mjs /tmp/dart_bs.txt

import { readFileSync } from 'node:fs';
import { adToBs, bsToAd } from '../src/calendars.js';

const path = process.argv[2];
if (!path) {
  console.error('usage: node compare_with_dart.mjs <dart_bs.txt>');
  process.exit(2);
}

let compared = 0;
let skipped = 0;
const mismatches = [];
const roundTripFailures = [];

for (const line of readFileSync(path, 'utf8').split('\n')) {
  const trimmed = line.trim();
  // The dart tool prints build noise on the first line.
  const match = /^(\d+)-(\d+)-(\d+) (\d+)-(\d+)-(\d+)$/.exec(trimmed);
  if (!match) continue;

  const [, ay, am, ad, by, bm, bd] = match.map(Number);
  const got = adToBs(ay, am, ad);
  if (!got) {
    skipped += 1;
    continue;
  }
  compared += 1;

  if (got.year !== by || got.month !== bm || got.day !== bd) {
    mismatches.push(`${ay}-${am}-${ad}: dart ${by}-${bm}-${bd}, js ${got.year}-${got.month}-${got.day}`);
  }

  const back = bsToAd(got.year, got.month, got.day);
  if (!back || back.year !== ay || back.month !== am || back.day !== ad) {
    roundTripFailures.push(`${ay}-${am}-${ad}`);
  }
}

console.log(`compared        : ${compared} days`);
console.log(`outside range   : ${skipped}`);
console.log(`mismatches      : ${mismatches.length}`);
console.log(`round-trip fails: ${roundTripFailures.length}`);

for (const line of mismatches.slice(0, 10)) console.log(`  ${line}`);
for (const line of roundTripFailures.slice(0, 10)) console.log(`  round-trip: ${line}`);

if (!compared) {
  console.error('Nothing was compared — is the input file in "AD BS" form?');
  process.exit(2);
}
process.exit(mismatches.length || roundTripFailures.length ? 1 : 0);
