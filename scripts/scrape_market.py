#!/usr/bin/env python3
"""
Scrape NEPSE market data and the CDSC IPO list.

Why this runs server-side rather than in the app: a browser cannot fetch
cdsc.com.np or sharesansar.com directly — neither sends CORS headers — so the
web build used to route through public CORS proxies. Both of those are now
dead (api.allorigins.win returns 520, corsproxy.io returns 403), which is why
the IPO and shares screen renders empty. Scraping here and publishing JSON
removes the third-party dependency entirely and makes the screen work the same
way on web and native.

Usage:
    python3 scripts/scrape_market.py -o market.json --pretty
"""

import argparse
import json
import re
import sys
from datetime import datetime, timezone, timedelta

import requests
from bs4 import BeautifulSoup
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

NEPAL_TZ = timezone(timedelta(hours=5, minutes=45))

CDSC_URL = "https://cdsc.com.np/ipolist"
SHARESANSAR_URL = "https://www.sharesansar.com/live-trading"

UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"
)


def _session() -> requests.Session:
    session = requests.Session()
    retry = Retry(
        total=4,
        backoff_factor=2,
        status_forcelist=(403, 429, 500, 502, 503, 504),
        allowed_methods=("GET",),
    )
    session.mount("https://", HTTPAdapter(max_retries=retry))
    session.headers.update({"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"})
    return session


def _number(text: str) -> float | None:
    """Parse a table cell like '1,234.50' or '-0.33'. None when not a number."""
    cleaned = re.sub(r"[^\d.\-]", "", (text or "").replace(",", ""))
    if not cleaned or cleaned in {"-", ".", "-."}:
        return None
    try:
        return float(cleaned)
    except ValueError:
        return None


def _int(text: str) -> int:
    value = _number(text)
    return int(value) if value is not None else 0


def _date(text: str) -> str | None:
    """CDSC prints dates as YYYY-MM-DD, sometimes with a time appended."""
    match = re.search(r"(\d{4})-(\d{1,2})-(\d{1,2})", text or "")
    if not match:
        return None
    year, month, day = (int(g) for g in match.groups())
    try:
        return datetime(year, month, day, tzinfo=timezone.utc).date().isoformat()
    except ValueError:
        return None


def scrape_ipos(session: requests.Session) -> list[dict]:
    """Open IPO/FPO issues from CDSC.

    An empty list is a legitimate result — there is frequently no open issue —
    so this must not be treated as a failure. The app is expected to say "no
    open issues" rather than show a spinner forever.
    """
    response = session.get(CDSC_URL, timeout=30)
    response.raise_for_status()
    soup = BeautifulSoup(response.text, "html.parser")

    table = soup.find("table")
    if table is None:
        return []

    ipos = []
    for row in table.select("tbody tr"):
        cells = [c.get_text(" ", strip=True) for c in row.find_all("td")]
        # S.N, Company, Issue Manager, Issued Unit, Applications, Applied Unit,
        # Amount, Open, Close, Last Update
        if len(cells) < 10:
            continue

        company = cells[1]
        # The company cell carries the ticker and issue type in brackets, e.g.
        # "Foo Hydropower Ltd (FOO) [Ordinary Shares]".
        symbol_match = re.search(r"\(([A-Z0-9]{2,12})\)", company)
        type_match = re.search(r"\[([^\]]+)\]", company)
        name = re.sub(r"\s*[\(\[][^\)\]]*[\)\]]", "", company).strip()

        ipos.append({
            "companyName": name or company,
            "symbol": symbol_match.group(1) if symbol_match else "",
            "issueType": type_match.group(1) if type_match else "Ordinary Shares",
            "issueManager": cells[2],
            "issuedUnits": _int(cells[3]),
            "numberOfApplications": _int(cells[4]),
            "appliedUnits": _int(cells[5]),
            "amount": _int(cells[6]),
            "openDate": _date(cells[7]),
            "closeDate": _date(cells[8]),
            "lastUpdate": cells[9],
        })
    return ipos


