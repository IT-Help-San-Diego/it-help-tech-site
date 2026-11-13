#!/usr/bin/env node
// Extract each field note's reference list into data/field-note-citations.json,
// the source of the schema.org `citation` array in the note's Article JSON-LD
// (templates/partials/_jsonld.html).
//
// The reference list in the note (its footnote definitions) stays the single
// source of truth; this file is derived from it. Run from the repo root:
//   node infra/citations/extract-citations.mjs           write the data file
//   node infra/citations/extract-citations.mjs --check   exit 1 if it is stale
// CI runs --check on pull requests (.github/workflows/llms-validate.yml).
//
// What counts as a citation: every distinct http(s) URL, and every site-root
// document link (/...pdf, /...bib), inside a footnote definition, except
// ORCID profiles (an author identifier, not a cited work) and links into
// /corrections/ (a correction record, not a source). One CreativeWork per URL;
// the first URL of a footnote carries the footnote's text as its name.
// Dependency-free and deterministic: same input, same bytes.

import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const REPO_ROOT = process.cwd();
const NOTES_DIR = path.join(REPO_ROOT, "content/field-notes");
const OUT = path.join(REPO_ROOT, "data/field-note-citations.json");
const SITE_CONFIG = path.join(REPO_ROOT, "config.toml");
// Notes whose markup stays as it is until their rebuild ships.
const EXCLUDE = new Set(["bug-bounty-programs-are-a-corporate-controlled-casino.md"]);

function die(msg) {
  console.error(`[extract-citations] ERROR: ${msg}`);
  process.exit(1);
}

function baseUrl() {
  const m = fs.readFileSync(SITE_CONFIG, "utf8").match(/^base_url\s*=\s*"([^"]+)"/m);
  if (!m) die("config.toml has no base_url");
  return m[1].replace(/\/$/, "");
}

function bodyOf(raw, file) {
  const lines = raw.split(/\r?\n/);
  const delim = lines[0];
  if (delim !== "---" && delim !== "+++") die(`${file}: no front matter`);
  const end = lines.indexOf(delim, 1);
  if (end === -1) die(`${file}: front matter not closed`);
  return lines.slice(end + 1);
}

// Plain-text name for a reference: the text before its first link, with
// markdown emphasis and code marks removed and trailing link labels trimmed.
function nameOf(text) {
  let s = text.split(/<https?:\/\/|\]\(|\[[^\]]*\]\(|https?:\/\//)[0];
  s = s.replace(/\[([^\]]+)\]\([^)]*\)/g, "$1").replace(/[*`]/g, "").replace(/\s+/g, " ").trim();
  const tail = /\s*(?:DOI|PDF|Docket via CourtListener|Library of Congress catalog record(?: for the \d{4} edition)?|Retrieved [^.]*?, from|Available at|URL)\s*:?\s*$/i;
  for (let i = 0; i < 3; i++) s = s.replace(tail, "").trim();
  return s.replace(/[\s,;:(]+$/, "").trim();
}

function urlsOf(text, base) {
  const found = [];
  const add = (u) => {
    u = u.replace(/[.,;:]+$/, "");
    if (u.startsWith("/")) {
      if (u.startsWith("/corrections/")) return;
      if (!/\.(pdf|bib)$/i.test(u)) return;
      u = base + u;
    }
    if (/^https?:\/\/orcid\.org\//i.test(u)) return;
    if (!found.includes(u)) found.push(u);
  };
  // Autolinks <https://...>, markdown links [x](url) and bare URLs, in the
  // order they appear, so the first URL is the one the footnote's text names.
  const token = /<(https?:\/\/[^>\s]+)>|\[[^\]]*\]\((\S+?)\)|(https?:\/\/[^\s<>)\]]+)/g;
  for (const m of text.matchAll(token)) add((m[1] ?? m[2] ?? m[3]).replace(/^<|>$/g, ""));
  return found;
}

function extract() {
  const base = baseUrl();
  const notes = {};
  const files = fs.readdirSync(NOTES_DIR).filter((f) => f.endsWith(".md") && f !== "_index.md" && !EXCLUDE.has(f)).sort();
  for (const f of files) {
    const lines = bodyOf(fs.readFileSync(path.join(NOTES_DIR, f), "utf8"), f);
    const cites = [];
    const seen = new Set();
    for (let i = 0; i < lines.length; i++) {
      const m = lines[i].match(/^\[\^([^\]]+)\]:\s*(.*)$/);
      if (!m) continue;
      if (i + 1 < lines.length && /^ {4}\S/.test(lines[i + 1])) die(`${f}: footnote [^${m[1]}] continues on an indented line; extend the extractor before relying on it`);
      const urls = urlsOf(m[2], base);
      urls.forEach((url, k) => {
        if (seen.has(url)) return;
        seen.add(url);
        const entry = { url };
        if (k === 0) {
          const name = nameOf(m[2]);
          if (name) entry.name = name;
        }
        cites.push(entry);
      });
    }
    notes[`/field-notes/${f.replace(/\.md$/, "")}/`] = cites;
  }
  return JSON.stringify({ generated_by: "infra/citations/extract-citations.mjs", notes }, null, 2) + "\n";
}

const next = extract();
if (process.argv.includes("--check")) {
  const prev = fs.existsSync(OUT) ? fs.readFileSync(OUT, "utf8") : "";
  if (prev !== next) die("data/field-note-citations.json is stale: run `node infra/citations/extract-citations.mjs` and commit the result");
  console.error("[extract-citations] data/field-note-citations.json is current");
} else {
  fs.writeFileSync(OUT, next, "utf8");
  const n = Object.values(JSON.parse(next).notes).reduce((a, c) => a + c.length, 0);
  console.error(`[extract-citations] wrote data/field-note-citations.json (${n} citations)`);
}
