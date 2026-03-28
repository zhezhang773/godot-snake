"""
Snake Style Preview Generator
Generates 10 different snake body styles for the Godot Snake Game.
"""

import math
from PIL import Image, ImageDraw, ImageFont
import os

WIDTH, HEIGHT = 600, 680
CELL = 50
BG = (15, 20, 30)

# Snake segments (a winding path for demo)
SEGMENTS = [
    (2, 5), (3, 5), (4, 5), (5, 5),
    (5, 4), (5, 3), (5, 2), (5, 1),
    (6, 1), (7, 1), (8, 1), (9, 1),
    (9, 2), (9, 3),
]
DIRECTION = (1, 1)  # facing right-down for eyes

HEAD_COLOR = (50, 235, 115)
BODY_COLOR = (45, 200, 95)
TAIL_COLOR = (30, 155, 75)
BELLY_COLOR = (90, 240, 130)
BLUSH = (255, 115, 140)
EYE_WHITE = (255, 255, 255)
PUPIL = (25, 25, 25)
HIGHLIGHT = (255, 255, 255)


def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def seg_center(seg):
    return (seg[0] * CELL + CELL // 2, seg[1] * CELL + CELL // 2)


def draw_cute_eyes(draw, cx, cy, size, direction):
    """Draw cute eyes with sparkles"""
    ex = size * 0.32
    ey_off = size * 0.0
    fwd_x = direction[0] * size * 0.12
    fwd_y = direction[1] * size * 0.12
    perp_x = -direction[1]
    perp_y = direction[0]
    dist = size * 0.30

    # Right eye
    rex = cx + fwd_x + perp_x * dist
    rey = cy + fwd_y + perp_y * dist
    # Left eye
    lex = cx + fwd_x - perp_x * dist
    ley = cy + fwd_y - perp_y * dist

    es = int(size * 0.22)
    ps = int(es * 0.55)

    # Eye whites
    draw.ellipse([rex - es, rey - es, rex + es, rey + es], fill=EYE_WHITE)
    draw.ellipse([lex - es, ley - es, lex + es, ley + es], fill=EYE_WHITE)

    # Pupils
    psx = direction[0] * es * 0.2
    psy = direction[1] * es * 0.2
    draw.ellipse([rex + psx - ps, rey + psy - ps, rex + psx + ps, rey + ps + ps], fill=PUPIL)
    draw.ellipse([lex + psx - ps, ley + psy - ps, lex + psx + ps, ley + psy + ps], fill=PUPIL)

    # Sparkle highlights
    hs = int(es * 0.28)
    hlx = -es * 0.25
    hly = -es * 0.30
    draw.ellipse([rex + hlx - hs, rey + hly - hs, rex + hlx + hs, rey + hly + hs], fill=HIGHLIGHT)
    draw.ellipse([lex + hlx - hs, ley + hly - hs, lex + hlx + hs, ley + hly + hs], fill=HIGHLIGHT)

    hs2 = int(hs * 0.5)
    draw.ellipse([rex + es * 0.15 - hs2, rey + es * 0.1 - hs2, rex + es * 0.15 + hs2, rey + es * 0.1 + hs2], fill=(255, 255, 255, 180))
    draw.ellipse([lex + es * 0.15 - hs2, ley + es * 0.1 - hs2, lex + es * 0.15 + hs2, ley + es * 0.1 + hs2], fill=(255, 255, 255, 180))


def draw_blush(draw, cx, cy, size, direction):
    fwd_x = direction[0] * size * 0.08
    fwd_y = direction[1] * size * 0.08
    perp_x = -direction[1]
    perp_y = direction[0]
    dist = size * 0.40
    bs = int(size * 0.13)

    draw.ellipse([cx + fwd_x + perp_x * dist - bs, cy + fwd_y + perp_y * dist - bs,
                  cx + fwd_x + perp_x * dist + bs, cy + fwd_y + perp_y * dist + bs],
                 fill=(BLUSH[0], BLUSH[1], BLUSH[2], 90))
    draw.ellipse([cx + fwd_x - perp_x * dist - bs, cy + fwd_y - perp_y * dist - bs,
                  cx + fwd_x - perp_x * dist + bs, cy + fwd_y - perp_y * dist + bs],
                 fill=(BLUSH[0], BLUSH[1], BLUSH[2], 90))


def get_seg_size(i, seg_count):
    """Get segment size based on position"""
    t = i / max(seg_count - 1, 1)
    if i == 0:
        return CELL * 0.88
    elif i <= 2:
        ht = i / 3.0
        return CELL * 0.88 + (CELL * 0.80 - CELL * 0.88) * ht
    else:
        return CELL * 0.80 + (CELL * 0.55 - CELL * 0.80) * t


def get_seg_color(i, seg_count):
    t = i / max(seg_count - 1, 1)
    return lerp_color(HEAD_COLOR, TAIL_COLOR, t)


# ============ STYLE 1: Pure Square (Pixel Classic) ============
def style_01_square():
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG + (255,))
    draw = ImageDraw.Draw(img)
    n = len(SEGMENTS)

    # Connections
    for i in range(n - 1):
        x1, y1 = SEGMENTS[i]
        x2, y2 = SEGMENTS[i + 1]
        c1 = seg_center(SEGMENTS[i])
        c2 = seg_center(SEGMENTS[i + 1])
        s1 = get_seg_size(i, n) / 2
        s2 = get_seg_size(i + 1, n) / 2
        color = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        x_min = min(c1[0] - s1, c2[0] - s2)
        y_min = min(c1[1] - s1, c2[1] - s2)
        x_max = max(c1[0] + s1, c2[0] + s2)
        y_max = max(c1[1] + s1, c2[1] + s2)
        draw.rectangle([x_min, y_min, x_max, y_max], fill=color)

    # Segments (tail to head)
    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        draw.rectangle([c[0] - s, c[1] - s, c[0] + s, c[1] + s], fill=color)

    # Eyes
    hc = seg_center(SEGMENTS[0])
    draw_cute_eyes(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)
    draw_blush(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)

    # Label
    try:
        font = ImageFont.truetype("arial.ttf", 20)
        font_sm = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()
        font_sm = font

    draw.text((20, 610), "1. Pure Square", fill=(255, 255, 255), font=font)
    draw.text((20, 640), "Classic pixel style, sharp edges", fill=(160, 165, 180), font=font_sm)
    return img


