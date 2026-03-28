const fs = require('fs');
const p = 'G:\\autoclawcode\\scripts\\Main.gd';
let c = fs.readFileSync(p, 'utf8');

// 1. Replace _draw_forest_tile with 5 pattern variants
const o1 = `func _draw_forest_tile(x: int, y: int, px: float, py: float) -> void:
\tvar seed_val: int = x * 137 + y * 59

\t# Dense overlapping canopy clusters that fill the entire tile
\tvar blobs: Array[Dictionary] = []
\t# Large base blobs (fully cover the tile)
\tfor i in range(4):
\t\tblobs.append({
\t\t\t"cx": px + CELL_SIZE * 0.25 + float(i) * CELL_SIZE * 0.2 + float((seed_val * (i + 1) * 7) % 6),
\t\t\t"cy": py + CELL_SIZE * 0.4 + float((seed_val * (i + 2) * 11) % 8),
\t\t\t"r": 13.0 + float((seed_val * (i + 3) * 3) % 5),
\t\t})
\t# Medium overlap blobs (fill gaps)
\tfor i in range(3):
\t\tblobs.append({
\t\t\t"cx": px + 5.0 + float((seed_val + i * 31) % 30),
\t\t\t"cy": py + 3.0 + float((seed_val + i * 47) % 34),
\t\t\t"r": 10.0 + float(i * 2),
\t\t})
\t# Small detail blobs (corners and edges)
\tblobs.append({"cx": px + 3.0, "cy": py + 3.0, "r": 8.0})
\tblobs.append({"cx": px + CELL_SIZE - 3.0, "cy": py + 3.0, "r": 8.0})
\tblobs.append({"cx": px + 3.0, "cy": py + CELL_SIZE - 3.0, "r": 8.0})
\tblobs.append({"cx": px + CELL_SIZE - 3.0, "cy": py + CELL_SIZE - 3.0, "r": 8.0})

\t# Layer 1: Deep shadow blobs
\tfor b in blobs:
\t\tdraw_circle(Vector2(b["cx"] + 1.5, b["cy"] + 1.5), b["r"],
\t\t\tColor(0.02, 0.06, 0.01, 0.6))

\t# Layer 2: Darkest canopy base
\tfor b in blobs:
\t\tdraw_circle(Vector2(b["cx"], b["cy"]), b["r"],
\t\t\tColor(0.05, 0.18, 0.03, 0.95))

\t# Layer 3: Mid-green variety
\tfor b in blobs:
\t\tvar g: float = 0.22 + float((seed_val + int(b["cx"])) % 10) * 0.015
\t\tdraw_circle(Vector2(b["cx"], b["cy"] - 1.0), b["r"] * 0.82,
\t\t\tColor(0.08, g, 0.05, 0.85))

\t# Layer 4: Lighter highlights (scattered)
\tfor i in range(5):
\t\tvar hx: float = px + 6.0 + float((seed_val + i * 41) % 28)
\t\tvar hy: float = py + 6.0 + float((seed_val + i * 53) % 28)
\t\tdraw_circle(Vector2(hx, hy), 5.0 + float(i % 3),
\t\t\tColor(0.14, 0.36, 0.08, 0.4))

\t# Layer 5: Bright leaf speckles
\tfor i in range(8):
\t\tvar sx: float = px + 4.0 + float((seed_val + i * 29) % 32)
\t\tvar sy: float = py + 4.0 + float((seed_val + i * 43) % 32)
\t\tdraw_circle(Vector2(sx, sy), 2.0,
\t\t\tColor(0.20, 0.44, 0.12, 0.35))`;

