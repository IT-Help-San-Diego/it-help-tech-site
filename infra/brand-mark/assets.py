"""assets.py <MASTER.svg> <work dir>
Writes the site's mark files from the coin's layered vector master. Run from the repository root:

    RESVG_JS=<folder of @resvg/resvg-js 2.6.2> python3 -I infra/brand-mark/assets.py <MASTER.svg> <work dir>

Needs node, cwebp, and a Python with Pillow and NumPy. Every picture is a render of the vector at its
own pixel size (resvg-js); this script only re-encodes the renders (pixels unchanged, checked) and
composes the link-preview card and the .ico. The mail logo is written by mail_logo.py.

  static/img/brand/metacognitive-720.png, .webp   the hero (WebP: cwebp quality 89, exact alpha)
  static/apple-touch-icon.png 180, android-chrome-192x192.png, android-chrome-512x512.png,
  static/mstile-150x150.png 150                    the whole coin, edge to edge, clear corners
  static/favicon.ico                               16 and 32 px: tab_icon.py's drawing; 48 px: the whole
                                                   coin; uncompressed 32-bit frames, as the file it replaced
  static/images/og-home.png                        the card: everything left of column 386 made black,
                                                   the coin (264 px) set at (81, 183); the wordmark's
                                                   pixels are not touched
"""
import sys, os, subprocess, numpy as np
from PIL import Image
MASTER, WORK = sys.argv[1], sys.argv[2]
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(os.path.dirname(HERE)); ST = os.path.join(ROOT, 'static')
os.makedirs(WORK, exist_ok=True)
def render(svg, px, name):
    out = os.path.join(WORK, name); subprocess.run(['node', os.path.join(HERE, 'render.js'), svg, out, str(px)], check=True); return out
def px(p): return np.asarray(Image.open(p).convert('RGBA'))
def save_png(src, dst):
    Image.open(src).save(dst, 'PNG', optimize=True); assert (px(src) == px(dst)).all(), dst
tab = os.path.join(WORK, 'tab-icon.svg')
subprocess.run([sys.executable, '-I', os.path.join(HERE, 'tab_icon.py'), MASTER, tab], check=True)
coin = {s: render(MASTER, s, 'coin-%d.png' % s) for s in (720, 512, 264, 192, 180, 150, 48)}
tabs = {s: render(tab, s, 'tab-%d.png' % s) for s in (16, 32)}
save_png(coin[720], os.path.join(ST, 'img/brand/metacognitive-720.png'))
subprocess.run(['cwebp', '-quiet', '-q', '89', '-alpha_q', '100', '-m', '6', '-sharp_yuv', coin[720], '-o', os.path.join(ST, 'img/brand/metacognitive-720.webp')], check=True)
for s, name in ((180, 'apple-touch-icon.png'), (192, 'android-chrome-192x192.png'), (512, 'android-chrome-512x512.png'), (150, 'mstile-150x150.png')):
    save_png(coin[s], os.path.join(ST, name))
ico = os.path.join(ST, 'favicon.ico')
Image.open(coin[48]).convert('RGBA').save(ico, format='ICO', bitmap_format='bmp', sizes=[(16, 16), (32, 32), (48, 48)],
    append_images=[Image.open(tabs[16]).convert('RGBA'), Image.open(tabs[32]).convert('RGBA')])
back = Image.open(ico)
for s, src in ((16, tabs[16]), (32, tabs[32]), (48, coin[48])):
    back.size = (s, s); assert (np.asarray(back.copy().convert('RGBA')) == px(src)).all(), 'favicon frame %d' % s
card_path = os.path.join(ST, 'images/og-home.png'); card = Image.open(card_path).convert('RGB'); before = np.asarray(card).copy()
assert card.size == (1200, 630)
card.paste((0, 0, 0), (0, 0, 386, 630))
c = Image.open(coin[264]).convert('RGBA'); card.paste(c, (81, 183), c)
card.save(card_path, 'PNG', optimize=True)
after = np.asarray(Image.open(card_path).convert('RGB')); assert (before[:, 386:] == after[:, 386:]).all(), 'the wordmark changed'
print('written; frames of favicon.ico:', sorted(Image.open(ico).info.get('sizes', [])))