# ============ STYLE 2: Rounded Square ============
def style_02_rounded():
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG + (255,))
    draw = ImageDraw.Draw(img)
    n = len(SEGMENTS)

    for i in range(n - 1):
        c1 = seg_center(SEGMENTS[i])
        c2 = seg_center(SEGMENTS[i + 1])
        s1 = get_seg_size(i, n) / 2
        s2 = get_seg_size(i + 1, n) / 2
        color = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        x_min = min(c1[0] - s1, c2[0] - s2)
        y_min = min(c1[1] - s1, c2[1] - s2)
        x_max = max(c1[0] + s1, c2[0] + s2)
        y_max = max(c1[1] + s1, c2[1] + s2)
        draw.rounded_rectangle([x_min, y_min, x_max, y_max], radius=8, fill=color)

    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        r = int(s * 0.3)
        draw.rounded_rectangle([c[0] - s, c[1] - s, c[0] + s, c[1] + s], radius=r, fill=color)
        if i % 3 == 0 and i > 2:
            stripe = lerp_color(color, BELLY_COLOR, 0.3)
            stripe_a = (stripe[0], stripe[1], stripe[2], 50)
            inset = int(s * 0.2)
            draw.rounded_rectangle([c[0] - s + inset, c[1] - s + inset, c[0] + s - inset, c[1] + s - inset], radius=r-2, fill=stripe_a)

    hc = seg_center(SEGMENTS[0])
    draw_cute_eyes(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)
    draw_blush(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)

    try:
        font = ImageFont.truetype("arial.ttf", 20)
        font_sm = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()
        font_sm = font
    draw.text((20, 610), "2. Rounded Square", fill=(255, 255, 255), font=font)
    draw.text((20, 640), "Soft corners, friendly look", fill=(160, 165, 180), font=font_sm)
    return img


