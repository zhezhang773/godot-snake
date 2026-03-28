extends Node2D
class_name TerrainSystem

# =========================================================
# Configuration
# =========================================================
const DEFAULT_CELL_SIZE: int = 40

# Terrain
enum Terrain { GROUND, FOREST, RIVER }
const NUM_FOREST_CLUSTERS_MIN: int = 6
const NUM_FOREST_CLUSTERS_MAX: int = 8
const FOREST_CLUSTER_MIN: int = 12
const FOREST_CLUSTER_MAX: int = 18
const NUM_RIVER_CLUSTERS_MIN: int = 5
const NUM_RIVER_CLUSTERS_MAX: int = 7
const RIVER_CLUSTER_MIN: int = 10
const RIVER_CLUSTER_MAX: int = 16
const RIVER_SPEED_PENALTY: float = 0.7

# Wormhole
const MAX_WORMHOLE_PAIRS: int = 2
const WORMHOLE_MIN_DIST: int = 5

# Level gate
const GATE_OPEN_SCORE_PER_LEVEL: int = 50

# =========================================================
# State
# =========================================================
var tiles: Array = []
var river_variants: Array = []
var wormholes: Array[Dictionary] = []
var wormhole_cooldown: bool = false

# Gate
var gate_pos: Vector2i = Vector2i(-1, -1)
var gate_open: bool = false
var gate_level: int = 1
var gate_anim: float = 0.0
var gate_flash: float = 0.0

# Grid settings
var CELL_SIZE: int = DEFAULT_CELL_SIZE
var GRID_WIDTH: int = 20
var GRID_HEIGHT: int = 20

# Colors
var bg_color: Color = Color(0.06, 0.08, 0.12, 1.0)
var border_color: Color = Color(0.3, 0.4, 0.55, 1.0)

# Wormhole color palettes
var wormhole_palettes: Array[Array] = [
	[Color(0.91, 0.28, 0.47), Color(1.0, 0.5, 0.65), Color(0.55, 0.12, 0.25), Color(0.91, 0.28, 0.47)],
	[Color(0.2, 0.6, 0.95), Color(0.45, 0.75, 1.0), Color(0.1, 0.3, 0.6), Color(0.2, 0.6, 0.95)],
]

# Audio reference
var audio_manager: Node = null

# Particles reference
var particles: Array[Dictionary] = []

# Floating texts reference
var floating_texts: Array[Dictionary] = []

# Localization
var Loc = null

# =========================================================
# Lifecycle
# =========================================================

func _init(cell_size: int = DEFAULT_CELL_SIZE, grid_width: int = 20, grid_height: int = 20) -> void:
	CELL_SIZE = cell_size
	GRID_WIDTH = grid_width
	GRID_HEIGHT = grid_height

func set_audio_manager(audio_ref: Node) -> void:
	audio_manager = audio_ref

func set_particles_ref(particles_ref: Array[Dictionary]) -> void:
	particles = particles_ref

func set_floating_texts_ref(float_texts_ref: Array[Dictionary]) -> void:
	floating_texts = float_texts_ref

func set_localization(loc_ref) -> void:
	Loc = loc_ref

# =========================================================
# Initialization
# =========================================================

func reset() -> void:
	tiles.clear()
	river_variants.clear()
	wormholes.clear()
	wormhole_cooldown = false
	
	gate_open = false
	gate_flash = 0.0
	gate_level = 1
	
	_generate_terrain()
	_generate_wormholes()
	_generate_gate()

# =========================================================
# Terrain Generation
# =========================================================

func _generate_terrain() -> void:
	# Initialize ground
	for y in range(GRID_HEIGHT):
		var row: Array = []
		for x in range(GRID_WIDTH):
			row.append(Terrain.GROUND)
		tiles.append(row)
	
	# Forest
	var num_forest: int = randi_range(NUM_FOREST_CLUSTERS_MIN, NUM_FOREST_CLUSTERS_MAX)
	for _i in range(num_forest):
		var fsize: int = randi_range(FOREST_CLUSTER_MIN, FOREST_CLUSTER_MAX)
		var edge: Vector2i = _find_terrain_edge(Terrain.FOREST)
		var fx: int; var fy: int
		if edge.x >= 0:
			fx = edge.x; fy = edge.y
		else:
			fx = randi_range(2, GRID_WIDTH - 3)
			fy = randi_range(2, GRID_HEIGHT - 3)
		_grow_cluster(fx, fy, fsize, Terrain.FOREST)
		_fill_interior(Terrain.FOREST, 2)
	
	# River
	var num_river: int = randi_range(NUM_RIVER_CLUSTERS_MIN, NUM_RIVER_CLUSTERS_MAX)
	for _i in range(num_river):
		var rsize: int = randi_range(RIVER_CLUSTER_MIN, RIVER_CLUSTER_MAX)
		var edge: Vector2i = _find_terrain_edge(Terrain.RIVER)
		var rx: int; var ry: int
		if edge.x >= 0:
			rx = edge.x; ry = edge.y
		else:
			rx = randi_range(2, GRID_WIDTH - 3)
			ry = randi_range(2, GRID_HEIGHT - 3)
		_grow_cluster(rx, ry, rsize, Terrain.RIVER)
		_fill_interior(Terrain.RIVER, 2)
	
	_assign_river_variants()
	
	# Clear spawn area
	var cx: int = GRID_WIDTH / 2
	var cy: int = GRID_HEIGHT / 2
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var tx: int = cx + dx
			var ty: int = cy + dy
			if tx >= 0 and tx < GRID_WIDTH and ty >= 0 and ty < GRID_HEIGHT:
				tiles[ty][tx] = Terrain.GROUND

