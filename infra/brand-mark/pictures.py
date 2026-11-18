"""pictures.py <MASTER.svg> <on-site.png> <remote.png> <work dir>
Remakes the two "How we work" pictures of the home page with the company's mark in them.

Run from the repository root:

    RESVG_JS=<folder of @resvg/resvg-js 2.6.2> python3 -I infra/brand-mark/pictures.py <MASTER.svg> <on-site.png> <remote.png> <a work folder>

The two sources are the owner-supplied 1254 px pictures of 23 April 2026 (sha256 4ee4ba36f861e54e... and
8ffe71b46aed326d...); they are not kept in this repository. The scenes are not generated again. In each
of the eight places the earlier owl medallion sits (two corner lockups, the polo, the tool bag, the
laptop screen, the mug, the notebook, the planter) the coin, rendered from its layered vector master,
is set over it. Every pixel outside those eight places is the source picture's own.

For each place the table below gives the ellipse the old medallion's outer ring makes in the picture
(measured), the way "up" on the mark points, and how the coin is lit there: a brightness, a plane of
shading fitted to the surface just outside the mark, a little softening to match the photograph. On
the planter the coin is printed into the stone (its colours multiplied by the stone's own texture).

Then the ten files of each picture are written to static/images/ as on 23 April 2026: widths 320,
512, 640, 960 and 1280, Lanczos. WebP with ImageMagick, method 6, at quality 78 with the sharp colour
conversion (webp:use-sharp-yuv). The earlier files were quality 80 without it (run on the two sources,
those settings give them back pixel for pixel), and that turned the coin's thin lavender ring grey at
the small sizes; quality 78 with the conversion keeps the ring's colour, is closer to the picture as a
whole, and is lighter. AVIF at quality 60, 4:4:4, speed 4, with Pillow's libavif, because the ImageMagick on the
machine that made these has no AVIF support.
Needs node, ImageMagick ("magick"), and a Python with Pillow (AVIF enabled) and NumPy."""
import sys, os, json, subprocess, math, numpy as np
from PIL import Image, ImageFilter
MASTER, SRC_ON, SRC_RE, WORK = sys.argv[1:5]
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(os.path.dirname(HERE))
RENDER = os.path.join(HERE, 'render.js'); OUT = WORK; DEST = os.path.join(ROOT, 'static', 'images')
os.makedirs(WORK, exist_ok=True)
SS = 4  # supersampling of the warp
# cx, cy, a, b, tilt: the old medallion's outer gold ring (source pixels; a along the tilt direction).
# grow: the coin's edge sits this far outside that ring, to cover the medallion's dark rim.
# up: degrees clockwise from straight up that the mark's own "up" points in the picture.
# gain: brightness of the coin there; soft: gaussian softening in source pixels; shade: fit the light.
PLACES = {
 'onsite': {
  'lockup':  dict(cx=171.20, cy=226.26, a=122.76, b=122.04, tilt=25.4,  grow=1.058, up=0,  gain=1.00, soft=0.0, shade=False),
  'polo':    dict(cx=612.81, cy=723.78, a=50.59,  b=47.21,  tilt=-64.4, grow=1.05,  up=0,  gain=0.86, soft=0.45, shade=True),
  'bag':     dict(cx=842.08, cy=1107.17,a=43.11,  b=33.80,  tilt=-83.8, grow=1.05,  up=-4, gain=0.80, soft=0.7, shade=True),
 },
 'remote': {
  'lockup':  dict(cx=390.25, cy=159.85, a=104.07, b=102.47, tilt=-3.1,  grow=1.066, up=0,  gain=1.00, soft=0.0, shade=False),
  'laptop':  dict(cx=817.15, cy=864.60, a=63.35,  b=60.39,  tilt=-49.3, grow=1.04,  up=8,  gain=0.97, soft=0.5, shade=False),
  'mug':     dict(cx=356.4,  cy=991.3,  a=43.4,   b=44.9,   tilt=0.0,   grow=1.065, up=0,  gain=0.78, soft=0.8, shade=True),
  'notebook':dict(cx=228.5,  cy=1149.7, a=58.8,   b=22.1,   tilt=1.0,   grow=1.05,  up=0,  gain=0.80, soft=0.8, shade=True),
  'planter': dict(cx=148.0,  cy=985.2,  a=30.2,   b=29.6,   tilt=0.0,   grow=1.07,  up=0,  gain=0.72, soft=0.8, shade=True, stone=True),
 },
}
_cache = {}
def coin(px):
    px = int(px)
    if px not in _cache:
        p = os.path.join(WORK, 'coin-%d.png' % px)
        if not os.path.exists(p): subprocess.run(['node', RENDER, MASTER, p, str(px)], check=True)
        _cache[px] = Image.open(p).convert('RGBA')
    return _cache[px]