# ============ STYLE 3: Circles (Original) ============
def style_03_circles():
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG + (255,))
    draw = ImageDraw.Draw(img)
    n = len(SEGMENTS)

    # Connections
    for i in range(n - 1):
        c1 = seg_center(SEGMENTS[i])
        c2 = seg_center(SEGMENTS[i + 1])
        s1 = get_seg_size(i, n) / 2
        s2 = get_seg_size(i + 1, n) / 2
        color = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        dx, dy = c2[0] - c1[0], c2[1] - c1[1]
        dist = math.sqrt(dx*dx + dy*dy)
        if dist < 1:
            continue
        nx, ny = -dy/dist, dx/dist
        mid_s = (s1 + s2) / 2
        pts = [
            (c1[0] + nx * s1 * 0.9, c1[1] + ny * s1 * 0.9),
            (c2[0] + nx * s2 * 0.9, c2[1] + ny * s2 * 0.9),
            (c2[0] - nx * s2 * 0.9, c2[1] - ny * s2 * 0.9),
            (c1[0] - nx * s1 * 0.9, c1[1] - ny * s1 * 0.9),
        ]
        draw.polygon(pts, fill=color)

    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        draw.ellipse([c[0] - s, c[1] - s, c[0] + s, c[1] + s], fill=color)
        belly = (BELLY_COLOR[0], BELLY_COLOR[1], BELLY_COLOR[2], 40)
        draw.ellipse([c[0] - s*0.5, c[1], c[0] + s*0.5, c[1] + s*0.7], fill=belly)

    hc = seg_center(SEGMENTS[0])
    draw_cute_eyes(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)
    draw_blush(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)

    try:
        font = ImageFont.truetype("arial.ttf", 20)
        font_sm = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()
        font_sm = font
    draw.text((20, 610), "3. Circles", fill=(255, 255, 255), font=font)
    draw.text((20, 640), "Smooth round body, bubbly feel", fill=(160, 165, 180), font=font_sm)
    return img


# ============ STYLE 4: Pill / Capsule ============
def style_04_pill():
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG + (255,))
    draw = ImageDraw.Draw(img)
    n = len(SEGMENTS)

    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        # Draw as pill: rectangle with semicircle ends
        # Determine orientation
        if i < n - 1:
            nc = seg_center(SEGMENTS[i + 1])
        else:
            nc = seg_center(SEGMENTS[i - 1])
        dx = nc[0] - c[0]
        dy = nc[1] - c[1]
        
        # Always draw as rounded rect with big radius
        r = int(s * 0.85)
        draw.rounded_rectangle([c[0] - s, c[1] - s, c[0] + s, c[1] + s], radius=r, fill=color)

    # Connections
    for i in range(n - 1):
        c1 = seg_center(SEGMENTS[i])
        c2 = seg_center(SEGMENTS[i + 1])
        s1 = get_seg_size(i, n) / 2
        s2 = get_seg_size(i + 1, n) / 2
        color = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        x_min = min(c1[0] - s1, c2[0] - s2)
        y_min = min(c1[1] - s1, c2[1] - s2)
        x_max = max(c1[0] + s1, c2[0] + s2)
        y_max = max(c1[1] + s1, c2[1] + s2)
        draw.rounded_rectangle([x_min, y_min, x_max, y_max], radius=int(min(s1, s2) * 0.8), fill=color)

    hc = seg_center(SEGMENTS[0])
    draw_cute_eyes(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)
    draw_blush(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)

    try:
        font = ImageFont.truetype("arial.ttf", 20)
        font_sm = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()
        font_sm = font
    draw.text((20, 610), "4. Pill / Capsule", fill=(255, 255, 255), font=font)
    draw.text((20, 640), "Rounded pill shape, smooth body", fill=(160, 165, 180), font=font_sm)
    return img


