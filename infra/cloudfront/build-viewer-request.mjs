#!/usr/bin/env node
import fs from 'node:fs';

const redirectsPath = 'infra/cloudfront/redirects.json';
const templatePath = 'infra/cloudfront/viewer-request-template.js';
const outPath = 'infra/cloudfront/viewer-request.generated.js';

const redirectsDoc = JSON.parse(fs.readFileSync(redirectsPath, 'utf8'));
const redirects = redirectsDoc.redirects ?? [];
const map = {};

for (const entry of redirects) {
  if (!entry || typeof entry.from !== 'string' || typeof entry.to !== 'string') {
    throw new Error(`invalid redirect entry: ${JSON.stringify(entry)}`);
  }
  if (entry.status !== 301) {
    throw new Error(`only 301 redirects are supported: ${JSON.stringify(entry)}`);
  }
  if (!entry.from.startsWith('/')) throw new Error(`from must be site-relative: ${entry.from}`);
  if (!entry.to.startsWith('/')) throw new Error(`to must be site-relative: ${entry.to}`);
  if (map[entry.from]) throw new Error(`duplicate redirect from ${entry.from}`);
  map[entry.from] = entry.to;
}

const template = fs.readFileSync(templatePath, 'utf8');
if (!template.includes('__REDIRECT_MAP__')) {
  throw new Error(`${templatePath} is missing __REDIRECT_MAP__ placeholder`);
}
const rendered = template.replace('__REDIRECT_MAP__', JSON.stringify(map, null, 2));
fs.writeFileSync(outPath, rendered);
console.log(`wrote ${outPath} with ${Object.keys(map).length} redirects`);
