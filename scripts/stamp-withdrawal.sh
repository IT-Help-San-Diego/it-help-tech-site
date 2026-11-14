#!/usr/bin/env bash
# Stamp a withdrawal with the date its record goes live.
#
# A corrections entry may not state an event before it happens, so a
# withdrawal's identifier and date stay placeholders until the day of the
# deploy. This script is the only thing that fills them in.
#
# Every withdrawal on the site has one row in WITHDRAWALS below, and every
# check runs for all of them. Only one may be waiting for its date at a time,
# because the placeholders are the same text for each.
#
#   scripts/stamp-withdrawal.sh 2026-11-20
#       Stamp every carrier of the withdrawal that is waiting. The date must be
#       today's date in the site's time
#       zone (America/Los_Angeles), because it is the day the withdrawal goes
#       live. STAMP_ALLOW_OTHER_DATE=1 lifts that for tests.
#   scripts/stamp-withdrawal.sh --unstamp [C-YYYYMMDD-NN]
#       Put the newest withdrawal's carriers back to their placeholders. Use
#       this when a stamped change did not ship on its date, then stamp again
#       on the day it does. Only the newest withdrawal, the last row of the
#       table, can be undone; an identifier, if given, must be its own. Never
#       undo one whose entry is on the published page: --check refuses a tree
#       whose identifier differs from the published one.
#   scripts/stamp-withdrawal.sh --check [--live-page <file>] [--require-publisher]
#       Change nothing. For each withdrawal, fail unless every carrier is
#       unstamped, or every carrier names the same entry and no other entry
#       shares its identifier.
#       --live-page takes a copy of the corrections page as it is published
#       now. If the entry is not on it yet, this deploy would publish it for
#       the first time, and its date must be today. If the copy is missing
#       or is not a corrections page, the rule is skipped with a warning: a
#       deploy is never blocked because the site could not be read.
#       --require-publisher fails a stamped tree that lacks the script that
#       publishes the redirects.
#   scripts/stamp-withdrawal.sh --check-built <dir>
#       Change nothing. Read a finished build: for each withdrawal the
#       corrections page must hold exactly one entry under the stamped anchor,
#       that entry must carry its heading, and the withdrawn addresses must be
#       gone from the build. Then every row of the redirect table, whether or
#       not it belongs to a withdrawal: the address it redirects must not be
#       built, and its target page and anchor must exist, the anchor once.
#       No placeholder may appear in any built page.
#   scripts/stamp-withdrawal.sh --check-live
#       Change nothing. Ask the live site: each withdrawn address must answer
#       301 to its stamped anchor, and the live corrections page must hold
#       exactly one entry under it. Every other row of the redirect table must
#       answer 301 to its target as well.
#
# Order on the day, in one sitting: merge origin/main into the branch; stamp;
# commit and push; wait for the checks on that stamped commit; merge; watch the
# deploy to its last step. A green check on an unstamped commit says nothing
# about the stamp. After stamping and before pushing, run
#   scripts/stamp-withdrawal.sh --check --require-publisher
#
# If the deploy does not finish that day, merge nothing else, and look at the
# published corrections page:
#   - the entry is NOT on it: it was never published. Unstamp, and stamp again
#     on the day it does ship.
#   - the entry IS on it: it was published on its date. Do not unstamp. Fix
#     whatever stopped the deploy and run the deploy again as stamped.
# STAMP_ALREADY_PUBLISHED=<identifier> (the repository variable of the same
# name, in the deploy and in the pull-request check) tells --check that an entry
# was published before although the page no longer shows it, for example after
# an older deploy was re-run. It vouches only for the entries it names; name
# several with spaces or commas between them. Set it for the repair, then clear
# it.
#
# A withdrawal's carriers are: its register entry (identifier, heading, logged
# date), its redirect rows, its entry in the evolution log and, for the Real
# Bot note, the link in /use-policy/. One identifier is chosen, the next free
# number for the date, and written to all of them. Nobody numbers anything by hand. The edge function file that is
# generated from the redirect rows is rebuilt after every stamp and unstamp,
# and --check fails if the committed copy does not match the rows.
set -euo pipefail
unset CDPATH
export STAMP_CALLER_DIR="$PWD"
cd "$(dirname "$0")/.."
exec python3 - "$@" <<'PY'
import datetime, html as htmllib, http.client, json, os, pathlib, re, sys, tempfile, time
import urllib.error, urllib.parse, urllib.request
from html.parser import HTMLParser

REGISTER = "data/corrections.toml"
POLICY = "content/use-policy.md"
REDIRECTS = "infra/cloudfront/redirects.json"
LOG = "PROJECT_EVOLUTION_LOG.md"
CARRIERS = (REGISTER, POLICY, REDIRECTS, LOG)


def _forms(path):
    """The three addresses one built page answered at."""
    return (path + "/", path, path + "/index.html")


_REAL_BOT = "/field-notes/the-real-bot-hasnt-been-built-yet"
_BUG_BOUNTY = "/field-notes/bug-bounty-programs-are-a-corporate-controlled-casino"
_BUG_BOUNTY_ALIAS = "/blog/bug-bounty-programs-are-a-corporate-controlled-casino"

# One row per withdrawal, oldest first. To add one: give it a record in the
# register, rows in the redirect table and an entry in the evolution log, all
# with the placeholders below, and a row here.
#   work    the `work` field of its register record
#   title   what its heading says between the identifier and the date
#   slugs   a redirect row belongs to it when its `from` starts with one of these
#   froms   exactly the rows it must have
#   policy  True if /use-policy/ links to its entry with the words "withdrawn on"
#   log     the words that follow the date in its heading in the evolution log
WITHDRAWALS = (
    {"work": "The Real Bot Hasn't Been Built Yet",
     "title": "The Real Bot Hasn't Been Built Yet",
     "slugs": (_REAL_BOT,),
     "froms": _forms(_REAL_BOT) + (_REAL_BOT + ".pdf", _REAL_BOT + ".bib"),
     "policy": True,
     "log": "The Real Bot field note withdrawn"},
    {"work": "Bug-Bounty Programs Are a Corporate-Controlled Casino",
     "title": "A field note on bug bounties and hosted-storefront security",
     "slugs": (_BUG_BOUNTY, _BUG_BOUNTY_ALIAS),
     "froms": _forms(_BUG_BOUNTY) + _forms(_BUG_BOUNTY_ALIAS),
     "policy": False,
     "log": "The bug-bounty field note's withdrawal recorded"},
)
assert sum(1 for w in WITHDRAWALS if w["policy"]) <= 1, "only one withdrawal may have a /use-policy/ link"
PH_ID, PH_ANCHOR, PH_ISO, PH_DATE = "C-YYYYMMDD-01", "c-yyyymmdd-01", "YYYY-MM-DD", "[DEPLOY DATE]"
PH_DATE_RE = re.compile(r"\[DEPLOY\s+DATE\]")
ID_RE = re.compile(r"C-\d{8}-\d{2}")
ANCHOR_RE = re.compile(r"c-\d{8}-\d{2}")
ZONE = "America/Los_Angeles"
PUBLISHER = "infra/cloudfront/deploy-viewer-request.sh"
BUILDER = "infra/cloudfront/build-viewer-request.mjs"
GENERATED = "infra/cloudfront/viewer-request.generated.js"
LIVE_BASE = os.environ.get("STAMP_LIVE_BASE", "https://www.it-help.tech").rstrip("/")
USAGE = ("usage: scripts/stamp-withdrawal.sh YYYY-MM-DD | --unstamp [C-YYYYMMDD-NN] | "
         "--check [--live-page <file>] [--require-publisher] | --check-built <dir> | --check-live")