func _find_terrain_edge(terrain_type: int) -> Vector2i:
	var edges: Array[Vector2i] = []
	var dirs_x: Array = [1, -1, 0, 0]
	var dirs_y: Array = [0, 0, 1, -1]
	
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if tiles[y][x] == terrain_type:
				for d in range(4):
					var nx: int = x + dirs_x[d]
					var ny: int = y + dirs_y[d]
					if nx >= 0 and nx < GRID_WIDTH and ny >= 0 and ny < GRID_HEIGHT:
						if tiles[ny][nx] == Terrain.GROUND:
							edges.append(Vector2i(nx, ny))
	
	if edges.is_empty():
		return Vector2i(-1, -1)
	return edges[randi() % edges.size()]

func _grow_cluster(sx: int, sy: int, size: int, terrain_type: int) -> void:
	var cx: int = sx
	var cy: int = sy
	var last_dir: int = randi() % 4
	var dirs_x: Array = [1, -1, 0, 0]
	var dirs_y: Array = [0, 0, 1, -1]
	
	for _i in range(size):
		if cx < 0 or cx >= GRID_WIDTH or cy < 0 or cy >= GRID_HEIGHT:
			var border: Vector2i = _find_terrain_edge(terrain_type)
			if border.x >= 0:
				cx = border.x; cy = border.y
			else:
				break
		
		if tiles[cy][cx] == Terrain.GROUND:
			tiles[cy][cx] = terrain_type
		
		if randf() < 0.6:
			cx += dirs_x[last_dir]
			cy += dirs_y[last_dir]
		else:
			last_dir = randi() % 4
			cx += dirs_x[last_dir]
			cy += dirs_y[last_dir]

func _fill_interior(terrain_type: int, max_island_size: int) -> void:
	var dirs_x: Array = [1, -1, 0, 0]
	var dirs_y: Array = [0, 0, 1, -1]
	var changed: bool = true
	
	while changed:
		changed = false
		for y in range(GRID_HEIGHT):
			for x in range(GRID_WIDTH):
				if tiles[y][x] != Terrain.GROUND:
					continue
				
				var neighbor_count: int = 0
				for d in range(4):
					var nx: int = x + dirs_x[d]
					var ny: int = y + dirs_y[d]
					if nx >= 0 and nx < GRID_WIDTH and ny >= 0 and ny < GRID_HEIGHT:
						if tiles[ny][nx] == terrain_type:
							neighbor_count += 1
				
				if neighbor_count >= 3:
					tiles[y][x] = terrain_type
					changed = true

func _assign_river_variants() -> void:
	var dirs_x: Array = [1, -1, 0, 0]
	var dirs_y: Array = [0, 0, 1, -1]
	
	for y in range(GRID_HEIGHT):
		var row: Array = []
		for x in range(GRID_WIDTH):
			row.append(-1)
		river_variants.append(row)
	
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if tiles[y][x] == Terrain.RIVER and river_variants[y][x] == -1:
				var rv: int = randi() % 5
				var queue: Array[Vector2i] = [Vector2i(x, y)]
				river_variants[y][x] = rv
				
				while queue.size() > 0:
					var cur: Vector2i = queue.pop_front()
					for d in range(4):
						var nx: int = cur.x + dirs_x[d]
						var ny: int = cur.y + dirs_y[d]
						if nx >= 0 and nx < GRID_WIDTH and ny >= 0 and ny < GRID_HEIGHT:
							if tiles[ny][nx] == Terrain.RIVER and river_variants[ny][nx] == -1:
								river_variants[ny][nx] = rv
								queue.append(Vector2i(nx, ny))

# =========================================================
# Wormholes
# =========================================================

func _generate_wormholes() -> void:
	wormholes.clear()
	var num_pairs: int = 1 + (randi() % 2)
	var center_x: int = GRID_WIDTH / 2
	var center_y: int = GRID_HEIGHT / 2
	
	for pair_id in range(num_pairs):
		var positions: Array[Vector2i] = []
		
		for _attempt in range(200):
			if positions.size() >= 2:
				break
			
			var x: int = randi_range(1, GRID_WIDTH - 2)
			var y: int = randi_range(1, GRID_HEIGHT - 2)
			var pos: Vector2i = Vector2i(x, y)
			
			if tiles[y][x] != Terrain.GROUND:
				continue
			if abs(x - center_x) <= 2 and abs(y - center_y) <= 2:
				continue
			
			var occupied: bool = false
			for wh in wormholes:
				if wh.pos == pos:
					occupied = true
			for ep in positions:
				if ep == pos or grid_distance(ep, pos) < WORMHOLE_MIN_DIST:
					occupied = true
			
			if occupied:
				continue
			positions.append(pos)
		
		if positions.size() == 2:
			var palette: Array = wormhole_palettes[pair_id % wormhole_palettes.size()]
			wormholes.append({"pos": positions[0], "pair_id": pair_id, "palette": palette, "phase": randf() * TAU})
			wormholes.append({"pos": positions[1], "pair_id": pair_id, "palette": palette, "phase": randf() * TAU})

