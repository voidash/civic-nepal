// End-to-end check of the packed extension in a real Chromium.
//
// The unit tests cover the conversion and detection logic; this covers the
// parts only a browser can answer — that the manifest loads, the dynamic
// module imports resolve under MV3, the DOM rewriting works, and the skip
// rules genuinely hold on a live page.
//
// Run with: node chrome_extension/test/e2e.mjs

import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, resolve } from 'node:path';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execSync } from 'node:child_process';
import { createServer } from 'node:http';
import { readFile } from 'node:fs';

// There is no package.json here on purpose — the extension has no build step
// and no dependencies. Playwright is only needed to run this file, so it is
// resolved from wherever it happens to be installed.
async function loadPlaywright() {
  let mod;
  try {
    mod = await import('playwright');
  } catch {
    const globalRoot = execSync('npm root -g', { encoding: 'utf8' }).trim();
    mod = await import(pathToFileURL(join(globalRoot, 'playwright', 'index.mjs')).href);
  }
  // A global install resolves to CommonJS, where the browsers hang off default.
  return mod.chromium ? mod : mod.default;
}

const { chromium } = await loadPlaywright();

const here = dirname(fileURLToPath(import.meta.url));
const extensionPath = resolve(here, '..');

// The fixture is served over HTTP rather than opened as a file:// URL. The
// manifest only matches http/https — as it should, since file access needs a
// permission users have to grant by hand — so a file:// fixture would silently
// test nothing at all.
const server = createServer((req, res) => {
  readFile(join(here, 'fixture.html'), (err, body) => {
    if (err) {
      res.writeHead(404).end('not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }).end(body);
  });
});
await new Promise((ready) => server.listen(0, '127.0.0.1', ready));
const fixture = `http://127.0.0.1:${server.address().port}/`;

const results = [];
function check(name, condition, detail = '') {
  results.push({ name, ok: Boolean(condition), detail });
}

const context = await chromium.launchPersistentContext(
  mkdtempSync(join(tmpdir(), 'nagarik-ext-')),
  {
    headless: process.env.NAGARIK_HEADLESS !== "0",
    args: [
      `--disable-extensions-except=${extensionPath}`,
      `--load-extension=${extensionPath}`,
      // The Google Calendar path is gated on the hostname, so the fixture is
      // served as calendar.google.com to exercise it for real rather than by
      // calling the module directly.
      `--host-resolver-rules=MAP calendar.google.com 127.0.0.1:${server.address().port}`,
    ],
  },
);

const page = await context.newPage();
const errors = [];
page.on('pageerror', (e) => errors.push(String(e)));
page.on('console', (m) => {
  if (m.type() === 'error') errors.push(m.text());
});

await page.goto(fixture);
// Content script runs at document_idle and schedules work on idle callbacks;
// the fixture also injects a paragraph at 400ms.
await page.waitForTimeout(2500);

const badgeIn = (sel) =>
  page.$eval(sel, (el) => {
    const badge = el.querySelector('.nagarik-date__badge');
    return badge ? badge.textContent : null;
  }).catch(() => null);

const countIn = (sel) =>
  page.$eval(sel, (el) => el.querySelectorAll('.nagarik-date').length).catch(() => -1);

// 9 August 2026 is 24 Shrawan 2083.
const expected = '२४ श्रावण २०८३';

check('ISO date annotated', (await badgeIn('#iso')) === expected, await badgeIn('#iso'));
check('long form annotated', (await badgeIn('#long')) === expected, await badgeIn('#long'));
check('day-month form annotated', (await badgeIn('#daymonth')) === expected, await badgeIn('#daymonth'));
check('unambiguous numeric annotated', (await badgeIn('#numeric')) !== null);

check('three dates found in one paragraph', (await countIn('#multi')) === 3, `got ${await countIn('#multi')}`);
check('non-dates left alone', (await countIn('#notdate')) === 0, `got ${await countIn('#notdate')}`);
check('impossible dates rejected', (await countIn('#impossible')) === 0, `got ${await countIn('#impossible')}`);

check('<pre> skipped', (await countIn('#inpre')) === 0);
check('<code> skipped', (await countIn('#incode')) === 0);
check(
  'textarea untouched',
  (await page.$eval('#inta', (el) => el.value.trim())) === '2026-08-09',
);

check('<time datetime> annotated', (await badgeIn('#timeel')) === expected, await badgeIn('#timeel'));
check('dynamically added date annotated', (await badgeIn('#dynamic')) !== null, await badgeIn('#dynamic'));

// Original text must survive verbatim — the badge is additive.
const isoText = await page.$eval('#iso', (el) => el.textContent);
check('original date text preserved', isoText.includes('2026-08-09'), isoText);

// Hover card.
// Hover card (guarded: a missing mark should report, not crash the run).
if (await page.$("#iso .nagarik-date")) await page.hover('#iso .nagarik-date');
await page.waitForTimeout(300);
const card = await page.$eval('.nagarik-date-card', (el) => ({
  hidden: el.hidden,
  text: el.textContent,
})).catch(() => null);
check('hover card appears', card && !card.hidden);
check('hover card shows Bikram Sambat', card?.text.includes('विक्रम सम्वत्'), card?.text);
check('hover card shows Nepal Sambat 1146', card?.text.includes('१‍१४६') || card?.text.includes('११४६'), card?.text);

// Google Calendar cells, on a page the extension believes is Google Calendar.
const gcalPage = await context.newPage();
await gcalPage.goto('http://calendar.google.com/');
await gcalPage.waitForTimeout(2000);

const gcalCells = await gcalPage.$$eval('#gcal [role="gridcell"]', (cells) =>
  cells.map((c) => {
    const bs = c.querySelector('.nagarik-gcal-bs');
    return { label: c.getAttribute('aria-label'), bs: bs ? bs.textContent : null };
  }),
);
check('gcal cell annotated with BS day', gcalCells[0]?.bs === '२४', JSON.stringify(gcalCells[0]));
check('gcal next day increments', gcalCells[1]?.bs === '२५', JSON.stringify(gcalCells[1]));
check(
  'gcal Nepali new year shows month name',
  gcalCells[2]?.bs?.includes('बैशाख'),
  JSON.stringify(gcalCells[2]),
);
check(
  'gcal cell with contradictory label is skipped',
  gcalCells[3]?.bs === null,
  JSON.stringify(gcalCells[3]),
);

check('no page errors', errors.length === 0, errors.slice(0, 3).join(' | '));

await context.close();
server.close();

let failed = 0;
for (const r of results) {
  if (!r.ok) failed += 1;
  console.log(`${r.ok ? 'ok  ' : 'FAIL'}  ${r.name}${r.ok || !r.detail ? '' : `  -> ${r.detail}`}`);
}
console.log(`\n${results.length - failed}/${results.length} passed`);
process.exit(failed ? 1 : 0);
