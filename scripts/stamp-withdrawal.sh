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
#   scripts/stamp-withdrawal.sh --check [--introduced-since <commit>]
#       Change nothing. Fail unless every carrier is unstamped, or every
#       carrier names the same entry and no other entry shares its identifier.
#       With --introduced-since, also fail if this would be the first time the
#       entry is published and its date is not today.
#   scripts/stamp-withdrawal.sh --check-built <dir>
#       Change nothing. Read a finished build: the corrections page must hold
#       exactly one entry under the stamped anchor, that entry must name the
#       withdrawn note, the withdrawn addresses must be gone from the build,
#       and no placeholder may appear in any built page.
#
# Order on the day: merge origin/main into the branch, stamp, build, check.
#
# The carriers are: the register entry (identifier, heading, logged date), the
# link in /use-policy/, the five redirect rows, and the evolution log. One
# identifier is chosen, the next free number for the date, and written to all
# of them. Nobody numbers anything by hand.
set -euo pipefail
unset CDPATH
cd "$(dirname "$0")/.."
exec python3 - "$@" <<'PY'
import datetime, html as htmllib, json, os, pathlib, re, subprocess, sys, tempfile

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
USAGE = ("usage: scripts/stamp-withdrawal.sh YYYY-MM-DD | --unstamp | "
         "--check [--introduced-since <commit>] | --check-built <dir>")


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
        try:
            with open(name, encoding="utf-8", newline="") as f:
                texts[name] = f.read()
        except OSError as e:
            raise Problem(f"cannot read {name}: {e.strerror}")
    return texts


def all_ids(register_text):
    return re.findall(r"""(?m)^[ \t]*id[ \t]*=[ \t]*["']([^"'\r\n]+)["']""", register_text)


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


def verdict(texts):
    """('unstamped' | 'stamped' | 'partial', identifier or None, missing). Raises Problem on any disagreement."""
    s = inspect(texts)
    if s["_status"] != "published":
        raise Problem(f'the withdrawal entry must have status = "published", not {s["_status"]!r}')
    ids = all_ids(texts[REGISTER])
    repeated = sorted({i for i in ids if ids.count(i) > 1})
    if repeated:
        raise Problem(f"{REGISTER} has more than one entry with the same identifier: {', '.join(repeated)}")
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
    if ids.count(ident) != (1 if s["register id"] else 0):
        holders = ", ".join(k for k in ID_KEYS + ANCHOR_KEYS if s[k] and s[k].upper() == ident)
        raise Problem(f"{ident} is already the identifier of another entry in {REGISTER}. It was found in: {holders}")
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
    m = re.search(r"""<section\b[^>]*\bid=["']?""" + re.escape(anchor) + r"""["']?[\s>].*?<h2\b[^>]*>(.*?)</h2>""",
                  page_html, flags=re.S)
    heading = htmllib.unescape(re.sub(r"<[^>]+>", "", m.group(1))).strip() if m else ""
    plain = heading.replace("’", "'")
    if WORK not in plain or ident not in plain:
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
            if not (len(argv) == 1 or (len(argv) == 3 and argv[1] == "--introduced-since")):
                die(USAGE)
            kind, ident, missing = verdict(texts)
            if kind == "partial":
                raise Problem(f"only part of the withdrawal is stamped as {ident}; still placeholders: {', '.join(missing)}")
            if kind == "unstamped":
                print("unstamped: every carrier still holds its placeholder")
                return
            if len(argv) == 3:
                before, seen = argv[2], False
                if before and not re.fullmatch(r"0+", before):
                    r = subprocess.run(["git", "show", f"{before}:{REGISTER}"], capture_output=True, text=True)
                    if r.returncode != 0:
                        raise Problem(f"cannot read {REGISTER} at {before} to see whether {ident} was already published: "
                                      f"{r.stderr.strip().splitlines()[-1] if r.stderr.strip() else 'git show failed'}")
                    seen = ident in all_ids(r.stdout)
                if not seen and id_date(ident) != today():
                    raise Problem(f"this would be the first time {ident} is published, and today in {ZONE} is "
                                  f"{today().isoformat()}, not {id_date(ident).isoformat()}. "
                                  f"Run scripts/stamp-withdrawal.sh --unstamp, then stamp again with today's date.")
            print(f"stamped: every carrier says {ident}, and no other entry shares it")
            return
        if argv[0] == "--check-built":
            if len(argv) != 2:
                die(USAGE)
            ident, heading = check_built(argv[1], texts)
            print(f"built site ok: one entry under #{ident.lower()}, headed {heading!r}; "
                  f"the withdrawn addresses are gone; no placeholder in any built file")
            return
        if argv[0] == "--unstamp":
            if len(argv) != 1:
                die(USAGE)
            kind, ident, missing = verdict(texts)
            if kind == "unstamped":
                print("already unstamped; nothing to do")
                return
            new = apply_unstamp(apply_stamp(texts, ident), ident)   # finish a partial stamp in memory, then undo it
            k2, i2, m2 = verdict(new)
            if k2 != "unstamped":
                raise Problem(f"could not return every carrier to its placeholder (the result would be {k2}); nothing was changed")
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
        if d != today() and os.environ.get("STAMP_ALLOW_OTHER_DATE") != "1":
            raise Problem(f"the date must be today's date in {ZONE} ({today().isoformat()}), "
                          f"because it is the day the withdrawal goes live. Nothing was changed.")
        if kind == "stamped":
            print(f"already stamped as {ident}; nothing to do")
            return
        if kind == "unstamped":
            taken = [int(i[-2:]) for i in all_ids(texts[REGISTER]) if re.fullmatch(rf"C-{d:%Y%m%d}-\d{{2}}", i)]
            number = max(taken, default=0) + 1
            if number > 99:
                raise Problem("no free number is left for that date")
            ident = f"C-{d:%Y%m%d}-{number:02d}"
        new = apply_stamp(texts, ident)
        k2, i2, m2 = verdict(new)          # check the result before anything is written
        if k2 != "stamped" or i2 != ident:
            raise Problem(f"stamping would leave the carriers {k2} (still placeholders: {', '.join(m2)}); nothing was changed")
        write_all(texts, new)
        print(f"{ident}, withdrawn {human(d)}: the register entry, the /use-policy/ link, "
              f"the five redirect rows and the evolution log all agree")
    except Problem as e:
        die(str(e))


main(sys.argv[1:])
PY