class Problem(Exception):
    pass


def die(msg):
    sys.exit("stamp-withdrawal: " + msg)


def today():
    from zoneinfo import ZoneInfo
    return datetime.datetime.now(ZoneInfo(ZONE)).date()


def human(d):
    return f"{d.day} {d:%B %Y}"


def id_date(ident):
    try:
        return datetime.date(int(ident[2:6]), int(ident[6:8]), int(ident[8:10]))
    except ValueError:
        raise Problem(f"{ident} does not contain a real date")


def read_carriers():
    texts = {}
    for name in CARRIERS:
        if os.path.islink(name):
            raise Problem(f"{name} is a symbolic link; the carriers must be ordinary files")
        try:
            with open(name, encoding="utf-8", newline="") as f:
                texts[name] = f.read()
        except OSError as e:
            raise Problem(f"cannot read {name}: {e.strerror}")
    return texts


def all_ids(register_text):
    """Every entry's identifier, upper-cased, read as TOML so no valid spelling is missed."""
    try:
        import tomllib
    except ImportError:
        raise Problem("this script needs Python 3.11 or later (it reads the register with tomllib)")
    try:
        doc = tomllib.loads(register_text)
    except tomllib.TOMLDecodeError as e:
        raise Problem(f"{REGISTER} is not valid TOML: {e}")
    ids = []
    if not isinstance(doc.get("correction", []), list):
        raise Problem(f"{REGISTER}: `correction` must be a list of [[correction]] records")
    for n, r in enumerate(doc.get("correction", []), 1):
        if not isinstance(r, dict) or not str(r.get("id", "")).strip():
            raise Problem(f"entry number {n} in {REGISTER} has no id")
        ids.append(str(r["id"]).upper())
    return ids


def redirect_rows(texts):
    """The rows of the redirect table, or a Problem that says what is wrong with the file."""
    try:
        doc = json.loads(texts[REDIRECTS])
    except ValueError as e:
        raise Problem(f"{REDIRECTS} is not valid JSON: {e}")
    rows = doc.get("redirects", []) if isinstance(doc, dict) else None
    if not isinstance(rows, list) or not all(isinstance(r, dict) for r in rows):
        raise Problem(f"{REDIRECTS} must be an object whose `redirects` is a list of objects, one per row")
    return rows


def log_words(w):
    """A pattern for the words of this withdrawal's log heading; a typographic apostrophe matches a plain one."""
    return re.escape(w["log"]).replace("'", "['\u2019]")


def split_records(register_text):
    return re.split(r"(?m)^\[\[correction\]\][ \t]*(?:#[^\r\n]*)?\r?$", register_text)[1:]


def field(record, name):
    m = re.search(r"(?m)^[ \t]*" + name + r"""[ \t]*=[ \t]*"([^"\r\n]*)\"""", record)
    return m.group(1) if m else None


def my_record(register_text, w):
    mine = [r for r in split_records(register_text) if field(r, "work") == w["work"] and field(r, "kind") == "withdrawal"]
    if len(mine) != 1:
        raise Problem(f'{REGISTER} should have one withdrawal entry with work = "{w["work"]}", found {len(mine)}')
    return mine[0]


def inspect(texts, w):
    """Read what each carrier of one withdrawal says. A value of None means: still a placeholder."""
    rec = my_record(texts[REGISTER], w)
    rid, heading, logged, status = (field(rec, k) for k in ("id", "heading", "logged", "status"))
    if rid is None or heading is None or logged is None:
        raise Problem(f"the withdrawal entry for {w['work']!r} needs id, heading and logged")
    hm = re.fullmatch(r"(\S+) · (.+) · withdrawn (.+)", heading)
    if not hm:
        raise Problem(f"the withdrawal entry's heading is not '<id> · <title> · withdrawn <date>': {heading!r}")
    if hm.group(2) != w["title"]:
        raise Problem(f"the withdrawal entry's heading names {hm.group(2)!r}, not the withdrawn note ({w['title']!r})")

    def ph(value, placeholder):
        return None if value == placeholder else value

    s = {
        "register id": ph(rid, PH_ID),
        "heading id": ph(hm.group(1), PH_ID),
        "heading date": None if PH_DATE_RE.fullmatch(hm.group(3)) else hm.group(3),
        "logged": ph(logged, PH_ISO),
    }

    if w["policy"]:
        links = re.findall(r"\[withdrawn\s+on\s+((?:\[DEPLOY\s+DATE\]|[^\[\]])+)\]\(\s*/corrections/#([^)\s]+)\s*\)", texts[POLICY])
        if len(links) != 1:
            raise Problem(f"{POLICY} should have one 'withdrawn on' link to a corrections anchor, found {len(links)}")
        policy_date, policy_anchor = links[0]
        s["use-policy anchor"] = ph(policy_anchor, PH_ANCHOR)
        s["use-policy date"] = None if PH_DATE_RE.fullmatch(policy_date.strip()) else " ".join(policy_date.split())

    rows = [r for r in redirect_rows(texts) if str(r.get("from", "")).startswith(w["slugs"])]
    froms = sorted(str(r.get("from")) for r in rows)
    if froms != sorted(w["froms"]):
        raise Problem(f"{REDIRECTS} should have exactly {len(w['froms'])} rows for the withdrawn note {w['work']!r}, "
                      f"{sorted(w['froms'])}; found {froms}")
    if any(r.get("status") != 301 for r in rows):
        raise Problem(f"every redirect row for the withdrawn note {w['work']!r} must have status 301")
    targets = sorted({str(r.get("to")) for r in rows})
    if len(targets) != 1 or not targets[0].startswith("/corrections/#"):
        raise Problem(f"the redirect rows for {w['work']!r} do not share one corrections anchor: {targets}")
    s["redirect anchor"] = ph(targets[0].split("#", 1)[1], PH_ANCHOR)

    heads = list(re.finditer(r"(?m)^### (\[DEPLOY\s+DATE\]|\d{4}-\d{2}-\d{2}): " + log_words(w), texts[LOG]))
    le = []
    if len(heads) == 1:
        following = re.compile(r"(?m)^### ").search(texts[LOG], heads[0].end())
        section = texts[LOG][heads[0].start():following.start() if following else len(texts[LOG])]
        le = re.findall(r"entry (C-[0-9A-Z]{8}-\d{2}), the withdrawal", section)
    if len(heads) != 1 or len(le) != 1:
        raise Problem(f"{LOG} should have one heading '<date>: {w['log']}' and, under it, one 'entry <id>, the withdrawal' "
                      f"line; found {len(heads)} and {len(le)}")
    s["log heading"] = None if PH_DATE_RE.fullmatch(heads[0].group(1)) else heads[0].group(1)
    s["log entry id"] = ph(le[0], PH_ID)
    s["_status"] = status
    return s


