#!/usr/bin/env bash
# Roll back the corporate-site CloudFront viewer-request function to the saved
# pre-withdrawal baseline.
#
# Default mode is dry-run: it verifies the saved baseline and prints the action.
# Use --execute only during an incident or an approved rollback drill.
set -euo pipefail

FUNCTION_NAME="${FUNCTION_NAME:-apex-redirect-to-www}"
BASELINE_PATH="${BASELINE_PATH:-infra/cloudfront/baseline/apex-redirect-to-www.live-20261113.js}"
BASELINE_SHA256="81fba1682643320787cf1bf06bdfd08f8824c05eb694a836575a1252f7311b27"
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
  --function-config "Comment=$COMMENT,Runtime=cloudfront-js-2.0" \
  --function-code "fileb://$BASELINE_PATH" \
  >/tmp/ithelp-cloudfront-function-rollback-update.json

PUBLISH_ETAG=$(python3 - <<'PY'
import json
print(json.load(open('/tmp/ithelp-cloudfront-function-rollback-update.json'))['ETag'])
PY
)

aws cloudfront publish-function \
  --name "$FUNCTION_NAME" \
  --if-match "$PUBLISH_ETAG" \
  >/tmp/ithelp-cloudfront-function-rollback-publish.json

python3 - <<'PY'
import json
j=json.load(open('/tmp/ithelp-cloudfront-function-rollback-publish.json'))
print('published rollback', j['FunctionSummary']['Name'], j['FunctionSummary']['Status'], j['ETag'])
PY

echo "Rollback published. Verify immediately:"
echo "  infra/cloudfront/verify-live-headers.sh"
