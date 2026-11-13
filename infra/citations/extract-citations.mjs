#!/usr/bin/env node
// Extract each field note's reference list into data/field-note-citations.json,
// the source of the schema.org `citation` array in the note's Article JSON-LD
// (templates/partials/_jsonld.html).
//
// The reference list in the note (its footnote definitions) stays the single
// source of truth; this file is derived from it. Run from the repo root:
//   node infra/citations/extract-citations.mjs           write the data file
//   node infra/citations/extract-citations.mjs --check   exit 1 if it is stale
// CI runs --check on pull requests (.github/workflows/llms-validate.yml) and
// the deploy runs it before the site is built (.github/workflows/deploy.yml).
//
// Each citation is the reference exactly as the note's author wrote it, as
// plain text: Markdown marks removed, every link written out as its full URL
// in place. Nothing is paired with anything (no "name" attached to a "url"),
// so a reference that names one work and links a page about it cannot come
// out mislabelled. If the note's reference is wrong, fix the note.
// Dependency-free and deterministic: same input, same bytes.

import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const REPO_ROOT = process.cwd();
const NOTES_DIR = path.join(REPO_ROOT, "content/field-notes");
const OUT = path.join(REPO_ROOT, "data/field-note-citations.json");
const SITE_CONFIG = path.join(REPO_ROOT, "config.toml");
// Notes left out: one stays as it is until its rebuild ships, one is being
// withdrawn. A name here that matches no file is harmless.
const EXCLUDE = new Set([
  "bug-bounty-programs-are-a-corporate-controlled-casino.md",
  "the-real-bot-hasnt-been-built-yet.md",
]);
const DEF = /^\[\^([^\]]+)\]:\s*(.*)$/;

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

const absolute = (url, base) => (url.startsWith("/") && !url.startsWith("//") ? base + url : url);

// Write out every Markdown link in `text` as plain text with its full URL.
// Link destinations follow CommonMark: balanced parentheses, optional <...>.
function linksToText(text, base, where) {
  let out = "";
  let i = 0;
  while (i < text.length) {
    // Autolink <scheme:...>
    if (text[i] === "<") {
      const m = text.slice(i).match(/^<((?:https?:\/\/|mailto:)[^<>\s]+)>/);
      if (m) { out += m[1]; i += m[0].length; continue; }
    }
    // Inline link [label](destination)
    if (text[i] === "[") {
      const close = text.indexOf("](", i);
      const nextOpen = text.indexOf("[", i + 1);
      if (close !== -1 && (nextOpen === -1 || nextOpen > close)) {
        let j = close + 2, depth = 1;
        while (j < text.length && depth > 0) {
          if (text[j] === "(") depth++;
          else if (text[j] === ")") depth--;
          if (depth > 0) j++;
        }
        if (depth !== 0) die(`${where}: unbalanced link destination near "${text.slice(i, i + 40)}"`);
        const label = text.slice(i + 1, close).replace(/[*`]/g, "").trim();
        let dest = text.slice(close + 2, j).trim().replace(/^<|>$/g, "");
        if (/\s/.test(dest)) die(`${where}: link destination with a title or space is not supported: "${dest}"`);
        dest = absolute(dest, base);
        out += label && label !== dest && absolute(label, base) !== dest ? `${label} (${dest})` : dest;
        i = j + 1;
        continue;
      }
    }
    out += text[i++];
  }
  return out;
}

function referenceText(raw, base, where) {
  let s = linksToText(raw, base, where);
  s = s.replace(/[*`]/g, "").replace(/\s+/g, " ").trim();
  if (/\]\(|<https?:\/\/|\[\^/.test(s)) die(`${where}: Markdown left in the reference text: "${s.slice(0, 80)}"`);
  return s;
}

function extract() {
  const base = baseUrl();
  const notes = {};
  const files = fs.readdirSync(NOTES_DIR).filter((f) => f.endsWith(".md") && f !== "_index.md" && !EXCLUDE.has(f)).sort();
  for (const f of files) {
    const lines = bodyOf(fs.readFileSync(path.join(NOTES_DIR, f), "utf8"), f);
    const cites = [];
    const seenLabels = new Set();
    for (let i = 0; i < lines.length; i++) {
      const m = lines[i].match(DEF);
      if (!m) continue;
      const where = `${f} [^${m[1]}]`;
      if (seenLabels.has(m[1])) die(`${where}: footnote label defined twice`);
      seenLabels.add(m[1]);
      // A definition must be one line: stop on every continuation form
      // (a lazy line right after it, or an indented line after a blank one)
      // rather than silently dropping part of a reference.
      const next = lines[i + 1] ?? "";
      if (next.trim() !== "" && !DEF.test(next)) die(`${where}: the definition continues on the next line; keep each reference on one line or extend the extractor`);
      if (next.trim() === "" && /^( {4}|\t)\S/.test(lines[i + 2] ?? "")) die(`${where}: the definition continues in an indented paragraph; keep each reference on one line or extend the extractor`);
      if (!m[2].trim()) die(`${where}: empty definition`);
      cites.push(referenceText(m[2], base, where));
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
  console.error(`[extract-citations] wrote data/field-note-citations.json (${n} references)`);
}