ID_KEYS = ("register id", "heading id", "log entry id")
ANCHOR_KEYS = ("use-policy anchor", "redirect anchor")


def verdict(texts, w, allow_own_repeat=False):
    """One withdrawal: ('unstamped' | 'stamped' | 'partial', identifier or None, missing). Raises Problem on any
    disagreement. allow_own_repeat lets --unstamp run when the only fault is another entry sharing its identifier."""
    s = inspect(texts, w)
    if s["_status"] != "published":
        raise Problem(f'the withdrawal entry for {w["work"]!r} must have status = "published", not {s["_status"]!r}')
    ids = all_ids(texts[REGISTER])
    mine = (s["register id"] or "").upper()
    if mine and ids.count(mine) > 1 and not (allow_own_repeat and ids.count(mine) == 2):
        how = (f"If this withdrawal has not been published yet, run scripts/stamp-withdrawal.sh --unstamp {mine} and "
               f"stamp again: it takes the next free number. If it has been published, the other entry is the newer one "
               f"and needs its own number." if w is WITHDRAWALS[-1] else
               f"This withdrawal has shipped and keeps its identifier: the other entry is the newer one and needs its "
               f"own number.")
        raise Problem(f"{REGISTER} has more than one entry with the same identifier: {mine}, which is the withdrawal of "
                      f"{w['work']!r}. {how} If more than one other entry shares it, renumber those first.")
    id_keys = [k for k in ID_KEYS if k in s]
    anchor_keys = [k for k in ANCHOR_KEYS if k in s]
    for k in id_keys:
        if s[k] is not None and not ID_RE.fullmatch(s[k]):
            raise Problem(f"{k} is {s[k]!r}, which is not an identifier in the form C-YYYYMMDD-NN")
    for k in anchor_keys:
        if s[k] is not None and not ANCHOR_RE.fullmatch(s[k]):
            raise Problem(f"{k} is {s[k]!r}, which is not an anchor in the form c-yyyymmdd-nn, lower case")
    value_keys = [k for k in s if not k.startswith("_")]
    show = "; ".join(f"{k} = {s[k]}" for k in value_keys if s[k])
    named = {s[k] for k in id_keys if s[k]} | {s[k].upper() for k in anchor_keys if s[k]}
    if len(named) > 1:
        raise Problem("the carriers disagree. " + show)
    if not named:
        if show:
            raise Problem("a date is set but no identifier is. " + show)
        return "unstamped", None, value_keys
    ident = named.pop()
    d = id_date(ident)
    # The identifier must belong to the withdrawal alone.
    if ids.count(ident) != (1 if s["register id"] else 0) and not (allow_own_repeat and ids.count(ident) == 2 and s["register id"]):
        holders = ", ".join(k for k in id_keys + anchor_keys if s[k] and s[k].upper() == ident)
        raise Problem(f"{ident} is already the identifier of another entry in {REGISTER}. It was found in: {holders}. "
                      f"Put that carrier back to its placeholder and stamp again; the script picks a free number.")
    wanted = {"heading date": human(d), "use-policy date": human(d), "logged": d.isoformat(), "log heading": d.isoformat()}
    for k, want in wanted.items():
        if k in s and s[k] is not None and s[k] != want:
            raise Problem(f"{k} is {s[k]!r}, but the identifier {ident} means {want!r}")
    missing = [k for k in value_keys if s[k] is None]
    return ("partial" if missing else "stamped"), ident, missing


def verdicts(texts):
    """One verdict per withdrawal, in the order of WITHDRAWALS, and then the rules that span them."""
    ids = all_ids(texts[REGISTER])
    one_at_a_time = ("The placeholders are the same text for each, so only one withdrawal may wait at a time: ship the "
                     "one that is waiting before the next is added. A new withdrawal also needs its own row in "
                     "WITHDRAWALS (see the comment above the table).")
    if ids.count(PH_ID) > 1:
        import tomllib
        works = [repr(str(r.get("work", "an entry with no work field"))) for r in tomllib.loads(texts[REGISTER]).get("correction", [])
                 if isinstance(r, dict) and str(r.get("id", "")).upper() == PH_ID]
        raise Problem("more than one withdrawal is waiting for its date: " + "; ".join(works) + ". " + one_at_a_time)
    out = [verdict(texts, w) for w in WITHDRAWALS]
    own = {ident for kind, ident, missing in out if ident}
    repeated = sorted({i for i in ids if ids.count(i) > 1} - own)   # a withdrawal's own repeat was raised above
    if repeated:
        raise Problem(f"{REGISTER} has more than one entry with the same identifier: {', '.join(repeated)}. "
                      f"That is not a withdrawal; give one of those entries its own number.")
    waiting = [w["work"] for w, (kind, ident, missing) in zip(WITHDRAWALS, out) if kind != "stamped"]
    if len(waiting) > 1:
        halves = [f"{w['work']!r} is only partly stamped as {ident} (still placeholders: {', '.join(missing)})"
                  for w, (kind, ident, missing) in zip(WITHDRAWALS, out) if kind == "partial"]
        if halves:
            raise Problem("; ".join(halves) + ". Another withdrawal is waiting for its date as well, so the stamp command "
                          "cannot finish this one. Put its carriers back as they were published (from git), then check again.")
        raise Problem("more than one withdrawal is waiting for its date: " + "; ".join(waiting) + ". " + one_at_a_time)
    if not waiting:
        for name in CARRIERS:
            t = texts[name]
            if PH_ID in t or PH_ANCHOR in t or PH_DATE_RE.search(t):
                lines = [str(i) for i, line in enumerate(t.splitlines(), 1)
                         if PH_ID in line or PH_ANCHOR in line or PH_DATE_RE.search(line)]
                raise Problem(f"a placeholder is still present in {name} (line {', '.join(lines[:6]) or 'spanning two lines'}), "
                              f"and no withdrawal in WITHDRAWALS is waiting for its date. If it belongs to a new "
                              f"withdrawal, add that withdrawal's row to the table (see the comment above it). If it is "
                              f"only text about placeholders, reword it: these files may not contain one.")
    return out


