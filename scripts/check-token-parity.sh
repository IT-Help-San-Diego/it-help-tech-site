#!/usr/bin/env bash
# scripts/check-token-parity.sh
#
# Sub-agent 2 token-parity gate.
#
# 1. Asserts every token defined in static/css/tokens.css (--*) maps to the
#    same value as the matching $-variable in sass/_tokens.scss.
# 2. Asserts no raw hex color literals remain in the three "consumer" files:
#       static/css/late-overrides.css
#       sass/_extra.scss
#       sass/css/abridge.scss
#    The two SOT files (static/css/tokens.css, sass/_tokens.scss) are
#    deliberately EXCLUDED from the hex grep — they MUST contain hex literals.
#
# Exits 0 only if both gates pass. Drift / leftover hex literals fail the
# build with a clear diff.

set -u

TOKENS_CSS="static/css/tokens.css"
TOKENS_SCSS="sass/_tokens.scss"

CONSUMERS=(
  "static/css/late-overrides.css"
  "sass/_extra.scss"
  "sass/css/abridge.scss"
)

fail=0

if [[ ! -f "$TOKENS_CSS" ]]; then
  echo "ERROR: missing $TOKENS_CSS" >&2
  exit 2
fi
if [[ ! -f "$TOKENS_SCSS" ]]; then
  echo "ERROR: missing $TOKENS_SCSS" >&2
  exit 2
fi

# ---- 1. Parity check --------------------------------------------------------
#
# CSS:  --name: value;
# SCSS: $name: value;
#
# Normalise whitespace and trailing comments before comparing.

normalise() {
  # strip block/line comments, normalise quote style (CSS uses ' / SCSS uses ")
  # to a single canonical form, drop trailing ';', collapse whitespace.
  sed -E \
    -e 's#/\*.*\*/##g' \
    -e 's#//.*$##' \
    -e "s/'/\"/g" \
    -e 's/[[:space:]]+/ /g' \
    -e 's/^ //; s/ $//' \
    -e 's/;$//' \
    -e 's/[[:space:]]*$//' \
    -e 's/,$//'
}

# Extract only the FIRST :root { ... } block from a CSS file (skips print
# overrides and prefers-reduced-motion :root re-declarations, which legitimately
# redefine the same token names with different values for the alt context).
first_root_block() {
  awk '
    BEGIN { in_root = 0; done = 0 }
    done { next }
    !in_root && /:root[ \t]*\{/ { in_root = 1; next }
    in_root && /^[ \t]*\}/ { in_root = 0; done = 1; next }
    in_root { print }
  ' "$1"
}

tmp_css="$(mktemp)"
tmp_scss="$(mktemp)"
trap 'rm -f "$tmp_css" "$tmp_scss"' EXIT

# ---- 0. Duplicate-token gate ------------------------------------------------
#
# Detect duplicate --token-name declarations inside the canonical :root block.
# Silent overrides (later declaration wins) caused real brand-continuity bugs.
dup_tokens="$(
  first_root_block "$TOKENS_CSS" \
    | grep -oE '^\s*--[A-Za-z0-9_-]+\s*:' \
    | sed -E 's/^[[:space:]]*--([A-Za-z0-9_-]+).*/\1/' \
    | sort | uniq -d
)"
if [[ -n "$dup_tokens" ]]; then
  echo "FAIL: duplicate --token declarations inside canonical :root of $TOKENS_CSS:" >&2
  printf '  --%s\n' $dup_tokens >&2
  fail=1
fi

# Extract --name: value pairs from tokens.css (only the canonical :root block,
# not @media print or prefers-reduced-motion overrides).
first_root_block "$TOKENS_CSS" \
  | grep -E '^\s*--[A-Za-z0-9_-]+\s*:' \
  | sed -E 's/^[[:space:]]*--([A-Za-z0-9_-]+)[[:space:]]*:[[:space:]]*(.*)$/\1=\2/' \
  | while IFS= read -r line; do
      name="${line%%=*}"
      value="${line#*=}"
      norm_value="$(printf '%s' "$value" | normalise)"
      printf '%s|%s\n' "$name" "$norm_value"
    done | sort -u > "$tmp_css"

