extends Node2D
class_name Snake

# =========================================================
# Configuration
# =========================================================
const DEFAULT_CELL_SIZE: int = 40

# Effect durations
const GHOST_DURATION: float = 20.0
const GHOST_WARN_THRESHOLD: float = 5.0

# Boost configuration
const BOOST_MULTIPLIER: float = 0.5
const BOOST_HOLD_THRESHOLD: float = 0.5

# =========================================================
# State
# =========================================================
var segments: Array[Vector2i] = []
var direction: Vector2i = Vector2i(1, 0)
var next_direction: Vector2i = Vector2i(1, 0)
var grow_pending: int = 0

# Effects
var ghost_active: bool = false
var ghost_timer: float = 0.0

# Boost
var boosted: bool = false
var boost_glow: float = 0.0
var boost_hold_timer: float = 0.0
var boost_hold_dir: Vector2i = Vector2i(0, 0)

# Animation
var eating_anim_timer: float = 0.0
var mouth_open: float = 0.0
var tongue_timer: float = 0.0
var tongue_flick_timer: float = 0.0
var blink_timer: float = 0.0
var is_blinking: bool = false
var next_blink_time: float = 3.0

# Grid settings
var CELL_SIZE: int = DEFAULT_CELL_SIZE
var GRID_WIDTH: int = 20
var GRID_HEIGHT: int = 20

# Colors
var head_color: Color = Color(0.22, 0.92, 0.45, 1.0)
var body_color: Color = Color(0.18, 0.82, 0.38, 1.0)
var tail_color: Color = Color(0.12, 0.62, 0.3, 1.0)
var eye_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var pupil_color: Color = Color(0.1, 0.1, 0.1, 1.0)
var belly_color: Color = Color(0.38, 0.94, 0.52, 1.0)
var blush_color: Color = Color(1.0, 0.45, 0.5, 0.3)
var tongue_color: Color = Color(0.95, 0.3, 0.35, 0.9)
var mouth_color: Color = Color(0.12, 0.08, 0.08, 1.0)
var boost_color: Color = Color(1.0, 0.6, 0.1, 1.0)
var boost_glow_color: Color = Color(1.0, 0.45, 0.0, 0.25)
var ghost_head_color: Color = Color(0.35, 0.3, 1.0, 0.7)
var ghost_body_color: Color = Color(0.3, 0.25, 0.9, 0.6)
var ghost_tail_color: Color = Color(0.25, 0.2, 0.7, 0.5)

# Audio reference
var audio_manager: Node = null

# Particles reference
var particles: Array[Dictionary] = []

# Terrain reference
var terrain: Array = []
enum Terrain { GROUND, FOREST, RIVER }

# =========================================================
# Lifecycle
# =========================================================

func _init(cell_size: int = DEFAULT_CELL_SIZE, grid_width: int = 20, grid_height: int = 20) -> void:
	CELL_SIZE = cell_size
	GRID_WIDTH = grid_width
	GRID_HEIGHT = grid_height

func set_terrain(terrain_ref: Array) -> void:
	terrain = terrain_ref

func set_audio_manager(audio_ref: Node) -> void:
	audio_manager = audio_ref

func set_particles_ref(particles_ref: Array[Dictionary]) -> void:
	particles = particles_ref

# =========================================================
# Initialization
# =========================================================

func reset() -> void:
	segments.clear()
	var sx: int = GRID_WIDTH / 2
	var sy: int = GRID_HEIGHT / 2
	for i in range(3):
		segments.append(Vector2i(sx - i, sy))
	direction = Vector2i(1, 0)
	next_direction = Vector2i(1, 0)
	grow_pending = 0
	
	ghost_active = false
	ghost_timer = 0.0
	
	boosted = false
	boost_glow = 0.0
	boost_hold_timer = 0.0
	boost_hold_dir = Vector2i(0, 0)
	
	eating_anim_timer = 0.0
	mouth_open = 0.0
	tongue_timer = 0.0
	tongue_flick_timer = 0.0
	blink_timer = 0.0
	is_blinking = false
	next_blink_time = 3.0

# =========================================================
# Movement
# =========================================================