def generated_is_current(texts):
    """True if the committed edge function file carries exactly the redirect rows (or there is no such file)."""
    if not os.path.isfile(GENERATED):
        return True
    try:
        with open(GENERATED, encoding="utf-8") as f:
            generated = f.read()
    except OSError:
        return False
    rows = redirect_rows(texts)
    pairs = [json.dumps(str(r.get("from")), ensure_ascii=False) + ": " + json.dumps(str(r.get("to")), ensure_ascii=False)
             for r in rows]
    mapped = len(re.findall(r"""(?m)^\s*"/[^"\n]*":\s*"/[^"\n]*",?\s*$""", generated))
    return all(p in generated for p in pairs) and mapped == len(pairs)


def rebuild_generated():
    """Rebuild the edge function file from the redirect rows, if this tree has the builder."""
    if not os.path.isfile(BUILDER):
        return
    import shutil, subprocess
    node = shutil.which("node")
    if not node:
        print(f"note: node is not installed here, so {GENERATED} was not rebuilt. Run: node {BUILDER}")
        return
    r = subprocess.run([node, BUILDER], capture_output=True, text=True)
    if r.returncode != 0:
        die(f"the carriers were written, but rebuilding {GENERATED} failed: {(r.stderr or r.stdout).strip()[-300:]}. "
            f"Fix that and run: node {BUILDER}")
    print("rebuilt", GENERATED)


def unknown_placeholders(texts):
    """Placeholders in the carriers beyond the ones this script fills in. Returns 'file line N: text' strings."""
    expected = {name: {"id": 0, "anchor": 0, "date": 0, "logged": 0} for name in CARRIERS}
    for w in WITHDRAWALS:
        s = inspect(texts, w)
        n = lambda key: 1 if key in s and s[key] is None else 0
        expected[REGISTER]["id"] += n("register id") + n("heading id")
        expected[REGISTER]["date"] += n("heading date")
        expected[REGISTER]["logged"] += n("logged")
        expected[POLICY]["anchor"] += n("use-policy anchor")
        expected[POLICY]["date"] += n("use-policy date")
        expected[REDIRECTS]["anchor"] += len(w["froms"]) * n("redirect anchor")
        expected[LOG]["id"] += n("log entry id")
        expected[LOG]["date"] += n("log heading")
    found = []
    for name in CARRIERS:
        t = texts[name]
        undated = f'logged = "{PH_ISO}"'
        actual = {"id": t.count(PH_ID), "anchor": t.count(PH_ANCHOR), "date": len(PH_DATE_RE.findall(t)),
                  "logged": t.count(undated) if name == REGISTER else 0}
        if any(actual[k] > expected[name][k] for k in actual):
            lines = [f"{name} line {i}: {line.strip()[:90]!r}" for i, line in enumerate(t.splitlines(), 1)
                     if PH_ID in line or PH_ANCHOR in line or "DEPLOY" in line or (name == REGISTER and undated in line)]
            found.append(f"{name} has {sum(actual.values())} placeholders where {sum(expected[name].values())} are expected "
                         f"({'; '.join(lines[:6])})")
    return found


def log_span(text, w):
    """(start, end) of this withdrawal's entry in the evolution log, heading included, or None."""
    m = re.search(r"(?m)^### (?:\[DEPLOY\s+DATE\]|\d{4}-\d{2}-\d{2}): " + log_words(w), text)
    if not m:
        return None
    following = re.compile(r"(?m)^### ").search(text, m.end())
    return m.start(), (following.start() if following else len(text))


def own_rows(text, w, change):
    """Apply `change` to the lines of the redirect table that hold this withdrawal's rows, and to no others."""
    return "".join(change(line) if any(f'"{slug}' in line for slug in w["slugs"]) else line
                   for line in text.splitlines(keepends=True))


def apply_stamp(texts, ident, w):
    """Fill in this withdrawal's placeholders: its record, its rows, its log entry and, if it has one, its
    /use-policy/ link. A placeholder anywhere else is left alone, and the checks that follow refuse it."""
    d = id_date(ident)
    out = {}
    reg = texts[REGISTER]
    rec = my_record(reg, w)
    new = (PH_DATE_RE.sub(human(d), rec.replace(PH_ID, ident))
           .replace(f'logged = "{PH_ISO}"', f'logged = "{d.isoformat()}"'))
    out[REGISTER] = reg.replace(rec, new, 1)
    out[POLICY] = texts[POLICY]
    if w["policy"]:
        out[POLICY] = PH_DATE_RE.sub(human(d), texts[POLICY].replace(PH_ANCHOR, ident.lower()))
    out[REDIRECTS] = own_rows(texts[REDIRECTS], w, lambda line: line.replace(PH_ANCHOR, ident.lower()))
    log = texts[LOG]
    span = log_span(log, w)
    if span:
        section = re.sub(r"\A### \[DEPLOY\s+DATE\]", lambda m: "### " + d.isoformat(), log[span[0]:span[1]])
        section = PH_DATE_RE.sub(human(d), section.replace(PH_ID, ident))
        log = log[:span[0]] + section + log[span[1]:]
    out[LOG] = log
    return out


def apply_unstamp(texts, ident, w):
    d = id_date(ident)
    out = {}
    reg = texts[REGISTER]
    rec = my_record(reg, w)
    # Only the two fields the stamp fills in. An identifier cited in the entry text was written by
    # hand; it is left where it is, and --unstamp then refuses and says so.
    new = re.sub(r'(?m)^([ \t]*id[ \t]*=[ \t]*")' + re.escape(ident) + r'(")', lambda m: m.group(1) + PH_ID + m.group(2), rec)
    new = re.sub(r'(?m)^([ \t]*heading[ \t]*=[ \t]*")' + re.escape(ident) + r'( · )', lambda m: m.group(1) + PH_ID + m.group(2), new)
    new = (new.replace(f'withdrawn {human(d)}"', f'withdrawn {PH_DATE}"')
              .replace(f'logged = "{d.isoformat()}"', f'logged = "{PH_ISO}"'))
    out[REGISTER] = reg.replace(rec, new, 1)
    out[POLICY] = texts[POLICY]
    if w["policy"]:
        out[POLICY] = re.sub(r"\[withdrawn\s+on\s+[^\[\]]+\]\(\s*/corrections/#" + re.escape(ident.lower()) + r"\s*\)",
                             lambda m: f"[withdrawn on {PH_DATE}](/corrections/#{PH_ANCHOR})", texts[POLICY])
    out[REDIRECTS] = own_rows(texts[REDIRECTS], w, lambda line: line.replace("/corrections/#" + ident.lower(),
                                                                             "/corrections/#" + PH_ANCHOR))
    log = texts[LOG]
    span = log_span(log, w)
    if span:
        section = re.sub(r"\A### " + re.escape(d.isoformat()), lambda m: "### " + PH_DATE, log[span[0]:span[1]])
        section = section.replace(f"entry {ident}, the withdrawal", f"entry {PH_ID}, the withdrawal")
        log = log[:span[0]] + section + log[span[1]:]
    out[LOG] = log
    return out


