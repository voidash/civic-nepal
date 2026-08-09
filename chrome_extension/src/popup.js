import { loadSettings, saveSettings } from './settings.js';
import {
  describeDate,
  formatBs,
  toNepaliDigits,
  WEEKDAYS_NP,
} from './calendars.js';

const $ = (id) => document.getElementById(id);

function showToday() {
  // Nepal is UTC+05:45, and the popup should show the date it is in Nepal
  // regardless of where the reader happens to be.
  const nowNpt = new Date(Date.now() + (5 * 60 + 45) * 60 * 1000);
  const y = nowNpt.getUTCFullYear();
  const m = nowNpt.getUTCMonth() + 1;
  const d = nowNpt.getUTCDate();

  const info = describeDate(y, m, d);
  if (!info) return;

  $('todayBs').textContent = formatBs(info.bs);
  $('todayAd').textContent = `${WEEKDAYS_NP[info.weekday]} · ${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;

  const extra = [];
  if (info.nepalSambat !== null) extra.push(`ने.सं. ${toNepaliDigits(info.nepalSambat)}`);
  if (info.buddhaSambat !== null) extra.push(`बु.सं. ${toNepaliDigits(info.buddhaSambat)}`);
  extra.push(`श.सं. ${toNepaliDigits(info.saka.year)}`);
  $('todayExtra').textContent = extra.join('  ·  ');
}

async function wire() {
  const settings = await loadSettings();
  $('enabled').checked = settings.enabled;
  $('googleCalendarBs').checked = settings.googleCalendarBs;

  $('enabled').addEventListener('change', (e) =>
    saveSettings({ enabled: e.target.checked }));
  $('googleCalendarBs').addEventListener('change', (e) =>
    saveSettings({ googleCalendarBs: e.target.checked }));
  $('options').addEventListener('click', () => chrome.runtime.openOptionsPage());
}

showToday();
wire();
