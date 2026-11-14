#!/usr/bin/env bash
# Stamp the Real Bot withdrawal with the date it goes live.
#
# A corrections entry may not state an event before it happens, so the
# withdrawal's identifier and date stay placeholders until the day of the
# deploy. This script is the only thing that fills them in.
#
#   scripts/stamp-withdrawal.sh 2026-11-20
#       Stamp every carrier. The date must be today's date in the site's time
#       zone (America/Los_Angeles), because it is the day the withdrawal goes
#       live. STAMP_ALLOW_OTHER_DATE=1 lifts that for tests.
#   scripts/stamp-withdrawal.sh --unstamp
#       Put every carrier back to its placeholder. Use this when a stamped
#       change did not ship on its date, then stamp again on the day it does.
#   scripts/stamp-withdrawal.sh --check [--live-page <file>] [--require-publisher]
#       Change nothing. Fail unless every carrier is unstamped, or every
#       carrier names the same entry and no other entry shares its identifier.
#       --live-page takes a copy of the corrections page as it is published
#       now. If the entry is not on it yet, this deploy would publish it for
#       the first time, and its date must be today. If the copy is missing
#       or is not a corrections page, the rule is skipped with a warning: a
#       deploy is never blocked because the site could not be read.
#       --require-publisher fails a stamped tree that lacks the script that
#       publishes the redirects.
#   scripts/stamp-withdrawal.sh --check-built <dir>
#       Change nothing. Read a finished build: the corrections page must hold
#       exactly one entry under the stamped anchor, that entry must name the
#       withdrawn note, the withdrawn addresses must be gone from the build,
#       and no placeholder may appear in any built page.
#   scripts/stamp-withdrawal.sh --check-live
#       Change nothing. Ask the live site: each of the five withdrawn
#       addresses must answer 301 to the stamped anchor, and the live
#       corrections page must hold exactly one entry under it.
#
# Order on the day, in one sitting: merge origin/main into the branch; stamp;
# commit and push; wait for the checks on that stamped commit; merge; watch the
# deploy to its last step. A green check on an unstamped commit says nothing
# about the stamp. If the deploy does not finish that day, merge nothing else
# until the branch has been unstamped and stamped again.
#
# The carriers are: the register entry (identifier, heading, logged date), the
# link in /use-policy/, the five redirect rows, and the evolution log. One
# identifier is chosen, the next free number for the date, and written to all
# of them. Nobody numbers anything by hand.
set -euo pipefail
unset CDPATH
export STAMP_CALLER_DIR="$PWD"
cd "$(dirname "$0")/.."
exec python3 - "$@" <<'PY'
import datetime, html as htmllib, json, os, pathlib, re, sys, tempfile, time
import urllib.error, urllib.request

