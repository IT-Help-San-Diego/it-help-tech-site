#!/usr/bin/env bash
# Stamp the Real Bot withdrawal with the date it goes live.
# A corrections entry may not state an event before it happens, so the
# identifier and the date stay placeholders until the day of the deploy.
#   scripts/stamp-withdrawal.sh 2026-11-20
# Replaces C-YYYYMMDD-01, c-yyyymmdd-01, YYYY-MM-DD (logged) and [DEPLOY DATE]
# in the register, /use-policy/, the redirect list and the evolution log.
set -euo pipefail
DATE="${1:?usage: scripts/stamp-withdrawal.sh YYYY-MM-DD}"
[[ "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "date must be YYYY-MM-DD" >&2; exit 1; }
cd "$(dirname "$0")/.."
python3 - "$DATE" <<'PY'
import sys, datetime, pathlib
d = datetime.date.fromisoformat(sys.argv[1])
ident = f"C-{d:%Y%m%d}-01"
human = f"{d.day} {d:%B %Y}"
files = ["data/corrections.toml", "content/use-policy.md", "infra/cloudfront/redirects.json", "PROJECT_EVOLUTION_LOG.md"]
for f in files:
    p = pathlib.Path(f); t = p.read_text()
    n = t.replace("C-YYYYMMDD-01", ident).replace("c-yyyymmdd-01", ident.lower()).replace("[DEPLOY DATE]", human).replace('logged = "YYYY-MM-DD"', f'logged = "{d.isoformat()}"')
    if n != t: p.write_text(n); print("stamped", f)
left = [f for f in files if any(k in pathlib.Path(f).read_text() for k in ("C-YYYYMMDD-01", "c-yyyymmdd-01", "[DEPLOY DATE]"))]
if left: sys.exit("placeholders remain in: " + ", ".join(left))
print(f"{ident}, withdrawn {human}")
PY