const n1 = `func _draw_forest_tile(x: int, y: int, px: float, py: float) -> void:
\tvar variant: int = (x * 73 + y * 137) % 5
\tvar s: int = x * 53 + y * 97
\tvar cx: float = px + CELL_SIZE / 2.0
\tvar cy: float = py + CELL_SIZE / 2.0
\tmatch variant:
\t\t0: _forest_variant_0(x, y, px, py, s)
\t\t1: _forest_variant_1(x, y, px, py, s)
\t\t2: _forest_variant_2(x, y, px, py, s)
\t\t3: _forest_variant_3(x, y, px, py, s)
\t\t4: _forest_variant_4(x, y, px, py, s)

# --- Forest Pattern A: Dense round canopy blobs ---
func _forest_variant_0(x: int, y: int, px: float, py: float, s: int) -> void:
\tvar blobs: Array[Array] = []
\tfor i in range(5):
\t\tblobs.append([
\t\t\tpx + 8.0 + float((s + i * 23) % 24),
\t\t\tpy + 8.0 + float((s + i * 37) % 24),
\t\t\t10.0 + float((s + i * 7) % 6)])
\t# Layer: deep shadow
\tfor b in blobs:
\t\tdraw_circle(Vector2(b[0] + 1.5, b[1] + 1.5), b[2], Color(0.02, 0.06, 0.01, 0.6))
\t# Layer: dark base
\tfor b in blobs:
\t\tdraw_circle(Vector2(b[0], b[1]), b[2], Color(0.05, 0.18, 0.03, 0.95))
\t# Layer: mid green
\tfor b in blobs:
\t\tdraw_circle(Vector2(b[0], b[1] - 1.0), b[2] * 0.8, Color(0.08, 0.30, 0.05, 0.85))
\t# Highlights
\tfor i in range(4):
\t\tdraw_circle(Vector2(px + 5.0 + float((s + i * 41) % 30), py + 5.0 + float((s + i * 53) % 30),
\t\t\t4.0, Color(0.14, 0.36, 0.08, 0.4))
\tfor i in range(6):
\t\tdraw_circle(Vector2(px + 3.0 + float((s + i * 29) % 34), py + 3.0 + float((s + i * 43) % 34),
\t\t\t2.0, Color(0.20, 0.44, 0.12, 0.3))

# --- Forest Pattern B: Large overlapping layered crowns ---
func _forest_variant_1(x: int, y: int, px: float, py: float, s: int) -> void:
\t# 3 large crown layers
\tvar positions: Array[Array] = [
\t\t[px + CELL_SIZE * 0.3, py + CELL_SIZE * 0.35],
\t\t[px + CELL_SIZE * 0.65, py + CELL_SIZE * 0.45],
\t\t[px + CELL_SIZE * 0.5, py + CELL_SIZE * 0.7],
\t]
\tfor i in range(positions.size()):
\t\tvar bx: float = positions[i][0] + float((s + i * 17) % 5)
\t\tvar by: float = positions[i][1] + float((s + i * 29) % 5)
\t\tvar r: float = 14.0 - float(i) * 1.5
\t\tdraw_circle(Vector2(bx + 1.5, by + 2.0), r, Color(0.02, 0.05, 0.01, 0.5))
\t\tdraw_circle(Vector2(bx, by), r, Color(0.04, 0.16, 0.03, 0.95))
\t\tdraw_circle(Vector2(bx - 1.0, by - 1.5), r * 0.75, Color(0.10, 0.28, 0.06, 0.7))
\t\tdraw_circle(Vector2(bx - 2.0, by - 3.0), r * 0.4, Color(0.16, 0.38, 0.10, 0.4))
\t# Leaf texture dots
\tfor i in range(7):
\t\tdraw_circle(Vector2(px + 4.0 + float((s + i * 31) % 32), py + 4.0 + float((s + i * 47) % 32),
\t\t\t1.5 + float(i % 3), Color(0.18, 0.42, 0.10, 0.35))

# --- Forest Pattern C: Tall triangular pine shapes ---
func _forest_variant_2(x: int, y: int, px: float, py: float, s: int) -> void:
\tfor i in range(3):
\t\tvar tx: float = px + 10.0 + float((s + i * 19) % 20)
\t\tvar ty: float = py + CELL_SIZE - 2.0
\t\tvar h: float = 30.0 + float((s + i * 13) % 8)
\t\t# Trunk
\t\tdraw_rect(Rect2(tx - 1.5, ty - h * 0.4, 3.0, h * 0.4), Color(0.18, 0.12, 0.05, 0.5))
\t\t# 3 triangle layers (pine tiers)
\t\tfor tier in range(3):
\t\t\tvar tier_y: float = ty - h * 0.35 - float(tier) * h * 0.22
\t\t\tvar tier_w: float = 8.0 + float(tier) * 4.0
\t\t\tvar pts: PackedVector2Array = PackedVector2Array([
\t\t\t\tVector2(tx, tier_y - 6.0),
\t\t\t\tVector2(tx - tier_w, tier_y + 5.0),
\t\t\t\tVector2(tx + tier_w, tier_y + 5.0),
\t\t\t])
\t\t\tdraw_colored_polygon(pts, Color(0.04, 0.15, 0.03, 0.9))
\t\t\tdraw_colored_polygon(pts, Color(0.04, 0.15, 0.03, 0.9))
\t\t\t# Highlight on left half
\t\t\tvar hpts: PackedVector2Array = PackedVector2Array([
\t\t\t\tVector2(tx, tier_y - 5.0),
\t\t\t\tVector2(tx - tier_w + 2.0, tier_y + 4.0),
\t\t\t\tVector2(tx, tier_y + 4.0),
\t\t\t])
\t\t\tdraw_colored_polygon(hpts, Color(0.10, 0.26, 0.06, 0.35))
\t# Needle texture
\tfor i in range(5):
\t\tvar nx: float = px + 3.0 + float((s + i * 37) % 34)
\t\tvar ny: float = py + 3.0 + float((s + i * 41) % 34)
\t\tdraw_line(Vector2(nx, ny), Vector2(nx - 2.0, ny + 3.0), Color(0.12, 0.32, 0.06, 0.3), 1.0)

# --- Forest Pattern D: Bushy shrub cluster ---
func _forest_variant_3(x: int, y: int, px: float, py: float, s: int) -> void:
\t# Ground cover
\tdraw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.04, 0.11, 0.03))
\t# 6 overlapping bush circles
\tfor i in range(6):
\t\tvar bx: float = px + 6.0 + float((s + i * 23) % 28)
\t\tvar by: float = py + 6.0 + float((s + i * 37) % 28)
\t\tvar br: float = 7.0 + float((s + i * 11) % 5)
\t\tdraw_circle(Vector2(bx + 1.0, by + 1.0), br, Color(0.02, 0.06, 0.01, 0.4))
\t\tdraw_circle(Vector2(bx, by), br, Color(0.06, 0.20, 0.04, 0.9))
\t\tdraw_circle(Vector2(bx, by), br * 0.7, Color(0.10, 0.30, 0.06, 0.6))
\t\tdraw_circle(Vector2(bx - 1.0, by - 1.0), br * 0.35, Color(0.16, 0.40, 0.10, 0.35))
\t# Small flowers / berries
\tfor i in range(4):
\t\tvar fx: float = px + 5.0 + float((s + i * 43) % 30)
\t\tvar fy: float = py + 5.0 + float((s + i * 59) % 30)
\t\tdraw_circle(Vector2(fx, fy), 1.5, Color(0.25, 0.45, 0.12, 0.4))
\t# Leaf lines
\tfor i in range(5):
\t\tvar lx: float = px + 3.0 + float((s + i * 29) % 34)
\t\tvar ly: float = py + 3.0 + float((s + i * 47) % 34)
\t\tdraw_line(Vector2(lx, ly), Vector2(lx + 3.0, ly - 2.0), Color(0.12, 0.30, 0.06, 0.25), 1.0)

# --- Forest Pattern E: Dark jungle with vine lines ---
func _forest_variant_4(x: int, y: int, px: float, py: float, s: int) -> void:
\t# Darker base
\tdraw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.03, 0.09, 0.02))
\t# Dense canopy (2 large + 3 small)
\tvar big: Array[Array] = [
\t\t[px + 12.0 + float((s * 3) % 8), py + 14.0 + float((s * 5) % 8), 15.0],
\t\t[px + 28.0 + float((s * 7) % 6), py + 22.0 + float((s * 11) % 6), 13.0],
\t]
\tfor b in big:
\t\tdraw_circle(Vector2(b[0] + 1.5, b[1] + 1.5), b[2], Color(0.01, 0.04, 0.01, 0.6))
\t\tdraw_circle(Vector2(b[0], b[1]), b[2], Color(0.04, 0.14, 0.02, 0.95))
\t\tdraw_circle(Vector2(b[0], b[1] - 1.5), b[2] * 0.8, Color(0.07, 0.24, 0.04, 0.8))
\tfor i in range(3):
\t\tvar sx: float = px + 5.0 + float((s + i * 31) % 30)
\t\tvar sy: float = py + 5.0 + float((s + i * 43) % 30)
\t\tdraw_circle(Vector2(sx, sy), 8.0, Color(0.05, 0.16, 0.03, 0.85))
\t\tdraw_circle(Vector2(sx, sy), 5.0, Color(0.09, 0.26, 0.05, 0.6))
\t# Vine lines (curved)
\tfor i in range(3):
\t\tvar vx: float = px + float((s + i * 19) % 30)
\t\tvar vy: float = py
\t\tvar vpts: PackedVector2Array = PackedVector2Array()
\t\tfor d in range(0, CELL_SIZE + 1, 5):
\t\t\tvpts.append(Vector2(vx + sin(float(d) * 0.5 + i) * 4.0, vy + float(d)))
\t\tif vpts.size() >= 2:
\t\t\tdraw_polyline(vpts, Color(0.06, 0.20, 0.04, 0.35), 1.5)
\t# Dark leaf dots
\tfor i in range(6):
\t\tdraw_circle(Vector2(px + 2.0 + float((s + i * 41) % 36), py + 2.0 + float((s + i * 53) % 36),
\t\t\t1.5, Color(0.12, 0.28, 0.06, 0.3))`;

