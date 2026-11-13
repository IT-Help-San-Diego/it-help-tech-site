# `llms-full.txt` generator

Auto-generates `llms-full.txt` from `content/*.md` so it never drifts from the live site.

## Why this exists

`llms-full.txt` is a long-form, plain-text mirror of the site for AI/LLM crawlers. Before this generator, it was hand-maintained in `static/llms-full.txt` and drifted badly: at the time the generator was introduced it listed 5 old service pillars when the live page had 7 new ones, and was missing 13+ vendor recommendations. Hand-maintenance did not scale at the editing cadence we run, so the static copy was deleted in Phase C and the generator is now the sole source.

## How it works

1. `infra/llms/build-llms-full.mjs` reads `infra/llms/llms-full.config.json` for the canonical page order, then walks each referenced `content/*.md`.
2. For each page: parses frontmatter (TOML `+++` or YAML `---`, both supported), strips JSON-LD `<script>` blocks, strips HTML comments and `<svg>` blocks, normalizes `<br>`/`<p>`, converts inline `<a>` tags to markdown links, strips remaining HTML conservatively, decodes common HTML entities, strips Zola heading-anchor `{#anchor}` syntax, **demotes in-page headings** so the highest level is at least `####` (nesting under the `### Page Label`), normalizes whitespace including stripping leading-whitespace residue left by stripped inline HTML wrappers like `<h1><span>...</span></h1>`.
   Field notes also get a `Published / Updated / Author` line from their frontmatter, and any published correction notices from `data/corrections.toml`, quoted as they appear above the page body. The `{{ corrections_index() }}` shortcode on `content/corrections.md` is rendered from the same register. Markdown autolinks (`<https://...>`) are kept as links (they are not HTML tags), `picture_simple` keeps its alt text like `picture`, and root-relative links are made absolute because the file is read off-site. Page descriptions are deliberately not emitted.
3. Writes the assembled output to `build/llms-full.txt` (UTF-8, LF line endings, deterministic — same input always produces the same output, byte-for-byte).
4. Deploy uploads `build/llms-full.txt` directly to S3 with a 1-hour TTL plus `stale-while-revalidate=86400`.

The script has zero dependencies beyond Node stdlib.

## Local usage

```bash
# Print to stdout without writing (debugging):
node infra/llms/build-llms-full.mjs --dry-run

# Write to build/llms-full.txt:
node infra/llms/build-llms-full.mjs

# Convenience preview (regenerate + show stats + first 60 lines):
scripts/preview-llms-full.sh

# Same, but cat the full file:
scripts/preview-llms-full.sh --full

# Same, but diff against the previous run:
scripts/preview-llms-full.sh --diff
```

`zola serve` cannot serve `/llms-full.txt` locally — `static/llms-full.txt`
was deleted in Phase C and must not be reintroduced (see Phase C above and
the LLM/bot files note in `AGENTS.md`). Use `scripts/preview-llms-full.sh`
to inspect the generator output instead. On deploy the file is uploaded
directly from `build/llms-full.txt` to S3.

## Config: `llms-full.config.json`

- `tagline` — short site tagline used in the header preamble.
- `main` / `optional` — section arrays. Each section has a `heading` and an `entries` list.
- Each entry is one of:
  - **File-backed**: `{ "label": "...", "file": "content/path.md" }`. Label and source URL are derived from config + file path; body comes from the page.
  - **Link-only**: `{ "label": "...", "url": "https://...", "description": "..." }`. For external destinations like the booking subdomain that have no markdown source.

### Per-page label override

If a content author wants the LLM-facing label to differ from the page `<title>`, they can add `extra.llms_label = "..."` to the page frontmatter. Config wins if both are set; otherwise frontmatter wins; otherwise page title.

## CI integration

- **PR validation** (`.github/workflows/llms-validate.yml`): runs the generator on every PR that touches `content/`, `infra/llms/`, or `config.toml`. Uploads the generated file as a workflow artifact so reviewers can download and inspect the LLM-facing copy before merge.
- **Deploy** (`.github/workflows/deploy.yml`): regenerates after `zola build` and before the S3 upload. Fail-closed — if the generator throws, the deploy stops and no `llms-*` file is uploaded that run.

## Failure runbook

| Symptom | Cause | Fix |
| --- | --- | --- |
| Deploy fails at "Generate llms-full.txt from content/" with `frontmatter missing required 'title'` | A content file is missing `title` in its frontmatter | Add the `title` field to the offending file (the error message names the file). Push fix; re-run deploy. |
| Same step fails with `config references missing file: …` | A renamed/moved `content/*.md` left a stale entry in `llms-full.config.json` | Update the `file` path in the config. Push fix. |
| Same step fails with `duplicate label in config: …` or `duplicate URL in config: …` | Two entries collide | Rename one of the labels, or remove the duplicate entry. |
| Same step warns `stripped N unrecognized HTML tag(s)` but doesn't fail | A page added an HTML construct the conservative stripper doesn't know about | Inspect `build/llms-full.txt` (or the PR validation artifact) to confirm output is acceptable. Extend the recognized-tag list in `transformBody()` if needed. |
| `llms-full.txt` on production looks stale 1+ hour after deploy | CloudFront edge cache | Cache-control is `max-age=3600`; wait an hour or invalidate `/llms-full.txt` via CloudFront. |
| Need to roll back to the prior hand-maintained file | Generator producing wrong output and we need a hotfix | Revert the PR that introduced the bad config/generator change, OR temporarily restore a known-good `build/llms-full.txt` to the deploy artifact. The hand-maintained `static/llms-full.txt` no longer exists (Phase C complete) — `git show` an earlier commit if you need a reference copy. |

## Rollout plan (complete)

- **Phase A** (PR #549): Added generator + config + PR-validate workflow + deploy.yml updates (output path + cache-control). `static/llms-full.txt` stayed in repo as fallback. Deploy proved the generator works against production.
- **Phase B**: Inspected generator output vs the prior hand-maintained file, tuned config/labels until parity was satisfactory.
- **Phase C** (PR #622): Deleted `static/llms-full.txt`. Generator is now the sole source of truth for `/llms-full.txt`.

## Known limitations

- **Heading demotion is regex-based, not code-fence-aware.** If a content page introduces a fenced code block whose lines start with `#`, `##`, etc. (e.g., a Bash or Python comment), the demoter will treat them as headings and shift them. Current configured pages contain no such content. If this becomes an issue, make the demoter walk the body and skip lines inside fenced (` ``` `) regions.
- **`<h1><span>...</span></h1>` and similar inline-wrapper hero markup**: text content survives, but original layout is flattened — multi-line spans collapse onto separate plain-text lines.

## Out of scope

- `llms.txt` (short nav index) stays hand-maintained — it's stable and not the drift source.
- `sitemap.xml` is auto-generated by Zola; no changes here.
- Schema (JSON-LD) is in markdown files and rebuilt by Zola; no changes here.
