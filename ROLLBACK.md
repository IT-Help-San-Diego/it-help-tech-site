# Rollback Cheat Sheet (it-help-tech-site)

## Quick code rollback (Git)

Run from repo root:

```
git checkout main
git pull
```

Revert individual changes (pick what you need):

- KaTeX cleanup (PR #391):  
  `git revert 80eee13 && git push`

- Workflow validation fix (PR #390):  
  `git revert 88392a9 && git push`

- CSP split + CloudFront policy automation (PR #389):  
  `git revert dbeee69 && git push`

- Earlier deploy workflow changes (PR #388):  
  `git revert dbefe14 && git push`

> Tip: If you need to roll back multiple commits, revert in **reverse order** (newest → oldest).

---

## CloudFront CSP rollback (headers policy)

### Site policy (strict CSP)
Restore the saved baseline snapshot:

```
cd infra/cloudfront
POLICY_ID="YOUR_SITE_POLICY_ID" ./restore_policy.sh ./csp-policy-v0.json
```

### Signature policy
If you want to revert signatures to the old policy:

1. In CloudFront, update the **behavior** for signature pages to use the previous response headers policy.
2. (Optional) If you have a saved JSON snapshot for that policy, you can restore it by setting `POLICY_ID` to the **signature policy ID** and running `restore_policy.sh` with that file.

---

## After any rollback

1. Watch `Actions → deploy.yml` on `main` until it is green.
2. (Optional) Invalidate CloudFront:
   - `/ithelp-logo-sig-*`
   - `/*` (only if you need instant global refresh)
3. Verify headers:

```
curl -I https://it-help.tech/ | grep -i content-security-policy
curl -I https://it-help.tech/ithelp-logo-sig-research.html | grep -i content-security-policy
```

---

## Notes

- You need AWS permissions for:
  - `cloudfront:GetResponseHeadersPolicy`
  - `cloudfront:UpdateResponseHeadersPolicy`
- All rollbacks are safe to undo later by re‑merging or reverting the revert commit.