func set_direction(new_dir: Vector2i) -> void:
	# Prevent 180-degree turns
	if direction.x != 0 and new_dir.x == -direction.x:
		return
	if direction.y != 0 and new_dir.y == -direction.y:
		return
	next_direction = new_dir

func get_direction() -> Vector2i:
	return direction

func get_next_direction() -> Vector2i:
	return next_direction

func move() -> Vector2i:
	direction = next_direction
	var head: Vector2i = segments[0]
	var new_head: Vector2i = Vector2i(head.x + direction.x, head.y + direction.y)
	
	# Wrap around walls if ghost or wall_pass active
	if new_head.x < 0 or new_head.x >= GRID_WIDTH or new_head.y < 0 or new_head.y >= GRID_HEIGHT:
		if ghost_active:
			new_head.x = posmod(new_head.x, GRID_WIDTH)
			new_head.y = posmod(new_head.y, GRID_HEIGHT)
	
	segments.insert(0, new_head)
	
	if grow_pending > 0:
		grow_pending -= 1
	else:
		segments.pop_back()
	
	eating_anim_timer = 0.3
	
	return new_head

func undo_move() -> void:
	if segments.size() > 1:
		segments.pop_front()

func grow(amount: int = 1) -> void:
	grow_pending += amount

func shrink(amount: int) -> void:
	var remove_count: int = mini(amount, segments.size() - 1)
	for _i in range(remove_count):
		segments.pop_back()
	
	# Spawn shrink particles
	if segments.size() > 0:
		var tail: Vector2i = segments[segments.size() - 1]
		_spawn_particles(tail, Color(1.0, 0.4, 0.2), 3, 50.0)

func get_head() -> Vector2i:
	return segments[0] if not segments.is_empty() else Vector2i(-1, -1)

func get_segments() -> Array[Vector2i]:
	return segments

func get_length() -> int:
	return segments.size()

# =========================================================
# Collision Detection
# =========================================================

func check_self_collision(head: Vector2i) -> bool:
	if ghost_active:
		return false
	
	for i in range(1, segments.size()):
		if segments[i] == head:
			return true
	return false

func check_wall_collision(head: Vector2i) -> bool:
	return head.x < 0 or head.x >= GRID_WIDTH or head.y < 0 or head.y >= GRID_HEIGHT

# =========================================================
# Effects
# =========================================================

func activate_ghost() -> void:
	ghost_active = true
	ghost_timer = GHOST_DURATION

func is_ghost_active() -> bool:
	return ghost_active

func update_effects(delta: float) -> void:
	# Ghost timer
	if ghost_active:
		ghost_timer -= delta
		if ghost_timer <= 0.0:
			ghost_active = false
			ghost_timer = 0.0
	
	# Boost detection
	_check_boost(delta)
	
	# Animation updates
	_update_animation(delta)

func _update_animation(delta: float) -> void:
	# Eating animation
	if eating_anim_timer > 0.0:
		eating_anim_timer = max(0.0, eating_anim_timer - delta)
		var eat_t: float = 1.0 - (eating_anim_timer / 0.3)
		mouth_open = sin(eat_t * PI) * 0.8
	else:
		mouth_open = 0.0
	
	# Tongue flick
	tongue_timer += delta
	tongue_flick_timer += delta
	if tongue_timer > 2.5 and tongue_flick_timer < 0.01:
		tongue_timer = 0.0
		tongue_flick_timer = 0.0
	
	# Blink
	blink_timer += delta
	if not is_blinking and blink_timer >= next_blink_time:
		is_blinking = true
		blink_timer = 0.0
	if is_blinking and blink_timer >= 0.15:
		is_blinking = false
		blink_timer = 0.0
		next_blink_time = randf_range(2.0, 5.0)

func _check_boost(delta: float) -> void:
	var key_held: bool = _is_direction_key_held(direction)
	
	if direction != boost_hold_dir:
		boost_hold_timer = 0.0
		boost_hold_dir = direction
	
	if key_held:
		boost_hold_timer += delta
		if boost_hold_timer >= BOOST_HOLD_THRESHOLD:
			boosted = true
		else:
			boosted = false
	else:
		boosted = false
		boost_hold_timer = 0.0
	
	if boosted:
		boost_glow = min(1.0, boost_glow + 0.15)
	else:
		boost_glow = max(0.0, boost_glow - 0.08)

