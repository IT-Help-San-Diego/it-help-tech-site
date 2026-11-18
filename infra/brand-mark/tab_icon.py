"""tab_icon.py <MASTER.svg> <out.svg>
The drawing used for the 16 and 32 px frames of favicon.ico, where the whole coin cannot be read.
From the master, unchanged: the field disc, and the centre mark (the sign, its mirror image and the
gold line, with the master's own placement transform).
NOT from the master, added here so that something survives at 16 px:
  - one ring, r 360 and 92 units wide, in the coin's colour, in place of the master's two thin rings;
  - a 30 unit stroke with round joins on the letters of the sign, in their own colour;
  - the gold line 3.4 times thicker about its own centre line;
  - the whole centre mark enlarged 1.36 times about the coin's centre.
Left out: the Greek-key border, the lettering, the four symmetry bars."""
import sys, copy, xml.etree.ElementTree as ET
SVG = 'http://www.w3.org/2000/svg'; IKNS = 'http://www.inkscape.org/namespaces/inkscape'
ET.register_namespace('', SVG); ET.register_namespace('inkscape', IKNS); ET.register_namespace('xlink', 'http://www.w3.org/1999/xlink')
IK = '{%s}label' % IKNS
RING = (360, 92); MARK_SCALE = 1.36; STROKE = 30; LINE_K = 3.4
root = ET.parse(sys.argv[1]).getroot()
new = ET.Element('{%s}svg' % SVG, {'width': '820', 'height': '820', 'viewBox': '0 0 820 820'})
ET.SubElement(new, '{%s}title' % SVG).text = 'METACOGNITIVE tab icon: field, one ring, the centre mark emboldened'
for g in root:
    if g.tag != '{%s}g' % SVG: continue
    key = (g.get(IK) or '').split(' ')[0]
    if key == '0':
        new.append(copy.deepcopy(g))
    elif key == '1':
        g2 = copy.deepcopy(g)
        for c in list(g2): g2.remove(c)
        ET.SubElement(g2, '{%s}circle' % SVG, {'cx': '410', 'cy': '410', 'r': str(RING[0]), 'fill': 'none', 'stroke': '#B498E6', 'stroke-width': str(RING[1])})
        new.append(g2)
    elif key == '4a':
        g2 = copy.deepcopy(g)
        for ch in g2:
            lab = ch.get(IK) or ''
            if lab.startswith('4 '):
                ch.set('stroke', '#B498E6'); ch.set('stroke-width', str(STROKE)); ch.set('stroke-linejoin', 'round')
            if lab.startswith('4b'):
                y = float(ch.get('y')); h = float(ch.get('height')); nh = h * LINE_K
                ch.set('y', repr(y - (nh - h) / 2)); ch.set('height', repr(nh))
        w = ET.SubElement(new, '{%s}g' % SVG, {'transform': 'translate(410 410) scale(%s) translate(-410 -410)' % MARK_SCALE})
        w.append(g2)
ET.ElementTree(new).write(sys.argv[2], encoding='utf-8')
