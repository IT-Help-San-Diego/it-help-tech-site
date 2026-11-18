// render.js <in.svg> <out.png> <width> [background]
// Renders an SVG at a pixel width with resvg-js 2.6.2 (the renderer every published picture of the
// coin was made with). Set RESVG_JS to the folder of @resvg/resvg-js if it is not installed here.
const {Resvg} = require(process.env.RESVG_JS || '@resvg/resvg-js');
const fs = require('fs');
const [,, inp, out, w, bg] = process.argv;
const opts = {fitTo: {mode: 'width', value: parseInt(w, 10)}};
if (bg && bg !== 'none') opts.background = bg;
fs.writeFileSync(out, new Resvg(fs.readFileSync(inp, 'utf8'), opts).render().asPng());