# ============ STYLE 5: Diamond ============
def style_05_diamond():
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG + (255,))
    draw = ImageDraw.Draw(img)
    n = len(SEGMENTS)

    # Connections
    for i in range(n - 1):
        c1 = seg_center(SEGMENTS[i])
        c2 = seg_center(SEGMENTS[i + 1])
        s1 = get_seg_size(i, n) / 2
        s2 = get_seg_size(i + 1, n) / 2
        color = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        hw = max(s1, s2)
        hh = abs(c1[1] - c2[1]) / 2 + min(s1, s2)
        draw.rectangle([min(c1[0], c2[0]) - hw, min(c1[1], c2[1]) - hh,
                       max(c1[0], c2[0]) + hw, max(c1[1], c2[1]) + hh], fill=color)

    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        pts = [(c[0], c[1] - s), (c[0] + s, c[1]), (c[0], c[1] + s), (c[0] - s, c[1])]
        draw.polygon(pts, fill=color)
        # Inner diamond
        inner = 0.55
        inner_color = lerp_color(color, BELLY_COLOR, 0.4)
        pts2 = [(c[0], c[1] - s * inner), (c[0] + s * inner, c[1]),
                 (c[0], c[1] + s * inner), (c[0] - s * inner, c[1])]
        draw.polygon(pts2, fill=inner_color + (60,))

    hc = seg_center(SEGMENTS[0])
    draw_cute_eyes(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)
    draw_blush(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)

    try:
        font = ImageFont.truetype("arial.ttf", 20)
        font_sm = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()
        font_sm = font
    draw.text((20, 610), "5. Diamond", fill=(255, 255, 255), font=font)
    draw.text((20, 640), "Rotated squares, elegant geometric", fill=(160, 165, 180), font=font_sm)
    return img


# ============ STYLE 6: Hexagon ============
def style_06_hexagon():
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG + (255,))
    draw = ImageDraw.Draw(img)
    n = len(SEGMENTS)

    def hex_points(cx, cy, s):
        pts = []
        for k in range(6):
            a = math.pi / 6 + k * math.pi / 3
            pts.append((cx + s * math.cos(a), cy + s * math.sin(a)))
        return pts

    # Connections
    for i in range(n - 1):
        c1 = seg_center(SEGMENTS[i])
        c2 = seg_center(SEGMENTS[i + 1])
        s1 = get_seg_size(i, n) / 2
        s2 = get_seg_size(i + 1, n) / 2
        color = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        x_min = min(c1[0] - s1, c2[0] - s2)
        y_min = min(c1[1] - s1, c2[1] - s2)
        x_max = max(c1[0] + s1, c2[0] + s2)
        y_max = max(c1[1] + s1, c2[1] + s2)
        draw.rectangle([x_min, y_min, x_max, y_max], fill=color)

    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        pts = hex_points(c[0], c[1], s)
        draw.polygon(pts, fill=color)
        # Inner hex
        inner_pts = hex_points(c[0], c[1], s * 0.6)
        belly = (BELLY_COLOR[0], BELLY_COLOR[1], BELLY_COLOR[2], 35)
        draw.polygon(inner_pts, fill=belly)

    hc = seg_center(SEGMENTS[0])
    draw_cute_eyes(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)
    draw_blush(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)

    try:
        font = ImageFont.truetype("arial.ttf", 20)
        font_sm = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()
        font_sm = font
    draw.text((20, 610), "6. Hexagon", fill=(255, 255, 255), font=font)
    draw.text((20, 640), "Honeycomb segments, nature vibe", fill=(160, 165, 180), font=font_sm)
    return img