func _is_direction_key_held(dir: Vector2i) -> bool:
	if dir == Vector2i(0, -1):
		return Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)
	elif dir == Vector2i(0, 1):
		return Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)
	elif dir == Vector2i(-1, 0):
		return Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
	elif dir == Vector2i(1, 0):
		return Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
	return false

func is_boosted() -> bool:
	return boosted

func get_boost_multiplier() -> float:
	return BOOST_MULTIPLIER if boosted else 1.0

# =========================================================
# Drawing
# =========================================================

func draw(canvas: CanvasItem, anim_timer: float, ghost_alpha_factor: float = 1.0) -> void:
	if segments.is_empty():
		return
	
	var seg_count: int = segments.size()
	
	# Precompute segment centers and widths
	var centers: Array[Vector2] = []
	var widths: Array[float] = []
	
	for i in range(seg_count):
		var seg: Vector2i = segments[i]
		var cx: float = seg.x * CELL_SIZE + CELL_SIZE / 2.0
		var cy: float = seg.y * CELL_SIZE + CELL_SIZE / 2.0
		centers.append(Vector2(cx, cy))
		
		var t: float = float(i) / float(max(seg_count - 1, 1))
		var w: float
		if i == 0:
			w = CELL_SIZE * 0.92
		elif i <= 2:
			var ht: float = float(i) / 3.0
			w = lerp(CELL_SIZE * 0.92, CELL_SIZE * 0.72, ht)
		else:
			w = CELL_SIZE * 0.72 - t * CELL_SIZE * 0.22
			w = maxf(w, CELL_SIZE * 0.28)
		widths.append(w)
	
	# Draw body from tail to head
	for i in range(seg_count - 1, 0, -1):
		var seg: Vector2i = segments[i]
		if not terrain.is_empty() and terrain[seg.y][seg.x] == Terrain.FOREST:
			continue
		
		var c: Vector2 = centers[i]
		var half_w: float = widths[i] / 2.0
		var t: float = float(i) / float(max(seg_count - 1, 1))
		
		var body_c: Color
		if ghost_active:
			body_c = ghost_head_color.lerp(ghost_tail_color, t)
			body_c.a *= ghost_alpha_factor
		elif boosted and boost_glow > 0.1:
			body_c = head_color.lerp(tail_color, t)
			var warmth: float = t * boost_glow * 0.3
			body_c.r = min(1.0, body_c.r + warmth)
			body_c.g = min(1.0, body_c.g + warmth * 0.5)
		else:
			body_c = head_color.lerp(tail_color, t)
		
		canvas.draw_circle(c, half_w, body_c)
		
		# Belly highlight
		if not ghost_active:
			var belly_c: Color = Color(belly_color.r, belly_color.g, belly_color.b, 0.2)
			canvas.draw_circle(c + Vector2(0, half_w * 0.1), half_w * 0.6, belly_c)
		
		# Tail tip
		if i == seg_count - 1:
			var tip_c: Color
			if ghost_active:
				tip_c = Color(0.35, 0.3, 0.8, 0.5 * ghost_alpha_factor)
			else:
				tip_c = Color(0.25, 0.92, 0.48, 0.5)
			canvas.draw_circle(c, half_w * 0.6, tip_c)
	
	# Draw head
	var seg0: Vector2i = segments[0]
	if terrain.is_empty() or terrain[seg0.y][seg0.x] != Terrain.FOREST:
		_draw_head(canvas, centers[0], widths[0] / 2.0, anim_timer, ghost_alpha_factor)

