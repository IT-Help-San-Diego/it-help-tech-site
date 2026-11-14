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

That file is the rollback target if the extended viewer-request function misbehaves.

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

Expected time to take effect: CloudFront Function publishes are normally fast, but verify with live `curl` output rather than assuming propagation.

## Deploy-day rule

On the day the Real Bot withdrawal redirects are published, verify unaffected paths first:

1. `https://www.it-help.tech/` → 200
2. `https://www.it-help.tech/services/` → 200
3. `https://www.it-help.tech/corrections/` → 200

Only after those pass should the withdrawal redirects be tested. Then run the HSTS/CSP/header checks.
