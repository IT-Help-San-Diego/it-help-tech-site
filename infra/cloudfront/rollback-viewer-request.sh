#!/usr/bin/env bash
# Roll back the corporate-site CloudFront viewer-request function to the saved
# pre-withdrawal baseline.
#
# Default mode is dry-run: it verifies the saved baseline and prints the action.
# Use --execute only during an incident or an approved rollback drill.
set -euo pipefail

FUNCTION_NAME="${FUNCTION_NAME:-apex-redirect-to-www}"
BASELINE_PATH="${BASELINE_PATH:-infra/cloudfront/baseline/apex-redirect-to-www.live-20261113.js}"
BASELINE_SHA256="${BASELINE_SHA256:-81fba1682643320787cf1bf06bdfd08f8824c05eb694a836575a1252f7311b27}"
COMMENT="${COMMENT:-ROLLBACK: apex redirect and legacy blog redirects baseline captured 2026-11-13}"
MODE="${1:---dry-run}"

if [[ "$MODE" != "--dry-run" && "$MODE" != "--execute" ]]; then
  echo "usage: $0 [--dry-run|--execute]" >&2
  exit 64
fi

actual_sha=$(shasum -a 256 "$BASELINE_PATH" | awk '{print $1}')
if [[ "$actual_sha" != "$BASELINE_SHA256" ]]; then
  echo "baseline checksum mismatch for $BASELINE_PATH" >&2
  echo "expected $BASELINE_SHA256" >&2
  echo "actual   $actual_sha" >&2
  exit 65
fi

printf 'baseline ok: %s  %s\n' "$actual_sha" "$BASELINE_PATH"
printf 'target function: %s\n' "$FUNCTION_NAME"

if [[ "$MODE" == "--dry-run" ]]; then
  aws cloudfront describe-function --name "$FUNCTION_NAME" --stage LIVE \
    --query '{Name:FunctionSummary.Name,Status:FunctionSummary.Status,ETag:ETag,Comment:FunctionSummary.FunctionConfig.Comment}' \
    --output json

  # Drift check: is the committed baseline still identical to what is live?
  # If a later publish changed the function, rolling back to this baseline would
  # also revert those later changes — the operator must know that before running
  # --execute. We compare the live code bytes to the saved baseline bytes.
  LIVE_TMP="$(mktemp "${TMPDIR:-/tmp}/ithelp-live-fn.XXXXXX.js")"
  if aws cloudfront get-function --name "$FUNCTION_NAME" --stage LIVE "$LIVE_TMP" >/dev/null 2>&1; then
    live_sha=$(shasum -a 256 "$LIVE_TMP" | awk '{print $1}')
    if [[ "$live_sha" == "$BASELINE_SHA256" ]]; then
      echo "drift check: live function MATCHES this baseline — rollback restores the current state (no-op)"
    else
      echo "drift check: live function DIFFERS from this baseline"
      echo "  live     $live_sha"
      echo "  baseline $BASELINE_SHA256"
      echo "  rollback would revert the live function to the baseline, discarding any changes published since capture."
      echo "  if the live function is a known-good later version, roll back to the matching pre-publish snapshot in $(dirname "$BASELINE_PATH")/ instead."
    fi
  else
    echo "drift check: could not read live function (permissions or missing function)"
  fi
  rm -f "$LIVE_TMP"

  echo "dry-run only; pass --execute to update and publish the saved baseline"
  exit 0
fi

# CloudFront Functions update the DEVELOPMENT copy first, then publish it to LIVE.
# Prefer the DEVELOPMENT ETag; fall back to LIVE if no DEVELOPMENT copy exists.
ETAG=$(aws cloudfront describe-function \
  --name "$FUNCTION_NAME" \
  --stage DEVELOPMENT \
  --query 'ETag' \
  --output text 2>/dev/null || true)

if [[ -z "$ETAG" || "$ETAG" == "None" ]]; then
  ETAG=$(aws cloudfront describe-function \
    --name "$FUNCTION_NAME" \
    --stage LIVE \
    --query 'ETag' \
    --output text)
fi

aws cloudfront update-function \
  --name "$FUNCTION_NAME" \
  --if-match "$ETAG" \
  --function-config "{\"Comment\":$(COMMENT="$COMMENT" python3 -c 'import json,os;print(json.dumps(os.environ["COMMENT"]))'),\"Runtime\":\"cloudfront-js-2.0\"}" \
  --function-code "fileb://$BASELINE_PATH" \
  >/tmp/ithelp-cloudfront-function-rollback-update.json

# JSON --function-config: the rollback comment contains commas, which the
# shorthand Key=Val,Key=Val parser would split into a list (ParamValidation).

PUBLISH_ETAG=$(python3 - <<'PY'
import json
print(json.load(open('/tmp/ithelp-cloudfront-function-rollback-update.json'))['ETag'])
PY
)

aws cloudfront publish-function \
  --name "$FUNCTION_NAME" \
  --if-match "$PUBLISH_ETAG" \
  >/tmp/ithelp-cloudfront-function-rollback-publish.json

# PublishFunction returns only FunctionSummary (no top-level ETag). Reading
# j['ETag'] here would crash AFTER the rollback already published — the worst
# possible moment. Report from FunctionSummary.
python3 - <<'PY'
import json
j=json.load(open('/tmp/ithelp-cloudfront-function-rollback-publish.json'))
s=j['FunctionSummary']
print('published rollback', s['Name'], s['Status'])
PY

echo "Rollback published. Verify immediately:"
echo "  infra/cloudfront/verify-live-headers.sh"