def write_all(old, new):
    changed = [n for n in CARRIERS if new[n] != old[n]]
    done = []
    for name in changed:
        tmp = None
        try:
            fd, tmp = tempfile.mkstemp(dir=os.path.dirname(name) or ".", prefix=".stamp-", suffix=".tmp")
            with os.fdopen(fd, "w", encoding="utf-8", newline="") as f:
                f.write(new[name])
            os.chmod(tmp, os.stat(name).st_mode & 0o7777)
            os.replace(tmp, name)
        except OSError as e:
            if tmp and os.path.exists(tmp):
                os.unlink(tmp)
            die(f"could not write {name}: {e.strerror}. Already written: {', '.join(done) or 'nothing'}. "
                f"Fix the cause and run the same command again; it finishes with the same identifier.")
        done.append(name)
        print("wrote", name)


def section_heading(page_html, anchor):
    m = re.search(r"""<section\b[^>]*\bid=["']?""" + re.escape(anchor) + r"""["']?[\s>].*?<h2\b[^>]*>(.*?)</h2>""",
                  page_html, flags=re.S)
    return htmllib.unescape(re.sub(r"<[^>]+>", "", m.group(1))).strip() if m else ""


class _Ids(HTMLParser):
    """Collects every id attribute in a page. A real parser, so quoting and attribute order do not matter."""
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.ids = []

    def handle_starttag(self, tag, attrs):
        self.ids += [v for k, v in attrs if k == "id" and v is not None]


def element_ids(page_html):
    p = _Ids()
    p.feed(page_html)
    p.close()
    return p.ids


# Addresses the deploy publishes from outside the Zola output: deploy.yml uploads build/llms-full.txt on
# its own, after the build has been checked. No build holds them, but the site serves them.
PUBLISHED_OUTSIDE_BUILD = ("/llms-full.txt",)


def edge_key(address):
    """The object the site serves for a site-relative address, as a path inside the build, or None if no
    object can match. This follows infra/cloudfront/viewer-request-template.js step 3 exactly: a trailing
    slash gets index.html; an address with no dot anywhere gets /index.html; anything else is asked for as
    it is. The bucket matches a key byte for byte, so an empty or dotted segment matches nothing."""
    uri = address.split("#", 1)[0].split("?", 1)[0]
    if uri.endswith("/"):
        uri += "index.html"
    elif "." not in uri and len(uri) > 1:
        uri += "/index.html"
    parts = uri[1:].split("/")
    if any(part in ("", ".", "..") for part in parts):
        return None
    return "/".join(parts)


def rows_against_build(root, texts):
    """Every row of the redirect table, read against a finished build. Returns (rows checked, problems)."""
    problems = []
    rows = redirect_rows(texts)
    # Exact names, collected once: a case-insensitive disk must not answer differently from the bucket.
    built = {p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file()}

    def served(address):
        key = edge_key(address)
        return key if key is not None and key in built else None

    for r in rows:
        src, dst = str(r.get("from", "")), str(r.get("to", ""))
        row = f"{src} -> {dst}"
        path, _, fragment = dst.partition("#")
        if not src.startswith("/") or not dst.startswith("/") or "#" in src or "?" in src or "?" in dst:
            problems.append(f"{row}: both ends must be paths on this site, with no query string, and only the "
                            f"target may carry an anchor")
            continue
        if not (src + path).isascii() or any(c.isspace() for c in src + dst):
            problems.append(f"{row}: write the addresses as a browser sends them, percent-encoded, with no spaces")
            continue
        if PH_ANCHOR in row or PH_ID in row or PH_DATE_RE.search(row):
            problems.append(f"{row}: the row is still undated")
            continue
        if src in PUBLISHED_OUTSIDE_BUILD:
            problems.append(f"{row}: the address it redirects is published by the deploy itself; the redirect would cover it")
        elif served(src) is not None:
            problems.append(f"{row}: the address it redirects is still built ({served(src)}); the redirect would cover a live page")
        if path in PUBLISHED_OUTSIDE_BUILD:
            if fragment:
                problems.append(f"{row}: the target is not a page, so it has no anchor to point at")
            continue
        target = served(path)
        if target is None:
            problems.append(f"{row}: the site serves nothing at the target address")
            continue
        if fragment:
            if not target.endswith(".html"):
                problems.append(f"{row}: the target is not a page, so it has no anchor to point at")
                continue
            try:
                ids = element_ids((root / target).read_text(encoding="utf-8", errors="replace"))
            except Exception as e:      # a parser fault on odd markup must read like any other refusal
                problems.append(f"{row}: the target page {target} could not be read as HTML ({type(e).__name__})")
                continue
            n = ids.count(urllib.parse.unquote(fragment))
            if n != 1:
                problems.append(f"{row}: the target page has {n} elements with id {fragment!r}; it needs exactly one")
    return len(rows), problems


def is_withdrawal_heading(heading, ident, w):
    plain = heading.replace(chr(0x2019), "'")
    return w["title"] in plain and ident in plain


def page_withdrawals(page_html):
    """{anchor: heading} for every entry on a corrections page that is a withdrawal: headed
    '<ID> · <title> · withdrawn <date>' under the anchor of that identifier. A later entry that only names
    the same work (a reference correction, say) is not one. Not a corrections page: nothing."""
    found = {}
    if "correction-entry" not in page_html:      # unreadable, cut short, or an error page
        return found
    for m in re.finditer(r"""<section\b[^>]*\bid=["']?(c-\d{8}-\d{2})["']?[\s>]""", page_html, flags=re.I):
        heading = section_heading(page_html, m.group(1)).replace(chr(0x2019), "'")
        hm = re.fullmatch(r"(C-\d{8}-\d{2}) · .+ · withdrawn .+", heading)
        if hm and hm.group(1).lower() == m.group(1).lower():
            found[m.group(1).lower()] = heading
    return found


def section_ids(page_html, anchor):
    """Entries on a corrections page under this anchor, in any letter case."""
    return re.findall(r"""<section\b[^>]*\bid=["']?(""" + re.escape(anchor) + r""")["']?[\s>]""", page_html, flags=re.I)


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k):
        return None


def _get(url, tries=3):
    opener = urllib.request.build_opener(_NoRedirect)
    last = None
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"Cache-Control": "no-cache"})
            with opener.open(req, timeout=20) as r:
                return r.status, r.headers, r.read().decode("utf-8", errors="replace")
        except urllib.error.HTTPError as e:
            return e.code, e.headers, ""
        except (UnicodeError, ValueError) as e:
            raise Problem(f"{url} cannot be requested as written ({type(e).__name__}); write it percent-encoded")
        except (urllib.error.URLError, OSError, http.client.HTTPException) as e:
            last = e
            time.sleep(2 * (attempt + 1))
    raise Problem(f"could not reach {url}: {last}")