func check_wormhole(pos: Vector2i) -> Vector2i:
	if wormhole_cooldown:
		return pos
	
	for wh in wormholes:
		if wh.pos == pos:
			var paired_pos: Vector2i = _get_paired_wormhole_pos(wh.pair_id, pos)
			_spawn_particles(pos, wh.palette[0], 15, 100.0)
			_spawn_particles(paired_pos, wh.palette[0], 15, 100.0)
			if Loc:
				_spawn_floating_text(Loc.t("float_wormhole"), pos, wh.palette[1], 14)
			if audio_manager:
				audio_manager.play_wormhole()
			wormhole_cooldown = true
			return paired_pos
	
	wormhole_cooldown = false
	return pos

func _get_paired_wormhole_pos(pair_id: int, current_pos: Vector2i) -> Vector2i:
	for wh in wormholes:
		if wh.pair_id == pair_id and wh.pos != current_pos:
			return wh.pos
	return current_pos

# =========================================================
# Level Gate
# =========================================================

func _generate_gate() -> void:
	var available: Array[Vector2i] = []
	var center_x: int = GRID_WIDTH / 2
	var center_y: int = GRID_HEIGHT / 2
	
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var pos: Vector2i = Vector2i(x, y)
			if tiles[y][x] != Terrain.GROUND:
				continue
			if abs(x - center_x) <= 3 and abs(y - center_y) <= 3:
				continue
			if x < 1 or x >= GRID_WIDTH - 1 or y < 1 or y >= GRID_HEIGHT - 1:
				continue
			
			var near_wormhole: bool = false
			for wh in wormholes:
				if pos == wh.pos or grid_distance(pos, wh.pos) < 2:
					near_wormhole = true
			
			if near_wormhole:
				continue
			available.append(pos)
	
	if available.is_empty():
		gate_pos = Vector2i(-1, -1)
	else:
		gate_pos = available[randi() % available.size()]

func update_gate(score: int) -> void:
	var needed: int = gate_level * GATE_OPEN_SCORE_PER_LEVEL
	if score >= needed and not gate_open:
		gate_open = true
		gate_flash = 1.0
		if audio_manager:
			audio_manager.play_gate_open()

func check_gate_collision(pos: Vector2i) -> bool:
	return pos == gate_pos and gate_open

func enter_next_level() -> Vector2i:
	var old_gate: Vector2i = gate_pos
	gate_level += 1
	gate_open = false
	gate_flash = 0.0
	
	reset()
	
	_spawn_particles(old_gate, Color(1.0, 0.85, 0.2), 30, 120.0)
	if Loc:
		_spawn_floating_text(Loc.t("float_levelup") % gate_level, old_gate, Color(1.0, 0.85, 0.2), 24)
	if audio_manager:
		audio_manager.play_gate_enter()
	
	return old_gate

# =========================================================
# Update
# =========================================================

func update(delta: float) -> void:
	gate_anim += delta
	if gate_flash > 0.0:
		gate_flash = max(0.0, gate_flash - delta * 2.5)

# =========================================================
# Drawing
# =========================================================

func draw(canvas: CanvasItem, anim_timer: float) -> void:
	_draw_terrain(canvas, anim_timer)
	_draw_wormholes(canvas, anim_timer)
	_draw_gate(canvas, anim_timer)

func _draw_terrain(canvas: CanvasItem, anim_timer: float) -> void:
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var H: float = float(GRID_HEIGHT * CELL_SIZE)
	
	canvas.draw_rect(Rect2(0, 0, W, H), bg_color)
	
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var terrain: int = tiles[y][x]
			var px: float = float(x * CELL_SIZE)
			var py: float = float(y * CELL_SIZE)
			match terrain:
				Terrain.GROUND:
					_draw_ground_tile(canvas, x, y, px, py)
				Terrain.FOREST:
					_draw_forest_tile(canvas, x, y, px, py)
				Terrain.RIVER:
					_draw_river_tile(canvas, x, y, px, py, anim_timer)

func _draw_ground_tile(canvas: CanvasItem, x: int, y: int, px: float, py: float) -> void:
	var tile_color: Color
	if (x + y) % 2 == 0:
		tile_color = Color(0.085, 0.095, 0.14)
	else:
		tile_color = Color(0.075, 0.085, 0.125)
	
	canvas.draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), tile_color)
	canvas.draw_circle(Vector2(px + CELL_SIZE * 0.3, py + CELL_SIZE * 0.3), 0.8, Color(0.1, 0.11, 0.16, 0.35))
	canvas.draw_circle(Vector2(px + CELL_SIZE * 0.7, py + CELL_SIZE * 0.7), 0.8, Color(0.1, 0.11, 0.16, 0.35))

func _draw_forest_tile(canvas: CanvasItem, x: int, y: int, px: float, py: float) -> void:
	var variant: int = (x * 73 + y * 137) % 4
	var s: int = x * 53 + y * 97
	
	match variant:
		0: _forest_variant_0(canvas, x, y, px, py, s)
		1: _forest_variant_1(canvas, x, y, px, py, s)
		2: _forest_variant_3(canvas, x, y, px, py, s)
		3: _forest_variant_4(canvas, x, y, px, py, s)

