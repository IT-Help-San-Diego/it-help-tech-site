#!/usr/bin/env bash
# Stamp the Real Bot withdrawal with the date it goes live.
# A corrections entry may not state an event before it happens, so the
# identifier and the date stay placeholders until the day of the deploy.
#
#   scripts/stamp-withdrawal.sh 2026-11-20     stamp every carrier
#   scripts/stamp-withdrawal.sh --check        change nothing; exit 1 if the
#                                              carriers disagree with each other
#
# Before stamping, merge origin/main into this branch. A merge made after the
# stamp can bring back an unstamped copy of a carrier; if that happens, run the
# script again with the same date and it finishes the job with the same number.
#
# One identifier is chosen and written to every carrier: the register entry,
# its heading, the anchor in /use-policy/, every redirect row for the withdrawn
# note, and the evolution log. The number is the next free one for that date,
# so a date that already has entries is safe. Nobody numbers anything by hand.
set -euo pipefail
ARG="${1:?usage: scripts/stamp-withdrawal.sh YYYY-MM-DD | --check}"
cd "$(dirname "$0")/.."
python3 - "$ARG" <<'PY'
import sys, re, json, datetime, pathlib

ARG = sys.argv[1]
WORK = "The Real Bot Hasn't Been Built Yet"           # as it appears in the entry heading
SLUG = "/field-notes/the-real-bot-hasnt-been-built-yet"  # start of every redirect source
REGISTER = pathlib.Path("data/corrections.toml")
POLICY = pathlib.Path("content/use-policy.md")
REDIRECTS = pathlib.Path("infra/cloudfront/redirects.json")
LOG = pathlib.Path("PROJECT_EVOLUTION_LOG.md")
ID_PLACEHOLDER, ANCHOR_PLACEHOLDER, DATE_PLACEHOLDER = "C-YYYYMMDD-01", "c-yyyymmdd-01", "[DEPLOY DATE]"
LOGGED_PLACEHOLDER = 'logged = "YYYY-MM-DD"'

def die(msg):
    sys.exit("stamp-withdrawal: " + msg)

def records(text):
    return re.split(r"(?m)^\[\[correction\]\]\s*$", text)[1:]

def withdrawal_record(text):
    hits = [r for r in records(text) if re.search(r'(?m)^heading = ".*' + re.escape(WORK), r)]
    if len(hits) != 1:
        die(f"expected one register entry whose heading names the withdrawn note, found {len(hits)}")
    m = re.search(r'(?m)^id = "([^"]+)"', hits[0])
    if not m:
        die("the withdrawal entry has no id")
    return m.group(1), hits[0]

def state():
    """What each carrier currently says. None means still a placeholder."""
    reg = REGISTER.read_text(encoding="utf-8")
    rid, rec = withdrawal_record(reg)
    out = {"register id": None if rid == ID_PLACEHOLDER else rid}
    heading = re.search(r'(?m)^heading = "([^"]*)"', rec).group(1)
    hm = re.match(r"(C-\d{8}-\d{2}|" + re.escape(ID_PLACEHOLDER) + ")", heading)
    out["register heading"] = None if (hm and hm.group(1) == ID_PLACEHOLDER) else (hm.group(1) if hm else "?")
    out["heading date"] = None if DATE_PLACEHOLDER in heading else "set"
    out["logged"] = None if LOGGED_PLACEHOLDER in rec else re.search(r'(?m)^logged = "([^"]+)"', rec).group(1)
    pol = POLICY.read_text(encoding="utf-8")
    pm = re.search(r"\(/corrections/#(c-[0-9a-z]+-\d{2})\)", pol)
    if not pm:
        die(f"{POLICY} has no link to a corrections anchor")
    out["use-policy anchor"] = None if pm.group(1) == ANCHOR_PLACEHOLDER else pm.group(1)
    rows = [r for r in json.loads(REDIRECTS.read_text(encoding="utf-8")).get("redirects", []) if str(r.get("from", "")).startswith(SLUG)]
    if len(rows) != 5:
        die(f"{REDIRECTS} should have five rows for the withdrawn note, found {len(rows)}")
    targets = sorted({r["to"] for r in rows})
    if len(targets) != 1 or not targets[0].startswith("/corrections/#"):
        die(f"the five redirect rows do not share one corrections anchor: {targets}")
    anchor = targets[0].split("#", 1)[1]
    out["redirect anchor"] = None if anchor == ANCHOR_PLACEHOLDER else anchor
    return out

