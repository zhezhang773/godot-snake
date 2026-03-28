"""
Generate snake style previews as SVG files (no external dependencies needed).
"""

import math
import os

WIDTH, HEIGHT = 600, 680
CELL = 50
BG = "#0f141e"

SEGMENTS = [
    (2, 5), (3, 5), (4, 5), (5, 5),
    (5, 4), (5, 3), (5, 2), (5, 1),
    (6, 1), (7, 1), (8, 1), (9, 1),
    (9, 2), (9, 3),
]
DIRECTION = (1, 1)

HEAD_COLOR = (50, 235, 115)
BODY_COLOR = (45, 200, 95)
TAIL_COLOR = (30, 155, 75)
BELLY_COLOR = (90, 240, 130)
BLUSH = (255, 115, 140)
EYE_WHITE = (255, 255, 255)
PUPIL = (25, 25, 25)


def rgb(c, a=1.0):
    if a >= 1.0:
        return f"rgb({c[0]},{c[1]},{c[2]})"
    return f"rgba({c[0]},{c[1]},{c[2]},{a})"


def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def seg_center(seg):
    return (seg[0] * CELL + CELL // 2, seg[1] * CELL + CELL // 2)


def get_seg_size(i, n):
    t = i / max(n - 1, 1)
    if i == 0:
        return CELL * 0.88
    elif i <= 2:
        ht = i / 3.0
        return CELL * 0.88 + (CELL * 0.80 - CELL * 0.88) * ht
    else:
        return CELL * 0.80 + (CELL * 0.55 - CELL * 0.80) * t


def get_seg_color(i, n):
    t = i / max(n - 1, 1)
    return lerp_color(HEAD_COLOR, TAIL_COLOR, t)


def eyes_svg(cx, cy, size, d):
    ex = size * 0.22
    fwd = (d[0] * size * 0.12, d[1] * size * 0.12)
    perp = (-d[1], d[0])
    dist = size * 0.30
    parts = []
    for sign in [1, -1]:
        ecx = cx + fwd[0] + perp[0] * dist * sign
        ecy = cy + fwd[1] + perp[1] * dist * sign
        parts.append(f'<circle cx="{ecx}" cy="{ecy}" r="{ex}" fill="{rgb(EYE_WHITE)}"/>')
        px = d[0] * ex * 0.2
        py = d[1] * ex * 0.2
        ps = ex * 0.55
        parts.append(f'<circle cx="{ecx+px}" cy="{ecy+py}" r="{ps}" fill="{rgb(PUPIL)}"/>')
        hs = ex * 0.28
        hlx, hly = -ex * 0.25, -ex * 0.30
        parts.append(f'<circle cx="{ecx+hlx}" cy="{ecy+hly}" r="{hs}" fill="white"/>')
        hs2 = hs * 0.5
        parts.append(f'<circle cx="{ecx+ex*0.15}" cy="{ecy+ex*0.1}" r="{hs2}" fill="white" opacity="0.7"/>')
    # Blush
    for sign in [1, -1]:
        bx = cx + fwd[0] + perp[0] * size * 0.40 * sign
        by = cy + fwd[1] + perp[1] * size * 0.40 * sign
        bs = size * 0.13
        parts.append(f'<circle cx="{bx}" cy="{by}" r="{bs}" fill="{rgb(BLUSH, 0.35)}"/>')
    return "\n  ".join(parts)


def svg_header():
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">'


def svg_footer():
    return "</svg>"


def label_svg(number, name, desc):
    return f'''<text x="20" y="618" fill="white" font-family="Arial,sans-serif" font-size="22" font-weight="bold">{number}. {name}</text>
<text x="20" y="648" fill="#a0a5b4" font-family="Arial,sans-serif" font-size="15">{desc}</text>'''


# ============ 1. Pure Square ============
def style_01():
    n = len(SEGMENTS)
    shapes = []
    for i in range(n - 1):
        c1, c2 = seg_center(SEGMENTS[i]), seg_center(SEGMENTS[i + 1])
        s1, s2 = get_seg_size(i, n) / 2, get_seg_size(i + 1, n) / 2
        c = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        x = min(c1[0] - s1, c2[0] - s2)
        y = min(c1[1] - s1, c2[1] - s2)
        w = max(c1[0] + s1, c2[0] + s2) - x
        h = max(c1[1] + s1, c2[1] + s2) - y
        shapes.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{rgb(c)}"/>')
    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        shapes.append(f'<rect x="{c[0]-s}" y="{c[1]-s}" width="{s*2}" height="{s*2}" fill="{rgb(color)}"/>')
    hc = seg_center(SEGMENTS[0])
    eyes = eyes_svg(hc[0], hc[1], CELL * 0.88, DIRECTION)
    return svg_header() + f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{BG}"/>' + "\n".join(shapes) + "\n" + eyes + "\n" + label_svg(1, "Pure Square", "Classic pixel style, sharp edges") + svg_footer()


# ============ 2. Rounded Square ============
def style_02():
    n = len(SEGMENTS)
    shapes = []
    for i in range(n - 1):
        c1, c2 = seg_center(SEGMENTS[i]), seg_center(SEGMENTS[i + 1])
        s1, s2 = get_seg_size(i, n) / 2, get_seg_size(i + 1, n) / 2
        c = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        x = min(c1[0] - s1, c2[0] - s2)
        y = min(c1[1] - s1, c2[1] - s2)
        w = max(c1[0] + s1, c2[0] + s2) - x
        h = max(c1[1] + s1, c2[1] + s2) - y
        r = min(w, h) * 0.2
        shapes.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{rgb(c)}"/>')
    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        r = s * 0.3
        shapes.append(f'<rect x="{c[0]-s}" y="{c[1]-s}" width="{s*2}" height="{s*2}" rx="{r}" fill="{rgb(color)}"/>')
        if i % 3 == 0 and i > 2:
            stripe = lerp_color(color, BELLY_COLOR, 0.3)
            inset = s * 0.2
            shapes.append(f'<rect x="{c[0]-s+inset}" y="{c[1]-s+inset}" width="{(s-inset)*2}" height="{(s-inset)*2}" rx="{r-2}" fill="{rgb(stripe,0.2)}"/>')
    hc = seg_center(SEGMENTS[0])
    eyes = eyes_svg(hc[0], hc[1], CELL * 0.88, DIRECTION)
    return svg_header() + f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{BG}"/>' + "\n".join(shapes) + "\n" + eyes + "\n" + label_svg(2, "Rounded Square", "Soft corners, friendly & neat") + svg_footer()


# ============ 3. Circles ============
def style_03():
    n = len(SEGMENTS)
    shapes = []
    for i in range(n - 1):
        c1, c2 = seg_center(SEGMENTS[i]), seg_center(SEGMENTS[i + 1])
        s1, s2 = get_seg_size(i, n) / 2, get_seg_size(i + 1, n) / 2
        c = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        dx, dy = c2[0] - c1[0], c2[1] - c1[1]
        dist = math.sqrt(dx*dx + dy*dy)
        if dist < 1: continue
        nx, ny = -dy/dist, dx/dist
        pts = [
            f"{c1[0]+nx*s1*0.9},{c1[1]+ny*s1*0.9}",
            f"{c2[0]+nx*s2*0.9},{c2[1]+ny*s2*0.9}",
            f"{c2[0]-nx*s2*0.9},{c2[1]-ny*s2*0.9}",
            f"{c1[0]-nx*s1*0.9},{c1[1]-ny*s1*0.9}",
        ]
        shapes.append(f'<polygon points="{" ".join(pts)}" fill="{rgb(c)}"/>')
    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        shapes.append(f'<circle cx="{c[0]}" cy="{c[1]}" r="{s}" fill="{rgb(color)}"/>')
        shapes.append(f'<ellipse cx="{c[0]}" cy="{c[1]+s*0.15}" rx="{s*0.5}" ry="{s*0.35}" fill="{rgb(BELLY_COLOR,0.15)}"/>')
    hc = seg_center(SEGMENTS[0])
    eyes = eyes_svg(hc[0], hc[1], CELL * 0.88, DIRECTION)
    return svg_header() + f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{BG}"/>' + "\n".join(shapes) + "\n" + eyes + "\n" + label_svg(3, "Circles", "Smooth round body, bubbly feel") + svg_footer()


# ============ 4. Pill / Capsule ============
def style_04():
    n = len(SEGMENTS)
    shapes = []
    for i in range(n - 1):
        c1, c2 = seg_center(SEGMENTS[i]), seg_center(SEGMENTS[i + 1])
        s1, s2 = get_seg_size(i, n) / 2, get_seg_size(i + 1, n) / 2
        c = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        x = min(c1[0] - s1, c2[0] - s2)
        y = min(c1[1] - s1, c2[1] - s2)
        w = max(c1[0] + s1, c2[0] + s2) - x
        h = max(c1[1] + s1, c2[1] + s2) - y
        r = min(w, h) / 2
        shapes.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{rgb(c)}"/>')
    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        r = s * 0.85
        shapes.append(f'<rect x="{c[0]-s}" y="{c[1]-s}" width="{s*2}" height="{s*2}" rx="{r}" fill="{rgb(color)}"/>')
    hc = seg_center(SEGMENTS[0])
    eyes = eyes_svg(hc[0], hc[1], CELL * 0.88, DIRECTION)
    return svg_header() + f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{BG}"/>' + "\n".join(shapes) + "\n" + eyes + "\n" + label_svg(4, "Pill / Capsule", "Fully rounded ends, smooth body") + svg_footer()


# ============ 5. Diamond ============
def style_05():
    n = len(SEGMENTS)
    shapes = []
    for i in range(n - 1):
        c1, c2 = seg_center(SEGMENTS[i]), seg_center(SEGMENTS[i + 1])
        s1, s2 = get_seg_size(i, n) / 2, get_seg_size(i + 1, n) / 2
        c = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        hw = max(s1, s2)
        hh = abs(c1[1] - c2[1]) / 2 + min(s1, s2)
        shapes.append(f'<rect x="{min(c1[0],c2[0])-hw}" y="{min(c1[1],c2[1])-hh}" width="{abs(c1[0]-c2[0])+hw*2}" height="{abs(c1[1]-c2[1])+hh*2}" fill="{rgb(c)}"/>')
    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        pts = f"{c[0]},{c[1]-s} {c[0]+s},{c[1]} {c[0]},{c[1]+s} {c[0]-s},{c[1]}"
        shapes.append(f'<polygon points="{pts}" fill="{rgb(color)}"/>')
        inner = 0.55
        ic = lerp_color(color, BELLY_COLOR, 0.4)
        pts2 = f"{c[0]},{c[1]-s*inner} {c[0]+s*inner},{c[1]} {c[0]},{c[1]+s*inner} {c[0]-s*inner},{c[1]}"
        shapes.append(f'<polygon points="{pts2}" fill="{rgb(ic,0.25)}"/>')
    hc = seg_center(SEGMENTS[0])
    eyes = eyes_svg(hc[0], hc[1], CELL * 0.88, DIRECTION)
    return svg_header() + f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{BG}"/>' + "\n".join(shapes) + "\n" + eyes + "\n" + label_svg(5, "Diamond", "Rotated squares, elegant geometric") + svg_footer()


# ============ 6. Hexagon ============
def style_06():
    n = len(SEGMENTS)
    shapes = []
    def hex_pts(cx, cy, s):
        return " ".join(f"{cx+s*math.cos(math.pi/6+k*math.pi/3)},{cy+s*math.sin(math.pi/6+k*math.pi/3)}" for k in range(6))
    for i in range(n - 1):
        c1, c2 = seg_center(SEGMENTS[i]), seg_center(SEGMENTS[i + 1])
        s1, s2 = get_seg_size(i, n) / 2, get_seg_size(i + 1, n) / 2
        c = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        x = min(c1[0] - s1, c2[0] - s2)
        y = min(c1[1] - s1, c2[1] - s2)
        w = max(c1[0] + s1, c2[0] + s2) - x
        h = max(c1[1] + s1, c2[1] + s2) - y
        shapes.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{rgb(c)}"/>')
    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        shapes.append(f'<polygon points="{hex_pts(c[0],c[1],s)}" fill="{rgb(color)}"/>')
        shapes.append(f'<polygon points="{hex_pts(c[0],c[1],s*0.6)}" fill="{rgb(BELLY_COLOR,0.15)}"/>')
    hc = seg_center(SEGMENTS[0])
    eyes = eyes_svg(hc[0], hc[1], CELL * 0.88, DIRECTION)
    return svg_header() + f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{BG}"/>' + "\n".join(shapes) + "\n" + eyes + "\n" + label_svg(6, "Hexagon", "Honeycomb segments, nature vibe") + svg_footer()


# ============ 7. Squircle ============
def style_07():
    n = len(SEGMENTS)
    shapes = []
    for i in range(n - 1):
        c1, c2 = seg_center(SEGMENTS[i]), seg_center(SEGMENTS[i + 1])
        s1, s2 = get_seg_size(i, n) / 2, get_seg_size(i + 1, n) / 2
        c = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        x = min(c1[0] - s1, c2[0] - s2)
        y = min(c1[1] - s1, c2[1] - s2)
        w = max(c1[0] + s1, c2[0] + s2) - x
        h = max(c1[1] + s1, c2[1] + s2) - y
        r = min(w, h) / 2
        shapes.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{rgb(c)}"/>')
    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        r = s * 0.95
        outline = rgb(tuple(max(0, x - 30) for x in color))
        shapes.append(f'<rect x="{c[0]-s}" y="{c[1]-s}" width="{s*2}" height="{s*2}" rx="{r}" fill="{rgb(color)}" stroke="{outline}" stroke-width="2"/>')
    hc = seg_center(SEGMENTS[0])
    eyes = eyes_svg(hc[0], hc[1], CELL * 0.88, DIRECTION)
    return svg_header() + f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{BG}"/>' + "\n".join(shapes) + "\n" + eyes + "\n" + label_svg(7, "Squircle", "iOS-style, modern & sleek") + svg_footer()


# ============ 8. Star ============
def style_08():
    n = len(SEGMENTS)
    shapes = []
    for i in range(n - 1):
        c1, c2 = seg_center(SEGMENTS[i]), seg_center(SEGMENTS[i + 1])
        s = max(get_seg_size(i, n), get_seg_size(i + 1, n)) / 2 * 0.7
        c = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        shapes.append(f'<line x1="{c1[0]}" y1="{c1[1]}" x2="{c2[0]}" y2="{c2[1]}" stroke="{rgb(c)}" stroke-width="{s*2}" stroke-linecap="round"/>')
    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        pts = " ".join([
            f"{c[0]},{c[1]-s}", f"{c[0]+s*0.45},{c[1]-s*0.45}",
            f"{c[0]+s},{c[1]}", f"{c[0]+s*0.45},{c[1]+s*0.45}",
            f"{c[0]},{c[1]+s}", f"{c[0]-s*0.45},{c[1]+s*0.45}",
            f"{c[0]-s},{c[1]}", f"{c[0]-s*0.45},{c[1]-s*0.45}",
        ])
        shapes.append(f'<polygon points="{pts}" fill="{rgb(color)}"/>')
    hc = seg_center(SEGMENTS[0])
    eyes = eyes_svg(hc[0], hc[1], CELL * 0.88, DIRECTION)
    return svg_header() + f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{BG}"/>' + "\n".join(shapes) + "\n" + eyes + "\n" + label_svg(8, "Star / Cross", "Pointed star segments, edgy") + svg_footer()


# ============ 9. Blob ============
def style_09():
    n = len(SEGMENTS)
    shapes = []
    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2 * 1.15
        color = get_seg_color(i, n)
        shapes.append(f'<circle cx="{c[0]}" cy="{c[1]}" r="{s}" fill="{rgb(color)}"/>')
        hl = lerp_color(color, (255, 255, 255), 0.15)
        hs = s * 0.6
        shapes.append(f'<circle cx="{c[0]-2}" cy="{c[1]-2}" r="{hs}" fill="{rgb(hl,0.12)}"/>')
    for i in range(n - 1, 0, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        shapes.append(f'<ellipse cx="{c[0]}" cy="{c[1]+s*0.15}" rx="{s*0.5}" ry="{s*0.35}" fill="{rgb(BELLY_COLOR,0.15)}"/>')
    hc = seg_center(SEGMENTS[0])
    eyes = eyes_svg(hc[0], hc[1], CELL * 0.88, DIRECTION)
    return svg_header() + f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{BG}"/>' + "\n".join(shapes) + "\n" + eyes + "\n" + label_svg(9, "Blob (Organic)", "Soft overlapping, like caterpillar") + svg_footer()


# ============ 10. Bordered Block ============
def style_10():
    n = len(SEGMENTS)
    outline_shapes = []
    fill_shapes = []
    outline_c = rgb((20, 100, 45))
    for i in range(n - 1):
        c1, c2 = seg_center(SEGMENTS[i]), seg_center(SEGMENTS[i + 1])
        s1, s2 = get_seg_size(i, n) / 2, get_seg_size(i + 1, n) / 2
        c = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        for offset, layer in [(3, outline_shapes), (0, fill_shapes)]:
            x = min(c1[0] - s1 - offset, c2[0] - s2 - offset)
            y = min(c1[1] - s1 - offset, c2[1] - s2 - offset)
            w = max(c1[0] + s1 + offset, c2[0] + s2 + offset) - x
            h = max(c1[1] + s1 + offset, c2[1] + s2 + offset) - y
            fill = outline_c if offset > 0 else rgb(c)
            layer.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="{fill}"/>')
    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        outline_shapes.append(f'<rect x="{c[0]-s-3}" y="{c[1]-s-3}" width="{(s+3)*2}" height="{(s+3)*2}" rx="6" fill="{outline_c}"/>')
        fill_shapes.append(f'<rect x="{c[0]-s}" y="{c[1]-s}" width="{s*2}" height="{s*2}" rx="5" fill="{rgb(color)}"/>')
        hl = lerp_color(color, (255, 255, 255), 0.2)
        inset = s * 0.15
        fill_shapes.append(f'<rect x="{c[0]-s+inset}" y="{c[1]-s+inset}" width="{(s-inset)*2}" height="{s-inset}" rx="4" fill="{rgb(hl,0.18)}"/>')
        sh = lerp_color(color, (0, 0, 0), 0.2)
        fill_shapes.append(f'<rect x="{c[0]-s+inset}" y="{c[1]}" width="{(s-inset)*2}" height="{s-inset}" rx="4" fill="{rgb(sh,0.15)}"/>')
    hc = seg_center(SEGMENTS[0])
    eyes = eyes_svg(hc[0], hc[1], CELL * 0.88, DIRECTION)
    return svg_header() + f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{BG}"/>' + "\n".join(outline_shapes) + "\n" + "\n".join(fill_shapes) + "\n" + eyes + "\n" + label_svg(10, "Bordered Block", "Outlined blocks with 3D shading") + svg_footer()


styles = [
    style_01, style_02, style_03, style_04, style_05,
    style_06, style_07, style_08, style_09, style_10,
]

out_dir = r"G:\autoclawcode\dev\snake_styles"
os.makedirs(out_dir, exist_ok=True)

for i, fn in enumerate(styles):
    svg = fn()
    path = os.path.join(out_dir, f"style_{i+1:02d}.svg")
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"Saved: style_{i+1:02d}.svg")

# Generate an all-in-one preview
all_svg = svg_header()
all_svg += f'<rect width="{WIDTH*2}" height="{HEIGHT*5}" fill="{BG}"/>'
for i, fn in enumerate(styles):
    ox = (i % 2) * WIDTH
    oy = (i // 2) * HEIGHT
    all_svg += f'<g transform="translate({ox},{oy})">' + fn().replace(svg_header(), "").replace(svg_footer(), "") + "</g>\n"

print(f"\nAll 10 styles generated in: {out_dir}")