func _forest_variant_0(canvas: CanvasItem, x: int, y: int, px: float, py: float, s: int) -> void:
	var blobs: Array[Array] = []
	for i in range(5):
		blobs.append([
			px + 8.0 + float((s + i * 23) % 24),
			py + 8.0 + float((s + i * 37) % 24),
			10.0 + float((s + i * 7) % 6)])
	
	for b in blobs:
		canvas.draw_circle(Vector2(b[0] + 1.5, b[1] + 1.5), b[2], Color(0.02, 0.06, 0.01, 0.6))
	for b in blobs:
		canvas.draw_circle(Vector2(b[0], b[1]), b[2], Color(0.05, 0.18, 0.03, 0.95))
	for b in blobs:
		canvas.draw_circle(Vector2(b[0], b[1] - 1.0), b[2] * 0.8, Color(0.08, 0.30, 0.05, 0.85))
	
	for i in range(4):
		canvas.draw_circle(Vector2(px + 5.0 + float((s + i * 41) % 30), py + 5.0 + float((s + i * 53) % 30)),
			4.0, Color(0.14, 0.36, 0.08, 0.4))
	for i in range(6):
		canvas.draw_circle(Vector2(px + 3.0 + float((s + i * 29) % 34), py + 3.0 + float((s + i * 43) % 34)),
			2.0, Color(0.20, 0.44, 0.12, 0.3))

func _forest_variant_1(canvas: CanvasItem, x: int, y: int, px: float, py: float, s: int) -> void:
	var positions: Array[Array] = [
		[px + CELL_SIZE * 0.3, py + CELL_SIZE * 0.35],
		[px + CELL_SIZE * 0.65, py + CELL_SIZE * 0.45],
		[px + CELL_SIZE * 0.5, py + CELL_SIZE * 0.7],
	]
	
	for i in range(positions.size()):
		var bx: float = positions[i][0] + float((s + i * 17) % 5)
		var by: float = positions[i][1] + float((s + i * 29) % 5)
		var r: float = 14.0 - float(i) * 1.5
		canvas.draw_circle(Vector2(bx + 1.5, by + 2.0), r, Color(0.02, 0.05, 0.01, 0.5))
		canvas.draw_circle(Vector2(bx, by), r, Color(0.04, 0.16, 0.03, 0.95))
		canvas.draw_circle(Vector2(bx - 1.0, by - 1.5), r * 0.75, Color(0.10, 0.28, 0.06, 0.7))
	
	for i in range(7):
		canvas.draw_circle(Vector2(px + 4.0 + float((s + i * 31) % 32), py + 4.0 + float((s + i * 47) % 32)),
			1.5 + float(i % 3), Color(0.18, 0.42, 0.10, 0.35))

func _forest_variant_3(canvas: CanvasItem, x: int, y: int, px: float, py: float, s: int) -> void:
	canvas.draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.04, 0.11, 0.03))
	
	for i in range(6):
		var bx: float = px + 6.0 + float((s + i * 23) % 28)
		var by: float = py + 6.0 + float((s + i * 37) % 28)
		var br: float = 7.0 + float((s + i * 11) % 5)
		canvas.draw_circle(Vector2(bx + 1.0, by + 1.0), br, Color(0.02, 0.06, 0.01, 0.4))
		canvas.draw_circle(Vector2(bx, by), br, Color(0.06, 0.20, 0.04, 0.9))
		canvas.draw_circle(Vector2(bx, by), br * 0.7, Color(0.10, 0.30, 0.06, 0.6))
		canvas.draw_circle(Vector2(bx - 1.0, by - 1.0), br * 0.35, Color(0.16, 0.40, 0.10, 0.35))
	
	for i in range(4):
		var fx: float = px + 5.0 + float((s + i * 43) % 30)
		var fy: float = py + 5.0 + float((s + i * 59) % 30)
		canvas.draw_circle(Vector2(fx, fy), 1.5, Color(0.25, 0.45, 0.12, 0.4))
	
	for i in range(5):
		var lx: float = px + 3.0 + float((s + i * 29) % 34)
		var ly: float = py + 3.0 + float((s + i * 47) % 34)
		canvas.draw_line(Vector2(lx, ly), Vector2(lx + 3.0, ly - 2.0), Color(0.12, 0.30, 0.06, 0.25), 1.0)

