extends Node
class_name FoodManager

# =========================================================
# Configuration
# =========================================================
const DEFAULT_CELL_SIZE: int = 40

# Special fruit
const SPECIAL_SPAWN_CHANCE: float = 0.50  # 50% 生成概率
const SPECIAL_FOOD_DURATION: float = 10.0
const SPECIAL_FOOD_SCORE: int = 30

# Trap fruit
const TRAP_SPAWN_CHANCE: float = 0.10
const TRAP_PENALTY: int = 100
const TRAP_REVEAL_DIST: int = 3
const TRAP_BLINK_INTERVAL: float = 0.18
const TRAP_COUNTDOWN_MAX: float = 5.0
const TRAP_SHRINK_SEGMENTS: int = 10

# Food lifetime
const FOOD_LIFETIME: float = 10.0
const FOOD_WARN_THRESHOLD: float = 3.0

# Food rain
const FOOD_RAIN_MIN: int = 4
const FOOD_RAIN_MAX: int = 8

# Special fruit types
enum SpecialType { GHOST, WALL_STOP, FOOD_RAIN, WALL_PASS, SPEED_UP, SPEED_DOWN }
const SPECIAL_TYPE_COUNT: int = 6

# =========================================================
# State
# =========================================================
var main_food_pos: Vector2i = Vector2i(8, 8)
var extra_foods: Array[Dictionary] = []
var food_spawn_time: float = 0.0
var food_time: float = 0.0

# Special fruit
var special_active: bool = false
var special_type: int = SpecialType.GHOST
var special_pos: Vector2i = Vector2i(-1, -1)
var special_timer: float = 0.0
var special_blink: float = 0.0

# Trap
var trap_active: bool = false
var trap_revealed: bool = false
var trap_countdown: float = 0.0

# Grid settings
var CELL_SIZE: int = DEFAULT_CELL_SIZE
var GRID_WIDTH: int = 20
var GRID_HEIGHT: int = 20

# Colors
var food_color: Color = Color(1.0, 0.35, 0.35, 1.0)
var food_glow_color: Color = Color(1.0, 0.2, 0.2, 0.15)

# Bomb colors
var bomb_body_color: Color = Color(0.25, 0.22, 0.2, 1.0)
var bomb_highlight_color: Color = Color(0.45, 0.4, 0.38, 1.0)
var bomb_fuse_color: Color = Color(0.55, 0.45, 0.25, 1.0)

# Special fruit colors
var special_colors: Dictionary = {
	SpecialType.GHOST: [
		Color(0.7, 0.3, 1.0, 1.0), Color(1.0, 0.4, 0.9, 1.0),
		Color(0.5, 0.6, 1.0, 1.0), Color(0.9, 0.5, 1.0, 1.0),
	],
	SpecialType.WALL_STOP: [
		Color(1.0, 0.85, 0.1, 1.0), Color(0.95, 0.7, 0.05, 1.0),
		Color(1.0, 0.95, 0.3, 1.0), Color(0.85, 0.65, 0.0, 1.0),
	],
	SpecialType.FOOD_RAIN: [
		Color(1.0, 0.7, 0.0, 1.0), Color(1.0, 0.5, 0.15, 1.0),
		Color(1.0, 0.85, 0.2, 1.0), Color(1.0, 0.6, 0.35, 1.0),
	],
	SpecialType.WALL_PASS: [
		Color(0.6, 0.2, 0.9, 1.0), Color(0.8, 0.3, 1.0, 1.0),
		Color(0.5, 0.4, 1.0, 1.0), Color(0.9, 0.5, 1.0, 1.0),
	],
	SpecialType.SPEED_UP: [
		Color(1.0, 0.3, 0.1, 1.0), Color(1.0, 0.55, 0.0, 1.0),
		Color(1.0, 0.2, 0.2, 1.0), Color(1.0, 0.7, 0.1, 1.0),
	],
	SpecialType.SPEED_DOWN: [
		Color(0.2, 0.5, 1.0, 1.0), Color(0.1, 0.7, 0.9, 1.0),
		Color(0.3, 0.4, 0.95, 1.0), Color(0.15, 0.6, 1.0, 1.0),
	],
}

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
	main_food_pos = Vector2i(GRID_WIDTH / 2 + 3, GRID_HEIGHT / 2)
	extra_foods.clear()
	food_spawn_time = 0.0
	food_time = 0.0
	
	trap_active = false
	trap_revealed = false
	trap_countdown = 0.0
	
	special_active = false
	special_timer = 0.0
	special_blink = 0.0

