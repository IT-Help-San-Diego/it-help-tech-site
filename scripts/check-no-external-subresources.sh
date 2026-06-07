#!/usr/bin/env bash
# CI gate: fail the build if any built page loads a cross-origin subresource.
#
# This is the safety net for the COEP `require-corp` header (Sub-4-bis).
# COEP requires every subresource to either be same-origin or carry an
# explicit CORP / CORS opt-in from the cross-origin server. The site has
# zero external subresources today; this gate prevents a future field note
# (or template change) from silently breaking the COEP-protected pages.
#
# Excludes the signature pages (`ithelp-logo-sig-*.html`) which are served
# by a separate CloudFront behavior with their own response-headers policy.
#
# Usage: run from repo root after `zola build`.
#   scripts/check-no-external-subresources.sh
#
# Exit codes:
#   0 — no external subresources found
#   1 — at least one external subresource found (blocks deploy)
#   2 — build output missing (run `zola build` first)
set -euo pipefail

PUBLIC_DIR="${PUBLIC_DIR:-public}"

if [ ! -d "$PUBLIC_DIR" ]; then
  echo "error: $PUBLIC_DIR not found — run 'zola build' first" >&2
  exit 2
fi

python3 - "$PUBLIC_DIR" <<'PY'
import re
import sys
from pathlib import Path

public = Path(sys.argv[1])
SITE_ORIGINS = ("it-help.tech",)  # any apex/subdomain treated as same-site

# Subresource attributes that COEP cares about.
# - <script src>, <img src>, <iframe src>, <video src>, <audio src>, <source src>, <embed src>, <object data>
# - <link rel=stylesheet|preload|modulepreload|icon|manifest|mask-icon|apple-touch-icon|prefetch href>
# - srcset / imagesrcset (responsive images) — comma-separated URL+descriptor list
# - <video poster=...>
SUBRESOURCE_RE = re.compile(
    r'<(?:script|img|iframe|video|audio|source|embed)[^>]+\bsrc\s*=\s*["\']([^"\']+)|'
    r'<object[^>]+\bdata\s*=\s*["\']([^"\']+)|'
    r'<link[^>]+\brel\s*=\s*["\'](?:stylesheet|preload|modulepreload|icon|manifest|mask-icon|apple-touch-icon|prefetch)["\'][^>]*\bhref\s*=\s*["\']([^"\']+)|'
    r'<link[^>]+\bhref\s*=\s*["\']([^"\']+)["\'][^>]*\brel\s*=\s*["\'](?:stylesheet|preload|modulepreload|icon|manifest|mask-icon|apple-touch-icon|prefetch)|'
    r'<video[^>]+\bposter\s*=\s*["\']([^"\']+)',
    re.IGNORECASE,
)
# srcset attributes can hold N comma-separated URLs; handle separately.
SRCSET_RE = re.compile(
    r'\b(?:imagesrcset|srcset)\s*=\s*["\']([^"\']+)["\']',
    re.IGNORECASE,
)

def is_external(url: str) -> bool:
    if not url.startswith(("http://", "https://", "//")):
        return False
    return not any(o in url for o in SITE_ORIGINS)

def iter_srcset_urls(value: str):
    # `srcset` is "URL [descriptor], URL [descriptor], ..." per HTML spec.
    for candidate in value.split(","):
        url = candidate.strip().split()[0] if candidate.strip() else ""
        if url:
            yield url

violations = []
for html_file in sorted(public.rglob("*.html")):
    # Signature pages are served by a separate CloudFront behavior with their own policy.
    if html_file.name.startswith("ithelp-logo-sig-"):
        continue
    text = html_file.read_text(encoding="utf-8")
    for match in SUBRESOURCE_RE.finditer(text):
        url = next((g for g in match.groups() if g), None)
        if url and is_external(url):
            violations.append((html_file.relative_to(public), url))
    for match in SRCSET_RE.finditer(text):
        for url in iter_srcset_urls(match.group(1)):
            if is_external(url):
                violations.append((html_file.relative_to(public), url))

if violations:
    print(f"FAIL: {len(violations)} external subresource(s) found.", file=sys.stderr)
    print("COEP require-corp requires every subresource to be same-origin or carry CORP/CORS opt-in.", file=sys.stderr)
    print("Either remove the embed, host the asset locally, or relax COEP in csp-policy-v1.json.", file=sys.stderr)
    print("", file=sys.stderr)
    for page, url in violations:
        print(f"  {page}: {url}", file=sys.stderr)
    sys.exit(1)

print("OK: 0 external subresources across all site pages — COEP require-corp is safe.")
PY