func _forest_variant_4(canvas: CanvasItem, x: int, y: int, px: float, py: float, s: int) -> void:
	canvas.draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.03, 0.09, 0.02))
	
	var big: Array[Array] = [
		[px + 12.0 + float((s * 3) % 8), py + 14.0 + float((s * 5) % 8), 15.0],
		[px + 28.0 + float((s * 7) % 6), py + 22.0 + float((s * 11) % 6), 13.0],
	]
	
	for b in big:
		canvas.draw_circle(Vector2(b[0] + 1.5, b[1] + 1.5), b[2], Color(0.01, 0.04, 0.01, 0.6))
		canvas.draw_circle(Vector2(b[0], b[1]), b[2], Color(0.04, 0.14, 0.02, 0.95))
		canvas.draw_circle(Vector2(b[0], b[1] - 1.5), b[2] * 0.8, Color(0.07, 0.24, 0.04, 0.8))
	
	for i in range(3):
		var sx: float = px + 5.0 + float((s + i * 31) % 30)
		var sy: float = py + 5.0 + float((s + i * 43) % 30)
		canvas.draw_circle(Vector2(sx, sy), 8.0, Color(0.05, 0.16, 0.03, 0.85))
		canvas.draw_circle(Vector2(sx, sy), 5.0, Color(0.09, 0.26, 0.05, 0.6))
	
	for i in range(3):
		var vx: float = px + float((s + i * 19) % 30)
		var vy: float = py
		var vpts: PackedVector2Array = []
		for d in range(0, CELL_SIZE + 1, 5):
			vpts.append(Vector2(vx + sin(float(d) * 0.5 + i) * 4.0, vy + float(d)))
		if vpts.size() >= 2:
			canvas.draw_polyline(vpts, Color(0.06, 0.20, 0.04, 0.35), 1.5)
	
	for i in range(6):
		canvas.draw_circle(Vector2(px + 2.0 + float((s + i * 41) % 36), py + 2.0 + float((s + i * 53) % 36)),
			1.5, Color(0.12, 0.28, 0.06, 0.3))

func _draw_river_tile(canvas: CanvasItem, x: int, y: int, px: float, py: float, anim_timer: float) -> void:
	var variant: int
	if y >= 0 and y < river_variants.size() and x >= 0 and x < river_variants[y].size() and river_variants[y][x] >= 0:
		variant = river_variants[y][x]
	else:
		variant = (x * 89 + y * 163) % 5
	var s: int = x * 61 + y * 113
	
	match variant:
		0: _river_variant_0(canvas, x, y, px, py, s, anim_timer)
		1: _river_variant_1(canvas, x, y, px, py, s, anim_timer)
		2: _river_variant_2(canvas, x, y, px, py, s, anim_timer)
		3: _river_variant_3(canvas, x, y, px, py, s, anim_timer)
		4: _river_variant_4(canvas, x, y, px, py, s, anim_timer)

func _river_variant_0(canvas: CanvasItem, x: int, y: int, px: float, py: float, s: int, anim_timer: float) -> void:
	canvas.draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.05, 0.12, 0.28))
	canvas.draw_rect(Rect2(px + 2, py + 2, CELL_SIZE - 4, CELL_SIZE - 4), Color(0.04, 0.10, 0.24, 0.5))
	
	var wave_off: float = anim_timer * 2.5 + float(x) * 0.9 + float(y) * 0.4
	for w in range(3):
		var wy: float = py + 8.0 + float(w) * 12.0
		var pts: PackedVector2Array = []
		for d in range(0, CELL_SIZE + 1, 3):
			var wx: float = px + float(d)
			var wwy: float = wy + sin(wave_off + float(d) * 0.28 + float(w) * 1.8) * 2.0
			pts.append(Vector2(wx, wwy))
		if pts.size() >= 2:
			canvas.draw_polyline(pts, Color(0.2, 0.38, 0.65, 0.3), 1.5)
	
	_river_sparkles(canvas, x, y, px, py, s, anim_timer)

func _river_variant_1(canvas: CanvasItem, x: int, y: int, px: float, py: float, s: int, anim_timer: float) -> void:
	canvas.draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.04, 0.11, 0.26))
	
	var flow_off: float = anim_timer * 3.0 + float(x) * 1.2 + float(y) * 0.7
	for i in range(5):
		var ly: float = py - 10.0 + float(i) * 12.0 + fmod(flow_off, 12.0)
		var pts: PackedVector2Array = []
		for d in range(0, CELL_SIZE + 20, 3):
			var dx: float = px + float(d)
			var dy: float = ly + float(d) * 0.6 + sin(flow_off + float(d) * 0.2) * 1.5
			if dy >= py and dy <= py + CELL_SIZE:
				pts.append(Vector2(dx, dy))
		if pts.size() >= 2:
			canvas.draw_polyline(pts, Color(0.18, 0.35, 0.60, 0.35), 1.5)
	
	_river_sparkles(canvas, x, y, px, py, s, anim_timer)

func _river_variant_2(canvas: CanvasItem, x: int, y: int, px: float, py: float, s: int, anim_timer: float) -> void:
	canvas.draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.05, 0.13, 0.30))
	canvas.draw_rect(Rect2(px + 2, py + 2, CELL_SIZE - 4, CELL_SIZE - 4), Color(0.04, 0.11, 0.25, 0.5))
	
	var rcx: float = px + CELL_SIZE * 0.5
	var rcy: float = py + CELL_SIZE * 0.5
	var ripple_off: float = anim_timer * 2.0 + float(x) + float(y)
	
	for r in range(3):
		var base_r: float = 4.0 + float(r) * 6.0
		var rr: float = base_r + sin(ripple_off + float(r) * 2.0) * 2.0
		if rr > 1.0:
			canvas.draw_circle(Vector2(rcx, rcy), rr, Color(0.15, 0.30, 0.55, 0.25), false, 1.5)
	
	_river_sparkles(canvas, x, y, px, py, s, anim_timer)