# =========================================================
# Update
# =========================================================

func update(delta: float, snake_head: Vector2i, occupied_cells: Array[Vector2i]) -> void:
	food_time += delta
	special_blink += delta * 8.0
	
	# Trap update
	if trap_active:
		_update_trap(delta, snake_head)
	
	# Food expiration
	if not trap_active:
		var mf_age: float = food_time - food_spawn_time
		if mf_age >= FOOD_LIFETIME:
			_spawn_main_food(occupied_cells)
	
	for idx in range(extra_foods.size() - 1, -1, -1):
		var ef_age: float = food_time - extra_foods[idx].spawn_time
		if ef_age >= FOOD_LIFETIME:
			extra_foods.remove_at(idx)
	
	# Special fruit timer
	if special_active:
		special_timer -= delta
		if special_timer <= 0.0:
			special_active = false
			special_timer = 0.0

func _update_trap(delta: float, snake_head: Vector2i) -> void:
	if not trap_revealed:
		if grid_distance(snake_head, main_food_pos) <= TRAP_REVEAL_DIST:
			trap_revealed = true
			trap_countdown = TRAP_COUNTDOWN_MAX
			if audio_manager:
				audio_manager.play_bomb_tick(false)
	
	if trap_revealed:
		trap_countdown -= delta
		var prev_sec: int = ceili(trap_countdown + delta)
		var curr_sec: int = ceili(trap_countdown)
		if curr_sec != prev_sec and curr_sec > 0:
			if audio_manager:
				audio_manager.play_bomb_tick(curr_sec <= 2)
		
		if trap_countdown <= 0.0:
			trap_active = false
			trap_revealed = false
			trap_countdown = 0.0

# =========================================================
# Spawning
# =========================================================

func spawn_main_food(occupied_cells: Array[Vector2i]) -> void:
	var available: Array[Vector2i] = _get_available_cells(occupied_cells)
	if available.is_empty():
		return
	
	main_food_pos = available[randi() % available.size()]
	food_spawn_time = food_time
	
	# Try spawn special
	if randf() < SPECIAL_SPAWN_CHANCE and not special_active:
		_try_spawn_special(occupied_cells)
	
	# Try spawn trap
	if randf() < TRAP_SPAWN_CHANCE and not trap_active:
		trap_active = true
		trap_revealed = false
		trap_countdown = 0.0

func _try_spawn_special(occupied_cells: Array[Vector2i]) -> void:
	var available: Array[Vector2i] = _get_available_cells(occupied_cells)
	if available.is_empty():
		return
	
	special_pos = available[randi() % available.size()]
	special_type = randi() % SPECIAL_TYPE_COUNT
	special_active = true
	special_timer = SPECIAL_FOOD_DURATION
	
	if audio_manager:
		audio_manager.play_special_appear()

func _get_available_cells(occupied_cells: Array[Vector2i]) -> Array[Vector2i]:
	var available: Array[Vector2i] = []
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var cell = Vector2i(x, y)
			if not cell in occupied_cells:
				available.append(cell)
	return available

func spawn_food_rain(occupied_cells: Array[Vector2i]) -> void:
	var count: int = randi_range(FOOD_RAIN_MIN, FOOD_RAIN_MAX)
	for _i in range(count):
		var available: Array[Vector2i] = _get_available_cells(occupied_cells)
		if available.is_empty():
			break
		var pos: Vector2i = available[randi() % available.size()]
		extra_foods.append({"pos": pos, "spawn_time": food_time})

# =========================================================
# Collision Detection
# =========================================================

func check_food_collision(pos: Vector2i) -> int:
	# Returns: 0 = no collision, 1 = main food, 2 = extra food, 3 = trap, 4 = special
	
	if trap_active and pos == main_food_pos:
		return 3
	
	if pos == main_food_pos:
		return 1
	
	for idx in range(extra_foods.size() - 1, -1, -1):
		if extra_foods[idx].pos == pos:
			extra_foods.remove_at(idx)
			return 2
	
	if special_active and pos == special_pos:
		return 4
	
	return 0

# =========================================================
# Eating Effects
# =========================================================

func eat_food(pos: Vector2i, combo: int) -> int:
	var bonus: int = 10
	if combo >= 3:
		bonus += combo * 2
	
	_spawn_particles(pos, Color(1.0, 0.5, 0.3), 10, 80.0)
	
	var text_color: Color = Color(1.0, 1.0, 0.5) if bonus > 10 else Color(1.0, 1.0, 1.0)
	_spawn_floating_text("+%d" % bonus, pos, text_color, 16 if bonus <= 10 else 20)
	
	if audio_manager:
		audio_manager.play_eat_fruit()
	
	return bonus

