function handler(event) {
  const req  = event.request;
  const host = req.headers.host.value;
  let   uri  = req.uri;

  /* === 1. Redirect apex → www ==================================== */
  if (host === 'it-help.tech') {
    return {
      statusCode: 301,
      statusDescription: 'Moved Permanently',
      headers: {
        location: { value: 'https://www.it-help.tech' + uri },
        'cache-control': { value: 'public,max-age=300' }
      }
    };
  }

  /* --- Generic redirects for tag & category archives ------------- */
const tagMatch = uri.match(/^\/blog\/tag\/([^\/]+)\/$/);
if (tagMatch) {
  const slug = tagMatch[1];          // e.g. "backup"
  return {
    statusCode: 301,
    statusDescription: 'Moved Permanently',
    headers: {
      location: { value: `/blog/#${slug}` },
      'cache-control': { value: 'public,max-age=300' }
    }
  };
}

const catMatch = uri.match(/^\/blog\/category\/([^\/]+)\/?$/);
if (catMatch) {
  // Categories in old Jekyll URLs use + for spaces; decode them.
  const slug = decodeURIComponent(catMatch[1].replace(/\+/g, ' ').trim())
                .toLowerCase()
                .replace(/\s+/g, '-');  // "Mac Tips" → "mac-tips"
  return {
    statusCode: 301,
    statusDescription: 'Moved Permanently',
    headers: {
      location: { value: `/blog/#${slug}` },
      'cache-control': { value: 'public,max-age=300' }
    }
  };
}

  /* === 3. Append index.html for pretty URLs ====================== */
  if (uri.endsWith('/')) {
    uri += 'index.html';
  } else if (!uri.includes('.') && uri.length > 1) {
    uri += '/index.html';
  }
  req.uri = uri;
  return req;          // fall-through: origin fetch
}