#!/usr/bin/env bash
# Update the existing CloudFront viewer-request function for it-help.tech.
#
# IMPORTANT:
# CloudFront allows only one function association per event type on a cache
# behavior. The distribution already has viewer-request function
# `apex-redirect-to-www`, so Real Bot redirects must be folded into that
# function. Do not create and attach a second viewer-request function.
#
# Usage:
#   ./infra/cloudfront/deploy-viewer-request.sh
#
# Requires AWS credentials with cloudfront:GetFunction, UpdateFunction,
# PublishFunction. This updates the function object; CloudFront then serves the
# new code through the existing distribution association.
set -euo pipefail

FUNCTION_NAME="${FUNCTION_NAME:-apex-redirect-to-www}"
CODE_PATH="${CODE_PATH:-infra/cloudfront/viewer-request.generated.js}"
COMMENT="${COMMENT:-apex-to-www, legacy tag/category redirects, and permanent content withdrawals}"

node infra/cloudfront/build-viewer-request.mjs
node infra/cloudfront/test-viewer-request.mjs

# --- Pre-publish snapshot -------------------------------------------------
# CloudFront keeps no previous live version; publishing overwrites LIVE. Before
# we overwrite, capture exactly what is live now so there is always a record of
# the state this publish replaces. The committed baseline under
# infra/cloudfront/baseline/ is the genesis (pre-withdrawal) rollback target;
# this snapshot is the previous-good target for whatever we are about to change.
SNAPSHOT_DIR="${SNAPSHOT_DIR:-infra/cloudfront/baseline}"
SNAPSHOT_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SNAPSHOT_PATH="$SNAPSHOT_DIR/${FUNCTION_NAME}.pre-publish.${SNAPSHOT_STAMP}.js"
mkdir -p "$SNAPSHOT_DIR"
if aws cloudfront get-function --name "$FUNCTION_NAME" --stage LIVE "$SNAPSHOT_PATH" >/tmp/ithelp-cloudfront-prepublish-get.json 2>/dev/null; then
  SNAPSHOT_SHA="$(shasum -a 256 "$SNAPSHOT_PATH" | awk '{print $1}')"
  SNAPSHOT_ETAG="$(python3 -c 'import json;print(json.load(open("/tmp/ithelp-cloudfront-prepublish-get.json"))["ETag"])')"
  printf 'pre-publish snapshot: %s\n' "$SNAPSHOT_PATH"
  printf 'pre-publish sha256:   %s\n' "$SNAPSHOT_SHA"
  printf 'pre-publish ETag:     %s\n' "$SNAPSHOT_ETAG"
  printf 'rollback target (previous-good): %s\n' "$SNAPSHOT_PATH"
else
  printf 'warning: no LIVE function to snapshot (first publish?) — genesis baseline remains the rollback target\n'
fi
# ------------------------------------------------------------------------

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
  --function-code "fileb://$CODE_PATH" \
  >/tmp/ithelp-cloudfront-function-update.json

PUBLISH_ETAG=$(python3 - <<'PY'
import json
print(json.load(open('/tmp/ithelp-cloudfront-function-update.json'))['ETag'])
PY
)

aws cloudfront publish-function \
  --name "$FUNCTION_NAME" \
  --if-match "$PUBLISH_ETAG" \
  >/tmp/ithelp-cloudfront-function-publish.json

python3 - <<'PY'
import json
j=json.load(open('/tmp/ithelp-cloudfront-function-publish.json'))
print('published', j['FunctionSummary']['Name'], j['FunctionSummary']['Status'], j['ETag'])
PY
