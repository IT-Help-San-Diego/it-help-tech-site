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
export COMMENT="${COMMENT:-apex-to-www, legacy tag/category redirects, and permanent content withdrawals}"

node infra/cloudfront/build-viewer-request.mjs
node infra/cloudfront/test-viewer-request.mjs

# --- Pre-publish snapshot -------------------------------------------------
# CloudFront keeps no previous live version; publishing overwrites LIVE. Before
# we overwrite, capture exactly what is live now so there is always a record of
# the state this publish replaces. The committed baseline under
# infra/cloudfront/baseline/ is the genesis (pre-withdrawal) rollback target;
# this snapshot is the previous-good target for whatever we are about to change.
#
# FAIL-CLOSED: an unreadable LIVE function must stop the publish, not warn and
# continue. The only legitimate no-snapshot case is a function that verifiably
# does not exist (NoSuchFunction); any other get-function failure (missing
# permission, throttling, network) aborts BEFORE the function is overwritten,
# because publishing without the safety snapshot is exactly the incident the
# snapshot exists to undo.
SNAPSHOT_DIR="${SNAPSHOT_DIR:-infra/cloudfront/baseline}"
SNAPSHOT_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SNAPSHOT_PATH="$SNAPSHOT_DIR/${FUNCTION_NAME}.pre-publish.${SNAPSHOT_STAMP}.js"
mkdir -p "$SNAPSHOT_DIR"
if aws cloudfront get-function --name "$FUNCTION_NAME" --stage LIVE "$SNAPSHOT_PATH" >/tmp/ithelp-cloudfront-prepublish-get.json 2>/tmp/ithelp-cloudfront-prepublish-get.err; then
  SNAPSHOT_SHA="$(shasum -a 256 "$SNAPSHOT_PATH" | awk '{print $1}')"
  SNAPSHOT_ETAG="$(python3 -c 'import json;print(json.load(open("/tmp/ithelp-cloudfront-prepublish-get.json"))["ETag"])')"
  printf 'pre-publish snapshot: %s\n' "$SNAPSHOT_PATH"
  printf 'pre-publish sha256:   %s\n' "$SNAPSHOT_SHA"
  printf 'pre-publish ETag:     %s\n' "$SNAPSHOT_ETAG"
  printf 'rollback target (previous-good): %s\n' "$SNAPSHOT_PATH"
elif grep -qiE 'NoSuchFunction|FunctionNotFound|not found' /tmp/ithelp-cloudfront-prepublish-get.err; then
  printf 'no LIVE function named %s (first publish) — genesis baseline remains the rollback target\n' "$FUNCTION_NAME"
else
  echo "ERROR: cannot read the LIVE $FUNCTION_NAME function to snapshot it before publishing." >&2
  echo "Publishing without a pre-publish snapshot would leave no previous-good rollback target." >&2
  echo "Fix the get-function failure, then re-run." >&2
  cat /tmp/ithelp-cloudfront-prepublish-get.err >&2
  exit 70
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
  --function-config "{\"Comment\":$(python3 -c 'import json,os;print(json.dumps(os.environ["COMMENT"]))'),\"Runtime\":\"cloudfront-js-2.0\"}" \
  --function-code "fileb://$CODE_PATH" \
  >/tmp/ithelp-cloudfront-function-update.json

# The Comment is passed as JSON (not shorthand Key=Val,Key=Val): the default
# comment contains commas, and the shorthand parser splits on every comma,
# turning Comment into a list and failing ParamValidation. JSON is comma-safe.

PUBLISH_ETAG=$(python3 - <<'PY'
import json
print(json.load(open('/tmp/ithelp-cloudfront-function-update.json'))['ETag'])
PY
)

aws cloudfront publish-function \
  --name "$FUNCTION_NAME" \
  --if-match "$PUBLISH_ETAG" \
  >/tmp/ithelp-cloudfront-function-publish.json

# PublishFunction's response contains only FunctionSummary — there is NO
# top-level ETag field (unlike UpdateFunction). Reading j['ETag'] here would
# KeyError-crash the script AFTER the publish already succeeded, aborting the
# deploy before any page uploads. Report from FunctionSummary instead.
python3 - <<'PY'
import json
j=json.load(open('/tmp/ithelp-cloudfront-function-publish.json'))
s=j['FunctionSummary']
print('published', s['Name'], s['Status'])
PY