func eat_special_fruit(pos: Vector2i, combo: int) -> Dictionary:
	var bonus: int = SPECIAL_FOOD_SCORE + combo * 5
	
	_spawn_particles(pos, Color(1.0, 0.85, 0.2), 25, 150.0)
	_spawn_floating_text("+%d" % bonus, pos, Color(1.0, 0.85, 0.2), 22)
	
	if audio_manager:
		audio_manager.play_eat_fruit()
	
	var effects: Dictionary = {
		"score": bonus,
		"ghost": false,
		"ghost_duration": 0.0,
		"wall_stop": false,
		"wall_stop_duration": 0.0,
		"wall_pass": false,
		"wall_pass_duration": 0.0,
		"food_rain": false,
		"speed_change": 0.0,
	}
	
	match special_type:
		SpecialType.GHOST:
			effects["ghost"] = true
			effects["ghost_duration"] = GHOST_DURATION
			if Loc:
				_spawn_floating_text(Loc.t("float_ghost"), pos, Color(0.7, 0.4, 1.0), 20)
		SpecialType.WALL_STOP:
			effects["wall_stop"] = true
			effects["wall_stop_duration"] = 15.0
			if Loc:
				_spawn_floating_text(Loc.t("float_shield"), pos, Color(1.0, 0.85, 0.2), 20)
		SpecialType.FOOD_RAIN:
			effects["food_rain"] = true
			if Loc:
				_spawn_floating_text(Loc.t("float_rain"), pos, Color(1.0, 0.8, 0.2), 20)
		SpecialType.WALL_PASS:
			effects["wall_pass"] = true
			effects["wall_pass_duration"] = 15.0
			if Loc:
				_spawn_floating_text(Loc.t("float_wallpass"), pos, Color(0.7, 0.3, 1.0), 20)
		SpecialType.SPEED_UP:
			effects["speed_change"] = 0.005
			if Loc:
				_spawn_floating_text(Loc.t("float_speedup"), pos, Color(1.0, 0.5, 0.1), 20)
		SpecialType.SPEED_DOWN:
			effects["speed_change"] = -0.005
			if Loc:
				_spawn_floating_text(Loc.t("float_speeddown"), pos, Color(0.3, 0.6, 1.0), 20)
	
	special_active = false
	special_timer = 0.0
	
	return effects

func eat_trap(pos: Vector2i) -> Dictionary:
	var effects: Dictionary = {
		"penalty": TRAP_PENALTY,
		"shrink": TRAP_SHRINK_SEGMENTS,
	}
	
	trap_active = false
	trap_revealed = false
	trap_countdown = 0.0
	
	_spawn_particles(pos, Color(1.0, 0.3, 0.1), 20, 120.0)
	_spawn_floating_text("-%d" % TRAP_PENALTY, pos, Color(1.0, 0.3, 0.2), 20)
	if Loc:
		_spawn_floating_text(Loc.t("float_seg") % TRAP_SHRINK_SEGMENTS, pos, Color(1.0, 0.6, 0.3), 14)
	
	if audio_manager:
		audio_manager.play_bomb_explode()
	
	return effects

# =========================================================
# Drawing
# =========================================================

func draw(canvas: CanvasItem, anim_timer: float) -> void:
	# Draw trap or main food
	if trap_active:
		_draw_trap(canvas, anim_timer)
	else:
		var mf_age: float = food_time - food_spawn_time
		var mf_blink: bool = mf_age > (FOOD_LIFETIME - FOOD_WARN_THRESHOLD)
		_draw_food(canvas, main_food_pos, mf_blink, anim_timer)
	
	# Draw extra foods
	for ef in extra_foods:
		var ef_age: float = food_time - ef.spawn_time
		var ef_blink: bool = ef_age > (FOOD_LIFETIME - FOOD_WARN_THRESHOLD)
		_draw_food(canvas, ef.pos, ef_blink, anim_timer)
	
	# Draw special food
	if special_active:
		_draw_special_food(canvas)

