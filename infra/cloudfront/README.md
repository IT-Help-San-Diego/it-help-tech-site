# CloudFront security headers

- **csp-policy-v1.json** — canonical policy (CSP + HSTS + nosniff + referrer-policy + permissions-policy).  
- **csp-policy-signatures-v1.json** — policy for hosted email-signature + animation pages (allows inline styles).  
- **csp-policy-v0.json** — baseline snapshot of the CSP before automation changes (for easy rollback).  
- **generate_policy.py** — regenerates CSP hashes from `public/**/*.html`.  
- **update_policy.sh**   — regenerates site CSP hashes, merges in existing CloudFront hashes, then idempotently pushes (fetches current ETag first).
- **update_policy_signatures.sh** — regenerates signature-page CSP hashes and updates the signatures policy (requires `POLICY_ID_SIGNATURES`).
- **restore_policy.sh**  — restores the CloudFront policy from a specific JSON file (defaults to `csp-policy-v0.json`).

## Refresh workflow
1. Build the site so `public/` is current (same as deploy): `zola build`  
2. Update the **site** policy: `./update_policy.sh`  
3. Update the **signature-pages** policy (optional): `POLICY_ID_SIGNATURES=... ./update_policy_signatures.sh`  
4. Invalidate CloudFront: `aws cloudfront create-invalidation --distribution-id E2TEEM88QINCGT --paths "/*"`

## Split policies (recommended)
To keep a strict CSP on the main site **and** keep the hosted signature pages working:

1. Create a separate Response Headers Policy in CloudFront using `csp-policy-signatures-v1.json` (name: `security-headers-signatures`).
2. In each relevant CloudFront distribution, create behaviors for:
   - `ithelp-logo-sig-*`
   and set their **Response headers policy** to `security-headers-signatures`.
3. Keep the default behavior using `security-headers` (site policy).
4. If you want GitHub Actions to update the signatures policy automatically, add repo secret `CF_HEADERS_POLICY_ID_SIGNATURES` with the policy ID.

## Rollback workflow
- Restore the pre-automation policy: `./restore_policy.sh ./csp-policy-v0.json`