let r1 = c.includes(o1); if(r1) c = c.replace(o1, n1);
console.log('1 Forest:', r1?'OK':'FAIL');

// 2. Replace _draw_river_tile with 5 pattern variants
const o2 = `func _draw_river_tile(x: int, y: int, px: float, py: float) -> void:
\tdraw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.05, 0.12, 0.28))
\tdraw_rect(Rect2(px + 2, py + 2, CELL_SIZE - 4, CELL_SIZE - 4), Color(0.04, 0.10, 0.24, 0.5))
\tvar wave_off: float = anim_timer * 2.5 + float(x) * 0.9 + float(y) * 0.4
\tfor w in range(3):
\t\tvar wy: float = py + 8.0 + float(w) * 12.0
\t\tvar pts: PackedVector2Array = PackedVector2Array()
\t\tfor d in range(0, CELL_SIZE + 1, 3):
\t\t\tvar wx: float = px + float(d)
\t\t\tvar wwy: float = wy + sin(wave_off + float(d) * 0.28 + float(w) * 1.8) * 2.0
\t\t\tpts.append(Vector2(wx, wwy))
\t\tif pts.size() >= 2:
\t\t\tdraw_polyline(pts, Color(0.2, 0.38, 0.65, 0.3), 1.5)
\tvar sparkle: float = sin(anim_timer * 3.5 + float(x) * 2.3 + float(y) * 1.7)
\tif sparkle > 0.65:
\t\tdraw_circle(Vector2(px + CELL_SIZE * 0.55, py + CELL_SIZE * 0.35), 1.5, Color(0.5, 0.7, 1.0, sparkle * 0.35))
\tsparkle = sin(anim_timer * 2.8 + float(x) * 1.1 + float(y) * 2.9 + 2.0)
\tif sparkle > 0.7:
\t\tdraw_circle(Vector2(px + CELL_SIZE * 0.3, py + CELL_SIZE * 0.7), 1.2, Color(0.5, 0.7, 1.0, sparkle * 0.25))`;