# ============ STYLE 7: Squircle (Ultra-Rounded) ============
def style_07_squircle():
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG + (255,))
    draw = ImageDraw.Draw(img)
    n = len(SEGMENTS)

    for i in range(n - 1):
        c1 = seg_center(SEGMENTS[i])
        c2 = seg_center(SEGMENTS[i + 1])
        s1 = get_seg_size(i, n) / 2
        s2 = get_seg_size(i + 1, n) / 2
        color = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        x_min = min(c1[0] - s1, c2[0] - s2)
        y_min = min(c1[1] - s1, c2[1] - s2)
        x_max = max(c1[0] + s1, c2[0] + s2)
        y_max = max(c1[1] + s1, c2[1] + s2)
        draw.rounded_rectangle([x_min, y_min, x_max, y_max], radius=int((x_max - x_min) / 2), fill=color)

    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        r = int(s * 0.95)
        draw.rounded_rectangle([c[0] - s, c[1] - s, c[0] + s, c[1] + s], radius=r, fill=color)
        # Subtle outline
        outline = tuple(max(0, x - 30) for x in color)
        draw.rounded_rectangle([c[0] - s, c[1] - s, c[0] + s, c[1] + s], radius=r, outline=outline, width=2)

    hc = seg_center(SEGMENTS[0])
    draw_cute_eyes(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)
    draw_blush(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)

    try:
        font = ImageFont.truetype("arial.ttf", 20)
        font_sm = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()
        font_sm = font
    draw.text((20, 610), "7. Squircle (Ultra-Rounded)", fill=(255, 255, 255), font=font)
    draw.text((20, 640), "iOS-style, modern & sleek", fill=(160, 165, 180), font=font_sm)
    return img


# ============ STYLE 8: Star / Cross-Shape ============
def style_08_star():
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG + (255,))
    draw = ImageDraw.Draw(img)
    n = len(SEGMENTS)

    # Connections
    for i in range(n - 1):
        c1 = seg_center(SEGMENTS[i])
        c2 = seg_center(SEGMENTS[i + 1])
        s1 = get_seg_size(i, n) / 2 * 0.7
        s2 = get_seg_size(i + 1, n) / 2 * 0.7
        color = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        draw.line([c1, c2], fill=color, width=int(max(s1, s2) * 2))

    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        # 4-pointed star / plus sign
        pts = [
            (c[0], c[1] - s),
            (c[0] + s * 0.45, c[1] - s * 0.45),
            (c[0] + s, c[1]),
            (c[0] + s * 0.45, c[1] + s * 0.45),
            (c[0], c[1] + s),
            (c[0] - s * 0.45, c[1] + s * 0.45),
            (c[0] - s, c[1]),
            (c[0] - s * 0.45, c[1] - s * 0.45),
        ]
        draw.polygon(pts, fill=color)

    hc = seg_center(SEGMENTS[0])
    draw_cute_eyes(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)
    draw_blush(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)

    try:
        font = ImageFont.truetype("arial.ttf", 20)
        font_sm = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()
        font_sm = font
    draw.text((20, 610), "8. Star / Cross", fill=(255, 255, 255), font=font)
    draw.text((20, 640), "Pointed star segments, edgy", fill=(160, 165, 180), font=font_sm)
    return img


