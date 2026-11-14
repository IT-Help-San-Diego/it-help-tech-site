#!/usr/bin/env bash
# Verify live response headers for the corporate site edge.
# This is intentionally separate from the viewer-request function tests: HSTS/CSP
# are response-header-policy concerns, not viewer-request redirect logic.
set -euo pipefail

URLS=(
  "https://www.it-help.tech/"
  "https://www.it-help.tech/corrections/"
  "https://www.it-help.tech/llms-full.txt"
)

for url in "${URLS[@]}"; do
  headers=$(curl -sS -I "$url" | tr -d '\r')
  printf '%s\n' "--- $url"
  printf '%s\n' "$headers" | awk 'BEGIN{IGNORECASE=1} /^HTTP\// || /^strict-transport-security:/ || /^content-security-policy:/ || /^x-frame-options:/ || /^x-content-type-options:/ {print}'
  printf '%s\n' "$headers" | grep -qi '^strict-transport-security: max-age=63072000; includeSubDomains; preload$'
  printf '%s\n' "$headers" | grep -qi '^x-frame-options: DENY$'
  printf '%s\n' "$headers" | grep -qi '^x-content-type-options: nosniff$'
  printf '%s\n' "$headers" | grep -qi '^content-security-policy: .*frame-ancestors '\''none'\''' 
  printf '%s\n' "$headers" | grep -qi '^content-security-policy: .*upgrade-insecure-requests'
done

printf 'live edge response-header checks passed\n'