const n2 = `func _draw_river_tile(x: int, y: int, px: float, py: float) -> void:
\tvar variant: int = (x * 89 + y * 163) % 5
\tvar s: int = x * 61 + y * 113
\tmatch variant:
\t\t0: _river_variant_0(x, y, px, py, s)
\t\t1: _river_variant_1(x, y, px, py, s)
\t\t2: _river_variant_2(x, y, px, py, s)
\t\t3: _river_variant_3(x, y, px, py, s)
\t\t4: _river_variant_4(x, y, px, py, s)

# --- River Pattern A: Horizontal sine waves ---
func _river_variant_0(x: int, y: int, px: float, py: float, s: int) -> void:
\tdraw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.05, 0.12, 0.28))
\tdraw_rect(Rect2(px + 2, py + 2, CELL_SIZE - 4, CELL_SIZE - 4), Color(0.04, 0.10, 0.24, 0.5))
\tvar wave_off: float = anim_timer * 2.5 + float(x) * 0.9 + float(y) * 0.4
\tfor w in range(3):
\t\tvar wy: float = py + 8.0 + float(w) * 12.0
\t\tvar pts: PackedVector2Array = PackedVector2Array()
\t\tfor d in range(0, CELL_SIZE + 1, 3):
\t\t\tvar wx: float = px + float(d)
\t\t\tvar wwy: float = wy + sin(wave_off + float(d) * 0.28 + float(w) * 1.8) * 2.0
\t\t\tpts.append(Vector2(wx, wwy))
\t\tif pts.size() >= 2:
\t\t\tdraw_polyline(pts, Color(0.2, 0.38, 0.65, 0.3), 1.5)
\t_river_sparkles(x, y, px, py, s)

# --- River Pattern B: Diagonal flow lines ---
func _river_variant_1(x: int, y: int, px: float, py: float, s: int) -> void:
\tdraw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.04, 0.11, 0.26))
\tvar flow_off: float = anim_timer * 3.0 + float(x) * 1.2 + float(y) * 0.7
\tfor i in range(5):
\t\tvar ly: float = py - 10.0 + float(i) * 12.0 + float(flow_off % 12.0)
\t\tvar pts: PackedVector2Array = PackedVector2Array()
\t\tfor d in range(0, CELL_SIZE + 20, 3):
\t\t\tvar dx: float = px + float(d)
\t\t\tvar dy: float = ly + float(d) * 0.6 + sin(flow_off + float(d) * 0.2) * 1.5
\t\t\tif dy >= py and dy <= py + CELL_SIZE:
\t\t\t\tps.append(Vector2(dx, dy))
\t\tif pts.size() >= 2:
\t\t\tdraw_polyline(pts, Color(0.18, 0.35, 0.60, 0.35), 1.5)
\t_river_sparkles(x, y, px, py, s)

# --- River Pattern C: Concentric ripples ---
func _river_variant_2(x: int, y: int, px: float, py: float, s: int) -> void:
\tdraw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.05, 0.13, 0.30))
\tdraw_rect(Rect2(px + 2, py + 2, CELL_SIZE - 4, CELL_SIZE - 4), Color(0.04, 0.11, 0.25, 0.5))
\tvar rcx: float = px + CELL_SIZE * 0.5
\tvar rcy: float = py + CELL_SIZE * 0.5
\tvar ripple_off: float = anim_timer * 2.0 + float(x) + float(y)
\tfor r in range(3):
\t\tvar base_r: float = 4.0 + float(r) * 6.0
\t\tvar rr: float = base_r + sin(ripple_off + float(r) * 2.0) * 2.0
\t\tif rr > 1.0:
\t\t\tdraw_circle(Vector2(rcx, rcy), rr, Color(0.15, 0.30, 0.55, 0.25), false, 1.5)
\t_river_sparkles(x, y, px, py, s)

# --- River Pattern D: Deep water with caustic light ---
func _river_variant_3(x: int, y: int, px: float, py: float, s: int) -> void:
\t# Deeper blue tones
\tdraw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.03, 0.08, 0.22))
\tdraw_rect(Rect2(px + 3, py + 3, CELL_SIZE - 6, CELL_SIZE - 6), Color(0.03, 0.07, 0.20, 0.6))
\t# Caustic light patches (animated irregular shapes)
\tvar caus_off: float = anim_timer * 1.8 + float(x) * 2.1 + float(y) * 1.3
\tfor i in range(4):
\t\tvar lx: float = px + 6.0 + float((s + i * 23) % 28)
\t\tvar ly: float = py + 6.0 + float((s + i * 37) % 28)
\t\tvar lsize: float = 3.0 + sin(caus_off + float(i) * 1.5) * 2.0
\t\tif lsize > 1.0:
\t\t\tdraw_circle(Vector2(lx, ly), lsize, Color(0.15, 0.30, 0.55, 0.3))
\t\t\tdraw_circle(Vector2(lx - 1.0, ly - 1.0), lsize * 0.5, Color(0.25, 0.45, 0.70, 0.2))
\t_river_sparkles(x, y, px, py, s)

# --- River Pattern E: Choppy waves with foam dots ---
func _river_variant_4(x: int, y: int, px: float, py: float, s: int) -> void:
\tdraw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.06, 0.14, 0.30))
\t# Horizontal choppy wave crests
\tvar chop_off: float = anim_timer * 3.5 + float(x) * 1.5 + float(y) * 0.8
\tfor w in range(4):
\t\tvar wy: float = py + 5.0 + float(w) * 10.0
\t\tvar pts: PackedVector2Array = PackedVector2Array()
\t\tfor d in range(0, CELL_SIZE + 1, 2):
\t\t\tvar wx: float = px + float(d)
\t\t\tvar wwy: float = wy + sin(chop_off + float(d) * 0.4 + float(w) * 2.5) * 3.0
\t\t\tps.append(Vector2(wx, wwy))
\t\tif pts.size() >= 2:
\t\t\tdraw_polyline(pts, Color(0.25, 0.42, 0.65, 0.35), 1.0)
\t\t# Foam dots on crests
\t\tfor f in range(2):
\t\t\tvar fx: float = px + 8.0 + float((s + w * 17 + f * 31) % 24)
\t\t\tvar fy: float = wy + sin(chop_off + float(fx - px) * 0.4) * 3.0
\t\t\tif fy > py and fy < py + CELL_SIZE:
\t\t\t\tdraw_circle(Vector2(fx, fy), 1.5, Color(0.5, 0.65, 0.85, 0.3))
\t_river_sparkles(x, y, px, py, s)

# --- Shared: animated sparkle for all river variants ---
func _river_sparkles(x: int, y: int, px: float, py: float, s: int) -> void:
\tvar sp1: float = sin(anim_timer * 3.5 + float(x) * 2.3 + float(y) * 1.7)
\tif sp1 > 0.65:
\t\tdraw_circle(Vector2(px + CELL_SIZE * 0.55, py + CELL_SIZE * 0.35), 1.5, Color(0.5, 0.7, 1.0, sp1 * 0.35))
\tvar sp2: float = sin(anim_timer * 2.8 + float(x) * 1.1 + float(y) * 2.9 + 2.0)
\tif sp2 > 0.7:
\t\tdraw_circle(Vector2(px + CELL_SIZE * 0.3, py + CELL_SIZE * 0.7), 1.2, Color(0.5, 0.7, 1.0, sp2 * 0.25))`;

let r2 = c.includes(o2); if(r2) c = c.replace(o2, n2);
console.log('2 River:', r2?'OK':'FAIL');

fs.writeFileSync(p, c, 'utf8');
console.log(r1&&r2 ? 'Written OK' : 'FAILED');