func _draw_food(canvas: CanvasItem, pos: Vector2i, blink: bool, anim_timer: float) -> void:
	if blink:
		var blink_cycle: float = fmod(anim_timer * 8.0, TAU)
		if blink_cycle > PI:
			return
	
	var center: Vector2 = Vector2(pos.x * CELL_SIZE + CELL_SIZE / 2.0, pos.y * CELL_SIZE + CELL_SIZE / 2.0)
	var pulse: float = 1.0 + sin(anim_timer * 5.0) * 0.12
	var radius: float = (CELL_SIZE / 2.0 - 4) * pulse
	
	for i in range(3):
		var gr: float = radius + (3 - i) * 4.0
		var ga: float = 0.05 + i * 0.03
		canvas.draw_circle(center, gr, Color(food_glow_color.r, food_glow_color.g, food_glow_color.b, ga))
	
	canvas.draw_circle(center, radius, food_color)
	canvas.draw_circle(center + Vector2(-3, -3), radius * 0.3, Color(1.0, 0.7, 0.7, 0.6))

func _draw_special_food(canvas: CanvasItem) -> void:
	var center: Vector2 = Vector2(
		special_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		special_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	)
	var palette: Array = special_colors[special_type]
	var blink_cycle: float = fmod(special_blink, 4.0 * PI)
	var color_index: int = int(blink_cycle / PI) % palette.size()
	var base_color: Color = palette[color_index]
	var flash_alpha: float = 0.55 + 0.45 * abs(sin(special_blink * 0.8))
	base_color.a = flash_alpha
	
	var pulse: float = 1.0 + sin(special_blink * 0.7) * 0.15
	var radius: float = (CELL_SIZE / 2.0 - 2) * pulse
	
	# Glow rings
	for ring in range(4):
		var ring_r: float = radius + (4 - ring) * 5.0
		var ring_a: float = (0.03 + ring * 0.02) * flash_alpha
		var rc: Color = palette[(color_index + ring) % palette.size()]
		rc.a = ring_a
		canvas.draw_circle(center, ring_r, rc)
	
	# Rays
	var ray_len: float = radius + 8.0
	var ray_col: Color = Color(base_color.r, base_color.g, base_color.b, 0.2 * flash_alpha)
	for k in range(8):
		var angle: float = special_blink * 0.3 + k * PI / 4.0
		canvas.draw_line(center, center + Vector2(cos(angle), sin(angle)) * ray_len, ray_col, 2.0)
	
	# Main circle
	canvas.draw_circle(center, radius, base_color)
	
	# Icon
	var icon_color: Color = Color(1.0, 1.0, 1.0, 0.8 * flash_alpha)
	match special_type:
		SpecialType.SPEED_UP:
			_draw_chevron_right(canvas, center.x, center.y, 8.0, icon_color, 3.0)
			_draw_chevron_right(canvas, center.x + 8.0, center.y, 8.0, icon_color, 3.0)
		SpecialType.SPEED_DOWN:
			_draw_chevron_left(canvas, center.x, center.y, 8.0, icon_color, 3.0)
			_draw_chevron_left(canvas, center.x - 8.0, center.y, 8.0, icon_color, 3.0)
		_:
			var icon_char: String
			match special_type:
				SpecialType.GHOST: icon_char = "G"
				SpecialType.WALL_STOP: icon_char = "S"
				SpecialType.FOOD_RAIN: icon_char = "F"
				SpecialType.WALL_PASS: icon_char = "P"
			canvas.draw_string(ThemeDB.fallback_font, Vector2(center.x + 6, center.y - 10),
				icon_char, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 1.0, 1.0, 0.7 * flash_alpha))

func _draw_trap(canvas: CanvasItem, anim_timer: float) -> void:
	if trap_revealed:
		var cycle: float = fmod(anim_timer, TRAP_BLINK_INTERVAL * 2.0)
		if cycle < TRAP_BLINK_INTERVAL:
			_draw_food(canvas, main_food_pos, false, anim_timer)
		else:
			_draw_bomb(canvas, anim_timer)
	else:
		_draw_food(canvas, main_food_pos, false, anim_timer)