func _river_variant_3(canvas: CanvasItem, x: int, y: int, px: float, py: float, s: int, anim_timer: float) -> void:
	canvas.draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.03, 0.08, 0.22))
	canvas.draw_rect(Rect2(px + 3, py + 3, CELL_SIZE - 6, CELL_SIZE - 6), Color(0.03, 0.07, 0.20, 0.6))
	
	var caus_off: float = anim_timer * 1.8 + float(x) * 2.1 + float(y) * 1.3
	for i in range(4):
		var lx: float = px + 6.0 + float((s + i * 23) % 28)
		var ly: float = py + 6.0 + float((s + i * 37) % 28)
		var lsize: float = 3.0 + sin(caus_off + float(i) * 1.5) * 2.0
		if lsize > 1.0:
			canvas.draw_circle(Vector2(lx, ly), lsize, Color(0.15, 0.30, 0.55, 0.3))
			canvas.draw_circle(Vector2(lx - 1.0, ly - 1.0), lsize * 0.5, Color(0.25, 0.45, 0.70, 0.2))
	
	_river_sparkles(canvas, x, y, px, py, s, anim_timer)

func _river_variant_4(canvas: CanvasItem, x: int, y: int, px: float, py: float, s: int, anim_timer: float) -> void:
	canvas.draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.06, 0.14, 0.30))
	
	var chop_off: float = anim_timer * 3.5 + float(x) * 1.5 + float(y) * 0.8
	for w in range(4):
		var wy: float = py + 5.0 + float(w) * 10.0
		var pts: PackedVector2Array = []
		for d in range(0, CELL_SIZE + 1, 2):
			var wx: float = px + float(d)
			var wwy: float = wy + sin(chop_off + float(d) * 0.4 + float(w) * 2.5) * 3.0
			pts.append(Vector2(wx, wwy))
		if pts.size() >= 2:
			canvas.draw_polyline(pts, Color(0.25, 0.42, 0.65, 0.35), 1.0)
		
		for f in range(2):
			var fx: float = px + 8.0 + float((s + w * 17 + f * 31) % 24)
			var fy: float = wy + sin(chop_off + float(fx - px) * 0.4) * 3.0
			if fy > py and fy < py + CELL_SIZE:
				canvas.draw_circle(Vector2(fx, fy), 1.5, Color(0.5, 0.65, 0.85, 0.3))
	
	_river_sparkles(canvas, x, y, px, py, s, anim_timer)

func _river_sparkles(canvas: CanvasItem, x: int, y: int, px: float, py: float, s: int, anim_timer: float) -> void:
	var sp1: float = sin(anim_timer * 3.5 + float(x) * 2.3 + float(y) * 1.7)
	if sp1 > 0.65:
		canvas.draw_circle(Vector2(px + CELL_SIZE * 0.55, py + CELL_SIZE * 0.35), 1.5, Color(0.5, 0.7, 1.0, sp1 * 0.35))
	
	var sp2: float = sin(anim_timer * 2.8 + float(x) * 1.1 + float(y) * 2.9 + 2.0)
	if sp2 > 0.7:
		canvas.draw_circle(Vector2(px + CELL_SIZE * 0.3, py + CELL_SIZE * 0.7), 1.2, Color(0.5, 0.7, 1.0, sp2 * 0.25))

func _draw_wormholes(canvas: CanvasItem, anim_timer: float) -> void:
	for wh in wormholes:
		_draw_single_wormhole(canvas, wh, anim_timer)

