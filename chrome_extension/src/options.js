import { DEFAULTS, loadSettings, saveSettings } from './settings.js';

const SELECTS = ['displayMode', 'numerals', 'language', 'dateOrder'];
const CHECKS = [
  'showWeekday',
  'showNepalSambat',
  'showSaka',
  'showBuddhaSambat',
  'googleCalendarBs',
];

const $ = (id) => document.getElementById(id);

async function render() {
  const settings = await loadSettings();
  for (const key of SELECTS) $(key).value = settings[key] ?? DEFAULTS[key];
  for (const key of CHECKS) $(key).checked = settings[key] ?? DEFAULTS[key];
  $('blocklist').value = (settings.blocklist ?? []).join('\n');
}

async function save() {
  const patch = {};
  for (const key of SELECTS) patch[key] = $(key).value;
  for (const key of CHECKS) patch[key] = $(key).checked;
  patch.blocklist = $('blocklist')
    .value.split('\n')
    .map((line) => line.trim().replace(/^https?:\/\//, '').replace(/\/.*$/, ''))
    .filter(Boolean);

  await saveSettings(patch);

  const status = $('status');
  status.textContent = 'Saved — reload open tabs to apply.';
  setTimeout(() => {
    status.textContent = '';
  }, 3000);
}

$('save').addEventListener('click', save);
render();
