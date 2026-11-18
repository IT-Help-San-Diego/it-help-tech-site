"""mail_logo.py <MASTER.svg> <out.svg> [--arcs]
The mail logo (BIMI): the coin in the SVG Tiny Portable/Secure profile, flat fills.
The profile has no filter, mask or clip path, and SVG Tiny 1.2 has no elliptical-arc path command.
So this file holds, from the master: the field disc, the two rings, the footprint of the "cut ring"
(the Greek-key border whose window carries only the two rails), the thirteen letter outlines of
METACOGNITIVE, the centre mark with its gold line, and the four symmetry bars. Left out: grain, the
gold bands and the lit edges. The master draws the lettering band as the uncut ring, a plate and the
cut ring clipped to the window; drawn flat, the cut ring whole gives the same picture without a clip.
Every number is the master's, except that each arc of the border is rewritten as cubic curves
(at most a quarter turn each, a twelfth of a turn on the two great circles; relative coordinates to
two decimals, each taken from the rounded point before it so that no error adds up); --arcs keeps the
arcs, as a yardstick."""
import sys, re, math, xml.etree.ElementTree as ET
SVG = 'http://www.w3.org/2000/svg'; IK = '{http://www.inkscape.org/namespaces/inkscape}label'; XL = '{http://www.w3.org/1999/xlink}href'
q = lambda t: '{%s}%s' % (SVG, t)
def num(v):
    s = ('%.2f' % v).rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s
def arc_to_cubics(x1, y1, rx, ry, phi, fa, fs, x2, y2):
    """One SVG arc as cubic curves, each spanning at most a quarter turn (W3C SVG 1.1, appendix F.6)."""
    if rx == 0 or ry == 0 or (x1 == x2 and y1 == y2): return [(x1, y1, x2, y2, x2, y2)]
    rx, ry = abs(rx), abs(ry); p = math.radians(phi); cp, sp = math.cos(p), math.sin(p)
    dx, dy = (x1 - x2) / 2, (y1 - y2) / 2
    x1p, y1p = cp * dx + sp * dy, -sp * dx + cp * dy
    lam = x1p * x1p / (rx * rx) + y1p * y1p / (ry * ry)
    if lam > 1: s = math.sqrt(lam); rx *= s; ry *= s
    n = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
    d = rx * rx * y1p * y1p + ry * ry * x1p * x1p
    co = (-1 if fa == fs else 1) * math.sqrt(max(0.0, n / d))
    cxp, cyp = co * rx * y1p / ry, -co * ry * x1p / rx
    cx, cy = cp * cxp - sp * cyp + (x1 + x2) / 2, sp * cxp + cp * cyp + (y1 + y2) / 2
    ang = lambda ux, uy: math.atan2(uy, ux)
    t1 = ang((x1p - cxp) / rx, (y1p - cyp) / ry); t2 = ang((-x1p - cxp) / rx, (-y1p - cyp) / ry)
    dt = t2 - t1
    if fs and dt < 0: dt += 2 * math.pi
    if not fs and dt > 0: dt -= 2 * math.pi
    # a cubic over a quarter turn leaves the circle by 0.027 % of its radius: nothing at the corner
    # radii (about 5 units), a tenth of a unit on the two great circles. Those are cut every 30 degrees.
    limit = math.pi / 2 if max(rx, ry) <= 50 else math.pi / 6
    k = max(1, int(math.ceil(abs(dt) / limit - 1e-9))); step = dt / k; out = []
    a = 4 / 3 * math.tan(step / 4)
    for i in range(k):
        s0, s1 = t1 + i * step, t1 + (i + 1) * step
        e = lambda t: (cx + rx * math.cos(t) * cp - ry * math.sin(t) * sp, cy + rx * math.cos(t) * sp + ry * math.sin(t) * cp)
        de = lambda t: (-rx * math.sin(t) * cp - ry * math.cos(t) * sp, -rx * math.sin(t) * sp + ry * math.cos(t) * cp)
        p0, p3 = e(s0), e(s1); d0, d3 = de(s0), de(s1)
        out.append((p0[0] + a * d0[0], p0[1] + a * d0[1], p3[0] - a * d3[0], p3[1] - a * d3[1], p3[0], p3[1]))
    out[-1] = out[-1][:4] + (x2, y2)
    return out
def no_arcs(d):
    tok = re.findall(r'[MLAZ]|-?\d*\.?\d+(?:e-?\d+)?', d); i = 0; out = []; cmd = None
    assert not re.search(r'[a-zB-KN-Y]', d.replace('e', '')), 'only absolute M, L, A, Z are expected in the border'
    cur = (0.0, 0.0)      # the true current point, for the arc geometry
    pen = (0.0, 0.0)      # the point as written (rounded), which relative coordinates count from
    start = (0.0, 0.0)
    r2 = lambda v: round(v, 2)
    def rel(x, y): return num(r2(x) - pen[0]) + ' ' + num(r2(y) - pen[1])
    while i < len(tok):
        if tok[i] in 'MLAZ': cmd = tok[i]; i += 1
        if cmd == 'Z':
            out.append('z'); cur = start; pen = (r2(start[0]), r2(start[1])); continue
        if cmd in 'ML':
            x, y = float(tok[i]), float(tok[i + 1]); i += 2
            if cmd == 'M': out.append('M%s %s' % (num(x), num(y))); start = (x, y); cmd = 'L'
            else: out.append('l' + rel(x, y))
            cur = (x, y); pen = (r2(x), r2(y))
        elif cmd == 'A':
            rx, ry, phi, fa, fs, x, y = (float(t) for t in tok[i:i + 7]); i += 7
            for c in arc_to_cubics(cur[0], cur[1], rx, ry, phi, int(fa), int(fs), x, y):
                out.append('c' + rel(c[0], c[1]) + ' ' + rel(c[2], c[3]) + ' ' + rel(c[4], c[5])); pen = (r2(c[4]), r2(c[5]))
            cur = (x, y)
    return ''.join(out).replace(' -', '-')