func _draw_single_wormhole(canvas: CanvasItem, wh: Dictionary, anim_timer: float) -> void:
	var pos: Vector2i = wh.pos
	var palette: Array = wh.palette
	var phase: float = wh.phase
	var cx: float = pos.x * CELL_SIZE + CELL_SIZE / 2.0
	var cy: float = pos.y * CELL_SIZE + CELL_SIZE / 2.0
	var main_c: Color = palette[0]
	var light_c: Color = palette[1]
	var dark_c: Color = palette[2]
	var glow_c: Color = palette[3]
	var pulse: float = 0.7 + 0.3 * sin(anim_timer * 2.5 + phase)
	var radius: float = CELL_SIZE / 2.0 - 2.0
	
	# Outer glow
	for ring in range(3):
		var gr: float = radius + 6.0 + float(ring) * 4.0
		var ga: float = (0.04 + ring * 0.02) * pulse
		canvas.draw_circle(Vector2(cx, cy), gr, Color(glow_c.r, glow_c.g, glow_c.b, ga))
	
	# Accretion disk
	var ring_width: float = 3.0 + sin(anim_timer * 1.8 + phase) * 0.5
	canvas.draw_circle(Vector2(cx, cy), radius + 1.0, Color(main_c.r, main_c.g, main_c.b, 0.6 * pulse), false, ring_width)
	canvas.draw_circle(Vector2(cx, cy), radius + 3.0, Color(light_c.r, light_c.g, light_c.b, 0.2 * pulse), false, 1.5)
	
	# Rotating spiral arms
	var num_arms: int = 3
	for arm in range(num_arms):
		var arm_offset: float = phase + float(arm) * TAU / float(num_arms)
		var pts: PackedVector2Array = []
		for step in range(0, 20):
			var t: float = float(step) / 20.0
			var angle: float = arm_offset + t * TAU * 1.5 + anim_timer * 2.0
			var r: float = radius * 0.9 * (1.0 - t * 0.7)
			if r < 2.0:
				break
			var px: float = cx + cos(angle) * r
			var py: float = cy + sin(angle) * r
			pts.append(Vector2(px, py))
		if pts.size() >= 2:
			var spiral_alpha: float = 0.35 * pulse * (1.0 - 0.3 * abs(sin(anim_timer * 1.5 + phase)))
			canvas.draw_polyline(pts, Color(light_c.r, light_c.g, light_c.b, spiral_alpha), 2.0)
	
	# Orbiting particles
	for dot in range(4):
		var dot_angle: float = anim_timer * 3.0 + phase + float(dot) * TAU / 4.0
		var dot_r: float = radius + 2.0 + sin(anim_timer * 5.0 + dot) * 1.5
		var dx: float = cx + cos(dot_angle) * dot_r
		var dy: float = cy + sin(dot_angle) * dot_r
		var dot_alpha: float = 0.5 + 0.3 * sin(anim_timer * 4.0 + dot * 1.5)
		var dot_size: float = 2.0 + sin(anim_timer * 3.0 + dot) * 0.5
		canvas.draw_circle(Vector2(dx, dy), dot_size + 1.5, Color(glow_c.r, glow_c.g, glow_c.b, dot_alpha * 0.3))
		canvas.draw_circle(Vector2(dx, dy), dot_size, Color(light_c.r, light_c.g, light_c.b, dot_alpha))
	
	# Black hole center
	var inner_r: float = radius * 0.65
	canvas.draw_circle(Vector2(cx, cy), inner_r + 2.0, Color(dark_c.r * 0.4, dark_c.g * 0.4, dark_c.b * 0.4, 0.7))
	canvas.draw_circle(Vector2(cx, cy), inner_r, Color(0.02, 0.02, 0.04, 1.0))
	canvas.draw_circle(Vector2(cx - 2.0, cy - 2.0), inner_r * 0.3, Color(main_c.r, main_c.g, main_c.b, 0.08 * pulse))
	
	# Pair ID label
	var label: String = str(wh.pair_id + 1)
	var font = ThemeDB.fallback_font
	var ls: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
	canvas.draw_string(font, Vector2(cx - ls.x / 2.0 + 0.5, cy - ls.y / 2.0 + 0.5), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 0, 0, 0.5))
	canvas.draw_string(font, Vector2(cx - ls.x / 2.0, cy - ls.y / 2.0), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(main_c.r, main_c.g, main_c.b, 0.5 * pulse))

func _draw_gate(canvas: CanvasItem, anim_timer: float) -> void:
	if gate_pos.x < 0:
		return
	
	var cx: float = gate_pos.x * CELL_SIZE + CELL_SIZE / 2.0
	var cy: float = gate_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	var r: float = CELL_SIZE / 2.0 - 1.0
	var font = ThemeDB.fallback_font
	var dest_label: String = str(gate_level + 1)
	
	if gate_open:
		var pulse: float = 0.7 + 0.3 * sin(gate_anim * 3.0)
		
		# Outer glow
		for i in range(3):
			var gr: float = r + 8.0 + float(i) * 5.0
			var ga: float = (0.06 + float(i) * 0.03) * pulse
			canvas.draw_circle(Vector2(cx, cy), gr, Color(1.0, 0.85, 0.2, ga))
		
		# Flash burst
		if gate_flash > 0.0:
			canvas.draw_circle(Vector2(cx, cy), r + 20.0, Color(1.0, 0.9, 0.3, gate_flash * 0.25))
			canvas.draw_circle(Vector2(cx, cy), r + 12.0, Color(1.0, 0.92, 0.5, gate_flash * 0.15))
		
		# Golden door frame
		var fc: Color = Color(1.0, 0.75, 0.1, 0.9 * pulse)
		canvas.draw_arc(Vector2(cx, cy), r + 2.0, 0, PI, 16, fc, 3.0)
		canvas.draw_line(Vector2(cx - r - 2.0, cy), Vector2(cx - r - 2.0, cy - r), fc, 3.0)
		canvas.draw_line(Vector2(cx + r + 2.0, cy), Vector2(cx + r + 2.0, cy - r), fc, 3.0)
		
		# Interior glow
		canvas.draw_circle(Vector2(cx, cy), r, Color(0.95, 0.88, 0.6, 0.5 * pulse))
		canvas.draw_circle(Vector2(cx, cy - r * 0.3), r * 0.5, Color(1.0, 0.95, 0.8, 0.4 * pulse))
		
		# Up arrow
		var bob: float = sin(gate_anim * 4.0) * 3.0
		var ac: Color = Color(1.0, 0.85, 0.2, 0.85 * pulse)
		var ax: float = cx
		var ay: float = cy + bob
		canvas.draw_line(Vector2(ax, ay + 7), Vector2(ax, ay - 7), ac, 3.0)
		canvas.draw_line(Vector2(ax - 6, ay - 1), Vector2(ax, ay - 7), ac, 3.0)
		canvas.draw_line(Vector2(ax + 6, ay - 1), Vector2(ax, ay - 7), ac, 3.0)
		
		# Destination label
		var ls: Vector2 = font.get_string_size(dest_label, HORIZONTAL_ALIGNMENT_CENTER, -1, 15)
		canvas.draw_string(font, Vector2(cx - ls.x / 2.0, cy - ls.y / 2.0 + 10), dest_label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.55, 0.4, 0.05, 0.85 * pulse))
	else:
		# Shadow
		canvas.draw_circle(Vector2(cx + 1.5, cy + 1.5), r + 2.0, Color(0.05, 0.05, 0.08, 0.5))
		
		# Door body
		_draw_rounded_rect(canvas, Rect2(cx - r - 1, cy - r - 1, (r + 1) * 2, (r + 1) * 2),
			Color(0.25, 0.27, 0.32, 0.95), 6)
		
		# Door frame
		var fc: Color = Color(0.4, 0.42, 0.5, 0.7)
		_draw_rounded_rect(canvas, Rect2(cx - r - 1, cy - r - 1, (r + 1) * 2, (r + 1) * 2),
			fc, 6, false, 2.0)
		
		# Lock icon
		var lock_cy: float = cy - 3.0
		var lock_w: float = 8.0
		var lock_h: float = 6.0
		canvas.draw_rect(Rect2(cx - lock_w / 2.0, lock_cy, lock_w, lock_h),
			Color(0.5, 0.52, 0.58, 0.6))
		canvas.draw_rect(Rect2(cx - lock_w / 2.0, lock_cy, lock_w, lock_h),
			Color(0.65, 0.67, 0.72, 0.4), false, 1.0)
		canvas.draw_arc(Vector2(cx, lock_cy), 4.0, PI, TAU, 8,
			Color(0.5, 0.52, 0.58, 0.6), 2.0)
		canvas.draw_circle(Vector2(cx, lock_cy + 3.0), 1.2, Color(0.35, 0.37, 0.42, 0.7))
		
		# Destination label
		var ls: Vector2 = font.get_string_size(dest_label, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		canvas.draw_string(font, Vector2(cx - ls.x / 2.0, cy + 6), dest_label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.52, 0.6, 0.5))

