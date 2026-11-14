#!/usr/bin/env node
import fs from 'node:fs';
import vm from 'node:vm';

const codePath = 'infra/cloudfront/viewer-request.generated.js';
const redirectsPath = 'infra/cloudfront/redirects.json';
const code = fs.readFileSync(codePath, 'utf8') + '\nhandler(event);';

function run(host, uri) {
  const event = { request: { uri, headers: { host: { value: host } } } };
  const context = { event };
  return vm.runInNewContext(code, context, { filename: codePath });
}

function assertEqual(actual, expected, label) {
  if (actual !== expected) {
    throw new Error(`${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

// --- Data-driven redirect-table assertions ---------------------------------
// The test's expected redirect values come from redirects.json, the SAME
// source build-viewer-request.mjs compiles into the function. Hardcoding the
// expected location (previously '#c-yyyymmdd-01') pinned the test to the
// placeholder state, which the deploy gate forbids publishing — so the test
// and the gate could never both be satisfied. Deriving the expectations here
// keeps the test correct for every table state (empty, placeholder, stamped)
// and consistent with the gate instead of contradicting it.
const redirectsDoc = JSON.parse(fs.readFileSync(redirectsPath, 'utf8'));
const redirects = redirectsDoc.redirects ?? [];
for (const entry of redirects) {
  const r = run('www.it-help.tech', entry.from);
  assertEqual(r.statusCode, 301, `redirect status for ${entry.from}`);
  assertEqual(
    r.headers.location.value,
    'https://www.it-help.tech' + entry.to,
    `redirect location for ${entry.from}`
  );
}
console.log(`checked ${redirects.length} table redirect(s) against redirects.json`);

// --- Structural rules (hardcoded in the template, not in the table) --------
// apex -> www (uri preserved, no pretty-URL append on the apex branch)
let r = run('it-help.tech', '/privacy/');
assertEqual(r.statusCode, 301, 'apex status');
assertEqual(r.headers.location.value, 'https://www.it-help.tech/privacy/', 'apex location');

r = run('it-help.tech', '/');
assertEqual(r.statusCode, 301, 'apex root status');
assertEqual(r.headers.location.value, 'https://www.it-help.tech/', 'apex root location');

// legacy tag / category archives
r = run('www.it-help.tech', '/blog/tag/dns/');
assertEqual(r.statusCode, 301, 'tag status');
assertEqual(r.headers.location.value, '/blog/#dns', 'tag location');
assertEqual(r.headers['cache-control'].value, 'public,max-age=300', 'tag cache-control');

r = run('www.it-help.tech', '/blog/category/Mac+Tips');
assertEqual(r.statusCode, 301, 'category status');
assertEqual(r.headers.location.value, '/blog/#mac-tips', 'category location');

// pretty-URL rewriting (NOT a redirect — the request falls through)
r = run('www.it-help.tech', '/corrections/');
assertEqual(r.statusCode, undefined, 'pretty URL /corrections/ must not redirect');
assertEqual(r.uri, '/corrections/index.html', 'pretty URL /corrections/');

r = run('www.it-help.tech', '/about');
assertEqual(r.statusCode, undefined, 'pretty URL /about must not redirect');
assertEqual(r.uri, '/about/index.html', 'pretty URL /about');

// --- Fall-through guarantees (Science's main concern + the home-page breaker)
// The home page must pass through to /index.html, never redirect. A mutation
// that redirects '/' takes down the whole site; this pins it.
r = run('www.it-help.tech', '/');
assertEqual(r.statusCode, undefined, 'home page must not redirect');
assertEqual(r.uri, '/index.html', 'home page rewrites to /index.html');

// A deep path not in the table passes through with pretty-URL append.
r = run('www.it-help.tech', '/services/pricing');
assertEqual(r.statusCode, undefined, 'unmapped deep path must not redirect');
assertEqual(r.uri, '/services/pricing/index.html', 'unmapped deep path rewrites');

// A file with an extension passes through UNCHANGED (no append, no redirect).
r = run('www.it-help.tech', '/robots.txt');
assertEqual(r.statusCode, undefined, 'static file must not redirect');
assertEqual(r.uri, '/robots.txt', 'static file uri unchanged');

// A www path that merely RESEMBLES a withdrawal URL but is not in the table
// must fall through, proving only exact table entries redirect.
r = run('www.it-help.tech', '/field-notes/some-other-note/');
assertEqual(r.statusCode, undefined, 'unmapped field-note must not redirect');
assertEqual(r.uri, '/field-notes/some-other-note/index.html', 'unmapped field-note rewrites');

console.log('viewer-request function tests passed');