def lum(a): return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]
def place(img, P):
    A = np.asarray(img).astype(np.float64)
    a, b = P['a'] * P['grow'], P['b'] * P['grow']; th = math.radians(P['tilt']); c, s = math.cos(th), math.sin(th)
    E = np.array([[c * a, -s * b], [s * a, c * b]])                    # unit circle -> the ellipse
    up = math.radians(P['up']); d = np.array([math.sin(up), -math.cos(up)])  # where the mark's up points
    v = np.linalg.solve(E, d); v /= np.linalg.norm(v)                  # the unit vector that E sends there
    Q = np.array([[-v[1], -v[0]], [v[0], -v[1]]])                      # rotation taking (0,-1) to v
    if np.linalg.det(E @ Q) < 0: Q = Q @ np.array([[-1, 0], [0, 1]])
    M = E @ Q                                                          # mark unit coordinates -> picture
    R = int(math.ceil(max(a, b) * (1.65 if P.get('stone') else 1.0))) + 6; x0, y0 = int(round(P['cx'])) - R, int(round(P['cy'])) - R; n = 2 * R
    T = int(2 * max(a, b) * SS) + 8; T += T % 2; tex = coin(T)
    Mi = np.linalg.inv(M)
    # output pixel (X, Y) in the supersampled window -> texture pixel
    k = T / 2.0; ox, oy = (x0 - P['cx']), (y0 - P['cy'])
    # u = Mi @ ((X + 0.5)/SS + o - 0) ; t = (u + 1) * k - 0.5
    aff = [Mi[0, 0] * k / SS, Mi[0, 1] * k / SS, k + k * (Mi[0, 0] * (ox + 0.5 / SS) + Mi[0, 1] * (oy + 0.5 / SS)) - 0.5,
           Mi[1, 0] * k / SS, Mi[1, 1] * k / SS, k + k * (Mi[1, 0] * (ox + 0.5 / SS) + Mi[1, 1] * (oy + 0.5 / SS)) - 0.5]
    warped = tex.transform((n * SS, n * SS), Image.AFFINE, aff, resample=Image.BICUBIC).resize((n, n), Image.LANCZOS)
    if P['soft'] > 0: warped = warped.filter(ImageFilter.GaussianBlur(P['soft']))
    Wc = np.asarray(warped).astype(np.float64); al = Wc[..., 3:4] / 255.0; rgb = Wc[..., :3] * P['gain']
    win = A[y0:y0 + n, x0:x0 + n, :3]
    yy, xx = np.mgrid[0:n, 0:n]; u = (xx + 0.5 + ox) * Mi[0, 0] + (yy + 0.5 + oy) * Mi[0, 1]; w = (xx + 0.5 + ox) * Mi[1, 0] + (yy + 0.5 + oy) * Mi[1, 1]
    rr = np.hypot(u, w)
    if P.get('stone'):
        # the planter: the old mark is printed dark on the stone. In a thin band just outside the coin,
        # where the old mark's rim could show, lay the stone's own smooth colour (a plane fitted, channel
        # by channel, to the stone just outside the mark), feathered out.
        ann = (rr > 1.22) & (rr < 1.60); G = np.c_[xx[ann], yy[ann], np.ones(ann.sum())]
        fill = np.stack([(np.linalg.lstsq(G, win[..., ch][ann], rcond=None)[0] * np.stack([xx, yy, np.ones_like(xx)], -1)).sum(-1) for ch in range(3)], -1)
        # the fill is given the stone's own grain (noise of the spread measured just outside, fixed seed)
        res = lum(win)[ann] - (np.linalg.lstsq(G, lum(win)[ann], rcond=None)[0] * G).sum(-1)
        g0 = np.random.default_rng(17).normal(0, 1, win.shape[:2]); gp = np.pad(g0, 1, mode='edge')
        grain = (4 * g0 + 2 * (gp[:-2, 1:-1] + gp[2:, 1:-1] + gp[1:-1, :-2] + gp[1:-1, 2:]) + gp[:-2, :-2] + gp[:-2, 2:] + gp[2:, :-2] + gp[2:, 2:]) / 16
        fill = fill + (grain / grain.std() * res.std())[..., None]
        ring = np.clip((1.13 - rr) / 0.05, 0, 1)[..., None]
        base = win * (1 - ring) + fill * ring
        # then print the coin on it: its colours multiplied into the stone
        stone = lum(base)[..., None] / max(1.0, float(lum(base)[rr < 1].mean()))
        printed = rgb * (0.55 + 0.45 * stone)
        out = base * (1 - al * 0.93) + printed * (al * 0.93)
    else:
        if P['shade']:
            ann = (rr > 1.06) & (rr < 1.40); L = lum(win)
            G = np.c_[xx[ann], yy[ann], np.ones(ann.sum())]; coef = np.linalg.lstsq(G, L[ann], rcond=None)[0]
            plane = coef[0] * xx + coef[1] * yy + coef[2]; f = plane / max(1.0, float(plane[rr < 1].mean()))
            rgb = rgb * np.clip(f, 0.72, 1.30)[..., None]
        out = win * (1 - al) + rgb * al
    A[y0:y0 + n, x0:x0 + n, :3] = out
    return Image.fromarray(np.clip(A + 0.5, 0, 255).astype(np.uint8))
for key, src in (('onsite', SRC_ON), ('remote', SRC_RE)):
    img = Image.open(src).convert('RGB'); assert img.size == (1254, 1254), img.size
    for name, P in PLACES[key].items(): img = place(img, P)
    full = os.path.join(OUT, key + '-1254.png'); img.save(full, 'PNG', optimize=True)
    for w in (320, 512, 640, 960, 1280):
        subprocess.run(['magick', full, '-filter', 'Lanczos', '-resize', '%dx%d' % (w, w), '-quality', '78', '-define', 'webp:method=6', '-define', 'webp:use-sharp-yuv=true',
                        os.path.join(DEST, '%s-%d.webp' % (key, w))], check=True)
        small = os.path.join(WORK, '%s-%d.png' % (key, w))
        subprocess.run(['magick', full, '-filter', 'Lanczos', '-resize', '%dx%d' % (w, w), small], check=True)
        Image.open(small).convert('RGB').save(os.path.join(DEST, '%s-%d.avif' % (key, w)), 'AVIF', quality=60, subsampling='4:4:4', speed=4)
    print(key, 'written')