func _draw_rounded_rect(canvas: CanvasItem, rect: Rect2, color: Color, radius: float, filled: bool = true, width: float = -1.0) -> void:
	if filled:
		var pts: PackedVector2Array = []
		var r: float = min(radius, rect.size.x / 2.0, rect.size.y / 2.0)
		var tl: Vector2 = rect.position
		var s: Vector2 = rect.size
		var seg_n: int = 8
		
		for j in range(seg_n + 1):
			var a: float = PI + (PI / 2.0) * float(j) / float(seg_n)
			pts.append(tl + Vector2(r, r) + Vector2(cos(a), sin(a)) * r)
		for j in range(seg_n + 1):
			var a: float = -PI / 2.0 + (PI / 2.0) * float(j) / float(seg_n)
			pts.append(tl + Vector2(s.x - r, r) + Vector2(cos(a), sin(a)) * r)
		for j in range(seg_n + 1):
			var a: float = 0.0 + (PI / 2.0) * float(j) / float(seg_n)
			pts.append(tl + Vector2(s.x - r, s.y - r) + Vector2(cos(a), sin(a)) * r)
		for j in range(seg_n + 1):
			var a: float = PI / 2.0 + (PI / 2.0) * float(j) / float(seg_n)
			pts.append(tl + Vector2(r, s.y - r) + Vector2(cos(a), sin(a)) * r)
		
		canvas.draw_colored_polygon(pts, color)
	else:
		canvas.draw_rect(rect, color, false, width)

# =========================================================
# Particles & Floating Text
# =========================================================

func _spawn_particles(grid_pos: Vector2i, color: Color, count: int = 12, spread: float = 80.0) -> void:
	var center: Vector2 = Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	)
	
	for i in range(count):
		if particles.size() >= 80:
			break
		var angle: float = randf() * TAU
		var speed: float = randf_range(30.0, spread)
		var vel: Vector2 = Vector2(cos(angle), sin(angle)) * speed
		var life: float = randf_range(0.3, 0.8)
		var size: float = randf_range(2.0, 5.0)
		var p_color: Color = color
		p_color.h += randf_range(-0.05, 0.05)
		p_color.s += randf_range(-0.1, 0.1)
		particles.append({
			"pos": center, "vel": vel,
			"life": life, "max_life": life,
			"color": p_color, "size": size,
		})

func _spawn_floating_text(text: String, grid_pos: Vector2i, color: Color, size: int = 16) -> void:
	var pos: Vector2 = Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	)
	floating_texts.append({
		"text": text, "pos": pos,
		"life": 1.0, "color": color, "size": size,
	})

# =========================================================
# Utility
# =========================================================

func get_terrain(x: int, y: int) -> int:
	if x < 0 or x >= GRID_WIDTH or y < 0 or y >= GRID_HEIGHT:
		return Terrain.GROUND
	return tiles[y][x]

func grid_distance(a: Vector2i, b: Vector2i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y))

func get_wormhole_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for wh in wormholes:
		positions.append(wh.pos)
	return positions

func get_gate_position() -> Vector2i:
	return gate_pos

func get_gate_level() -> int:
	return gate_level

func is_gate_open() -> bool:
	return gate_open
