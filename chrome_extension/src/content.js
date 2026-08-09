// Annotates Gregorian dates on any page with their Nepali equivalents.
//
// Loaded as a classic script because MV3 content scripts cannot be ES modules;
// the real logic lives in modules pulled in with a dynamic import, which keeps
// the conversion code shared with the options page and testable under Node.

(async function main() {
  const url = (path) => chrome.runtime.getURL(path);
  const [cal, detect, config, gcal] = await Promise.all([
    import(url('src/calendars.js')),
    import(url('src/detect.js')),
    import(url('src/settings.js')),
    import(url('src/gcal.js')),
  ]);

  let settings = await config.loadSettings();
  if (!settings.enabled || config.isBlocked(settings, location.hostname)) return;

  const MARK_CLASS = 'nagarik-date';
  const SKIP_TAGS = new Set([
    'SCRIPT', 'STYLE', 'NOSCRIPT', 'TEXTAREA', 'INPUT', 'SELECT', 'OPTION',
    'CODE', 'PRE', 'KBD', 'SAMP', 'SVG', 'MATH', 'CANVAS', 'IFRAME',
  ]);

  let annotated = 0;
  let card = null;

  // ── Formatting ─────────────────────────────────────────────────────────

  const digits = (n) =>
    settings.numerals === 'devanagari' ? cal.toNepaliDigits(n) : String(n);

  function badgeText(bs) {
    const months = settings.language === 'nepali' ? cal.BS_MONTHS_NP : cal.BS_MONTHS_EN;
    return `${digits(bs.day)} ${months[bs.month - 1]} ${digits(bs.year)}`;
  }

  /** Rows for the hover card: label, value, and whether it is exact. */
  function cardRows(info) {
    const rows = [];
    const months = settings.language === 'nepali' ? cal.BS_MONTHS_NP : cal.BS_MONTHS_EN;
    rows.push(['विक्रम सम्वत्', `${digits(info.bs.day)} ${months[info.bs.month - 1]} ${digits(info.bs.year)}`]);

    if (settings.showWeekday) {
      const names = settings.language === 'nepali' ? cal.WEEKDAYS_NP : cal.WEEKDAYS_EN;
      rows.push(['बार', names[info.weekday]]);
    }
    if (settings.showNepalSambat && info.nepalSambat !== null) {
      rows.push(['नेपाल सम्वत्', digits(info.nepalSambat)]);
    }
    if (settings.showSaka) {
      const sakaMonths = settings.language === 'nepali' ? cal.SAKA_MONTHS_NP : cal.SAKA_MONTHS_EN;
      rows.push(['शक सम्वत्', `${digits(info.saka.day)} ${sakaMonths[info.saka.month - 1]} ${digits(info.saka.year)}`]);
    }
    if (settings.showBuddhaSambat && info.buddhaSambat !== null) {
      rows.push(['बुद्ध सम्वत्', digits(info.buddhaSambat)]);
    }
    return rows;
  }

  // ── Hover card ─────────────────────────────────────────────────────────
  // One shared element rather than a tooltip per date, so a page with
  // hundreds of dates does not grow hundreds of hidden subtrees.

  function ensureCard() {
    if (card) return card;
    card = document.createElement('div');
    card.className = 'nagarik-date-card';
    card.setAttribute('role', 'tooltip');
    card.hidden = true;
    document.body.appendChild(card);
    return card;
  }

  function showCard(target) {
    const info = readInfo(target);
    if (!info) return;
    const el = ensureCard();
    el.textContent = '';

    const heading = document.createElement('div');
    heading.className = 'nagarik-date-card__ad';
    heading.textContent = target.dataset.nagarikAd;
    el.appendChild(heading);

    for (const [label, value] of cardRows(info)) {
      const row = document.createElement('div');
      row.className = 'nagarik-date-card__row';
      const key = document.createElement('span');
      key.className = 'nagarik-date-card__label';
      key.textContent = label;
      const val = document.createElement('span');
      val.className = 'nagarik-date-card__value';
      val.textContent = value;
      row.append(key, val);
      el.appendChild(row);
    }

    el.hidden = false;
    position(el, target);
  }

  function position(el, target) {
    const rect = target.getBoundingClientRect();
    // Measure after unhiding so the flip has real dimensions to work with.
    const { width, height } = el.getBoundingClientRect();
    let left = rect.left + window.scrollX;
    let top = rect.bottom + window.scrollY + 6;

    if (left + width > window.scrollX + document.documentElement.clientWidth - 8) {
      left = Math.max(8, window.scrollX + document.documentElement.clientWidth - width - 8);
    }
    // Flip above when there is no room below.
    if (rect.bottom + height + 12 > document.documentElement.clientHeight) {
      top = rect.top + window.scrollY - height - 6;
    }
    el.style.left = `${left}px`;
    el.style.top = `${top}px`;
  }

  function hideCard() {
    if (card) card.hidden = true;
  }

  function readInfo(target) {
    const raw = target.dataset.nagarikDate;
    if (!raw) return null;
    const [y, m, d] = raw.split('-').map(Number);
    return cal.describeDate(y, m, d);
  }

  // ── Annotation ─────────────────────────────────────────────────────────

  function makeMark(originalText, date) {
    const info = cal.describeDate(date.year, date.month, date.day);
    if (!info) return null;

    const mark = document.createElement('span');
    mark.className = MARK_CLASS;
    mark.dataset.nagarikDate = `${date.year}-${date.month}-${date.day}`;
    mark.dataset.nagarikAd = originalText;

    const original = document.createElement('span');
    original.className = 'nagarik-date__original';
    original.textContent = originalText;
    mark.appendChild(original);

    if (settings.displayMode === 'inline') {
      const badge = document.createElement('span');
      badge.className = 'nagarik-date__badge';
      badge.textContent = badgeText(info.bs);
      mark.appendChild(badge);
    } else {
      mark.classList.add('nagarik-date--hover');
    }

    mark.tabIndex = 0;
    mark.setAttribute('aria-label', `${originalText} — ${badgeText(info.bs)} विक्रम सम्वत्`);
    return mark;
  }

  /** Replace the dates inside one text node. Returns how many were added. */
  function annotateTextNode(node) {
    const text = node.nodeValue;
    if (!text || text.length < 6) return 0;

    const hits = detect.findDates(text, { dateOrder: settings.dateOrder });
    if (!hits.length) return 0;

    const fragment = document.createDocumentFragment();
    let cursor = 0;
    let added = 0;

    for (const hit of hits) {
      if (annotated + added >= settings.maxAnnotationsPerPage) break;
      const mark = makeMark(hit.text, hit.date);
      if (!mark) continue;
      if (hit.start > cursor) {
        fragment.appendChild(document.createTextNode(text.slice(cursor, hit.start)));
      }
      fragment.appendChild(mark);
      cursor = hit.end;
      added += 1;
    }

    if (!added) return 0;
    if (cursor < text.length) {
      fragment.appendChild(document.createTextNode(text.slice(cursor)));
    }
    node.parentNode.replaceChild(fragment, node);
    return added;
  }

  function shouldSkip(element) {
    for (let node = element; node; node = node.parentElement) {
      if (SKIP_TAGS.has(node.tagName)) return true;
      if (node.classList?.contains(MARK_CLASS)) return true;
      if (node.isContentEditable) return true;
      if (node.dataset?.nagarikSkip === 'true') return true;
    }
    return false;
  }

  function collectTextNodes(root) {
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode(node) {
        if (!node.nodeValue || node.nodeValue.length < 6) return NodeFilter.FILTER_REJECT;
        if (!node.parentElement || shouldSkip(node.parentElement)) {
          return NodeFilter.FILTER_REJECT;
        }
        return NodeFilter.FILTER_ACCEPT;
      },
    });
    const nodes = [];
    let node;
    while ((node = walker.nextNode())) nodes.push(node);
    return nodes;
  }

  /** Use `<time datetime>` where the page has given us an exact date. */
  function annotateTimeElements(root) {
    const elements = root.querySelectorAll?.('time[datetime]') ?? [];
    for (const time of elements) {
      if (annotated >= settings.maxAnnotationsPerPage) return;
      if (time.dataset.nagarikDone === 'true' || shouldSkip(time)) continue;
      const date = detect.parseMachineDate(time.getAttribute('datetime'));
      time.dataset.nagarikDone = 'true';
      if (!date) continue;
      const info = cal.describeDate(date.year, date.month, date.day);
      if (!info) continue;

      time.dataset.nagarikDate = `${date.year}-${date.month}-${date.day}`;
      time.dataset.nagarikAd = time.textContent.trim();
      time.classList.add(MARK_CLASS, 'nagarik-date--time');

      if (settings.displayMode === 'inline') {
        const badge = document.createElement('span');
        badge.className = 'nagarik-date__badge';
        badge.textContent = badgeText(info.bs);
        time.appendChild(badge);
      } else {
        time.classList.add('nagarik-date--hover');
      }
      annotated += 1;
    }
  }

  /** Walk a subtree in idle slices so a long page never blocks input. */
  function scan(root) {
    if (annotated >= settings.maxAnnotationsPerPage) return;
    annotateTimeElements(root);

    const nodes = collectTextNodes(root);
    let index = 0;

    const step = (deadline) => {
      while (
        index < nodes.length &&
        annotated < settings.maxAnnotationsPerPage &&
        (!deadline || deadline.timeRemaining() > 4)
      ) {
        const node = nodes[index++];
        // The node may have been detached by the page since collection.
        if (node.parentNode) annotated += annotateTextNode(node);
      }
      if (index < nodes.length && annotated < settings.maxAnnotationsPerPage) {
        schedule(step);
      }
    };
    schedule(step);
  }

  const schedule =
    typeof requestIdleCallback === 'function'
      ? (fn) => requestIdleCallback(fn, { timeout: 500 })
      : (fn) => setTimeout(() => fn(null), 0);

  // ── Wiring ─────────────────────────────────────────────────────────────

  document.addEventListener('mouseover', (event) => {
    const mark = event.target.closest?.(`.${MARK_CLASS}`);
    if (mark) showCard(mark);
  });
  document.addEventListener('mouseout', (event) => {
    if (event.target.closest?.(`.${MARK_CLASS}`)) hideCard();
  });
  document.addEventListener('focusin', (event) => {
    const mark = event.target.closest?.(`.${MARK_CLASS}`);
    if (mark) showCard(mark);
  });
  document.addEventListener('focusout', hideCard);
  window.addEventListener('scroll', hideCard, { passive: true });

  scan(document.body);

  if (settings.googleCalendarBs && gcal.isGoogleCalendar(location.hostname)) {
    gcal.start({
      cal,
      settings,
      // Google's own accessibility labels are the trustworthy source for what
      // date a cell shows, so the same parser used on ordinary pages reads them.
      parseLabel: (label) => detect.findDates(label, { dateOrder: settings.dateOrder })[0]?.date ?? null,
    });
  }

  // Pages that render after load, and single-page navigations, need a second
  // look. Batched so a chatty app does not trigger a scan per mutation.
  let pending = new Set();
  let timer = null;
  new MutationObserver((records) => {
    for (const record of records) {
      for (const node of record.addedNodes) {
        if (node.nodeType === Node.ELEMENT_NODE && !shouldSkip(node)) pending.add(node);
      }
    }
    if (!pending.size || timer) return;
    timer = setTimeout(() => {
      const roots = [...pending];
      pending = new Set();
      timer = null;
      for (const root of roots) {
        if (root.isConnected) scan(root);
      }
    }, 350);
  }).observe(document.body, { childList: true, subtree: true });

  // Applying a settings change to already-rewritten DOM is not worth the
  // complexity; a reload is one keystroke and always correct.
  config.onSettingsChanged(() => {
    document.querySelectorAll('.nagarik-date__badge').forEach((el) => el.remove());
    hideCard();
  });
})();