def scrape_stocks(session: requests.Session) -> tuple[list[dict], dict | None]:
    """Live prices and the NEPSE index from ShareSansar."""
    response = session.get(SHARESANSAR_URL, timeout=30)
    response.raise_for_status()
    soup = BeautifulSoup(response.text, "html.parser")

    stocks = []
    for table in soup.find_all("table"):
        headers = [th.get_text(strip=True).lower() for th in table.select("thead th")]
        if "symbol" not in headers or "ltp" not in headers:
            continue

        for row in table.select("tbody tr"):
            cells = [c.get_text(" ", strip=True) for c in row.find_all("td")]
            # S.No, Symbol, LTP, Point Change, % Change, Open, High, Low,
            # Volume, Prev. Close
            if len(cells) < 10:
                continue
            symbol = cells[1].strip()
            ltp = _number(cells[2])
            if not symbol or ltp is None:
                continue
            stocks.append({
                "symbol": symbol,
                "companyName": symbol,   # the live table carries tickers only
                "ltp": ltp,
                "change": _number(cells[3]) or 0.0,
                "changePercent": _number(cells[4]) or 0.0,
                "open": _number(cells[5]) or ltp,
                "high": _number(cells[6]) or ltp,
                "low": _number(cells[7]) or ltp,
                "volume": _int(cells[8]),
                "previousClose": _number(cells[9]) or ltp,
            })
        if stocks:
            break

    summary = None
    # The header strip reads "NEPSE Index <turnover> <index value>".
    text = re.sub(r"\s+", " ", soup.get_text(" ", strip=True))
    match = re.search(r"NEPSE Index\s+([\d,]+)\s+([\d,]+\.\d+)", text)
    if match:
        summary = {
            "nepseIndex": _number(match.group(2)) or 0.0,
            "turnover": _number(match.group(1)) or 0.0,
            "tradedShares": sum(s["volume"] for s in stocks),
            "transactions": len(stocks),
        }
    return stocks, summary


def main() -> int:
    parser = argparse.ArgumentParser(description="Scrape NEPSE market data")
    parser.add_argument("-o", "--output", help="Output file (default: stdout)")
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument(
        "--min-stocks",
        type=int,
        default=0,
        help="Exit non-zero below this many stocks, so a blocked scrape fails "
             "the job instead of publishing an empty market",
    )
    args = parser.parse_args()

    session = _session()

    # The two sources are independent: NEPSE being closed or CDSC being down
    # must not take the other one with it.
    ipos, ipo_error = [], None
    try:
        ipos = scrape_ipos(session)
    except Exception as exc:                                  # noqa: BLE001
        ipo_error = str(exc)
        print(f"IPO scrape failed: {exc}", file=sys.stderr)

    stocks, summary, stock_error = [], None, None
    try:
        stocks, summary = scrape_stocks(session)
    except Exception as exc:                                  # noqa: BLE001
        stock_error = str(exc)
        print(f"Stock scrape failed: {exc}", file=sys.stderr)

    print(f"IPOs: {len(ipos)} | stocks: {len(stocks)} | index: "
          f"{summary['nepseIndex'] if summary else 'n/a'}", file=sys.stderr)

    if len(stocks) < args.min_stocks:
        print(
            f"ERROR: only {len(stocks)} stocks, expected at least "
            f"{args.min_stocks}. Refusing to publish.",
            file=sys.stderr,
        )
        return 1

    now = datetime.now(tz=timezone.utc)
    result = {
        "scraped_at": now.isoformat(),
        "scraped_at_npt": now.astimezone(NEPAL_TZ).strftime("%Y-%m-%d %H:%M"),
        "sources": {"ipos": CDSC_URL, "stocks": SHARESANSAR_URL},
        "errors": {k: v for k, v in
                   {"ipos": ipo_error, "stocks": stock_error}.items() if v},
        "ipos": ipos,
        "stocks": stocks,
        "summary": summary,
    }

    output = json.dumps(result, ensure_ascii=False, indent=2 if args.pretty else None)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as handle:
            handle.write(output)
        print(f"Written to {args.output}", file=sys.stderr)
    else:
        print(output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
