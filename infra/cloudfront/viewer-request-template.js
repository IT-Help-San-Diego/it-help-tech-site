function handler(event) {
  var req = event.request;
  var host = req.headers.host.value;
  var uri = req.uri;

  var redirects = __REDIRECT_MAP__;
  if (redirects[uri]) {
    return movedPermanently('https://www.it-help.tech' + redirects[uri]);
  }

  /* === 1. Redirect apex -> www ==================================== */
  if (host === 'it-help.tech') {
    return movedPermanently('https://www.it-help.tech' + uri);
  }

  /* --- Generic redirects for tag & category archives ------------- */
  var tagMatch = uri.match(/^\/blog\/tag\/([^\/]+)\/$/);
  if (tagMatch) {
    var tagSlug = tagMatch[1];
    return movedPermanently('/blog/#' + tagSlug);
  }

  var catMatch = uri.match(/^\/blog\/category\/([^\/]+)\/?$/);
  if (catMatch) {
    var catSlug = decodeURIComponent(catMatch[1].replace(/\+/g, ' ').trim())
      .toLowerCase()
      .replace(/\s+/g, '-');
    return movedPermanently('/blog/#' + catSlug);
  }

  /* === 3. Append index.html for pretty URLs ====================== */
  if (uri.endsWith('/')) {
    uri += 'index.html';
  } else if (!uri.includes('.') && uri.length > 1) {
    uri += '/index.html';
  }
  req.uri = uri;
  return req;
}

function movedPermanently(location) {
  return {
    statusCode: 301,
    statusDescription: 'Moved Permanently',
    headers: {
      location: { value: location },
      'cache-control': { value: 'public,max-age=300' }
    }
  };
}