def verdict(s):
    """('unstamped' | 'stamped' | 'partial' | 'conflict', id or None, detail)"""
    ids = {k: v for k, v in s.items() if k in ("register id", "register heading")}
    anchors = {k: v for k, v in s.items() if k in ("use-policy anchor", "redirect anchor")}
    values = {v for v in ids.values() if v} | {v.upper() for v in anchors.values() if v}
    if len(values) > 1:
        return "conflict", None, "; ".join(f"{k} = {v}" for k, v in s.items() if v and k not in ("heading date", "logged"))
    if not values:
        if s["heading date"] or s["logged"]:
            return "conflict", None, "a date is set but no identifier is"
        return "unstamped", None, ""
    ident = values.pop()
    missing = [k for k, v in s.items() if v is None]
    if s["logged"] and s["logged"].replace("-", "") != ident[2:10]:
        return "conflict", None, f"logged is {s['logged']} but the identifier is {ident}"
    return ("partial" if missing else "stamped"), ident, ", ".join(missing)

s = state()
kind, ident, detail = verdict(s)

if ARG == "--check":
    if kind == "unstamped":
        print("unstamped: every carrier still holds its placeholder")
    elif kind == "stamped":
        print(f"stamped: every carrier says {ident}")
    else:
        die(f"{kind}: {detail}")
    sys.exit(0)

if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", ARG):
    die("the date must be YYYY-MM-DD")
try:
    d = datetime.date.fromisoformat(ARG)
except ValueError:
    die(f"{ARG} is not a real date")

if kind == "conflict":
    die("the carriers disagree, so nothing was changed. " + detail)
if kind in ("stamped", "partial") and ident[2:10] != f"{d:%Y%m%d}":
    die(f"already stamped as {ident}; that date is {ident[2:6]}-{ident[6:8]}-{ident[8:10]}, not {ARG}. Nothing was changed.")
if kind == "stamped":
    print(f"already stamped as {ident}; nothing to do")
    sys.exit(0)
if kind == "unstamped":
    taken = [int(n) for n in re.findall(rf'(?m)^id = "C-{d:%Y%m%d}-(\d{{2}})"', REGISTER.read_text(encoding="utf-8"))]
    number = max(taken, default=0) + 1
    if number > 99:
        die("no free number left for that date")
    ident = f"C-{d:%Y%m%d}-{number:02d}"

human = f"{d.day} {d:%B %Y}"
for p in (REGISTER, POLICY, REDIRECTS, LOG):
    t = p.read_text(encoding="utf-8")
    n = (t.replace(ID_PLACEHOLDER, ident).replace(ANCHOR_PLACEHOLDER, ident.lower())
          .replace(DATE_PLACEHOLDER, human).replace(LOGGED_PLACEHOLDER, f'logged = "{d.isoformat()}"'))
    if n != t:
        p.write_text(n, encoding="utf-8")
        print("stamped", p)

after_kind, after_ident, after_detail = verdict(state())
if after_kind != "stamped" or after_ident != ident:
    die(f"after stamping the carriers are {after_kind}: {after_detail}")
left = [str(p) for p in (REGISTER, POLICY, REDIRECTS, LOG)
        if any(k in p.read_text(encoding="utf-8") for k in (ID_PLACEHOLDER, ANCHOR_PLACEHOLDER, DATE_PLACEHOLDER))]
if left:
    die("placeholders remain in: " + ", ".join(left))
print(f"{ident}, withdrawn {human}: register entry, heading, use-policy anchor and five redirect rows all agree")
PY