# Extract $name: value pairs from _tokens.scss.
grep -E '^\s*\$[A-Za-z0-9_-]+\s*:' "$TOKENS_SCSS" \
  | sed -E 's/^[[:space:]]*\$([A-Za-z0-9_-]+)[[:space:]]*:[[:space:]]*(.*)$/\1=\2/' \
  | while IFS= read -r line; do
      name="${line%%=*}"
      value="${line#*=}"
      norm_value="$(printf '%s' "$value" | normalise)"
      printf '%s|%s\n' "$name" "$norm_value"
    done | sort -u > "$tmp_scss"

# Compare: every name present in BOTH must have the same value.
parity_drift="$(
  join -t '|' -j 1 \
    <(sort -t '|' -k1,1 "$tmp_css") \
    <(sort -t '|' -k1,1 "$tmp_scss") \
  | awk -F '|' '$2 != $3 { printf "  %s: css=%s  scss=%s\n", $1, $2, $3 }'
)"

if [[ -n "$parity_drift" ]]; then
  echo "FAIL: token value drift between $TOKENS_CSS and $TOKENS_SCSS:" >&2
  echo "$parity_drift" >&2
  fail=1
fi

# Also surface tokens that exist on only one side (informational; not a hard fail
# because the SCSS mirror can legitimately omit print-only / motion-only tokens
# that have no SCSS-time use).
only_css="$(comm -23 <(cut -d '|' -f1 "$tmp_css" | sort -u) <(cut -d '|' -f1 "$tmp_scss" | sort -u))"
only_scss="$(comm -13 <(cut -d '|' -f1 "$tmp_css" | sort -u) <(cut -d '|' -f1 "$tmp_scss" | sort -u))"
if [[ -n "$only_scss" ]]; then
  echo "FAIL: SCSS variables defined in $TOKENS_SCSS with no matching --* in $TOKENS_CSS:" >&2
  printf '  $%s\n' $only_scss >&2
  fail=1
fi
if [[ -n "$only_css" ]]; then
  echo "INFO: tokens only defined in $TOKENS_CSS (no SCSS mirror):" >&2
  printf '  --%s\n' $only_css >&2
fi

# ---- 2. Hex-grep gate -------------------------------------------------------
#
# tokens.css and _tokens.scss are SOT and MUST contain hex literals — they are
# NOT included in the grep below.
#
# Before grepping each consumer, strip two classes of *legitimate* hex that
# would otherwise be false positives, WITHOUT weakening the gate against a
# genuine stray literal (e.g. `color: #abcdef;`):
#
#   1. CSS block comments (/* ... */, possibly multi-line) — these carry prose
#      like "PR #548" that the grep reads as a 3-digit hex. Comments are blanked
#      out but their newlines are preserved so reported line numbers stay exact.
#   2. Documented fallback values inside var(--token, #hex) — the hex is only a
#      defensive fallback for an already-tokenised reference. Only the hex that
#      immediately follows `var(--name,` is removed; a bare `#hex` anywhere else
#      is still caught.
strip_hex_noise() {
  perl -0777 -pe '
    s{/\*.*?\*/}{ (my $m = $&) =~ tr/\n//cd; $m }ges;
    s/(\bvar\(\s*--[A-Za-z0-9_-]+)\s*,\s*#[0-9a-fA-F]{3,8}\b/$1/g;
  '
}

hex_hits=""
for consumer in "${CONSUMERS[@]}"; do
  consumer_hits="$(strip_hex_noise < "$consumer" \
    | grep -En '#[0-9a-fA-F]{3,8}\b' \
    | sed "s#^#${consumer}:#" || true)"
  if [[ -n "$consumer_hits" ]]; then
    hex_hits+="${consumer_hits}"$'\n'
  fi
done
hex_hits="${hex_hits%$'\n'}"

if [[ -n "$hex_hits" ]]; then
  echo "FAIL: hex color literals found in consumer files (must use var(--*) tokens):" >&2
  echo "$hex_hits" >&2
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "OK: token parity verified and no hex literals in consumer files."