root = ET.parse(sys.argv[1]).getroot(); keep_arcs = '--arcs' in sys.argv
L = {}
for g in root:
    if g.tag == q('g') and g.get('style') != 'display:none': L.setdefault((g.get(IK) or '').split(' ')[0], g)
field = L['0'].find(q('circle')); rings = L['1'].findall(q('circle'))
rails = [c for c in L['5a'] if c.tag == q('g')][0]; inner = [c for c in rails if c.tag == q('g')][0]
cut = [g for g in inner if g.tag == q('g') and (g.get(IK) or '').startswith('2 ')][0]; cutfp = [x for x in cut if x.tag == q('g')][0]
glyphs = L['5b'].find(q('g')); g4 = L['4a']
body = [x for x in g4 if (x.get(IK) or '').startswith('4 ')][0]; fix = [x for x in g4 if (x.get(IK) or '').startswith('4b')][0]
tok = body.find(q('defs')).find(q('g'))
def ser(e):
    t = e.tag.split('}')[1]
    if t == 'g': return '<g%s>%s</g>' % ((' transform="%s"' % e.get('transform')) if e.get('transform') else '', ''.join(ser(x) for x in e))
    if t == 'path': return '<path d="%s"/>' % e.get('d')
    raise SystemExit('unexpected element ' + t)
s = '<svg xmlns="http://www.w3.org/2000/svg" version="1.2" baseProfile="tiny-ps" width="820" height="820" viewBox="0 0 820 820">'
s += '<title>IT Help San Diego</title>'
s += '<desc>The METACOGNITIVE semaphore of the Tetrasemaphore in flat colours: field, rings, Greek-key border, the lettering METACOGNITIVE, and the sign with its mirror image across a gold line.</desc>'
s += '<path fill="#17121D" d="M0 0h820v820H0z"/><g transform="translate(410 410) scale(0.9) translate(-410 -410)">'
s += '<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (field.get('cx'), field.get('cy'), field.get('r'), field.get('fill'))
for c in rings: s += '<circle cx="%s" cy="%s" r="%s" fill="none" stroke="%s" stroke-width="%s"/>' % (c.get('cx'), c.get('cy'), c.get('r'), c.get('stroke'), c.get('stroke-width'))
s += '<g fill="%s" fill-rule="%s">' % (cutfp.get('fill'), cutfp.get('fill-rule'))
for p in cutfp.iter(q('path')): s += '<path d="%s"/>' % (p.get('d') if keep_arcs else no_arcs(p.get('d')))
s += '</g><g fill="%s">' % glyphs.get('fill') + ''.join('<path transform="%s" d="%s"/>' % (p.get('transform'), p.get('d')) for p in glyphs.findall(q('path'))) + '</g>'
s += '<g transform="%s"><g fill="%s">' % (g4.get('transform'), body.get('fill'))
for u in body.findall(q('use')):
    assert u.get(XL) == '#tok'; s += '<g transform="%s">%s</g>' % (u.get('transform'), ser(tok))
s += '</g><rect x="%s" y="%s" width="%s" height="%s" fill="%s"/></g>' % (fix.get('x'), fix.get('y'), fix.get('width'), fix.get('height'), fix.get('fill'))
s += '<g fill="%s">' % L['6'].get('fill') + ''.join('<rect x="%s" y="%s" width="%s" height="%s"/>' % (r.get('x'), r.get('y'), r.get('width'), r.get('height')) for r in L['6'].findall(q('rect'))) + '</g></g></svg>\n'
open(sys.argv[2], 'w', encoding='utf-8').write(s)
# the profile's rules, checked on the text written
bad = [t for t in ('<image', '<script', '<style', '<foreignObject', '<animate', '<set', '<a ', '<filter', '<mask', '<clipPath', '<pattern', '<use', '<defs', 'xlink:', 'href=', 'filter=', 'mask=', 'clip-path=', 'style=', '<!--', '<?xml', '<!DOCTYPE', ' id=') if t in s]
assert not bad, bad
assert s.startswith('<svg xmlns="http://www.w3.org/2000/svg" version="1.2" baseProfile="tiny-ps"') and s.index('<title>') < s.index('<path')
if not keep_arcs:
    for d in re.findall(r' d="([^"]*)"', s): assert re.fullmatch(r'[MmLlHhVvCcSsQqTtZz0-9eE\s,.\-+]*', d), 'a path command outside SVG Tiny 1.2: ' + d[:60]
    assert len(s.encode()) <= 32000, len(s.encode())
print(sys.argv[2], len(s.encode()), 'bytes', '(arcs kept)' if keep_arcs else '(no arc command)')
