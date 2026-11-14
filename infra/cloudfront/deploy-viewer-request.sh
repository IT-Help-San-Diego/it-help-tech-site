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