func _draw_bomb(canvas: CanvasItem, anim_timer: float) -> void:
	var center: Vector2 = Vector2(main_food_pos.x * CELL_SIZE + CELL_SIZE / 2.0, main_food_pos.y * CELL_SIZE + CELL_SIZE / 2.0)
	var pulse: float = 1.0 + sin(anim_timer * 12.0) * 0.08
	var radius: float = (CELL_SIZE / 2.0 - 4) * pulse
	
	canvas.draw_circle(center, radius + 8.0, Color(1.0, 0.15, 0.0, 0.08))
	canvas.draw_circle(center, radius + 4.0, Color(1.0, 0.2, 0.0, 0.12))
	canvas.draw_circle(center, radius, bomb_body_color)
	canvas.draw_circle(center + Vector2(-radius * 0.25, -radius * 0.25), radius * 0.3, bomb_highlight_color)
	
	# X mark
	var x_size: float = radius * 0.45
	var x_color: Color = Color(0.7, 0.15, 0.1, 0.9)
	canvas.draw_line(center + Vector2(-x_size, -x_size), center + Vector2(x_size, x_size), x_color, 2.5)
	canvas.draw_line(center + Vector2(x_size, -x_size), center + Vector2(-x_size, x_size), x_color, 2.5)
	
	# Fuse
	draw_rect(canvas, Rect2(center.x - 3, center.y - radius - 2, 6, 4), Color(0.6, 0.55, 0.4, 1.0))
	var fuse_start: Vector2 = Vector2(center.x, center.y - radius - 2)
	var fuse_mid: Vector2 = Vector2(center.x + 5, center.y - radius - 7)
	var fuse_end: Vector2 = Vector2(center.x + 2, center.y - radius - 12)
	canvas.draw_line(fuse_start, fuse_mid, bomb_fuse_color, 2.0)
	canvas.draw_line(fuse_mid, fuse_end, bomb_fuse_color, 2.0)
	
	# Spark
	var spark_blink: float = abs(sin(anim_timer * 15.0))
	var spark_size: float = 3.0 + spark_blink * 2.0
	canvas.draw_circle(fuse_end, spark_size + 2.0, Color(1.0, 0.5, 0.1, 0.4 * spark_blink))
	canvas.draw_circle(fuse_end, spark_size, Color(1.0, 0.85, 0.2, 0.8 * spark_blink))
	canvas.draw_circle(fuse_end, spark_size * 0.4, Color(1.0, 1.0, 0.8, 0.9))
	
	# Countdown
	var remaining: int = max(1, ceili(trap_countdown))
	var countdown_text: String = str(remaining)
	var font = ThemeDB.fallback_font
	var ts: Vector2 = font.get_string_size(countdown_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
	var tx: float = center.x - ts.x / 2.0
	var ty: float = center.y - ts.y / 2.0 + 2
	canvas.draw_string(font, Vector2(tx + 1, ty + 1), countdown_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0, 0.8))
	
	var num_color: Color
	if trap_countdown <= 2.0:
		var flash: float = abs(sin(anim_timer * 6.0))
		num_color = Color(1.0, 0.3 + flash * 0.3, 0.2, 1.0)
	else:
		num_color = Color(1.0, 0.85, 0.2, 0.95)
	canvas.draw_string(font, Vector2(tx, ty), countdown_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, num_color)
	
	var warn_text: String = "-%d" % TRAP_PENALTY
	var wts: Vector2 = font.get_string_size(warn_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
	canvas.draw_string(font, Vector2(center.x - wts.x / 2.0, center.y + radius + 10),
		warn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.3, 0.2, 0.8))

func _draw_chevron_right(canvas: CanvasItem, cx: float, cy: float, arm: float, color: Color, width: float = 3.0) -> void:
	var shadow: Color = Color(0.0, 0.0, 0.0, color.a * 0.4)
	canvas.draw_line(Vector2(cx - arm + 1.0, cy - arm + 1.0), Vector2(cx + 1.0, cy + 1.0), shadow, width)
	canvas.draw_line(Vector2(cx - arm + 1.0, cy + arm + 1.0), Vector2(cx + 1.0, cy + 1.0), shadow, width)
	canvas.draw_line(Vector2(cx - arm, cy - arm), Vector2(cx, cy), color, width)
	canvas.draw_line(Vector2(cx - arm, cy + arm), Vector2(cx, cy), color, width)

func _draw_chevron_left(canvas: CanvasItem, cx: float, cy: float, arm: float, color: Color, width: float = 3.0) -> void:
	var shadow: Color = Color(0.0, 0.0, 0.0, color.a * 0.4)
	canvas.draw_line(Vector2(cx + arm + 1.0, cy - arm + 1.0), Vector2(cx + 1.0, cy + 1.0), shadow, width)
	canvas.draw_line(Vector2(cx + arm + 1.0, cy + arm + 1.0), Vector2(cx + 1.0, cy + 1.0), shadow, width)
	canvas.draw_line(Vector2(cx + arm, cy - arm), Vector2(cx, cy), color, width)
	canvas.draw_line(Vector2(cx + arm, cy + arm), Vector2(cx, cy), color, width)

func draw_rect(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(rect, color)

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

func grid_distance(a: Vector2i, b: Vector2i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y))

func get_all_food_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	positions.append(main_food_pos)
	for ef in extra_foods:
		positions.append(ef.pos)
	if special_active:
		positions.append(special_pos)
	return positions