func _draw_head(canvas: CanvasItem, head_c: Vector2, head_r: float, anim_timer: float, alpha_factor: float) -> void:
	# Boost glow
	if boosted and boost_glow > 0.1 and not ghost_active:
		var glow_a: float = boost_glow * 0.2 * (0.6 + 0.4 * abs(sin(anim_timer * 8.0)))
		canvas.draw_circle(head_c, head_r * 1.6, Color(boost_glow_color.r, boost_glow_color.g, boost_glow_color.b, glow_a))
	
	# Head shadow
	canvas.draw_circle(head_c + Vector2(1.5, 2.0), head_r, Color(0.0, 0.0, 0.0, 0.12 * alpha_factor))
	
	# Main head circle
	var hc: Color
	if ghost_active:
		hc = Color(ghost_head_color.r, ghost_head_color.g, ghost_head_color.b, ghost_head_color.a * alpha_factor)
	else:
		hc = head_color
	canvas.draw_circle(head_c, head_r, hc)
	
	# Top highlight
	if not ghost_active:
		var hl: Color = Color(min(1.0, hc.r + 0.12), min(1.0, hc.g + 0.1), min(1.0, hc.b + 0.1), 0.3)
		canvas.draw_circle(head_c + Vector2(-head_r * 0.2, -head_r * 0.25), head_r * 0.5, hl)
		
		var bh: Color = Color(belly_color.r, belly_color.g, belly_color.b, 0.2)
		canvas.draw_circle(head_c + Vector2(0, head_r * 0.15), head_r * 0.55, bh)
	
	# Draw eyes
	_draw_eyes(canvas, head_c, head_r, direction, alpha_factor)
	
	# Rosy blush
	if not ghost_active:
		var fwd: Vector2 = Vector2(direction) * head_r * 0.1
		var perp_d: Vector2 = Vector2(-direction.y, direction.x)
		var cheek_dist: float = head_r * 0.52
		var blush_a: float = blush_color.a * alpha_factor
		canvas.draw_circle(head_c + perp_d * cheek_dist + fwd, head_r * 0.16, Color(blush_color.r, blush_color.g, blush_color.b, blush_a))
		canvas.draw_circle(head_c - perp_d * cheek_dist + fwd, head_r * 0.16, Color(blush_color.r, blush_color.g, blush_color.b, blush_a))
	
	# Tongue
	if tongue_flick_timer < 0.18 and tongue_flick_timer > 0.01 and not ghost_active:
		_draw_tongue(canvas, head_c, head_r, alpha_factor)
	
	# Eating mouth
	if mouth_open > 0.05 and not ghost_active:
		_draw_eating_mouth(canvas, head_c, head_r, alpha_factor)

func _draw_eyes(canvas: CanvasItem, center: Vector2, head_r: float, dir: Vector2i, alpha_factor: float) -> void:
	var eye_sz: float = head_r * 0.34
	var pupil_sz: float = eye_sz * 0.48
	var eye_off: float = head_r * 0.36
	var fwd_off: float = head_r * 0.25
	var fwd: Vector2 = Vector2(dir) * fwd_off
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var re: Vector2 = center + fwd + perp * eye_off
	var le: Vector2 = center + fwd - perp * eye_off
	
	var ec: Color
	var pc: Color
	if ghost_active:
		ec = Color(0.7, 0.65, 1.0, 0.6 * alpha_factor)
		pc = Color(0.3, 0.2, 0.8, 0.8 * alpha_factor)
	elif boosted and boost_glow > 0.3:
		var bf: float = boost_glow * 0.3
		ec = Color(1.0, lerp(1.0, 0.85, bf), lerp(1.0, 0.7, bf), 1.0)
		pc = Color(lerp(0.1, 0.3, bf), lerp(0.1, 0.15, bf), lerp(0.1, 0.0, bf), 1.0)
	else:
		ec = eye_color
		pc = pupil_color
	
	if is_blinking:
		var blink_w: float = eye_sz * 0.8
		var blink_c: Color = Color(ec.r, ec.g, ec.b, ec.a)
		canvas.draw_arc(re, blink_w, 0.3, PI - 0.3, 12, blink_c, 2.8)
		canvas.draw_arc(le, blink_w, 0.3, PI - 0.3, 12, blink_c, 2.8)
	else:
		# Eye shadow
		canvas.draw_circle(re + Vector2(1, 1.5), eye_sz, Color(0, 0, 0, 0.15 * alpha_factor))
		canvas.draw_circle(le + Vector2(1, 1.5), eye_sz, Color(0, 0, 0, 0.15 * alpha_factor))
		
		# White of eyes
		canvas.draw_circle(re, eye_sz, ec)
		canvas.draw_circle(le, eye_sz, ec)
		
		# Iris
		var iris_c: Color = Color(0.18, 0.72, 0.35, 0.9 * alpha_factor)
		if ghost_active:
			iris_c = Color(0.4, 0.35, 0.9, 0.7 * alpha_factor)
		var iris_sz: float = pupil_sz * 1.35
		var ps: Vector2 = Vector2(dir) * eye_sz * 0.22
		canvas.draw_circle(re + ps, iris_sz, iris_c)
		canvas.draw_circle(le + ps, iris_sz, iris_c)
		
		# Pupils
		canvas.draw_circle(re + ps, pupil_sz, pc)
		canvas.draw_circle(le + ps, pupil_sz, pc)
		
		# Sparkles
		var hl1: Vector2 = Vector2(-eye_sz * 0.28, -eye_sz * 0.32)
		var hl_sz: float = eye_sz * 0.30
		var hl_c: Color = Color(1.0, 1.0, 1.0, 0.95 * alpha_factor)
		canvas.draw_circle(re + hl1, hl_sz, hl_c)
		canvas.draw_circle(le + hl1, hl_sz, hl_c)
		
		var hl2: Vector2 = Vector2(eye_sz * 0.18, eye_sz * 0.12)
		canvas.draw_circle(re + hl2, hl_sz * 0.55, hl_c)
		canvas.draw_circle(le + hl2, hl_sz * 0.55, hl_c)
		
		var hl3: Vector2 = Vector2(-eye_sz * 0.05, eye_sz * 0.25)
		canvas.draw_circle(re + hl3, hl_sz * 0.3, Color(1.0, 1.0, 1.0, 0.6 * alpha_factor))
		canvas.draw_circle(le + hl3, hl_sz * 0.3, Color(1.0, 1.0, 1.0, 0.6 * alpha_factor))