WORK = "The Real Bot Hasn't Been Built Yet"
SLUG = "/field-notes/the-real-bot-hasnt-been-built-yet"
FROMS = {SLUG + "/", SLUG, SLUG + "/index.html", SLUG + ".pdf", SLUG + ".bib"}
REGISTER = "data/corrections.toml"
POLICY = "content/use-policy.md"
REDIRECTS = "infra/cloudfront/redirects.json"
LOG = "PROJECT_EVOLUTION_LOG.md"
CARRIERS = (REGISTER, POLICY, REDIRECTS, LOG)
PH_ID, PH_ANCHOR, PH_ISO, PH_DATE = "C-YYYYMMDD-01", "c-yyyymmdd-01", "YYYY-MM-DD", "[DEPLOY DATE]"
PH_DATE_RE = re.compile(r"\[DEPLOY\s+DATE\]")
ID_RE = re.compile(r"C-\d{8}-\d{2}")
ANCHOR_RE = re.compile(r"c-\d{8}-\d{2}")
ZONE = "America/Los_Angeles"
PUBLISHER = "infra/cloudfront/deploy-viewer-request.sh"
LIVE_BASE = os.environ.get("STAMP_LIVE_BASE", "https://www.it-help.tech").rstrip("/")
USAGE = ("usage: scripts/stamp-withdrawal.sh YYYY-MM-DD | --unstamp | "
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
    for n, r in enumerate(doc.get("correction", []), 1):
        if not isinstance(r, dict) or not str(r.get("id", "")).strip():
            raise Problem(f"entry number {n} in {REGISTER} has no id")
        ids.append(str(r["id"]).upper())
    return ids


def split_records(register_text):
    return re.split(r"(?m)^\[\[correction\]\][ \t]*(?:#[^\r\n]*)?\r?$", register_text)[1:]


def field(record, name):
    m = re.search(r"(?m)^[ \t]*" + name + r"""[ \t]*=[ \t]*"([^"\r\n]*)\"""", record)
    return m.group(1) if m else None


def my_record(register_text):
    mine = [r for r in split_records(register_text) if field(r, "work") == WORK and field(r, "kind") == "withdrawal"]
    if len(mine) != 1:
        raise Problem(f'{REGISTER} should have one withdrawal entry with work = "{WORK}", found {len(mine)}')
    return mine[0]


def inspect(texts):
    """Read what each carrier says. A value of None means: still a placeholder."""
    rec = my_record(texts[REGISTER])
    rid, heading, logged, status = (field(rec, k) for k in ("id", "heading", "logged", "status"))
    if rid is None or heading is None or logged is None:
        raise Problem("the withdrawal entry needs id, heading and logged")
    hm = re.fullmatch(r"(\S+) · (.+) · withdrawn (.+)", heading)
    if not hm:
        raise Problem(f"the withdrawal entry's heading is not '<id> · <title> · withdrawn <date>': {heading!r}")
    if hm.group(2) != WORK:
        raise Problem(f"the withdrawal entry's heading names {hm.group(2)!r}, not the withdrawn note")

    links = re.findall(r"\[withdrawn\s+on\s+((?:\[DEPLOY\s+DATE\]|[^\[\]])+)\]\(\s*/corrections/#([^)\s]+)\s*\)", texts[POLICY])
    if len(links) != 1:
        raise Problem(f"{POLICY} should have one 'withdrawn on' link to a corrections anchor, found {len(links)}")
    policy_date, policy_anchor = links[0]

    try:
        doc = json.loads(texts[REDIRECTS])
    except ValueError as e:
        raise Problem(f"{REDIRECTS} is not valid JSON: {e}")
    rows = [r for r in doc.get("redirects", []) if isinstance(r, dict) and str(r.get("from", "")).startswith(SLUG)]
    froms = sorted(str(r.get("from")) for r in rows)
    if froms != sorted(FROMS):
        raise Problem(f"{REDIRECTS} should have exactly five rows for the withdrawn note, {sorted(FROMS)}; found {froms}")
    if any(r.get("status") != 301 for r in rows):
        raise Problem("every redirect row for the withdrawn note must have status 301")
    targets = sorted({str(r.get("to")) for r in rows})
    if len(targets) != 1 or not targets[0].startswith("/corrections/#"):
        raise Problem(f"the five redirect rows do not share one corrections anchor: {targets}")
    redirect_anchor = targets[0].split("#", 1)[1]

    lh = re.findall(r"(?m)^### (\[DEPLOY\s+DATE\]|\d{4}-\d{2}-\d{2}): The Real Bot field note withdrawn", texts[LOG])
    le = re.findall(r"entry (C-[0-9A-Z]{8}-\d{2}), the withdrawal", texts[LOG])
    if len(lh) != 1 or len(le) != 1:
        raise Problem(f"{LOG} should have one heading and one 'entry <id>, the withdrawal' line for the withdrawal; "
                      f"found {len(lh)} and {len(le)}")

    def ph(value, placeholder):
        return None if value == placeholder else value

    return {
        "register id": ph(rid, PH_ID),
        "heading id": ph(hm.group(1), PH_ID),
        "heading date": None if PH_DATE_RE.fullmatch(hm.group(3)) else hm.group(3),
        "logged": ph(logged, PH_ISO),
        "use-policy anchor": ph(policy_anchor, PH_ANCHOR),
        "use-policy date": None if PH_DATE_RE.fullmatch(policy_date.strip()) else " ".join(policy_date.split()),
        "redirect anchor": ph(redirect_anchor, PH_ANCHOR),
        "log heading": None if PH_DATE_RE.fullmatch(lh[0]) else lh[0],
        "log entry id": ph(le[0], PH_ID),
        "_status": status,
    }


ID_KEYS = ("register id", "heading id", "log entry id")
ANCHOR_KEYS = ("use-policy anchor", "redirect anchor")


def verdict(texts, allow_own_repeat=False):
    """('unstamped' | 'stamped' | 'partial', identifier or None, missing). Raises Problem on any disagreement.
    allow_own_repeat lets --unstamp run when the only fault is another entry sharing the withdrawal's identifier."""
    s = inspect(texts)
    if s["_status"] != "published":
        raise Problem(f'the withdrawal entry must have status = "published", not {s["_status"]!r}')
    ids = all_ids(texts[REGISTER])
    repeated = sorted({i for i in ids if ids.count(i) > 1})
    mine = (s["register id"] or "").upper()
    if repeated and not (allow_own_repeat and repeated == [mine] and ids.count(mine) == 2):
        advice = ("If the withdrawal has not been published yet, run scripts/stamp-withdrawal.sh --unstamp and stamp "
                  "again: it takes the next free number. If it has been published, the other entry is the newer one "
                  "and needs its own number." if mine in repeated else
                  "That is not the withdrawal; give one of those entries its own number.")
        raise Problem(f"{REGISTER} has more than one entry with the same identifier: {', '.join(repeated)}. {advice}")
    for k in ID_KEYS:
        if s[k] is not None and not ID_RE.fullmatch(s[k]):
            raise Problem(f"{k} is {s[k]!r}, which is not an identifier in the form C-YYYYMMDD-NN")
    for k in ANCHOR_KEYS:
        if s[k] is not None and not ANCHOR_RE.fullmatch(s[k]):
            raise Problem(f"{k} is {s[k]!r}, which is not an anchor in the form c-yyyymmdd-nn, lower case")
    value_keys = [k for k in s if not k.startswith("_")]
    show = "; ".join(f"{k} = {s[k]}" for k in value_keys if s[k])
    named = {s[k] for k in ID_KEYS if s[k]} | {s[k].upper() for k in ANCHOR_KEYS if s[k]}
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
        holders = ", ".join(k for k in ID_KEYS + ANCHOR_KEYS if s[k] and s[k].upper() == ident)
        raise Problem(f"{ident} is already the identifier of another entry in {REGISTER}. It was found in: {holders}. "
                      f"Put that carrier back to its placeholder and stamp again; the script picks a free number.")
    wanted = {"heading date": human(d), "use-policy date": human(d), "logged": d.isoformat(), "log heading": d.isoformat()}
    for k, want in wanted.items():
        if s[k] is not None and s[k] != want:
            raise Problem(f"{k} is {s[k]!r}, but the identifier {ident} means {want!r}")
    missing = [k for k in value_keys if s[k] is None]
    if not missing:
        for name in CARRIERS:
            t = texts[name]
            if PH_ID in t or PH_ANCHOR in t or PH_DATE_RE.search(t):
                raise Problem(f"a placeholder is still present in {name}")
    return ("partial" if missing else "stamped"), ident, missing


def unknown_placeholders(texts):
    """Placeholders in the carriers beyond the ones this script fills in. Returns 'file line N: text' strings."""
    s = inspect(texts)
    n = lambda key: 1 if s[key] is None else 0
    expected = {
        REGISTER: {"id": n("register id") + n("heading id"), "anchor": 0, "date": n("heading date")},
        POLICY: {"id": 0, "anchor": n("use-policy anchor"), "date": n("use-policy date")},
        REDIRECTS: {"id": 0, "anchor": 5 * n("redirect anchor"), "date": 0},
        LOG: {"id": n("log entry id"), "anchor": 0, "date": n("log heading")},
    }
    found = []
    for name in CARRIERS:
        t = texts[name]
        actual = {"id": t.count(PH_ID), "anchor": t.count(PH_ANCHOR), "date": len(PH_DATE_RE.findall(t))}
        if any(actual[k] > expected[name][k] for k in actual):
            lines = [f"{name} line {i}: {line.strip()[:90]!r}" for i, line in enumerate(t.splitlines(), 1)
                     if PH_ID in line or PH_ANCHOR in line or "DEPLOY" in line]
            found.append(f"{name} has {sum(actual.values())} placeholders where {sum(expected[name].values())} are expected "
                         f"({'; '.join(lines[:6])})")
    return found


def apply_stamp(texts, ident):
    d = id_date(ident)
    out = {}
    reg = PH_DATE_RE.sub(human(d), texts[REGISTER].replace(PH_ID, ident))
    out[REGISTER] = reg.replace(f'logged = "{PH_ISO}"', f'logged = "{d.isoformat()}"')
    out[POLICY] = PH_DATE_RE.sub(human(d), texts[POLICY].replace(PH_ANCHOR, ident.lower()))
    out[REDIRECTS] = texts[REDIRECTS].replace(PH_ANCHOR, ident.lower())
    log = re.sub(r"(?m)^### \[DEPLOY\s+DATE\](: The Real Bot field note withdrawn)",
                 lambda m: "### " + d.isoformat() + m.group(1), texts[LOG])
    out[LOG] = PH_DATE_RE.sub(human(d), log.replace(PH_ID, ident))
    return out


def apply_unstamp(texts, ident):
    d = id_date(ident)
    out = {}
    reg = texts[REGISTER]
    rec = my_record(reg)
    new = (rec.replace(ident, PH_ID)
              .replace(f'withdrawn {human(d)}"', f'withdrawn {PH_DATE}"')
              .replace(f'logged = "{d.isoformat()}"', f'logged = "{PH_ISO}"'))
    out[REGISTER] = reg.replace(rec, new, 1)
    out[POLICY] = re.sub(r"\[withdrawn\s+on\s+[^\[\]]+\]\(\s*/corrections/#" + re.escape(ident.lower()) + r"\s*\)",
                         lambda m: f"[withdrawn on {PH_DATE}](/corrections/#{PH_ANCHOR})", texts[POLICY])
    out[REDIRECTS] = texts[REDIRECTS].replace("/corrections/#" + ident.lower(), "/corrections/#" + PH_ANCHOR)
    log = re.sub(r"(?m)^### " + re.escape(d.isoformat()) + r"(: The Real Bot field note withdrawn)",
                 lambda m: "### " + PH_DATE + m.group(1), texts[LOG])
    out[LOG] = log.replace(f"entry {ident}, the withdrawal", f"entry {PH_ID}, the withdrawal")
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


def is_withdrawal_heading(heading, ident):
    plain = heading.replace(chr(0x2019), "'")
    return WORK in plain and ident in plain


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
        except (urllib.error.URLError, OSError) as e:
            last = e
            time.sleep(2 * (attempt + 1))
    raise Problem(f"could not reach {url}: {last}")


def check_live(ident):
    anchor = ident.lower()
    want = f"{LIVE_BASE}/corrections/#{anchor}"
    waits = [0] + [int(x) for x in os.environ.get("STAMP_LIVE_WAITS", "10 20 30 30").split()]
    for pause in waits:      # a published function can take a short while to reach every edge
        time.sleep(pause)
        bad = []
        for src in sorted(FROMS):
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


def check_built(directory, texts):
    kind, ident, missing = verdict(texts)
    if kind != "stamped":
        raise Problem(f"the carriers are {kind}; a built site can only be checked once the withdrawal is stamped")
    root = pathlib.Path(directory)
    page = root / "corrections" / "index.html"
    if not page.is_file():
        raise Problem(f"{page} does not exist")
    page_html = page.read_text(encoding="utf-8")
    entry_ids = re.findall(r"""<section\b[^>]*\bid=["']?(c-\d{8}-\d{2})["']?[\s>]""", page_html, flags=re.I)
    dup = sorted({i for i in entry_ids if entry_ids.count(i) > 1})
    if dup:
        raise Problem(f"the built corrections page has more than one entry under the same anchor: {', '.join(dup)}")
    anchor = ident.lower()
    found = re.findall(r"""\bid=["']?(""" + re.escape(anchor) + r""")["']?[\s>]""", page_html, flags=re.I)
    if found != [anchor]:
        raise Problem(f"the built corrections page should have exactly one element with id {anchor}; found {found}")
    heading = section_heading(page_html, anchor)
    if not is_withdrawal_heading(heading, ident):
        raise Problem(f"the entry under #{anchor} is headed {heading!r}; it should name {ident} and the withdrawn note")
    still = []
    for src in sorted(FROMS):
        rel = src.lstrip("/")
        last = rel.rstrip("/").rsplit("/", 1)[-1]
        candidates = [root / rel] if "." in last else [root / rel.rstrip("/") / "index.html", root / (rel.rstrip("/") + ".html")]
        still += [str(c) for c in candidates if c.is_file()]
    if still:
        raise Problem("the withdrawn note is still in the build: " + ", ".join(sorted(set(still))))
    leftovers = []
    for p in sorted(root.rglob("*")):
        if p.is_file() and p.suffix.lower() in (".html", ".txt", ".xml", ".json"):
            t = p.read_text(encoding="utf-8", errors="replace")
            if PH_ID in t or PH_ANCHOR in t or PH_DATE_RE.search(t):
                leftovers.append(str(p))
    if leftovers:
        raise Problem("a placeholder appears in built files: " + ", ".join(leftovers[:8]))
    return ident, heading


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
            kind, ident, missing = verdict(texts)
            if kind == "partial":
                raise Problem(f"only part of the withdrawal is stamped as {ident}; still placeholders: {', '.join(missing)}")
            if kind == "unstamped":
                print("unstamped: every carrier still holds its placeholder")
                return
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
                if re.search(r"yyyymmdd|YYYY-MM-DD|\[DEPLOY DATE\]", texts[REDIRECTS]):
                    lacking.append(f"{REDIRECTS} still contains placeholder text, which makes the publisher skip its run")
                if lacking:
                    raise Problem(f"the withdrawal is stamped as {ident}, but: " + "; ".join(lacking) + ". "
                                  f"Deploying now would delete the note without redirecting its addresses.")
            if live_page is not None:
                path = live_page if os.path.isabs(live_page) else os.path.join(os.environ.get("STAMP_CALLER_DIR", "."), live_page)
                try:
                    with open(path, encoding="utf-8", errors="replace") as f:
                        live = f.read()
                except OSError:
                    live = ""
                published = (len(section_ids(live, ident.lower())) == 1
                             and is_withdrawal_heading(section_heading(live, ident.lower()), ident))
                if published or os.environ.get("STAMP_ALREADY_PUBLISHED") == "1":
                    print(f"{ident} is already on the published corrections page" if published else
                          f"note: STAMP_ALREADY_PUBLISHED is set; treating {ident} as published before")
                elif "correction-entry" not in live:
                    # Not a corrections page at all: unreadable, empty, or an error page. A deploy
                    # must never be blocked because the site could not be read, so say so and go on.
                    msg = (f"the published corrections page could not be read, so the rule that {ident} "
                           f"is first published on its own date was not applied")
                    print(("::warning::" if os.environ.get("GITHUB_ACTIONS") else "warning: ") + msg)
                elif id_date(ident) != today():
                    raise Problem(f"{ident} is not on the published corrections page, and today in {ZONE} is "
                                  f"{today().isoformat()}, not {id_date(ident).isoformat()}. If it has never been "
                                  f"published, run scripts/stamp-withdrawal.sh --unstamp and stamp again with today's "
                                  f"date. If it WAS published and the page has since lost it (an older deploy re-run, "
                                  f"or a restore), do not re-date it: fix the page by deploying with "
                                  f"STAMP_ALREADY_PUBLISHED=1 set for that run.")
                else:
                    print(f"{ident} is not published yet and is dated today")
            print(f"stamped: every carrier says {ident}, and no other entry shares it")
            return
        if argv[0] == "--check-live":
            if len(argv) != 1:
                die(USAGE)
            kind, ident, missing = verdict(texts)
            if kind == "unstamped":
                print("unstamped: nothing is published yet, so there is nothing to check on the live site")
                return
            if kind != "stamped":
                raise Problem(f"only part of the withdrawal is stamped as {ident}; still placeholders: {', '.join(missing)}")
            check_live(ident)
            print(f"live site ok: the five withdrawn addresses answer 301 to {LIVE_BASE}/corrections/#{ident.lower()}, "
                  f"and the live corrections page has one entry under that anchor")
            return
        if argv[0] == "--check-built":
            if len(argv) != 2:
                die(USAGE)
            built = argv[1] if os.path.isabs(argv[1]) else os.path.join(os.environ.get("STAMP_CALLER_DIR", "."), argv[1])
            ident, heading = check_built(built, texts)
            print(f"built site ok: one entry under #{ident.lower()}, headed {heading!r}; "
                  f"the withdrawn addresses are gone; no placeholder in any built file")
            return
        if argv[0] == "--unstamp":
            if len(argv) != 1:
                die(USAGE)
            kind, ident, missing = verdict(texts, allow_own_repeat=True)
            if kind == "unstamped":
                print("already unstamped; nothing to do")
                return
            new = apply_unstamp(apply_stamp(texts, ident), ident)   # finish a partial stamp in memory, then undo it
            k2, i2, m2 = verdict(new)
            if k2 != "unstamped":
                raise Problem(f"could not return every carrier to its placeholder (the result would be {k2}); nothing was changed")
            d0 = id_date(ident)
            survivors = []
            for name in (POLICY, REDIRECTS, LOG):
                for n, line in enumerate(new[name].splitlines(), 1):
                    if ident in line or ident.lower() in line:
                        survivors.append(f"{name} line {n}")
            mine_after = my_record(new[REGISTER])
            if ident in mine_after or human(d0) in (field(mine_after, "heading") or ""):
                survivors.append(f"the withdrawal entry in {REGISTER}")
            if survivors:
                raise Problem(f"{ident} is also written by hand in: {', '.join(survivors)}. --unstamp would leave it there. "
                              f"Nothing was changed. Remove those mentions first.")
            write_all(texts, new)
            print(f"unstamped: {ident} removed from every carrier")
            return
        if argv[0].startswith("-") or len(argv) != 1:
            die(USAGE)
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", argv[0]):
            die("the date must be YYYY-MM-DD")
        try:
            d = datetime.date.fromisoformat(argv[0])
        except ValueError:
            die(f"{argv[0]} is not a real date")
        kind, ident, missing = verdict(texts)
        if kind != "unstamped" and id_date(ident) != d:
            raise Problem(f"already stamped as {ident}, which is dated {id_date(ident).isoformat()}, not {argv[0]}. "
                          f"Nothing was changed. To change the date, run --unstamp first.")
        if d != today():
            if os.environ.get("STAMP_ALLOW_OTHER_DATE") != "1":
                raise Problem(f"the date must be today's date in {ZONE} ({today().isoformat()}), "
                              f"because it is the day the withdrawal goes live. Nothing was changed.")
            print(f"note: STAMP_ALLOW_OTHER_DATE is set; stamping {argv[0]} although today is {today().isoformat()}")
        if kind == "stamped":
            print(f"already stamped as {ident}; nothing to do")
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
        new = apply_stamp(texts, ident)
        k2, i2, m2 = verdict(new)          # check the result before anything is written
        if k2 != "stamped" or i2 != ident:
            raise Problem(f"stamping would leave the carriers {k2} (still placeholders: {', '.join(m2)}); nothing was changed")
        back = apply_unstamp(new, ident)
        # A placeholder wrapped across a line break is still the same placeholder.
        norm = lambda s: " ".join(PH_DATE_RE.sub(PH_DATE, s).split())
        reference = texts if kind == "unstamped" else apply_unstamp(apply_stamp(back, ident), ident)
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
        print(f"{ident}, withdrawn {human(d)}: the register entry, the /use-policy/ link, "
              f"the five redirect rows and the evolution log all agree")
    except Problem as e:
        die(str(e))


main(sys.argv[1:])
PY