def check_live(ident, w):
    anchor = ident.lower()
    want = f"{LIVE_BASE}/corrections/#{anchor}"
    waits = [0] + [int(x) for x in os.environ.get("STAMP_LIVE_WAITS", "10 20 30 30").split()]
    for pause in waits:      # a published function can take a short while to reach every edge
        time.sleep(pause)
        bad = []
        for src in sorted(w["froms"]):
            status, headers, _ = _get(LIVE_BASE + src)
            location = headers.get("Location") if headers else None
            if status != 301 or location != want:
                bad.append(f"{src} answered {status}" + (f" to {location}" if location else ""))
        if not bad:
            break
    if bad:
        raise Problem(f"the withdrawn addresses do not all redirect to {want}: " + "; ".join(bad) + ". "
                      f"Nothing is rolled back by this check. If the note's pages were deleted in this deploy, readers "
                      f"are getting errors at those addresses now: publish the redirects (see infra/cloudfront/ROLLBACK.md "
                      f"if present) or revert the withdrawal and deploy again.")
    status, _, body = _get(LIVE_BASE + "/corrections/")
    if status != 200:
        raise Problem(f"{LIVE_BASE}/corrections/ answered {status}")
    found = section_ids(body, anchor)
    if found != [anchor]:
        raise Problem(f"the live corrections page should have exactly one entry under #{anchor}; found {found}")
    heading = section_heading(body, anchor)
    if not is_withdrawal_heading(heading, ident, w):
        raise Problem(f"the entry under #{anchor} on the live page is headed {heading!r}; it should name {ident} and "
                      f"{w['title']!r}")


def check_built(directory, texts):
    """Returns [(identifier, heading)] for every withdrawal, in the order of WITHDRAWALS."""
    results = verdicts(texts)
    for w, (kind, ident, missing) in zip(WITHDRAWALS, results):
        if kind != "stamped":
            raise Problem(f"the carriers of the withdrawal of {w['work']!r} are {kind}; a built site can only be checked "
                          f"once every withdrawal is stamped")
    root = pathlib.Path(directory)
    page = root / "corrections" / "index.html"
    if not page.is_file():
        raise Problem(f"{page} does not exist")
    page_html = page.read_text(encoding="utf-8")
    entry_ids = re.findall(r"""<section\b[^>]*\bid=["']?(c-\d{8}-\d{2})["']?[\s>]""", page_html, flags=re.I)
    dup = sorted({i for i in entry_ids if entry_ids.count(i) > 1})
    if dup:
        raise Problem(f"the built corrections page has more than one entry under the same anchor: {', '.join(dup)}")
    done = []
    for w, (kind, ident, missing) in zip(WITHDRAWALS, results):
        anchor = ident.lower()
        found = re.findall(r"""\bid=["']?(""" + re.escape(anchor) + r""")["']?[\s>]""", page_html, flags=re.I)
        if found != [anchor]:
            raise Problem(f"the built corrections page should have exactly one element with id {anchor}; found {found}")
        heading = section_heading(page_html, anchor)
        if not is_withdrawal_heading(heading, ident, w):
            raise Problem(f"the entry under #{anchor} is headed {heading!r}; it should name {ident} and {w['title']!r}")
        still = []
        for src in sorted(w["froms"]):
            rel = src.lstrip("/")
            last = rel.rstrip("/").rsplit("/", 1)[-1]
            candidates = [root / rel] if "." in last else [root / rel.rstrip("/") / "index.html", root / (rel.rstrip("/") + ".html")]
            still += [str(c) for c in candidates if c.is_file()]
        if still:
            raise Problem(f"the withdrawn note {w['work']!r} is still in the build: " + ", ".join(sorted(set(still))))
        done.append((ident, heading))
    count, row_problems = rows_against_build(root, texts)
    if row_problems:
        raise Problem("the redirect table does not fit the build: " + " | ".join(row_problems))
    leftovers = []
    for p in sorted(root.rglob("*")):
        if p.is_file() and p.suffix.lower() in (".html", ".txt", ".xml", ".json"):
            t = p.read_text(encoding="utf-8", errors="replace")
            if PH_ID in t or PH_ANCHOR in t or PH_DATE_RE.search(t):
                leftovers.append(str(p))
    if leftovers:
        raise Problem("a placeholder appears in built files: " + ", ".join(leftovers[:8]))
    return done