func _draw_tongue(canvas: CanvasItem, center: Vector2, head_r: float, alpha_factor: float) -> void:
	var flick_t: float = tongue_flick_timer / 0.18
	var alpha: float = sin(flick_t * PI) * 0.85
	if alpha < 0.02:
		return
	
	var t_c: Color = Color(tongue_color.r, tongue_color.g, tongue_color.b, alpha * alpha_factor)
	var tongue_len: float = head_r * 0.6
	var base_pos: Vector2 = center + Vector2(direction) * head_r * 0.82
	var tip_pos: Vector2 = base_pos + Vector2(direction) * tongue_len
	var perp: Vector2 = Vector2(-direction.y, direction.x)
	var fork_len: float = tongue_len * 0.32
	var fork_spread: float = head_r * 0.22
	
	canvas.draw_line(base_pos, tip_pos, t_c, 2.0)
	
	var fork_l: Vector2 = tip_pos + Vector2(direction) * fork_len + perp * fork_spread
	var fork_r: Vector2 = tip_pos + Vector2(direction) * fork_len - perp * fork_spread
	canvas.draw_line(tip_pos, fork_l, t_c, 1.5)
	canvas.draw_line(tip_pos, fork_r, t_c, 1.5)
	
	canvas.draw_circle(fork_l, 1.2, t_c)
	canvas.draw_circle(fork_r, 1.2, t_c)

func _draw_eating_mouth(canvas: CanvasItem, center: Vector2, head_r: float, alpha_factor: float) -> void:
	var mouth_pos: Vector2 = center + Vector2(direction) * head_r * 0.52
	var mouth_r: float = head_r * 0.28 * mouth_open
	var m_alpha: float = 0.8 * mouth_open * alpha_factor
	
	canvas.draw_circle(mouth_pos, mouth_r, Color(mouth_color.r, mouth_color.g, mouth_color.b, m_alpha))
	
	if mouth_open > 0.3:
		var lip_c: Color = Color(0.85, 0.25, 0.3, 0.3 * mouth_open * alpha_factor)
		var lip_r: float = mouth_r * 0.65
		canvas.draw_arc(mouth_pos + Vector2(direction) * mouth_r * 0.15, lip_r, 0.4, PI - 0.4, 16, lip_c, 1.8)

# =========================================================
# Particles
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
