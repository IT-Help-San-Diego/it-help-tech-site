# CloudFront viewer-request function rollback

This site has one viewer-request CloudFront Function attached to the default behavior:

- Function name: `apex-redirect-to-www`
- Distribution: `EQ3CZ9QIS55YX`
- Purpose before the Real Bot withdrawal: apex-to-www redirect, legacy `/blog/tag/*` redirects, legacy `/blog/category/*` redirects, and pretty-URL `index.html` rewriting.

CloudFront Function live code is not versioned by CloudFront. Publishing a new function overwrites the live copy. A GitHub revert changes the repository only; it does not roll back the function already running at the edge unless a deploy publishes replacement code.

## Baseline saved before PR #707 can publish

The live function source was captured from CloudFront before the Real Bot withdrawal redirect tooling was published:

- Baseline file: `infra/cloudfront/baseline/apex-redirect-to-www.live-20261113.js`
- SHA-256: `81fba1682643320787cf1bf06bdfd08f8824c05eb694a836575a1252f7311b27`
- CloudFront ETag at capture: `E3JWKAKR8XB7XF`
- Runtime at capture: `cloudfront-js-2.0` (the rollback script republishes this same runtime)

That file is the **genesis** rollback target — the pre-withdrawal state. In addition, `deploy-viewer-request.sh` writes a timestamped `*.pre-publish.*.js` snapshot into the same directory every time it publishes, so there is always a **previous-good** target for the most recent change, not only the genesis state.

The rollback script's `--dry-run` reports whether the live function still matches the genesis baseline. If it reports drift, roll back to the matching pre-publish snapshot instead of the genesis baseline, or you will also revert the later (intended) changes.

## Who runs rollback

Hermes runs rollback, because Hermes owns AWS/CloudFront operations for this site. Carey gives the go if this is not an obvious production incident.

## Dry-run check

```bash
cd ~/GitHub/it-help-tech-site
infra/cloudfront/rollback-viewer-request.sh --dry-run
```

Dry-run verifies the baseline checksum and reads the current CloudFront function metadata. It does not mutate CloudFront.

## Execute rollback

```bash
cd ~/GitHub/it-help-tech-site
infra/cloudfront/rollback-viewer-request.sh --execute
```

The script updates the function's DEVELOPMENT copy with the saved baseline and publishes it to LIVE.

## After rollback

Immediately verify the site edge:

```bash
cd ~/GitHub/it-help-tech-site
infra/cloudfront/verify-live-headers.sh
```

Expected time to take effect: a CloudFront Function publish propagates to all edge locations in well under a minute (typically a few seconds), because function code is distributed through the CloudFront control plane, not the cache. This is the whole reason the script exists: the alternative — reverting the commit and waiting for a full deploy cycle (`git` revert → build → S3 sync → `/*` invalidation) — takes several minutes, during which a fault that returns errors affects every visitor. Do not assume propagation; confirm with live `curl` output.

## Testing the execute path safely (before the day it is needed)

The `--execute` path has two real AWS mutations (`update-function`, `publish-function`) that must be exercised once before a real incident, per the rollback requirement. Do this against a throwaway function name, never the live one:

```bash
cd ~/GitHub/it-help-tech-site
# create a disposable function from the same baseline
aws cloudfront create-function \
  --name rollback-drill \
  --function-config 'Comment=rollback drill,Runtime=cloudfront-js-2.0' \
  --function-code fileb://infra/cloudfront/baseline/apex-redirect-to-www.live-20261113.js
# exercise the script against the drill function
FUNCTION_NAME=rollback-drill infra/cloudfront/rollback-viewer-request.sh --execute
# clean up
ETAG=$(aws cloudfront describe-function --name rollback-drill --stage DEVELOPMENT --query ETag --output text)
aws cloudfront delete-function --name rollback-drill --if-match "$ETAG"
```

A disposable function is never associated with the distribution, so this drill cannot affect live traffic.

## Deploy-day rule

On the day the Real Bot withdrawal redirects are published, verify unaffected paths first:

1. `https://www.it-help.tech/` → 200
2. `https://www.it-help.tech/services/` → 200
3. `https://www.it-help.tech/corrections/` → 200

Only after those pass should the withdrawal redirects be tested. Then run the HSTS/CSP/header checks.