# ============ STYLE 9: Blob (Organic) ============
def style_09_blob():
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG + (255,))
    draw = ImageDraw.Draw(img)
    n = len(SEGMENTS)

    # Draw as overlapping circles with larger radius for blob effect
    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2 * 1.15  # slightly larger for overlap
        color = get_seg_color(i, n)
        draw.ellipse([c[0] - s, c[1] - s, c[0] + s, c[1] + s], fill=color)
        # Inner soft highlight
        hs = s * 0.6
        highlight = lerp_color(color, (255, 255, 255), 0.15)
        draw.ellipse([c[0] - hs - 2, c[1] - hs - 2, c[0] + hs - 2, c[1] + hs - 2], fill=highlight + (30,))

    # Belly overlay on bottom half
    for i in range(n - 1, 0, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        draw.ellipse([c[0] - s * 0.6, c[1], c[0] + s * 0.6, c[1] + s * 0.8],
                     fill=(BELLY_COLOR[0], BELLY_COLOR[1], BELLY_COLOR[2], 35))

    hc = seg_center(SEGMENTS[0])
    draw_cute_eyes(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)
    draw_blush(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)

    try:
        font = ImageFont.truetype("arial.ttf", 20)
        font_sm = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()
        font_sm = font
    draw.text((20, 610), "9. Blob (Organic)", fill=(255, 255, 255), font=font)
    draw.text((20, 640), "Soft overlapping circles, like a caterpillar", fill=(160, 165, 180), font=font_sm)
    return img


# ============ STYLE 10: Gradient Block with Border ============
def style_10_bordered():
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG + (255,))
    draw = ImageDraw.Draw(img)
    n = len(SEGMENTS)

    # Dark outline layer
    for i in range(n - 1):
        c1 = seg_center(SEGMENTS[i])
        c2 = seg_center(SEGMENTS[i + 1])
        s1 = get_seg_size(i, n) / 2 + 3
        s2 = get_seg_size(i + 1, n) / 2 + 3
        outline = (20, 100, 45)
        x_min = min(c1[0] - s1, c2[0] - s2)
        y_min = min(c1[1] - s1, c2[1] - s2)
        x_max = max(c1[0] + s1, c2[0] + s2)
        y_max = max(c1[1] + s1, c2[1] + s2)
        draw.rounded_rectangle([x_min, y_min, x_max, y_max], radius=6, fill=outline)

    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2 + 3
        outline = (20, 100, 45)
        draw.rounded_rectangle([c[0] - s, c[1] - s, c[0] + s, c[1] + s], radius=6, fill=outline)

    # Fill layer
    for i in range(n - 1):
        c1 = seg_center(SEGMENTS[i])
        c2 = seg_center(SEGMENTS[i + 1])
        s1 = get_seg_size(i, n) / 2
        s2 = get_seg_size(i + 1, n) / 2
        color = lerp_color(BODY_COLOR, TAIL_COLOR, i / max(n - 1, 1))
        x_min = min(c1[0] - s1, c2[0] - s2)
        y_min = min(c1[1] - s1, c2[1] - s2)
        x_max = max(c1[0] + s1, c2[0] + s2)
        y_max = max(c1[1] + s1, c2[1] + s2)
        draw.rounded_rectangle([x_min, y_min, x_max, y_max], radius=5, fill=color)

    for i in range(n - 1, -1, -1):
        c = seg_center(SEGMENTS[i])
        s = get_seg_size(i, n) / 2
        color = get_seg_color(i, n)
        draw.rounded_rectangle([c[0] - s, c[1] - s, c[0] + s, c[1] + s], radius=5, fill=color)
        # Top highlight
        hl = lerp_color(color, (255, 255, 255), 0.2)
        inset = int(s * 0.15)
        draw.rounded_rectangle([c[0] - s + inset, c[1] - s + inset, c[0] + s - inset, c[1]],
                              radius=4, fill=hl + (40,))
        # Bottom shadow
        sh = lerp_color(color, (0, 0, 0), 0.2)
        draw.rounded_rectangle([c[0] - s + inset, c[1], c[0] + s - inset, c[1] + s - inset],
                              radius=4, fill=sh + (30,))

    hc = seg_center(SEGMENTS[0])
    draw_cute_eyes(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)
    draw_blush(draw, hc[0], hc[1], CELL * 0.88, DIRECTION)

    try:
        font = ImageFont.truetype("arial.ttf", 20)
        font_sm = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()
        font_sm = font
    draw.text((20, 610), "10. Bordered Block", fill=(255, 255, 255), font=font)
    draw.text((20, 640), "Outlined blocks with 3D shading", fill=(160, 165, 180), font=font_sm)
    return img


# Generate all styles
styles = [
    style_01_square,
    style_02_rounded,
    style_03_circles,
    style_04_pill,
    style_05_diamond,
    style_06_hexagon,
    style_07_squircle,
    style_08_star,
    style_09_blob,
    style_10_bordered,
]

out_dir = r"G:\autoclawcode\dev\snake_styles"
os.makedirs(out_dir, exist_ok=True)

for i, style_fn in enumerate(styles):
    img = style_fn()
    path = os.path.join(out_dir, f"style_{i+1:02d}.png")
    img.save(path)
    print(f"Saved: {path}")

print(f"\nAll {len(styles)} styles generated in: {out_dir}")