def main(argv):
    if not argv:
        die(USAGE)
    try:
        texts = read_carriers()
        if argv[0] == "--check":
            opts, live_page, need_publisher = argv[1:], None, False
            while opts:
                if opts[0] == "--live-page" and len(opts) >= 2 and not opts[1].startswith("--"):
                    live_page, opts = opts[1], opts[2:]
                elif opts[0] == "--require-publisher":
                    need_publisher, opts = True, opts[1:]
                else:
                    die(USAGE)
            results = verdicts(texts)
            for w, (kind, ident, missing) in zip(WITHDRAWALS, results):
                if kind == "partial":
                    raise Problem(f"only part of the withdrawal of {w['work']!r} is stamped as {ident}; "
                                  f"still placeholders: {', '.join(missing)}")
            if not generated_is_current(texts):
                raise Problem(f"{GENERATED} does not match the rows in {REDIRECTS}. Run: node {BUILDER}, and commit the result.")
            live = None
            if live_page is not None:
                path = live_page if os.path.isabs(live_page) else os.path.join(os.environ.get("STAMP_CALLER_DIR", "."), live_page)
                try:
                    with open(path, encoding="utf-8", errors="replace") as f:
                        live = f.read()
                except OSError:
                    live = ""
            every_one_stamped = all(kind == "stamped" for kind, ident, missing in results)
            # An entry that readers can already see keeps its identifier for good: citations and the
            # redirects point at it. So for every withdrawal on the published page, this tree must carry
            # exactly that identifier, and no published withdrawal may be missing from this tree.
            on_page = page_withdrawals(live) if live else {}
            for w, (kind, ident, missing) in zip(WITHDRAWALS, results):
                there = sorted(a for a, heading in on_page.items() if f" · {w['title']} · withdrawn " in heading)
                if there and (kind != "stamped" or ident.lower() not in there):
                    raise Problem(f"the published corrections page already carries the withdrawal of {w['work']!r} as "
                                  f"{', '.join(a.upper() for a in there)}, but this tree has it "
                                  + (f"as {ident}" if kind == "stamped" else "unstamped") + ". A published identifier is "
                                  "never changed. Restore the stamp that was published (revert the change that removed or "
                                  "replaced it); do not stamp again.")
            stamped_here = {ident.lower() for kind, ident, missing in results if kind == "stamped"}
            strays = sorted(a.upper() for a in on_page if a not in stamped_here)
            if strays:
                raise Problem(f"the published corrections page carries the withdrawal {', '.join(strays)}, which no row of "
                              f"WITHDRAWALS in this tree is stamped as. A published withdrawal is never removed or "
                              f"renumbered: restore its row, its record and its stamp as they were published.")
            for w, (kind, ident, missing) in zip(WITHDRAWALS, results):
                if kind == "unstamped":
                    print(f"unstamped: every carrier of the withdrawal of {w['work']!r} still holds its placeholder")
                    continue
                if need_publisher:
                    try:
                        with open(".github/workflows/deploy.yml", encoding="utf-8") as f:
                            deploy = f.read()
                    except OSError:
                        deploy = ""
                    lacking = []
                    if not os.path.isfile(PUBLISHER):
                        lacking.append(f"{PUBLISHER} is not in this tree")
                    if "deploy-viewer-request.sh" not in deploy:
                        lacking.append("the deploy workflow has no step that publishes the redirects")
                    if "stamp-withdrawal.sh --check-live" not in deploy:
                        lacking.append("the deploy workflow has no step that checks the withdrawn addresses on the live site")
                    # While another withdrawal waits for its date the site does not build at all, so
                    # its placeholders cannot reach the publisher. Once nothing waits, none may remain.
                    if every_one_stamped and re.search(r"yyyymmdd|YYYY-MM-DD|\[DEPLOY DATE\]", texts[REDIRECTS]):
                        lacking.append(f"{REDIRECTS} still contains placeholder text, which makes the publisher skip its run")
                    if lacking:
                        raise Problem(f"the withdrawal of {w['work']!r} is stamped as {ident}, but: " + "; ".join(lacking) + ". "
                                      f"Deploying now would delete the note without redirecting its addresses.")
                if live is not None:
                    # Published means: the page has one entry under this anchor, headed as this withdrawal's
                    # identifier. The title is not compared, so a reworded heading keeps its identifier.
                    published = ident.lower() in on_page and len(section_ids(live, ident.lower())) == 1
                    vouched = ident in re.split(r"[\s,]+", os.environ.get("STAMP_ALREADY_PUBLISHED", "").strip().upper())
                    if published or vouched:
                        print(f"{ident} is already on the published corrections page" if published else
                              f"note: STAMP_ALREADY_PUBLISHED names {ident}; treating it as published before")
                    elif "correction-entry" not in live:
                        # Not a corrections page at all: unreadable, empty, or an error page. A deploy
                        # must never be blocked because the site could not be read, so say so and go on.
                        msg = (f"the published corrections page could not be read, so two rules were not applied to "
                               f"{ident}: that it is first published on its own date, and that a published identifier "
                               f"never changes")
                        print(("::warning::" if os.environ.get("GITHUB_ACTIONS") else "warning: ") + msg)
                    elif id_date(ident) != today():
                        raise Problem(f"{ident} is not on the published corrections page, and today in {ZONE} is "
                                      f"{today().isoformat()}, not {id_date(ident).isoformat()}. If it has never been "
                                      f"published, run scripts/stamp-withdrawal.sh --unstamp {ident} and stamp again with "
                                      f"today's date. If it WAS published and the page has since lost it (an older deploy "
                                      f"re-run, or a restore), do not re-date it: fix the page by deploying with "
                                      f"STAMP_ALREADY_PUBLISHED set, for that run, to every identifier the page has "
                                      f"lost (here at least {ident}; separate several with spaces).")
                    else:
                        print(f"{ident} is not published yet and is dated today")
                print(f"stamped: every carrier says {ident}, and no other entry shares it")
            return
        if argv[0] == "--check-live":
            if len(argv) != 1:
                die(USAGE)
            results = verdicts(texts)
            for w, (kind, ident, missing) in zip(WITHDRAWALS, results):
                if kind == "partial":
                    raise Problem(f"only part of the withdrawal of {w['work']!r} is stamped as {ident}; "
                                  f"still placeholders: {', '.join(missing)}")
            failed = []
            for w, (kind, ident, missing) in zip(WITHDRAWALS, results):
                if kind == "unstamped":
                    print(f"unstamped: the withdrawal of {w['work']!r} is not published yet, so there is nothing of it "
                          f"to check on the live site")
                    continue
                try:      # one withdrawal's fault must not hide the state of the next
                    check_live(ident, w)
                except Problem as e:
                    failed.append(f"[{ident}] {e}")
                    continue
                print(f"live site ok: the {len(w['froms'])} withdrawn addresses of {w['work']!r} answer 301 to "
                      f"{LIVE_BASE}/corrections/#{ident.lower()}, and the live corrections page has one entry under that anchor")
            covered = {src for w in WITHDRAWALS for src in w["froms"]}
            others = [r for r in redirect_rows(texts) if str(r.get("from", "")) not in covered]
            wrong, pending = [], others
            waits = [0] + [int(x) for x in os.environ.get("STAMP_LIVE_WAITS", "10 20 30 30").split()]
            for pause in (waits if others else []):     # a new row can take a short while to reach every edge
                time.sleep(pause)
                wrong, again = [], []
                for r in pending:
                    src, want = str(r.get("from", "")), LIVE_BASE + str(r.get("to", ""))
                    try:
                        status, headers, _ = _get(LIVE_BASE + src)
                    except Problem as e:
                        wrong.append(f"[{src}] {e}")
                        again.append(r)
                        continue
                    location = headers.get("Location") if headers else None
                    if status != 301 or location != want:
                        wrong.append(f"[{src}] answered {status}" + (f" to {location}" if location else
                                     " with no Location" if status == 301 else "") + f"; the table says 301 to {want}")
                        again.append(r)
                pending = again
                if not pending:
                    break
            if others and not wrong:
                print(f"live site ok: the {len(others)} redirect row{'s' if len(others) != 1 else ''} that belong"
                      f"{'' if len(others) != 1 else 's'} to no withdrawal answer{'' if len(others) != 1 else 's'} "
                      f"as the table says")
            failed += wrong
            if failed:
                raise Problem(" || ".join(failed))
            return
        if argv[0] == "--check-built":
            if len(argv) != 2:
                die(USAGE)
            built = argv[1] if os.path.isabs(argv[1]) else os.path.join(os.environ.get("STAMP_CALLER_DIR", "."), argv[1])
            for ident, heading in check_built(built, texts):
                print(f"built site ok: one entry under #{ident.lower()}, headed {heading!r}; its withdrawn addresses are gone")
            print(f"built site ok: each of the {len(redirect_rows(texts))} redirect rows points at an address the site "
                  f"serves, with its anchor present once, and none covers a page that is still built")
            print("built site ok: no placeholder in the built HTML, text, XML or JSON files")
            return
        if argv[0] == "--unstamp":
            if len(argv) > 2 or (len(argv) == 2 and not ID_RE.fullmatch(argv[1])):
                die(USAGE)
            # Only the newest withdrawal, the last row of the table, can still be unpublished: the
            # rows before it shipped before it was added. So only the newest can be undone.
            w = WITHDRAWALS[-1]
            if len(argv) == 2:
                holder = None
                for o in WITHDRAWALS:
                    s = inspect(texts, o)
                    if argv[1] in ({s[k] for k in ID_KEYS if s.get(k)} | {s[k].upper() for k in ANCHOR_KEYS if s.get(k)}):
                        holder = o
                if holder is None:
                    raise Problem(f"no withdrawal is stamped as {argv[1]}. Nothing was changed.")
                if holder is not w:
                    raise Problem(f"{argv[1]} is the withdrawal of {holder['work']!r}, which shipped before the newest "
                                  f"withdrawal was added. A published withdrawal is never undone. Nothing was changed.")
            kind, ident, missing = verdict(texts, w, allow_own_repeat=True)
            if kind == "unstamped":
                verdicts(texts)      # nothing to undo, but a faulty tree is still reported
                if not generated_is_current(texts):
                    raise Problem(f"{GENERATED} does not match the rows in {REDIRECTS}. Run: node {BUILDER}, and commit the result.")
                print("already unstamped; nothing to do")
                return
            others_waiting = [o["work"] for o in WITHDRAWALS if o is not w
                              and any(v is None for k, v in inspect(texts, o).items() if not k.startswith("_"))]
            if others_waiting:
                raise Problem(f"another withdrawal is still waiting for its date ({'; '.join(others_waiting)}), and the "
                              f"placeholders are the same text for each, so undoing {ident} now would mix the two. "
                              f"Nothing was changed.")
            extra = unknown_placeholders(texts)
            if extra:
                raise Problem("a carrier holds a placeholder this script does not fill in, so undoing the stamp would write "
                              "into text that is not the withdrawal's. Nothing was changed. " + " | ".join(extra))
            shared = all_ids(texts[REGISTER]).count(ident) > 1
            new = apply_unstamp(apply_stamp(texts, ident, w), ident, w)   # finish a partial stamp in memory, then undo it
            k2, i2, m2 = verdict(new, w)
            if k2 != "unstamped":
                raise Problem(f"could not return every carrier to its placeholder (the result would be {k2}); nothing was changed")
            verdicts(new)
            d0 = id_date(ident)
            survivors = []
            for name in (POLICY, REDIRECTS, LOG):
                for n, line in enumerate(new[name].splitlines(), 1):
                    if ident in line or ident.lower() in line:
                        survivors.append(f"{name} line {n}")
            mine_after = my_record(new[REGISTER], w)
            if ident in mine_after or human(d0) in (field(mine_after, "heading") or ""):
                at = [str(n) for n, line in enumerate(new[REGISTER].splitlines(), 1) if ident in line]
                survivors.append(f"the withdrawal entry in {REGISTER}" + (f" (line {', '.join(at[:4])})" if at else ""))
            if survivors and shared:
                print(f"note: {ident} is also the identifier of another entry, so these mentions of it were left alone: "
                      f"{', '.join(survivors)}")
            elif survivors:
                raise Problem(f"{ident} is also written by hand in: {', '.join(survivors)}. --unstamp would leave it there. "
                              f"Nothing was changed. Remove those mentions first.")
            write_all(texts, new)
            rebuild_generated()
            print(f"unstamped: {ident} removed from every carrier of the withdrawal of {w['work']!r}")
            return
        if argv[0].startswith("-") or len(argv) != 1:
            die(USAGE)
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", argv[0]):
            die("the date must be YYYY-MM-DD")
        try:
            d = datetime.date.fromisoformat(argv[0])
        except ValueError:
            die(f"{argv[0]} is not a real date")
        results = verdicts(texts)
        waiting = [(w, r) for w, r in zip(WITHDRAWALS, results) if r[0] != "stamped"]
        stamped = [ident for kind, ident, missing in results if kind == "stamped"]
        if waiting:
            w, (kind, ident, missing) = waiting[0]
            if kind == "partial" and id_date(ident) != d:
                how = (f"To change the date, run --unstamp {ident} first." if w is WITHDRAWALS[-1] else
                       f"That withdrawal has shipped: put its carriers back as they were published (from git); "
                       f"its identifier and date do not change.")
                raise Problem(f"already stamped as {ident}, which is dated {id_date(ident).isoformat()}, not {argv[0]}. "
                              f"Nothing was changed. " + how)
        elif not any(id_date(i) == d for i in stamped):
            raise Problem(f"already stamped as {', '.join(stamped)}, and none of those is dated {argv[0]}. "
                          f"Nothing was changed. Only the newest withdrawal's date can be changed, and only while it is "
                          f"unpublished: run --unstamp first.")
        if d != today():
            if os.environ.get("STAMP_ALLOW_OTHER_DATE") != "1":
                raise Problem(f"the date must be today's date in {ZONE} ({today().isoformat()}), "
                              f"because it is the day the withdrawal goes live. Nothing was changed.")
            print(f"note: STAMP_ALLOW_OTHER_DATE is set; stamping {argv[0]} although today is {today().isoformat()}")
        if not waiting:
            print(f"already stamped as {', '.join(stamped)}; nothing to do")
            return
        if kind == "unstamped":
            taken = [int(i[-2:]) for i in all_ids(texts[REGISTER]) if re.fullmatch(rf"C-{d:%Y%m%d}-\d{{2}}", i)]
            number = max(taken, default=0) + 1
            if number > 99:
                raise Problem("no free number is left for that date")
            ident = f"C-{d:%Y%m%d}-{number:02d}"
        extra = unknown_placeholders(texts)
        if extra:
            raise Problem("a carrier holds a placeholder this script does not fill in, so the stamp would write this "
                          "withdrawal's date somewhere it does not belong. Nothing was changed. " + " | ".join(extra))
        new = apply_stamp(texts, ident, w)
        k2, i2, m2 = verdict(new, w)          # check the result before anything is written
        if k2 != "stamped" or i2 != ident:
            raise Problem(f"stamping would leave the carriers {k2} (still placeholders: {', '.join(m2)}); nothing was changed")
        verdicts(new)
        back = apply_unstamp(new, ident, w)
        # A placeholder wrapped across a line break is still the same placeholder.
        norm = lambda s: " ".join(PH_DATE_RE.sub(PH_DATE, s).split())
        reference = texts if kind == "unstamped" else apply_unstamp(apply_stamp(back, ident, w), ident, w)
        where = []
        for name in CARRIERS:
            if norm(back[name]) != norm(reference[name]):
                a, b = reference[name].splitlines(), back[name].splitlines()
                n = next((k for k, (x, y) in enumerate(zip(a, b), 1) if norm(x) != norm(y)), min(len(a), len(b)) + 1)
                where.append(f"{name} line {n}: {(a[n - 1] if n <= len(a) else '').strip()[:90]!r}")
        if where:
            raise Problem("a carrier holds a placeholder this script does not know about, so the stamp could not be undone "
                          "exactly. Nothing was changed. Look at: " + "; ".join(where))
        write_all(texts, new)
        rebuild_generated()
        print(f"{ident}, withdrawn {human(d)}: the register entry for {w['work']!r}, "
              + ("the /use-policy/ link, " if w["policy"] else "")
              + f"its {len(w['froms'])} redirect rows and the evolution log all agree")
    except Problem as e:
        die(str(e))


main(sys.argv[1:])
PY
