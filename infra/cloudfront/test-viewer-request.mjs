#!/usr/bin/env node
import fs from 'node:fs';
import vm from 'node:vm';

const codePath = 'infra/cloudfront/viewer-request.generated.js';
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

let r = run('www.it-help.tech', '/field-notes/the-real-bot-hasnt-been-built-yet/');
assertEqual(r.statusCode, 301, 'Real Bot note status');
assertEqual(r.headers.location.value, 'https://www.it-help.tech/corrections/#c-yyyymmdd-01', 'Real Bot note location');

r = run('www.it-help.tech', '/field-notes/the-real-bot-hasnt-been-built-yet.pdf');
assertEqual(r.statusCode, 301, 'Real Bot PDF status');
assertEqual(r.headers.location.value, 'https://www.it-help.tech/corrections/#c-yyyymmdd-01', 'Real Bot PDF location');

r = run('www.it-help.tech', '/field-notes/the-real-bot-hasnt-been-built-yet.bib');
assertEqual(r.statusCode, 301, 'Real Bot BibTeX status');
assertEqual(r.headers.location.value, 'https://www.it-help.tech/corrections/#c-yyyymmdd-01', 'Real Bot BibTeX location');

r = run('it-help.tech', '/privacy/');
assertEqual(r.statusCode, 301, 'apex status');
assertEqual(r.headers.location.value, 'https://www.it-help.tech/privacy/', 'apex location');

r = run('www.it-help.tech', '/blog/tag/dns/');
assertEqual(r.statusCode, 301, 'tag status');
assertEqual(r.headers.location.value, '/blog/#dns', 'tag location');

r = run('www.it-help.tech', '/blog/category/Mac+Tips');
assertEqual(r.statusCode, 301, 'category status');
assertEqual(r.headers.location.value, '/blog/#mac-tips', 'category location');

r = run('www.it-help.tech', '/corrections/');
assertEqual(r.uri, '/corrections/index.html', 'pretty URL /corrections/');

r = run('www.it-help.tech', '/about');
assertEqual(r.uri, '/about/index.html', 'pretty URL /about');

console.log('viewer-request function tests passed');
