#!/usr/bin/env python3
"""Rank countries by estimated iPhone users and spending power (L19-010).

Data sources (fetched once, cached under --cache):
  - World Bank API: population (SP.POP.TOTL), internet users % (IT.NET.USER.ZS),
    GNI per capita, Atlas method, current USD (NY.GNP.PCAP.CD); most recent non-empty value.
  - StatCounter Global Stats: mobile OS share (iOS) per country, monthly, averaged over
    the 12 months FROM..TO below.

Estimates:
  iphone_users = population x internet% x iOS share of mobile web traffic
  value        = iphone_users x GNI per capita (a spending-power proxy, not revenue)

StatCounter measures page views, not devices, so iOS share is a proxy for the share of
active smartphone users. Treat all outputs as estimates for ranking, not market sizes.

Usage: python3 scripts/market/rank_countries.py --cache /tmp/cache --out docs/market/country-ranking-2026-11.csv
"""
import argparse, csv, json, os, sys, time, urllib.parse, urllib.request

FROM, TO = "202511", "202610"
UA = {"User-Agent": "Mozilla/5.0 (market-research script)"}

# Not in the World Bank dataset; added by hand (sources in docs/06-markets-and-documents.md §6).
MANUAL = {
    "TW": {"name": "Taiwan", "population": 23_400_000, "internet": 90.0, "gni": 34_000},
}
# No App Store storefront (Apple does not operate the App Store there).
NO_APP_STORE = {"IR", "KP", "SY", "CU"}


def get(url, cache, key):
    path = os.path.join(cache, key)
    if os.path.exists(path):
        return open(path, encoding="utf-8").read()
    req = urllib.request.Request(url, headers=UA)
    for attempt in range(3):
        try:
            data = urllib.request.urlopen(req, timeout=30).read().decode("utf-8")
            break
        except Exception as error:  # network hiccup: retry, then give up loudly
            if attempt == 2:
                raise SystemExit(f"fetch failed {url}: {error}")
            time.sleep(2)
    open(path, "w", encoding="utf-8").write(data)
    time.sleep(0.3)
    return data


def world_bank(cache):
    countries = json.loads(get("https://api.worldbank.org/v2/country?format=json&per_page=400", cache, "wb_countries.json"))[1]
    real = {c["iso2Code"]: c["name"] for c in countries if c["region"]["value"] != "Aggregates"}
    out = {iso2: {"name": name} for iso2, name in real.items()}
    for key, indicator in [("population", "SP.POP.TOTL"), ("internet", "IT.NET.USER.ZS"), ("gni", "NY.GNP.PCAP.CD")]:
        url = f"https://api.worldbank.org/v2/country/all/indicator/{indicator}?format=json&mrnev=1&per_page=400"
        for row in json.loads(get(url, cache, f"wb_{indicator}.json"))[1]:
            iso2 = row["country"]["id"]
            if iso2 in out and row["value"] is not None:
                out[iso2][key] = float(row["value"])
                out[iso2][key + "_year"] = row["date"]
    return out


def ios_share(iso2, name, cache):
    query = urllib.parse.urlencode({
        "device": "Mobile", "device_hidden": "mobile", "statType_hidden": "os_combined",
        "region_hidden": iso2, "granularity": "monthly", "statType": "Operating System",
        "region": name, "fromInt": FROM, "toInt": TO,
        "fromMonthYear": f"{FROM[:4]}-{FROM[4:]}", "toMonthYear": f"{TO[:4]}-{TO[4:]}", "csv": "1",
    })
    text = get("https://gs.statcounter.com/os-market-share/mobile/chart.php?" + query, cache, f"sc_{iso2}.csv")
    rows = list(csv.DictReader(text.splitlines()))
    values = [float(r["iOS"]) for r in rows if r.get("iOS") not in (None, "")]
    return (sum(values) / len(values), len(values)) if values else (None, 0)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cache", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    os.makedirs(args.cache, exist_ok=True)

    data = world_bank(args.cache)
    data.update(MANUAL)
    rows = []
    for iso2, c in sorted(data.items()):
        if "population" not in c or c["population"] < 300_000:
            continue  # microstates do not change the ranking
        share, months = ios_share(iso2, c["name"], args.cache)
        if share is None or "internet" not in c:
            print(f"skip {iso2} {c['name']}: missing data", file=sys.stderr)
            continue
        users = c["population"] * c["internet"] / 100 * share / 100
        rows.append({
            "iso2": iso2, "country": c["name"], "app_store": iso2 not in NO_APP_STORE,
            "population_m": round(c["population"] / 1e6, 2), "internet_pct": round(c["internet"], 1),
            "internet_year": c.get("internet_year", "manual"), "ios_share_pct": round(share, 1), "ios_months": months,
            "iphone_users_m": round(users / 1e6, 2), "gni_per_capita_usd": c.get("gni"),
            "value_index": round(users * c["gni"] / 1e12, 3) if c.get("gni") else None,
        })
    rows.sort(key=lambda r: r["iphone_users_m"], reverse=True)
    with open(args.out, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    print(f"wrote {len(rows)} countries to {args.out}")


if __name__ == "__main__":
    main()
