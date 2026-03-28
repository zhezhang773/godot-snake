extends Node2D
# =========================================================
# 优化：内嵌粒子对象池
# =========================================================
const OPTIMIZED_MAX_PARTICLES: int = 100
var _particle_pool: Array[Dictionary] = []
var _particle_active_count: int = 0

# =========================================================
# 优化：内嵌浮动文字对象池
# =========================================================
const OPTIMIZED_MAX_FLOATING_TEXTS: int = 50
var _floating_text_pool: Array[Dictionary] = []
var _floating_text_active_count: int = 0
# =========================================================
# Configuration
# =========================================================
const DEFAULT_CELL_SIZE: int = 40
const DEFAULT_GRID_WIDTH: int = 20
const DEFAULT_GRID_HEIGHT: int = 20
const DRAW_MARGIN: int = 30

# Special fruit
const SPECIAL_SPAWN_CHANCE: float = 0.30  # 30% 生成概率
const SPECIAL_FOOD_DURATION: float = 5.0
const SPECIAL_FOOD_SCORE: int = 30

# Effect durations
const GHOST_DURATION: float = 20.0
const GHOST_WARN_THRESHOLD: float = 5.0
const WALL_STOP_DURATION: float = 15.0
const WALL_PASS_DURATION: float = 15.0
const FOOD_RAIN_MIN: int = 4
const FOOD_RAIN_MAX: int = 8

# Speed fruit
const SPEED_UP_AMOUNT: float = 0.005
const SPEED_DOWN_AMOUNT: float = 0.005
const SPEED_DEATH_THRESHOLD: float = 0.005

# Boost (long-press)
const BOOST_MULTIPLIER: float = 0.5
const BOOST_HOLD_THRESHOLD: float = 0.5

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

# Terrain
enum Terrain { GROUND, FOREST, RIVER, MOUNTAIN, VOLCANO, MAGMA }
const NUM_FOREST_CLUSTERS_MIN: int = 6
const NUM_FOREST_CLUSTERS_MAX: int = 8
const FOREST_CLUSTER_MIN: int = 12
const FOREST_CLUSTER_MAX: int = 18
const NUM_RIVER_CLUSTERS_MIN: int = 5
const NUM_RIVER_CLUSTERS_MAX: int = 7
const RIVER_CLUSTER_MIN: int = 10
const RIVER_CLUSTER_MAX: int = 16
const RIVER_SPEED_PENALTY: float = 0.7

# Mountain terrain
const NUM_MOUNTAIN_CLUSTERS_MIN: int = 6
const NUM_MOUNTAIN_CLUSTERS_MAX: int = 10
const MOUNTAIN_CLUSTER_MIN: int = 8
const MOUNTAIN_CLUSTER_MAX: int = 15

# Volcano and Magma
const VOLCANO_MAGMA_DAMAGE_INTERVAL: float = 1.0
const VOLCANO_MAGMA_DAMAGE_SCORE: int = 50
const RIVER_SCORE_INTERVAL: float = 1.0
const RIVER_SCORE_PENALTY: int = 1

# Wormhole
const MAX_WORMHOLE_PAIRS: int = 2

# Level gate
const GATE_OPEN_SCORE_PER_LEVEL: int = 50
const WORMHOLE_MIN_DIST: int = 5

# Special fruit types
enum SpecialType { GHOST, WALL_STOP, FOOD_RAIN, WALL_PASS, SPEED_UP, SPEED_DOWN, MAGMA_FRUIT }
const SPECIAL_TYPE_COUNT: int = 7

# Magma fruit effect
const MAGMA_FRUIT_DURATION: float = 10.0
const MAGMA_FRUIT_SPEED_DIVISOR: float = 2.0  # Divide interval by 2 = double speed
const MAGMA_FRUIT_SCORE_MULTIPLIER: int = 2



# Particle effects
const MAX_PARTICLES: int = 80

# =========================================================
# Menu Configuration
# =========================================================
enum MenuScreen { MAIN, HELP, HIGH_SCORE }
const MENU_ICONS: PackedStringArray = ["▶", "★", "?", "✕"]
const MENU_START_Y: float = 310.0
const MENU_SPACING: float = 70.0
const MENU_ITEM_W: float = 300.0
const MENU_ITEM_H: float = 52.0

# Pause menu
const PAUSE_ICONS: PackedStringArray = ["▶", "◀"]
const PAUSE_ITEMS_COUNT: int = 2

# =========================================================
# Game State
# =========================================================
var score: int = 0
var total_score: int = 0
var high_score: int = 0
var game_over: bool = false
var game_started: bool = false
var game_speed: float = 0.15
var speed_timer: float = 0.0
var display_speed: float = 0.3

# Level gate
var gate_pos: Vector2i = Vector2i(-1, -1)
var gate_open: bool = false
var gate_level: int = 1
var gate_anim: float = 0.0
var gate_flash: float = 0.0
var paused: bool = false
var pause_selected: int = 0
var death_reason: String = ""
var combo: int = 0
var combo_timer: float = 0.0
var total_food_eaten: int = 0

# =========================================================
# Terrain
# =========================================================
var tiles: Array = []
var river_variants: Array = []
var river_penalty_timer: float = 0.0
var magma_damage_timer: float = 0.0
var is_on_magma: bool = false

# Burning effect after leaving magma
var is_burning: bool = false
var burning_timer: float = 0.0
const BURNING_DURATION: float = 5.0
const BURNING_DAMAGE_INTERVAL: float = 1.0
var burning_damage_timer: float = 0.0
const BURNING_DAMAGE_SCORE: int = 20

# Wormholes
var wormholes: Array[Dictionary] = []
var wormhole_cooldown: bool = false

# Wormhole color palettes [main, light, dark, glow]
var wormhole_palettes: Array[Array] = [
	[Color(0.91, 0.28, 0.47), Color(1.0, 0.5, 0.65), Color(0.55, 0.12, 0.25), Color(0.91, 0.28, 0.47)],
	[Color(0.2, 0.6, 0.95), Color(0.45, 0.75, 1.0), Color(0.1, 0.3, 0.6), Color(0.2, 0.6, 0.95)],
]

# =========================================================
# Menu State
# =========================================================
var in_menu: bool = true
var current_menu_screen: int = MenuScreen.MAIN
var menu_selected: int = 0
var menu_anim: float = 0.0
var menu_particles: Array[Dictionary] = []

# =========================================================
# Boost State (long-press direction to accelerate)
# =========================================================
var boosted: bool = false
var boost_glow: float = 0.0
var boost_hold_timer: float = 0.0
var boost_hold_dir: Vector2i = Vector2i(0, 0)

# =========================================================
# Grid / Visual
# =========================================================
var CELL_SIZE: int = DEFAULT_CELL_SIZE
var GRID_WIDTH: int = DEFAULT_GRID_WIDTH
var GRID_HEIGHT: int = DEFAULT_GRID_HEIGHT

# =========================================================
# Snake
# =========================================================
var segments: Array[Vector2i] = []
var direction: Vector2i = Vector2i(1, 0)
var next_direction: Vector2i = Vector2i(1, 0)
var grow_pending: int = 0

# =========================================================
# Food (main + extras from food rain)
# =========================================================
var main_food_pos: Vector2i = Vector2i(8, 8)
var extra_foods: Array[Dictionary] = []
var food_spawn_time: float = 0.0
var food_time: float = 0.0

# =========================================================
# Trap Fruit (single, replaces main food)
# =========================================================
var trap_active: bool = false
var trap_revealed: bool = false
var trap_countdown: float = 0.0

# =========================================================
# Special Fruit
# =========================================================
var special_active: bool = false
var special_type: int = SpecialType.GHOST
var special_pos: Vector2i = Vector2i(-1, -1)
var special_timer: float = 0.0
var special_blink: float = 0.0

# =========================================================
# Active Effects (timed)
# =========================================================
var ghost_active: bool = false
var ghost_timer: float = 0.0
var wall_stop_active: bool = false
var wall_stop_timer: float = 0.0
var wall_pass_active: bool = false
var wall_pass_timer: float = 0.0

# Magma fruit effect
var magma_fruit_active: bool = false
var magma_fruit_timer: float = 0.0

# =========================================================
# Particles
# =========================================================
var particles: Array[Dictionary] = []

# =========================================================
# Floating Texts (score popups)
# =========================================================
var floating_texts: Array[Dictionary] = []

# =========================================================
# Animation timers
# =========================================================
var food_pulse: float = 0.0
var screen_shake: float = 0.0
var anim_timer: float = 0.0

# =========================================================
# Snake Animation
var eating_anim_timer: float = 0.0
var mouth_open: float = 0.0
var tongue_timer: float = 0.0
var tongue_flick_timer: float = 0.0
var blink_timer: float = 0.0
var is_blinking: bool = false
var next_blink_time: float = 3.0

# Audio reference
# =========================================================
var audio_manager: Node = null

# =========================================================
# Language button
# =========================================================
var _lang_btn_rect: Rect2 = Rect2(0, 0, 0, 0)

# Stored menu item rects for mouse click detection
var _menu_item_rects: Array[Rect2] = []
var _pause_item_rects: Array[Rect2] = []
var _gameover_btn_rects: Array[Rect2] = []

# =========================================================
# Colors
# =========================================================
var bg_color: Color = Color(0.06, 0.08, 0.12, 1.0)
var grid_color: Color = Color(0.1, 0.13, 0.18, 1.0)
var head_color: Color = Color(0.22, 0.92, 0.45, 1.0)
var body_color: Color = Color(0.18, 0.82, 0.38, 1.0)
var tail_color: Color = Color(0.12, 0.62, 0.3, 1.0)
var eye_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var pupil_color: Color = Color(0.1, 0.1, 0.1, 1.0)
var food_color: Color = Color(1.0, 0.35, 0.35, 1.0)
var food_glow_color: Color = Color(1.0, 0.2, 0.2, 0.15)
var border_color: Color = Color(0.3, 0.4, 0.55, 1.0)

# Cute snake colors
var belly_color: Color = Color(0.38, 0.94, 0.52, 1.0)
var blush_color: Color = Color(1.0, 0.45, 0.5, 0.3)
var tongue_color: Color = Color(0.95, 0.3, 0.35, 0.9)
var scale_dot_color: Color = Color(0.1, 0.6, 0.28, 0.25)
var mouth_color: Color = Color(0.12, 0.08, 0.08, 1.0)

# Boost color
var boost_color: Color = Color(1.0, 0.6, 0.1, 1.0)
var boost_glow_color: Color = Color(1.0, 0.45, 0.0, 0.25)

# Ghost effect
var ghost_head_color: Color = Color(0.35, 0.3, 1.0, 0.7)
var ghost_body_color: Color = Color(0.3, 0.25, 0.9, 0.6)
var ghost_tail_color: Color = Color(0.25, 0.2, 0.7, 0.5)

# Wall Stop sponge
var sponge_color: Color = Color(0.92, 0.72, 0.08, 0.92)
var sponge_highlight: Color = Color(1.0, 0.92, 0.35, 0.85)
var sponge_dark: Color = Color(0.6, 0.42, 0.05, 0.88)
var sponge_bubble_color: Color = Color(1.0, 0.95, 0.5, 0.65)
var sponge_shine_color: Color = Color(1.0, 0.98, 0.7, 0.3)

# Wall Pass portal
var portal_color: Color = Color(0.6, 0.2, 0.9, 0.7)
var portal_glow: Color = Color(0.8, 0.4, 1.0, 0.25)

# Bomb
var bomb_body_color: Color = Color(0.25, 0.22, 0.2, 1.0)
var bomb_highlight_color: Color = Color(0.45, 0.4, 0.38, 1.0)
var bomb_fuse_color: Color = Color(0.55, 0.45, 0.25, 1.0)

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
	SpecialType.MAGMA_FRUIT: [
		Color(1.0, 0.85, 0.0, 1.0), Color(1.0, 0.95, 0.2, 1.0),
		Color(1.0, 0.7, 0.1, 1.0), Color(0.95, 0.6, 0.0, 1.0),
	],
}

var ghost_bar_color: Color = Color(0.5, 0.3, 1.0, 0.7)
var wallstop_bar_color: Color = Color(0.95, 0.78, 0.15, 0.8)
var wallpass_bar_color: Color = Color(0.6, 0.25, 0.9, 0.7)
var trap_bar_color: Color = Color(0.9, 0.3, 0.1, 0.7)
var magma_fruit_bar_color: Color = Color(1.0, 0.6, 0.0, 0.8)

# =========================================================
# Localization helper
# =========================================================
func _get_menu_names() -> PackedStringArray:
	return PackedStringArray([
		Loc.t("menu_start"),
		Loc.t("menu_highscore"),
		Loc.t("menu_help"),
		Loc.t("menu_quit"),
	])

# =========================================================
# Lifecycle
# =========================================================

func _ready() -> void:
	randomize()
	_load_high_score()
	audio_manager = get_node_or_null("AudioManager")
	
	# 初始化优化系统
	_init_particle_pool()
	_init_floating_text_pool()
	
	
	_init_menu()
	_reset_game()
	_spawn_main_food()

func _init_menu() -> void:
	in_menu = true
	current_menu_screen = MenuScreen.MAIN
	menu_selected = 0
	menu_anim = 0.0
	menu_particles.clear()
	var canvas_w: float = float(GRID_WIDTH * CELL_SIZE)
	var canvas_h: float = float(GRID_HEIGHT * CELL_SIZE)
	for i in range(35):
		var is_green: bool = randf() < 0.7
		menu_particles.append({
			"x": randf() * canvas_w,
			"y": randf() * canvas_h,
			"vx": randf_range(-10, 10),
			"vy": randf_range(-10, 10),
			"size": randf_range(1.2, 3.2),
			"color": Color(0.1, 1.0, 0.35, 1.0) if is_green else Color(1.0, 0.35, 0.35, 1.0),
			"alpha": randf_range(0.08, 0.3),
			"phase": randf() * TAU,
		})

func _update_menu_particles(delta: float) -> void:
	var cw: float = float(GRID_WIDTH * CELL_SIZE)
	var ch: float = float(GRID_HEIGHT * CELL_SIZE)
	for p in menu_particles:
		p["x"] += p["vx"] * delta
		p["y"] += p["vy"] * delta
		if p["x"] < -10: p["x"] = cw + 10
		if p["x"] > cw + 10: p["x"] = -10
		if p["y"] < -10: p["y"] = ch + 10
		if p["y"] > ch + 10: p["y"] = -10

func _return_to_menu() -> void:
	in_menu = true
	current_menu_screen = MenuScreen.MAIN
	menu_selected = 0
	game_over = false
	game_started = false
	paused = false
	pause_selected = 0
	score = 0
	total_score = 0
	_reset_game()
	_spawn_main_food()
	gate_level = 1
	if audio_manager:
		audio_manager.set_music_volume(0.15)

# =========================================================
# Menu Input
# =========================================================

func _handle_menu_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match current_menu_screen:
		MenuScreen.MAIN:
			_handle_main_menu_input(event)
		MenuScreen.HELP, MenuScreen.HIGH_SCORE:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				current_menu_screen = MenuScreen.MAIN

func _handle_main_menu_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or event.keycode == KEY_UP or event.keycode == KEY_W:
		menu_selected = posmod(menu_selected - 1, _get_menu_names().size())
	elif event.is_action_pressed("move_down") or event.keycode == KEY_DOWN or event.keycode == KEY_S:
		menu_selected = posmod(menu_selected + 1, _get_menu_names().size())
	elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		_select_menu_item()

func _select_menu_item() -> void:
	match menu_selected:
		0:  # Start Game
			in_menu = false
			game_started = true
			score = 0
			total_score = 0
			gate_level = 1
			game_speed = 0.3
			speed_timer = 0.0
			if audio_manager:
				audio_manager.set_music_volume(0.6)
		1:  # High Score
			current_menu_screen = MenuScreen.HIGH_SCORE
		2:  # Help
			current_menu_screen = MenuScreen.HELP
		3:  # Quit
			get_tree().quit()

# =========================================================
# Pause Menu Input
# =========================================================

func _handle_pause_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	# ESC closes pause entirely (toggle off)
	if event.keycode == KEY_ESCAPE:
		paused = false
		return
	# Navigate pause items
	if event.is_action_pressed("move_up") or event.keycode == KEY_UP or event.keycode == KEY_W:
		pause_selected = posmod(pause_selected - 1, PAUSE_ITEMS_COUNT)
	elif event.is_action_pressed("move_down") or event.keycode == KEY_DOWN or event.keycode == KEY_S:
		pause_selected = posmod(pause_selected + 1, PAUSE_ITEMS_COUNT)
	elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		_select_pause_item()

func _select_pause_item() -> void:
	match pause_selected:
		0:  # Continue
			paused = false
		1:  # Return to Menu
			_return_to_menu()

func _reset_game() -> void:
	segments.clear()
	var sx: int = GRID_WIDTH / 2
	var sy: int = GRID_HEIGHT / 2
	for i in range(3):
		segments.append(Vector2i(sx - i, sy))
	direction = Vector2i(1, 0)
	next_direction = Vector2i(1, 0)
	grow_pending = 0
	main_food_pos = Vector2i(sx + 3, sy)
	extra_foods.clear()
	food_spawn_time = 0.0
	food_time = 0.0
	trap_active = false
	trap_revealed = false
	trap_countdown = 0.0
	special_active = false
	special_timer = 0.0
	ghost_active = false
	ghost_timer = 0.0
	wall_stop_active = false
	wall_stop_timer = 0.0
	wall_pass_active = false
	wall_pass_timer = 0.0
	screen_shake = 0.0
	death_reason = ""
	combo = 0
	combo_timer = 0.0
	total_food_eaten = 0
	particles.clear()
	floating_texts.clear()
	tiles.clear()
	river_variants.clear()
	wormholes.clear()
	wormhole_cooldown = false
	gate_open = false
	gate_flash = 0.0
	_generate_terrain()
	_generate_gate()
	river_penalty_timer = 0.0
	magma_damage_timer = 0.0
	is_on_magma = false
	is_burning = false
	burning_timer = 0.0
	burning_damage_timer = 0.0
	magma_fruit_active = false
	magma_fruit_timer = 0.0
	game_speed = 0.3
	boosted = false
	boost_glow = 0.0
	boost_hold_timer = 0.0
	boost_hold_dir = Vector2i(0, 0)
	paused = false
	pause_selected = 0
	eating_anim_timer = 0.0
	mouth_open = 0.0
	tongue_timer = 0.0
	tongue_flick_timer = 0.0
	blink_timer = 0.0
	is_blinking = false
	next_blink_time = 3.0
	if audio_manager:
		audio_manager.set_music_tempo(100.0)
		# 在函数末尾添加：
	# 清理优化系统
	for i in range(OPTIMIZED_MAX_PARTICLES):
		_particle_pool[i]["active"] = false
	_particle_active_count = 0

	for i in range(OPTIMIZED_MAX_FLOATING_TEXTS):
		_floating_text_pool[i]["active"] = false
	_floating_text_active_count = 0

# =========================================================
# Mouse Click Handlers
# =========================================================

func _click_menu_items(mouse_pos: Vector2) -> void:
	var local_pos: Vector2 = mouse_pos - Vector2(DRAW_MARGIN, DRAW_MARGIN)
	for i in range(_menu_item_rects.size()):
		if _menu_item_rects[i].has_point(local_pos):
			menu_selected = i
			_select_menu_item()
			return

func _click_gameover_buttons(mouse_pos: Vector2) -> void:
	var local_pos: Vector2 = mouse_pos - Vector2(DRAW_MARGIN, DRAW_MARGIN)
	for i in range(_gameover_btn_rects.size()):
		if _gameover_btn_rects[i].has_point(local_pos):
			match i:
				0:  # New Game
					score = 0
					total_score = 0
					gate_level = 1
					game_speed = 0.3
					speed_timer = 0.0
					game_over = false
					game_started = true
					paused = false
					pause_selected = 0
					_reset_game()
					_spawn_main_food()
					if audio_manager:
						audio_manager.set_music_volume(0.6)
				1:  # Quit
					_return_to_menu()
			return

func _click_pause_items(mouse_pos: Vector2) -> void:
	var local_pos: Vector2 = mouse_pos - Vector2(DRAW_MARGIN, DRAW_MARGIN)
	for i in range(_pause_item_rects.size()):
		if _pause_item_rects[i].has_point(local_pos):
			pause_selected = i
			_select_pause_item()
			return

# =========================================================
# Boost Detection (with hold threshold)
# =========================================================

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

func _is_direction_action_held(dir: Vector2i) -> bool:
	if dir == Vector2i(0, -1):
		return Input.is_action_pressed("move_up")
	elif dir == Vector2i(0, 1):
		return Input.is_action_pressed("move_down")
	elif dir == Vector2i(-1, 0):
		return Input.is_action_pressed("move_left")
	elif dir == Vector2i(1, 0):
		return Input.is_action_pressed("move_right")
	return false

func _check_boost(delta: float) -> void:
	var key_held: bool = _is_direction_key_held(direction) or _is_direction_action_held(direction)
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

# =========================================================
# Main Loop
# =========================================================

func _process(delta: float) -> void:
	# Menu mode
	if in_menu:
		menu_anim += delta
		_update_menu_particles(delta)
		queue_redraw()
		return

	# Game mode
	anim_timer += delta
	# Eating animation timer
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
	food_pulse += delta * 5.0
	special_blink += delta * 8.0
	gate_anim += delta
	if screen_shake > 0.0:
		screen_shake = max(0.0, screen_shake - delta * 8.0)

	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0

	_update_particles(delta)
	_update_floating_texts(delta)

	if paused:
		queue_redraw()
		return
	if not game_started or game_over:
		queue_redraw()
		return

	# Effect countdown
	if special_active:
		special_timer -= delta
		if special_timer <= 0.0:
			special_active = false
			special_timer = 0.0

	# Effect timers
	if ghost_active:
		ghost_timer -= delta
		if ghost_timer <= 0.0:
			ghost_active = false
			ghost_timer = 0.0
	if wall_stop_active:
		wall_stop_timer -= delta
		if wall_stop_timer <= 0.0:
			wall_stop_active = false
			wall_stop_timer = 0.0
	if wall_pass_active:
		wall_pass_timer -= delta
		if wall_pass_timer <= 0.0:
			wall_pass_active = false
			wall_pass_timer = 0.0
	
	# Magma fruit effect timer
	if magma_fruit_active:
		magma_fruit_timer -= delta
		if magma_fruit_timer <= 0.0:
			magma_fruit_active = false
			magma_fruit_timer = 0.0
			_spawn_floating_text(Loc.t("float_magma_end"), segments[0] if not segments.is_empty() else Vector2i(0, 0), Color(0.9, 0.3, 0.1), 16)
	
	# Magma damage and burning effect
	if game_started and not game_over:
		if is_on_magma:
			# On magma: take damage and start/refresh burning
			magma_damage_timer += delta
			burning_timer = BURNING_DURATION  # Refresh burning timer
			is_burning = true
			
			if magma_damage_timer >= VOLCANO_MAGMA_DAMAGE_INTERVAL:
				magma_damage_timer = 0.0
				score -= VOLCANO_MAGMA_DAMAGE_SCORE
				if score < 0:
					score = 0
				# Spawn fire particles
				if not segments.is_empty():
					_spawn_particles(segments[0], Color(1.0, 0.2, 0.0), 10, 100.0)
					_spawn_floating_text(Loc.t("float_burning") % VOLCANO_MAGMA_DAMAGE_SCORE, segments[0], Color(1.0, 0.3, 0.0), 16)
				if audio_manager:
					audio_manager.play_bomb_explode()
		else:
			# Not on magma: check burning effect
			if is_burning:
				burning_timer -= delta
				burning_damage_timer += delta
				
				# Burning damage every second
				if burning_damage_timer >= BURNING_DAMAGE_INTERVAL:
					burning_damage_timer = 0.0
					score -= BURNING_DAMAGE_SCORE
					if score < 0:
						score = 0
					if not segments.is_empty():
						_spawn_floating_text("-%d" % BURNING_DAMAGE_SCORE, segments[0], Color(1.0, 0.5, 0.1), 14)
				
				# Check if burning ends
				if burning_timer <= 0.0:
					is_burning = false
					burning_timer = 0.0
					burning_damage_timer = 0.0
			
			# Reset magma timer when not on magma
			magma_damage_timer = 0.0

	# Trap
	if trap_active:
		if not trap_revealed and not segments.is_empty():
			var head: Vector2i = segments[0]
			if grid_distance(head, main_food_pos) <= TRAP_REVEAL_DIST:
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
				_spawn_main_food()
				combo_timer = 8.0

	# Food timer
	food_time += delta
	# Food expiration
	if not trap_active:
		var mf_age: float = food_time - food_spawn_time
		if mf_age >= FOOD_LIFETIME:
			combo = 0
			_spawn_main_food()
	for idx in range(extra_foods.size() - 1, -1, -1):
		var ef_age: float = food_time - extra_foods[idx].spawn_time
		if ef_age >= FOOD_LIFETIME:
			combo = 0
			extra_foods.remove_at(idx)

	# Gate open check
	var needed: int = gate_level * GATE_OPEN_SCORE_PER_LEVEL
	if score >= needed and not gate_open:
		gate_open = true
		gate_flash = 1.0
		if audio_manager:
			audio_manager.play_gate_open()
	if gate_flash > 0.0:
		gate_flash = max(0.0, gate_flash - delta * 2.5)

	# Check boost state
	_check_boost(delta)

	# Game tick
	var effective_speed: float = game_speed
	if boosted:
		effective_speed = game_speed * BOOST_MULTIPLIER
	# Magma fruit: double speed (halve the interval)
	if magma_fruit_active:
		effective_speed /= MAGMA_FRUIT_SPEED_DIVISOR
	if not segments.is_empty():
		if _get_terrain(segments[0].x, segments[0].y) == Terrain.RIVER:
			effective_speed *= (1.0 + RIVER_SPEED_PENALTY)
			# Extinguish burning when entering water
			if is_burning:
				is_burning = false
				burning_timer = 0.0
				burning_damage_timer = 0.0
				_spawn_floating_text(Loc.t("float_extinguish"), segments[0], Color(0.3, 0.6, 1.0), 14)

	display_speed = effective_speed
	speed_timer += delta
	if speed_timer >= effective_speed:
		speed_timer = 0.0
		_game_tick()
	queue_redraw()

# =========================================================
# Particles
# =========================================================

func _update_particles(delta: float) -> void:
	for i in range(OPTIMIZED_MAX_PARTICLES):
		var p: Dictionary = _particle_pool[i]
		
		if not p["active"]:
			continue
		
		p["life"] -= delta
		
		if p["life"] <= 0.0:
			p["active"] = false
			_particle_active_count -= 1
			continue
		
		p["pos"] += p["velocity"] * delta
		p["velocity"] *= 0.96
		p["velocity"].y += 120.0 * delta

func _spawn_particles(grid_pos: Vector2i, color: Color, count: int = 12, spread: float = 80.0) -> void:
	var center: Vector2 = Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	)
	
	var spawned: int = 0
	for i in range(OPTIMIZED_MAX_PARTICLES):
		if spawned >= count:
			break
		
		var p: Dictionary = _particle_pool[i]
		if not p["active"]:
			var angle: float = randf() * TAU
			var speed: float = randf_range(30.0, spread)
			
			p["pos"] = center
			p["velocity"] = Vector2(cos(angle), sin(angle)) * speed
			p["life"] = randf_range(0.3, 0.8)
			p["max_life"] = p["life"]
			
			var p_color: Color = color
			p_color.h += randf_range(-0.05, 0.05)
			p_color.s += randf_range(-0.1, 0.1)
			p["color"] = p_color
			
			p["size"] = randf_range(2.0, 5.0)
			p["active"] = true
			
			spawned += 1
			_particle_active_count += 1
		var life: float = randf_range(0.3, 0.8)
		var size: float = randf_range(2.0, 5.0)
		var p_color: Color = color
		p_color.h += randf_range(-0.05, 0.05)
		p_color.s += randf_range(-0.1, 0.1)
		particles.append({
			"pos": center, "velocity": Vector2(cos(randf() * TAU), sin(randf() * TAU)) * randf_range(30.0, 80.0),
			"life": life, "max_life": life,
			"color": p_color, "size": size,
		})

func _draw_particles() -> void:
	for i in range(OPTIMIZED_MAX_PARTICLES):
		var p: Dictionary = _particle_pool[i]
		
		if not p["active"]:
			continue
		
		var alpha: float = p["life"] / p["max_life"]
		var color: Color = p["color"]
		color.a = alpha
		var size: float = p["size"] * alpha
		
		draw_circle(p["pos"], size, color)

# =========================================================
# Floating Texts
# =========================================================

func _update_floating_texts(delta: float) -> void:
	for i in range(OPTIMIZED_MAX_FLOATING_TEXTS):
		var ft: Dictionary = _floating_text_pool[i]
		
		if not ft["active"]:
			continue
		
		ft["life"] -= delta
		ft["pos"].y -= 40.0 * delta
		
		if ft["life"] <= 0.0:
			ft["active"] = false
			_floating_text_active_count -= 1

func _spawn_floating_text(text: String, grid_pos: Vector2i, color: Color, size: int = 16) -> void:
	var pos: Vector2 = Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	)
	
	for i in range(OPTIMIZED_MAX_FLOATING_TEXTS):
		var ft: Dictionary = _floating_text_pool[i]
		
		if not ft["active"]:
			ft["text"] = text
			ft["pos"] = pos
			ft["life"] = 1.0
			ft["color"] = color
			ft["size"] = size
			ft["active"] = true
			_floating_text_active_count += 1
			return

func _draw_floating_texts() -> void:
	var font = ThemeDB.fallback_font
	
	for i in range(OPTIMIZED_MAX_FLOATING_TEXTS):
		var ft: Dictionary = _floating_text_pool[i]
		
		if not ft["active"]:
			continue
		
		var alpha: float = ft["life"]
		var color: Color = ft["color"]
		color.a = alpha
		var text: String = ft["text"]
		var size: int = ft["size"]
		
		var ss: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
		var x: float = ft["pos"].x - ss.x / 2.0
		var y: float = ft["pos"].y - ss.y / 2.0
		
		draw_string(font, Vector2(x + 1, y + 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, alpha * 0.5))
		draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

# =========================================================
# Grid Distance (Chebyshev)
# =========================================================

func grid_distance(a: Vector2i, b: Vector2i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y))

# =========================================================
# Snake shorten (from bomb)
# =========================================================

func _shrink_snake(amount: int) -> void:
	var remove_count: int = mini(amount, segments.size() - 1)
	for _i in range(remove_count):
		var removed: Vector2i = segments.pop_back()
		_spawn_particles(removed, Color(1.0, 0.4, 0.2), 3, 50.0)

# =========================================================
# Game Tick
# =========================================================

func _game_tick() -> void:
	direction = next_direction
	var head: Vector2i = segments[0]
	var new_head: Vector2i = Vector2i(head.x + direction.x, head.y + direction.y)

	var hit_wall: bool = (new_head.x < 0 or new_head.x >= GRID_WIDTH
		or new_head.y < 0 or new_head.y >= GRID_HEIGHT)
	if hit_wall:
		if wall_pass_active:
			new_head.x = posmod(new_head.x, GRID_WIDTH)
			new_head.y = posmod(new_head.y, GRID_HEIGHT)
		elif wall_stop_active:
			if audio_manager:
				audio_manager.play_wall_hit(true)
			return
		else:
			death_reason = "wall"
			_end_game()
			return

	# Mountain collision - always fatal
	if _get_terrain(new_head.x, new_head.y) == Terrain.MOUNTAIN:
		death_reason = "mountain"
		_end_game()
		return
	
	# Check if on magma (for damage over time)
	is_on_magma = (_get_terrain(new_head.x, new_head.y) == Terrain.MAGMA)

	if not ghost_active:
		for i in range(segments.size()):
			if segments[i] == new_head:
				death_reason = "self"
				_end_game()
				return

	# Wormhole teleportation
	if not wormhole_cooldown:
		for wh in wormholes:
			if wh.pos == new_head:
				var paired_pos: Vector2i = _get_paired_wormhole_pos(wh.pair_id, wh.pos)
				_spawn_particles(new_head, wh.palette[0], 15, 100.0)
				_spawn_particles(paired_pos, wh.palette[0], 15, 100.0)
				_spawn_floating_text(Loc.t("float_wormhole"), new_head, wh.palette[1], 14)
				new_head = paired_pos
				wormhole_cooldown = true
				if audio_manager:
					audio_manager.play_wormhole()
				break
	else:
		wormhole_cooldown = false

	# Gate collision
	if new_head == gate_pos and gate_open:
		_enter_next_level()
		return

	# Re-check self-collision after teleport
	if not ghost_active:
		for i in range(segments.size()):
			if segments[i] == new_head:
				death_reason = "self"
				_end_game()
				return

	segments.insert(0, new_head)
	var ate: bool = false

	if new_head == main_food_pos:
		if trap_active:
			score -= TRAP_PENALTY
			screen_shake = 1.0
			combo = 0
			ate = true
			trap_active = false
			trap_revealed = false
			trap_countdown = 0.0
			_spawn_particles(new_head, Color(1.0, 0.3, 0.1), 20, 120.0)
			_spawn_floating_text("-%d" % TRAP_PENALTY, new_head, Color(1.0, 0.3, 0.2), 20)
			_spawn_floating_text(Loc.t("float_seg") % TRAP_SHRINK_SEGMENTS, new_head, Color(1.0, 0.6, 0.3), 14)
			if audio_manager:
				audio_manager.play_bomb_explode()
			_shrink_snake(TRAP_SHRINK_SEGMENTS)
			if segments.size() <= 1:
				death_reason = "bomb"
				_end_game()
				return
			_spawn_main_food()
		else:
			_eat_food(new_head)
			ate = true
			_spawn_main_food()

	if not ate:
		for idx in range(extra_foods.size() - 1, -1, -1):
			if extra_foods[idx].pos == new_head:
				_eat_food(new_head)
				extra_foods.remove_at(idx)
				ate = true
				break

	if special_active and new_head == special_pos:
		_eat_special_fruit(new_head)
		ate = true


	if not ate:
		segments.pop_back()

	if boosted and not segments.is_empty():
		if randf() < 0.4:
			var tail: Vector2i = segments[segments.size() - 1]
			_spawn_particles(tail, boost_color, 2, 40.0)

# =========================================================
# Eating Food
# =========================================================

func _eat_food(pos: Vector2i) -> void:
	combo += 1
	combo_timer = 8.0
	var bonus: int = 10
	if combo >= 3:
		bonus += combo * 2
	
	# Magma fruit: double score
	if magma_fruit_active:
		bonus *= MAGMA_FRUIT_SCORE_MULTIPLIER
	
	total_food_eaten += 1
	score += bonus

	eating_anim_timer = 0.3
	_spawn_particles(pos, Color(1.0, 0.5, 0.3), 10, 80.0)
	var text_color: Color = Color(1.0, 1.0, 0.5) if bonus > 10 else Color(1.0, 1.0, 1.0)
	_spawn_floating_text("+%d" % bonus, pos, text_color, 16 if bonus <= 10 else 20)

	if audio_manager:
		audio_manager.play_eat_fruit()

# =========================================================
# Eating Special Fruit
# =========================================================

func _eat_special_fruit(pos: Vector2i) -> void:
	var bonus: int = SPECIAL_FOOD_SCORE + combo * 5
	score += bonus
	combo += 1
	combo_timer = 8.0

	eating_anim_timer = 0.3
	_spawn_particles(pos, Color(1.0, 0.85, 0.2), 25, 150.0)
	_spawn_floating_text("+%d" % bonus, pos, Color(1.0, 0.85, 0.2), 22)

	if audio_manager:
		audio_manager.play_eat_fruit()  # 播放吃果实音效

	match special_type:
		SpecialType.GHOST:
			ghost_active = true
			ghost_timer = GHOST_DURATION
			_spawn_floating_text(Loc.t("float_ghost"), pos, Color(0.7, 0.4, 1.0), 20)
		SpecialType.WALL_STOP:
			wall_stop_active = true
			wall_stop_timer = WALL_STOP_DURATION
			_spawn_floating_text(Loc.t("float_shield"), pos, Color(1.0, 0.85, 0.2), 20)
		SpecialType.FOOD_RAIN:
			_spawn_food_rain()
			_spawn_floating_text(Loc.t("float_rain"), pos, Color(1.0, 0.8, 0.2), 20)
		SpecialType.WALL_PASS:
			wall_pass_active = true
			wall_pass_timer = WALL_PASS_DURATION
			_spawn_floating_text(Loc.t("float_wallpass"), pos, Color(0.7, 0.3, 1.0), 20)
		SpecialType.SPEED_UP:
			game_speed += SPEED_UP_AMOUNT
			_spawn_floating_text(Loc.t("float_speedup"), pos, Color(1.0, 0.5, 0.1), 20)
		SpecialType.SPEED_DOWN:
			game_speed -= SPEED_DOWN_AMOUNT
			_spawn_floating_text(Loc.t("float_speeddown"), pos, Color(0.3, 0.6, 1.0), 20)
			if game_speed <= SPEED_DEATH_THRESHOLD:
				death_reason = "frozen"
				_end_game()
				special_active = false
				special_timer = 0.0
				return
		SpecialType.MAGMA_FRUIT:
			magma_fruit_active = true
			magma_fruit_timer = MAGMA_FRUIT_DURATION
			_spawn_floating_text(Loc.t("float_magma"), pos, Color(0.9, 0.25, 0.05), 22)

	special_active = false
	special_timer = 0.0



# =========================================================
# Food Spawning
# =========================================================

func _get_all_occupied() -> Array[Vector2i]:
	var occupied: Array[Vector2i] = segments.duplicate()
	occupied.append(main_food_pos)
	for f in extra_foods:
		occupied.append(f.pos)
	if special_active:
		occupied.append(special_pos)
	for wh in wormholes:
		occupied.append(wh.pos)
	if gate_pos.x >= 0:
		occupied.append(gate_pos)
	return occupied

func _get_available_cells() -> Array[Vector2i]:
	var occupied: Array[Vector2i] = _get_all_occupied()
	var available: Array[Vector2i] = []
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var cell = Vector2i(x, y)
			if not cell in occupied:
				# Exclude mountain, volcano and magma terrain
				var terrain: int = _get_terrain(x, y)
				if terrain != Terrain.MOUNTAIN and terrain != Terrain.VOLCANO and terrain != Terrain.MAGMA:
					available.append(cell)
	return available

func _spawn_main_food() -> void:
	var available: Array[Vector2i] = _get_available_cells()
	if available.is_empty():
		return
	main_food_pos = available[randi() % available.size()]
	food_spawn_time = food_time
	if randf() < SPECIAL_SPAWN_CHANCE and not special_active:
		_try_spawn_special()
	if randf() < TRAP_SPAWN_CHANCE and not trap_active:
		trap_active = true
		trap_revealed = false
		trap_countdown = 0.0

func _try_spawn_special() -> void:
	# First determine the special type
	special_type = randi() % SPECIAL_TYPE_COUNT
	
	# Magma fruit only spawns on magma terrain
	if special_type == SpecialType.MAGMA_FRUIT:
		var magma_cells: Array[Vector2i] = []
		for y in range(GRID_HEIGHT):
			for x in range(GRID_WIDTH):
				if tiles[y][x] == Terrain.MAGMA:
					magma_cells.append(Vector2i(x, y))
		
		if magma_cells.is_empty():
			# No magma available, try another special type
			special_type = randi() % (SPECIAL_TYPE_COUNT - 1)  # Exclude MAGMA_FRUIT
		else:
			special_pos = magma_cells[randi() % magma_cells.size()]
			special_active = true
			special_timer = SPECIAL_FOOD_DURATION
			if audio_manager:
				audio_manager.play_special_appear()
			return
	
	# For other special types, use normal available cells
	var available: Array[Vector2i] = _get_available_cells()
	if available.is_empty():
		return
	special_pos = available[randi() % available.size()]
	special_active = true
	special_timer = SPECIAL_FOOD_DURATION
	if audio_manager:
		audio_manager.play_special_appear()  # 播放特殊果实出现音效

# =========================================================
# Food Rain
# =========================================================

func _spawn_food_rain() -> void:
	var count: int = randi_range(FOOD_RAIN_MIN, FOOD_RAIN_MAX)
	for _i in range(count):
		var available: Array[Vector2i] = _get_available_cells()
		if available.is_empty():
			break
		var pos: Vector2i = available[randi() % available.size()]
		extra_foods.append({"pos": pos, "spawn_time": food_time})

# =========================================================
# Game Over / Restart
# =========================================================

func _end_game() -> void:
	total_score += score
	game_over = true
	screen_shake = 2.0
	if not segments.is_empty():
		for seg in segments:
			_spawn_particles(seg, Color(1.0, 0.3, 0.2), 5, 100.0)
	if total_score > high_score:
		high_score = total_score
		_save_high_score()
	if audio_manager:
		match death_reason:
			"wall":
				audio_manager.play_wall_hit(false)
			"bomb":
				audio_manager.play_bomb_explode()
		audio_manager.play_game_over()
		audio_manager.set_music_volume(0.15)
	boosted = false
	boost_glow = 0.0
	boost_hold_timer = 0.0
	boost_hold_dir = Vector2i(0, 0)

func _unhandled_input(event: InputEvent) -> void:
	# Language button click (works in all states)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _lang_btn_rect.has_point(event.position):
			Loc.switch_language()
			return

	# Menu input takes priority
	if in_menu:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_click_menu_items(event.position)
			return
		_handle_menu_input(event)
		return

	# Pause state: handle pause menu navigation
	if paused and not game_over:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_click_pause_items(event.position)
			return
		_handle_pause_input(event)
		return

	# Game Over → Space to restart / Mouse click buttons
	if game_over:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_click_gameover_buttons(event.position)
			return
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_SPACE:
				score = 0
				total_score = 0
				gate_level = 1
				game_speed = 0.3
				speed_timer = 0.0
				game_over = false
				game_started = true
				paused = false
				pause_selected = 0
				_reset_game()
				_spawn_main_food()
				if audio_manager:
					audio_manager.set_music_volume(0.6)
			elif event.keycode == KEY_ESCAPE:
				_return_to_menu()
		return

	# Pause toggle (ESC to open pause)
	if not game_over and game_started and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		paused = true
		pause_selected = 0
		return

	# Direction input
	if event is InputEventKey and event.pressed:
		if (event.is_action_pressed("move_up") or event.keycode == KEY_UP) and direction.y != 1:
			next_direction = Vector2i(0, -1)
		elif (event.is_action_pressed("move_down") or event.keycode == KEY_DOWN) and direction.y != -1:
			next_direction = Vector2i(0, 1)
		elif (event.is_action_pressed("move_left") or event.keycode == KEY_LEFT) and direction.x != 1:
			next_direction = Vector2i(-1, 0)
		elif (event.is_action_pressed("move_right") or event.keycode == KEY_RIGHT) and direction.x != -1:
			next_direction = Vector2i(1, 0)

# =========================================================
# Drawing - Master
# =========================================================

func _draw() -> void:
	var vp_size: float = GRID_WIDTH * CELL_SIZE + DRAW_MARGIN * 2
	draw_rect(Rect2(0, 0, vp_size, vp_size), bg_color)

	# ---- Menu mode ----
	if in_menu:
		draw_set_transform(Vector2(DRAW_MARGIN, DRAW_MARGIN), 0.0, Vector2.ONE)
		_draw_menu_bg()
		_draw_menu_screen()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_language_button()
		return

	# ---- Game mode ----
	var shake_offset: Vector2 = Vector2.ZERO
	if screen_shake > 0.0:
		shake_offset = Vector2(
			randf_range(-1, 1) * screen_shake * 4.0,
			randf_range(-1, 1) * screen_shake * 4.0
		)
	draw_set_transform(shake_offset + Vector2(DRAW_MARGIN, DRAW_MARGIN), 0.0, Vector2.ONE)
	_draw_background()
	_draw_wormholes()
	_draw_gate()
	if trap_active:
		_draw_trap()
	else:
		var mf_age: float = food_time - food_spawn_time
		var mf_blink: bool = mf_age > (FOOD_LIFETIME - FOOD_WARN_THRESHOLD)
		_draw_food(main_food_pos, mf_blink)
	for ef in extra_foods:
		var ef_age: float = food_time - ef.spawn_time
		var ef_blink: bool = ef_age > (FOOD_LIFETIME - FOOD_WARN_THRESHOLD)
		_draw_food(ef.pos, ef_blink)
	if special_active:
		_draw_special_food()
	_draw_snake()
	_draw_particles()
	_draw_floating_texts()
	_draw_boost_indicator()
	_draw_ui()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
# =========================================================
# Drawing - Language Toggle Button (inside border)
# =========================================================

func _draw_language_button() -> void:
	var grid_w: float = float(GRID_WIDTH * CELL_SIZE)
	var grid_h: float = float(GRID_HEIGHT * CELL_SIZE)
	var btn_w: float = 64.0
	var btn_h: float = 28.0
	var btn_x: float = DRAW_MARGIN + grid_w - btn_w - 6.0
	var btn_y: float = DRAW_MARGIN + grid_h - btn_h - 6.0
	var font = ThemeDB.fallback_font

	_lang_btn_rect = Rect2(btn_x, btn_y, btn_w, btn_h)

	var pill_rect: Rect2 = Rect2(btn_x, btn_y, btn_w, btn_h)
	_draw_rounded_rect(pill_rect, Color(0.12, 0.14, 0.2, 0.88), 14)
	_draw_rounded_rect(pill_rect, Color(0.4, 0.45, 0.55, 0.55), 14, false, 1.5)

	# Globe icon (simple circle with lines)
	var icon_cx: float = btn_x + 14.0
	var icon_cy: float = btn_y + btn_h / 2.0
	var icon_r: float = 6.0
	draw_circle(Vector2(icon_cx, icon_cy), icon_r, Color(0.5, 0.7, 0.9, 0.7), false, 1.2)
	draw_arc(Vector2(icon_cx, icon_cy), icon_r * 0.6, -PI * 0.45, PI * 0.45, 1.0, Color(0.5, 0.7, 0.9, 0.5))
	draw_line(Vector2(icon_cx - icon_r, icon_cy), Vector2(icon_cx + icon_r, icon_cy), Color(0.5, 0.7, 0.9, 0.4), 1.0)
	draw_line(Vector2(icon_cx, icon_cy - icon_r), Vector2(icon_cx, icon_cy + icon_r), Color(0.5, 0.7, 0.9, 0.4), 1.0)

	# Language label: bold+black active / gray inactive, separated by slash
	var text_start_x: float = icon_cx + icon_r + 6.0
	var available_w: float = btn_x + btn_w - 4.0 - text_start_x
	var center_y: float = btn_y + btn_h / 2.0
	var normal_sz: int = 11
	var bold_sz: int = 12
	var bold_color := Color(0.1, 0.1, 0.1, 1.0)
	var gray_color := Color(0.55, 0.58, 0.65, 0.75)
	var slash_color := Color(0.4, 0.43, 0.5, 0.55)

	var text_a: String; var text_b: String; var text_c: String
	var a_bold: bool; var c_bold: bool
	var a_color: Color; var c_color: Color

	if Loc.current_language == "en":
		text_a = "CN"; text_b = "/"; text_c = "EN"
		a_bold = false; c_bold = true
		a_color = gray_color; c_color = bold_color
	else:
		text_a = "\u4e2d"; text_b = "/"; text_c = "\u82f1"
		a_bold = true; c_bold = false
		a_color = bold_color; c_color = gray_color

	var sz_a: int = bold_sz if a_bold else normal_sz
	var sz_b: int = normal_sz
	var sz_c: int = bold_sz if c_bold else normal_sz
	var size_a: Vector2 = font.get_string_size(text_a, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_a)
	var size_b: Vector2 = font.get_string_size(text_b, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_b)
	var size_c: Vector2 = font.get_string_size(text_c, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_c)
	var total_w: float = size_a.x + size_b.x + size_c.x
	var draw_x: float = text_start_x + (available_w - total_w) / 2.0

	# Part A
	var base_a: float = center_y + (font.get_ascent(sz_a) - font.get_descent(sz_a)) / 2.0
	if a_bold:
		draw_string(font, Vector2(draw_x + 0.8, base_a), text_a, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_a, Color(0.15, 0.15, 0.15, 0.6))
	draw_string(font, Vector2(draw_x, base_a), text_a, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_a, a_color)
	draw_x += size_a.x

	# Part B (slash)
	var base_b: float = center_y + (font.get_ascent(sz_b) - font.get_descent(sz_b)) / 2.0
	draw_string(font, Vector2(draw_x, base_b), text_b, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_b, slash_color)
	draw_x += size_b.x

	# Part C
	var base_c: float = center_y + (font.get_ascent(sz_c) - font.get_descent(sz_c)) / 2.0
	if c_bold:
		draw_string(font, Vector2(draw_x + 0.8, base_c), text_c, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_c, Color(0.15, 0.15, 0.15, 0.6))
	draw_string(font, Vector2(draw_x, base_c), text_c, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_c, c_color)

# =========================================================
# Drawing - Menu Background
# =========================================================

func _draw_menu_bg() -> void:
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var H: float = float(GRID_HEIGHT * CELL_SIZE)

	draw_rect(Rect2(0, 0, W, H), bg_color)

	# Subtle grid
	var grid_c: Color = Color(0.1, 0.13, 0.2, 0.1)
	for x in range(GRID_WIDTH + 1):
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, H), grid_c, 0.5)
	for y in range(GRID_HEIGHT + 1):
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(W, y * CELL_SIZE), grid_c, 0.5)

	# Center radial glow
	draw_circle(Vector2(W / 2.0, H / 2.0), 300.0, Color(0.08, 0.18, 0.12, 0.12))
	draw_circle(Vector2(W / 2.0, H / 2.0), 180.0, Color(0.08, 0.18, 0.12, 0.06))

	# Floating particles
	for p in menu_particles:
		var a: float = p["alpha"] * (0.4 + 0.6 * abs(sin(menu_anim * 1.2 + p["phase"])))
		var c: Color = Color(p["color"])
		c.a = a
		draw_circle(Vector2(p["x"], p["y"]), p["size"], c)

	# Border
	draw_rect(Rect2(0, 0, W, H), border_color, false, 2.0)

# =========================================================
# Drawing - Menu Screen Router
# =========================================================

func _draw_menu_screen() -> void:
	match current_menu_screen:
		MenuScreen.MAIN:
			_draw_main_menu()
		MenuScreen.HELP:
			_draw_help_screen()
		MenuScreen.HIGH_SCORE:
			_draw_highscore_screen()

# =========================================================
# Drawing - Main Menu
# =========================================================

func _draw_main_menu() -> void:
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var H: float = float(GRID_HEIGHT * CELL_SIZE)
	var font = ThemeDB.fallback_font
	var menu_names: PackedStringArray = _get_menu_names()

	# ---- Title ----
	var title_text: String = Loc.t("menu_title")
	var title_size: int = 62
	var tp: Vector2 = _centered_pos(title_text, 130.0, title_size, font)

	# Title glow (soft multi-offset)
	var glow_c: Color = Color(0.2, 1.0, 0.5, 0.1)
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if dx * dx + dy * dy <= 5:
				draw_string(font, tp + Vector2(dx, dy), title_text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, glow_c)
	# Title main
	draw_string(font, tp, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size,
		Color(0.2, 1.0, 0.5, 1.0))

	# Decorative line under title
	var line_y: float = 178.0
	var line_hw: float = 100.0
	draw_line(Vector2(W / 2.0 - line_hw, line_y), Vector2(W / 2.0 + line_hw, line_y),
		Color(0.2, 0.9, 0.4, 0.3), 1.5)
	# Small diamond at center of line
	var dc: float = 3.0
	var ddx: float = W / 2.0
	draw_line(Vector2(ddx - dc, line_y), Vector2(ddx, line_y - dc), Color(0.2, 0.9, 0.4, 0.5), 1.5)
	draw_line(Vector2(ddx, line_y - dc), Vector2(ddx + dc, line_y), Color(0.2, 0.9, 0.4, 0.5), 1.5)
	draw_line(Vector2(ddx + dc, line_y), Vector2(ddx, line_y + dc), Color(0.2, 0.9, 0.4, 0.5), 1.5)
	draw_line(Vector2(ddx, line_y + dc), Vector2(ddx - dc, line_y), Color(0.2, 0.9, 0.4, 0.5), 1.5)

	# Tagline
	_draw_centered_text(Loc.t("menu_tagline"), 205.0, 14, Color(0.35, 0.38, 0.45, 0.75))

	# ---- Menu Items ----
	_menu_item_rects.clear()
	for i in range(menu_names.size()):
		var item_y: float = MENU_START_Y + float(i) * MENU_SPACING
		var pill_x: float = (W - MENU_ITEM_W) / 2.0
		var pill_y: float = item_y - MENU_ITEM_H / 2.0
		_menu_item_rects.append(Rect2(pill_x, pill_y, MENU_ITEM_W, MENU_ITEM_H))
		var hovered: bool = _menu_item_rects[i].has_point(get_global_mouse_position() - Vector2(DRAW_MARGIN, DRAW_MARGIN))
		if hovered:
			menu_selected = i
		_draw_menu_item(menu_names[i], MENU_ICONS[i], W, item_y, i == menu_selected, font)

	# ---- Footer ----
	var footer_y: float = 660.0
	_draw_centered_text(Loc.t("menu_navigate"), footer_y, 13,
		Color(0.3, 0.33, 0.38, 0.6))

	# Version
	_draw_centered_text(Loc.t("menu_version"), 770.0, 11,
		Color(0.2, 0.22, 0.28, 0.4))

# =========================================================
# Drawing - Menu Item
# =========================================================

func _draw_menu_item(text: String, icon: String, canvas_w: float, center_y: float,
		selected: bool, font: Font) -> void:
	var pill_x: float = (canvas_w - MENU_ITEM_W) / 2.0
	var pill_y: float = center_y - MENU_ITEM_H / 2.0
	var pill_rect: Rect2 = Rect2(pill_x, pill_y, MENU_ITEM_W, MENU_ITEM_H)

	if selected:
		var pulse: float = 0.6 + 0.4 * sin(menu_anim * 4.0)

		# Outer glow
		draw_rect(pill_rect.grow(10), Color(0.1, 0.45, 0.2, 0.06 * pulse))

		# Pill fill
		_draw_rounded_rect(pill_rect, Color(0.05, 0.16, 0.08, 0.75), 14)

		# Pill border (pulsing)
		var ba: float = 0.55 + 0.35 * pulse
		_draw_rounded_rect(pill_rect, Color(0.2, 0.95, 0.4, ba), 14, false, 2.0)

		# Left indicator dot
		var dot_x: float = pill_x + 20.0
		draw_circle(Vector2(dot_x, center_y), 4.0, Color(0.2, 1.0, 0.5, 0.85))
		draw_circle(Vector2(dot_x, center_y), 9.0, Color(0.2, 1.0, 0.5, 0.15 * pulse))

		# Text shadow + text
		var tx: float = pill_x + 40.0
		var ty: float = center_y + 7.0
		draw_string(font, Vector2(tx + 1, ty + 1), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0, 0.35))
		draw_string(font, Vector2(tx, ty), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 1.0, 1.0, 1.0))
	else:
		# Pill fill
		_draw_rounded_rect(pill_rect, Color(0.08, 0.1, 0.14, 0.45), 14)

		# Pill border
		_draw_rounded_rect(pill_rect, Color(0.22, 0.25, 0.32, 0.25), 14, false, 1.0)

		# Text (dim)
		var tx: float = pill_x + 40.0
		var ty: float = center_y + 6.0
		draw_string(font, Vector2(tx, ty), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.5, 0.53, 0.58, 0.7))

# =========================================================
# Drawing - Help Screen
# =========================================================

func _draw_help_screen() -> void:
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var font = ThemeDB.fallback_font
	var lx: float = 70.0
	var rx: float = 400.0
	var y: float = 35.0

	# Title
	_draw_centered_text(Loc.t("help_title"), y, 34, Color(0.2, 1.0, 0.5, 1.0))

	# Decorative line
	var line_y: float = 68.0
	draw_line(Vector2(60, line_y), Vector2(W - 60, line_y), Color(0.2, 0.9, 0.4, 0.2), 1.0)

	# ---- CONTROLS ----
	y = 100.0
	_draw_section_header(Loc.t("help_controls"), lx, y, font)
	y += 30.0
	_draw_kv_line(Loc.t("help_key_move"), Loc.t("help_val_move"), lx, rx, y, font); y += 24.0
	_draw_kv_line(Loc.t("help_key_boost"), Loc.t("help_val_boost"), lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(1.0, 0.6, 0.1)); y += 24.0
	_draw_kv_line(Loc.t("help_key_pause"), Loc.t("help_val_pause"), lx, rx, y, font); y += 24.0
	_draw_kv_line(Loc.t("help_key_restart"), Loc.t("help_val_restart"), lx, rx, y, font); y += 24.0
	_draw_kv_line(Loc.t("help_key_mobile"), Loc.t("mobile_swipe"), lx, rx, y, font); y += 42.0

	# ---- TIMED FRUITS ----
	_draw_section_header(Loc.t("help_timed_fruits"), lx, y, font)
	y += 30.0
	_draw_kv_line(Loc.t("help_ghost_key"), Loc.t("help_ghost_val") % GHOST_DURATION, lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(0.7, 0.4, 1.0)); y += 24.0
	_draw_kv_line(Loc.t("help_shield_key"), Loc.t("help_shield_val") % WALL_STOP_DURATION, lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(1.0, 0.85, 0.15)); y += 24.0
	_draw_kv_line(Loc.t("help_rain_key"), Loc.t("help_rain_val"), lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(1.0, 0.75, 0.1)); y += 24.0
	_draw_kv_line(Loc.t("help_pass_key"), Loc.t("help_pass_val") % WALL_PASS_DURATION, lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(0.7, 0.3, 1.0)); y += 42.0

	# ---- INSTANT FRUITS ----
	_draw_section_header(Loc.t("help_instant_fruits"), lx, y, font)
	y += 30.0
	_draw_kv_line(Loc.t("help_speedup_key"), Loc.t("help_speedup_val") % SPEED_UP_AMOUNT, lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(1.0, 0.5, 0.1)); y += 24.0
	_draw_kv_line(Loc.t("help_speeddown_key"), Loc.t("help_speeddown_val"), lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(0.3, 0.6, 1.0)); y += 42.0

	# ---- DANGER ----
	_draw_section_header(Loc.t("help_danger"), lx, y, font, Color(0.9, 0.35, 0.25))
	y += 30.0
	_draw_kv_line(Loc.t("help_bomb_key"), Loc.t("help_bomb_val") % TRAP_PENALTY, lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(1.0, 0.45, 0.3)); y += 24.0
	_draw_kv_line(Loc.t("help_reveal_key"), Loc.t("help_reveal_val"), lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(1.0, 0.45, 0.3)); y += 24.0
	_draw_kv_line(Loc.t("help_fullshrink_key"), Loc.t("help_fullshrink_val"), lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(1.0, 0.45, 0.3)); y += 42.0

	# ---- WORMHOLE ----
	_draw_section_header(Loc.t("help_wormhole"), lx, y, font, Color(0.85, 0.45, 0.7))
	y += 30.0
	_draw_kv_line(Loc.t("help_wormhole"), Loc.t("help_wormhole_val"), lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(0.85, 0.45, 0.7)); y += 42.0

	# ---- SCORING ----
	_draw_section_header(Loc.t("help_scoring"), lx, y, font)
	y += 30.0
	_draw_kv_line(Loc.t("help_normal_food_key"), Loc.t("help_normal_food_val"), lx, rx, y, font); y += 24.0
	_draw_kv_line(Loc.t("help_special_food_key"), Loc.t("help_special_food_val") % SPECIAL_FOOD_SCORE, lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(1.0, 0.85, 0.2)); y += 24.0
	_draw_kv_line(Loc.t("help_combo_key"), Loc.t("help_combo_val"), lx, rx, y, font,
		Color(0.3, 0.3, 0.35), Color(1.0, 0.85, 0.2)); y += 24.0


	# Footer
	var blink: float = 0.5 + 0.4 * sin(menu_anim * 2.5)
	_draw_centered_text(Loc.t("help_back"), 760.0, 14,
		Color(0.4, 0.43, 0.5, blink))

# =========================================================
# Drawing - High Score Screen
# =========================================================

func _draw_highscore_screen() -> void:
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var H: float = float(GRID_HEIGHT * CELL_SIZE)
	var font = ThemeDB.fallback_font

	# Title
	_draw_centered_text(Loc.t("hs_title"), 180.0, 36, Color(1.0, 0.85, 0.0, 1.0))

	# Decorative line
	draw_line(Vector2(W / 2.0 - 110, 215), Vector2(W / 2.0 + 110, 215),
		Color(1.0, 0.85, 0.0, 0.25), 1.5)

	# Trophy icon (simple star shape)
	var cx: float = W / 2.0
	var cy: float = 280.0
	_draw_star(cx, cy, 30.0, 14.0, 5,
		Color(1.0, 0.85, 0.0, 0.12 + 0.06 * sin(menu_anim * 2.0)))
	_draw_star(cx, cy, 24.0, 10.0, 5,
		Color(1.0, 0.85, 0.0, 0.2 + 0.1 * sin(menu_anim * 2.0)))

	# "BEST" label
	_draw_centered_text(Loc.t("hs_best"), 340.0, 16, Color(0.5, 0.55, 0.6, 0.7))

	# Score number (large)
	var score_text: String = str(high_score)
	var sp: Vector2 = _centered_pos(score_text, 390.0, 72, font)
	var score_pulse: float = 0.7 + 0.3 * sin(menu_anim * 2.0)

	# Score glow
	var sg_c: Color = Color(1.0, 0.85, 0.0, 0.07 * score_pulse)
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if dx * dx + dy * dy <= 5:
				draw_string(font, sp + Vector2(dx, dy), score_text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 72, sg_c)
	draw_string(font, sp, score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 72,
		Color(1.0, 0.85, 0.0, 1.0))

	# No score message
	if high_score == 0:
		_draw_centered_text(Loc.t("hs_no_scores"), 475.0, 16,
			Color(0.4, 0.43, 0.5, 0.5))

	# Decorative line below score
	draw_line(Vector2(W / 2.0 - 80, 510), Vector2(W / 2.0 + 80, 510),
		Color(1.0, 0.85, 0.0, 0.12), 1.0)

	# Stats
	if total_food_eaten > 0 or high_score > 0:
		_draw_centered_text(Loc.t("hs_total_food") % total_food_eaten, 545.0, 14,
			Color(0.45, 0.48, 0.55, 0.6))

	# Footer
	var blink: float = 0.5 + 0.4 * sin(menu_anim * 2.5)
	_draw_centered_text(Loc.t("help_back"), 760.0, 14,
		Color(0.4, 0.43, 0.5, blink))

# =========================================================
# Drawing - Menu Helpers
# =========================================================

func _draw_star(cx: float, cy: float, outer_r: float, inner_r: float, points: int, color: Color) -> void:
	var pts: PackedVector2Array = []
	for i in range(points * 2):
		var angle: float = -PI / 2.0 + PI * float(i) / float(points)
		var r: float = outer_r if i % 2 == 0 else inner_r
		pts.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r))
	draw_colored_polygon(pts, color)

func _draw_section_header(title: String, x: float, y: float, font: Font,
		color: Color = Color(0.65, 0.7, 0.78)) -> void:
	draw_string(font, Vector2(x, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	# Underline
	var ss: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	draw_line(Vector2(x, y + 5), Vector2(x + ss.x, y + 5),
		Color(color.r, color.g, color.b, 0.2), 1.0)

func _draw_kv_line(key: String, value: String, lx: float, rx: float, y: float,
		font: Font, key_color: Color = Color(0.3, 0.3, 0.35),
		val_color: Color = Color(0.5, 0.53, 0.58)) -> void:
	draw_string(font, Vector2(lx + 16, y), key,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, key_color)
	draw_string(font, Vector2(rx, y), value,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, val_color)

func _centered_pos(text: String, y: float, size: int, font: Font) -> Vector2:
	var ss: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
	return Vector2((float(GRID_WIDTH * CELL_SIZE) - ss.x) / 2.0, y)

# =========================================================
# Drawing - Background & Borders (Game)
# =========================================================

func _draw_background() -> void:
	_draw_terrain()

	if wall_pass_active:
		_draw_wall_portal()
	elif wall_stop_active:
		draw_rect(Rect2(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE), border_color, false, 2.0)
		_draw_wall_sponge()
	elif magma_fruit_active:
		# Magma fruit screen effect - warm golden glow at edges
		var magma_glow: Color = Color(1.0, 0.4, 0.0, 0.15 + 0.1 * sin(anim_timer * 4.0))
		draw_rect(Rect2(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE), magma_glow, false, 4.0)
	elif ghost_active:
		draw_rect(Rect2(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE), border_color, false, 3.0)
	elif boosted:
		var b_pulse: float = 0.5 + 0.5 * abs(sin(special_blink * 1.0))
		var b_alpha: float = 0.4 + 0.4 * b_pulse * boost_glow
		draw_rect(Rect2(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE),
			Color(boost_color.r, boost_color.g, boost_color.b, b_alpha), false, 3.0)
	else:
		draw_rect(Rect2(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE), border_color, false, 3.0)

# =========================================================
# Drawing - Boost Indicator (corner HUD)
# =========================================================

func _draw_boost_indicator() -> void:
	if boost_hold_timer <= 0.01 and boost_glow <= 0.01:
		return

	var W: float = GRID_WIDTH * CELL_SIZE
	var H: float = GRID_HEIGHT * CELL_SIZE
	var bx: float = W / 2.0
	var by: float = H - 65.0
	var font = ThemeDB.fallback_font

	if not boosted and boost_hold_timer > 0.01:
		var progress: float = clampf(boost_hold_timer / BOOST_HOLD_THRESHOLD, 0.0, 1.0)
		var text: String = Loc.t("boost_charging") % boost_hold_timer
		var ts: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		var pill_w: float = ts.x + 20.0
		var pill_h: float = 22.0
		var pill_x: float = bx - pill_w / 2.0
		var pill_y: float = by - pill_h / 2.0

		_draw_rounded_rect(Rect2(pill_x, pill_y, pill_w, pill_h),
			Color(0.12, 0.08, 0.02, 0.7 * progress), 11)
		_draw_rounded_rect(Rect2(pill_x, pill_y, pill_w, pill_h),
			Color(boost_color.r, boost_color.g, boost_color.b, 0.4 * progress), 11, false, 1.5)
		var bar_margin: float = 3.0
		var bar_h: float = 3.0
		var fill_w: float = (pill_w - bar_margin * 2.0) * progress
		if fill_w > 1.0:
			_draw_rounded_rect(Rect2(pill_x + bar_margin, pill_y + pill_h - bar_margin - bar_h,
				fill_w, bar_h),
				Color(boost_color.r, boost_color.g, boost_color.b, 0.6 * progress), 1.5)
		var txt_alpha: float = 0.5 + 0.3 * progress
		var tx: float = bx - ts.x / 2.0
		var ty: float = by - ts.y / 2.0 + 1
		draw_string(font, Vector2(tx, ty), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
			Color(1.0, 0.7, 0.3, txt_alpha * progress))

	if boost_glow > 0.01:
		var text: String = Loc.t("boost_active")
		var ts: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		var pill_w: float = ts.x + 24.0
		var pill_h: float = 26.0
		var pill_x: float = bx - pill_w / 2.0
		var pill_y: float = by - pill_h / 2.0

		var glow_alpha: float = boost_glow * 0.3 * (0.7 + 0.3 * abs(sin(anim_timer * 6.0)))
		draw_rect(Rect2(pill_x - 4, pill_y - 4, pill_w + 8, pill_h + 8),
			Color(boost_glow_color.r, boost_glow_color.g, boost_glow_color.b, glow_alpha))

		var pill_color: Color = Color(0.15, 0.08, 0.0, 0.85 * boost_glow)
		_draw_rounded_rect(Rect2(pill_x, pill_y, pill_w, pill_h), pill_color, 13)

		var border_pulse: float = 0.6 + 0.4 * abs(sin(anim_timer * 5.0))
		var border_c: Color = Color(boost_color.r, boost_color.g, boost_color.b, border_pulse * boost_glow)
		_draw_rounded_rect(Rect2(pill_x, pill_y, pill_w, pill_h), border_c, 13, false, 1.5)

		var text_alpha: float = 0.6 + 0.4 * abs(sin(anim_timer * 4.0))
		var text_c: Color = Color(1.0, 0.75, 0.2, text_alpha * boost_glow)
		var tx: float = bx - ts.x / 2.0
		var ty: float = by - ts.y / 2.0 + 2
		draw_string(font, Vector2(tx + 1, ty + 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0, 0, 0, 0.5 * boost_glow))
		draw_string(font, Vector2(tx, ty), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, text_c)

# =========================================================
# Drawing - Wall Portal (Wall Pass effect)
# =========================================================

func _draw_wall_portal() -> void:
	var W: float = GRID_WIDTH * CELL_SIZE
	var H: float = GRID_HEIGHT * CELL_SIZE
	var pulse: float = 0.5 + 0.5 * abs(sin(special_blink * 0.35))
	var thickness: float = 6.0

	var glow_alpha: float = pulse * 0.6
	var top_rect: Rect2 = Rect2(0, -thickness, W, thickness)
	var bot_rect: Rect2 = Rect2(0, H, W, thickness)
	var left_rect: Rect2 = Rect2(-thickness, 0, thickness, H)
	var right_rect: Rect2 = Rect2(W, 0, thickness, H)

	var pc: Color = Color(portal_color.r, portal_color.g, portal_color.b, glow_alpha)
	draw_rect(top_rect, pc)
	draw_rect(bot_rect, pc)
	draw_rect(left_rect, pc)
	draw_rect(right_rect, pc)

	var outer_glow: float = thickness + 4.0 + sin(special_blink * 0.5) * 2.0
	var og_color: Color = Color(portal_glow.r, portal_glow.g, portal_glow.b, pulse * 0.15)
	draw_rect(Rect2(-outer_glow, -outer_glow, W + outer_glow * 2, outer_glow), og_color)
	draw_rect(Rect2(-outer_glow, H, W + outer_glow * 2, outer_glow), og_color)
	draw_rect(Rect2(-outer_glow, 0, outer_glow, H), og_color)
	draw_rect(Rect2(W, 0, outer_glow, H), og_color)

	var dot_speed: float = 80.0
	var spacing: float = CELL_SIZE * 0.8
	for side in range(4):
		var offset: float = fmod(anim_timer * dot_speed, spacing)
		var d: float = -spacing + offset
		while true:
			var pos: Vector2
			var max_len: float
			if side == 0:
				pos = Vector2(d, -thickness / 2.0)
				max_len = W
			elif side == 1:
				pos = Vector2(d, H + thickness / 2.0)
				max_len = W
			elif side == 2:
				pos = Vector2(-thickness / 2.0, d)
				max_len = H
			else:
				pos = Vector2(W + thickness / 2.0, d)
				max_len = H
			if (side < 2 and pos.x > max_len) or (side >= 2 and pos.y > max_len):
				break
			var dot_alpha: float = pulse * 0.7 * abs(sin(d * 0.3 + anim_timer * 3.0))
			var dot_r: float = 2.0 + abs(sin(d * 0.5)) * 1.5
			draw_circle(pos, dot_r + 1.5, Color(portal_glow.r, portal_glow.g, portal_glow.b, dot_alpha * 0.3))
			draw_circle(pos, dot_r, Color(1.0, 0.7, 1.0, dot_alpha))
			d += spacing

	for corner in range(4):
		var cx: float
		var cy: float
		match corner:
			0: cx = 0.0; cy = 0.0
			1: cx = W; cy = 0.0
			2: cx = 0.0; cy = H
			3: cx = W; cy = H
		var spiral_r: float = 12.0 + sin(special_blink * 0.4) * 3.0
		var spiral_alpha: float = pulse * 0.4
		draw_circle(Vector2(cx, cy), spiral_r, Color(portal_glow.r, portal_glow.g, portal_glow.b, spiral_alpha))
		for k in range(4):
			var angle: float = anim_timer * 2.0 + corner * 1.5 + k * PI / 2.0
			var dx: float = cos(angle) * spiral_r * 0.6
			var dy: float = sin(angle) * spiral_r * 0.6
			draw_circle(Vector2(cx + dx, cy + dy), 1.5, Color(1.0, 0.8, 1.0, spiral_alpha * 0.8))

# =========================================================
# Drawing - Wall Golden Sponge Shield (Wall Stop effect)
# =========================================================

func _draw_wall_sponge() -> void:
	var W: float = GRID_WIDTH * CELL_SIZE
	var H: float = GRID_HEIGHT * CELL_SIZE
	var thickness: float = 14.0
	var pulse: float = 0.65 + 0.35 * abs(sin(special_blink * 0.4))

	var sc: Color = Color(sponge_color.r, sponge_color.g, sponge_color.b, pulse * 0.95)
	draw_rect(Rect2(-thickness, -thickness, W + thickness * 2, thickness), sc)
	draw_rect(Rect2(-thickness, H, W + thickness * 2, thickness), sc)
	draw_rect(Rect2(-thickness, 0, thickness, H), sc)
	draw_rect(Rect2(W, 0, thickness, H), sc)

	var pore_spacing: float = CELL_SIZE * 0.65
	var pore_idx: int = 0
	for side in range(4):
		var d: float = -pore_spacing
		while true:
			var pos: Vector2
			var max_dist: float
			var perp_len: float
			var is_horiz: bool = (side < 2)
			if side == 0:
				pos = Vector2(d, -thickness / 2.0)
				max_dist = W
				perp_len = thickness
			elif side == 1:
				pos = Vector2(d, H + thickness / 2.0)
				max_dist = W
				perp_len = thickness
			elif side == 2:
				pos = Vector2(-thickness / 2.0, d)
				max_dist = H
				perp_len = thickness
			else:
				pos = Vector2(W + thickness / 2.0, d)
				max_dist = H
				perp_len = thickness
			var check: float = pos.x if is_horiz else pos.y
			if check > max_dist:
				break
			var pore_r: float = 2.0 + sin(pore_idx * 2.3 + anim_timer) * 0.8
			var pore_a: float = pulse * 0.2 * abs(sin(pore_idx * 1.7 + anim_timer * 1.5))
			var offset_px: float = sin(pore_idx * 3.7) * perp_len * 0.25
			var pore_pos: Vector2 = pos
			if is_horiz:
				pore_pos.y += offset_px
			else:
				pore_pos.x += offset_px
			draw_circle(pore_pos, pore_r, Color(sponge_dark.r, sponge_dark.g, sponge_dark.b, pore_a))
			draw_circle(pore_pos, pore_r + 1.0, Color(sponge_highlight.r, sponge_highlight.g, sponge_highlight.b, pore_a * 0.3))
			pore_idx += 1
			d += pore_spacing

	var inner_shadow: float = 4.0
	var ish_color: Color = Color(sponge_dark.r, sponge_dark.g, sponge_dark.b, 0.5)
	draw_rect(Rect2(0, 0, W, inner_shadow), ish_color)
	draw_rect(Rect2(0, H - inner_shadow, W, inner_shadow), ish_color)
	draw_rect(Rect2(0, 0, inner_shadow, H), ish_color)
	draw_rect(Rect2(W - inner_shadow, 0, inner_shadow, H), ish_color)

	draw_rect(Rect2(-thickness, -thickness, W + thickness * 2, thickness), sponge_highlight, false, 2.0)
	draw_rect(Rect2(-thickness, H, W + thickness * 2, thickness), sponge_highlight, false, 2.0)
	draw_rect(Rect2(-thickness, 0, thickness, H), sponge_highlight, false, 2.0)
	draw_rect(Rect2(W, 0, thickness, H), sponge_highlight, false, 2.0)

	draw_rect(Rect2(-thickness - 1.5, -thickness - 1.5, W + thickness * 2 + 3.0, thickness + 3.0), sponge_dark, false, 1.5)

	var spark_speed: float = 60.0
	var spark_spacing: float = CELL_SIZE * 1.2
	for side in range(4):
		var offset: float = fmod(anim_timer * spark_speed, spark_spacing)
		var d: float = -spark_spacing + offset
		var spark_idx: int = 0
		while true:
			var pos: Vector2
			var max_dist: float
			var is_horiz: bool = (side < 2)
			if side == 0:
				pos = Vector2(d, -thickness / 2.0)
				max_dist = W
			elif side == 1:
				pos = Vector2(d, H + thickness / 2.0)
				max_dist = W
			elif side == 2:
				pos = Vector2(-thickness / 2.0, d)
				max_dist = H
			else:
				pos = Vector2(W + thickness / 2.0, d)
				max_dist = H
			var check: float = pos.x if is_horiz else pos.y
			if check > max_dist:
				break
			var spark_alpha: float = pulse * 0.55 * abs(sin(spark_idx * 1.3 + anim_timer * 2.5))
			var spark_r: float = 2.0 + abs(sin(spark_idx * 0.9 + anim_timer * 3.0)) * 1.5
			draw_circle(pos, spark_r + 3.0, Color(sponge_shine_color.r, sponge_shine_color.g, sponge_shine_color.b, spark_alpha * 0.3))
			draw_circle(pos, spark_r, Color(sponge_bubble_color.r, sponge_bubble_color.g, sponge_bubble_color.b, spark_alpha))
			spark_idx += 1
			d += spark_spacing

	for corner in range(4):
		var cx: float
		var cy: float
		match corner:
			0: cx = -thickness / 2.0; cy = -thickness / 2.0
			1: cx = W + thickness / 2.0; cy = -thickness / 2.0
			2: cx = -thickness / 2.0; cy = H + thickness / 2.0
			3: cx = W + thickness / 2.0; cy = H + thickness / 2.0
		var corner_pulse: float = abs(sin(anim_timer * 2.0 + corner * 1.57))
		var corner_r: float = 5.0 + corner_pulse * 3.0
		draw_circle(Vector2(cx, cy), corner_r + 3.0, Color(sponge_shine_color.r, sponge_shine_color.g, sponge_shine_color.b, 0.15 * pulse))
		draw_circle(Vector2(cx, cy), corner_r, Color(sponge_bubble_color.r, sponge_bubble_color.g, sponge_bubble_color.b, 0.3 * pulse * corner_pulse))
		for k in range(3):
			var angle: float = anim_timer * 1.5 + corner * 2.09 + k * TAU / 3.0
			var dx: float = cos(angle) * corner_r * 0.7
			var dy: float = sin(angle) * corner_r * 0.7
			draw_circle(Vector2(cx + dx, cy + dy), 1.2, Color(1.0, 0.98, 0.7, 0.5 * pulse * corner_pulse))

# =========================================================
# Drawing - Normal Food
# =========================================================

func _draw_food(pos: Vector2i, blink: bool = false) -> void:
	if blink:
		var blink_cycle: float = fmod(anim_timer * 8.0, TAU)
		if blink_cycle > PI:
			return
	var center: Vector2 = Vector2(pos.x * CELL_SIZE + CELL_SIZE / 2.0, pos.y * CELL_SIZE + CELL_SIZE / 2.0)
	var pulse: float = 1.0 + sin(food_pulse) * 0.12
	var radius: float = (CELL_SIZE / 2.0 - 4) * pulse
	for i in range(3):
		var gr: float = radius + (3 - i) * 4.0
		var ga: float = 0.05 + i * 0.03
		draw_circle(center, gr, Color(food_glow_color.r, food_glow_color.g, food_glow_color.b, ga))
	draw_circle(center, radius, food_color)
	draw_circle(center + Vector2(-3, -3), radius * 0.3, Color(1.0, 0.7, 0.7, 0.6))

# =========================================================
# Drawing - Trap / Bomb
# =========================================================

func _draw_trap() -> void:
	if trap_revealed:
		var cycle: float = fmod(anim_timer, TRAP_BLINK_INTERVAL * 2.0)
		if cycle < TRAP_BLINK_INTERVAL:
			_draw_food(main_food_pos)
		else:
			_draw_bomb(main_food_pos, trap_countdown)
	else:
		_draw_food(main_food_pos)

func _draw_bomb(pos: Vector2i, countdown_val: float) -> void:
	var center: Vector2 = Vector2(pos.x * CELL_SIZE + CELL_SIZE / 2.0, pos.y * CELL_SIZE + CELL_SIZE / 2.0)
	var pulse: float = 1.0 + sin(anim_timer * 12.0) * 0.08
	var radius: float = (CELL_SIZE / 2.0 - 4) * pulse

	draw_circle(center, radius + 8.0, Color(1.0, 0.15, 0.0, 0.08))
	draw_circle(center, radius + 4.0, Color(1.0, 0.2, 0.0, 0.12))
	draw_circle(center, radius, bomb_body_color)
	draw_circle(center + Vector2(-radius * 0.25, -radius * 0.25), radius * 0.3, bomb_highlight_color)

	var x_size: float = radius * 0.45
	var x_color: Color = Color(0.7, 0.15, 0.1, 0.9)
	draw_line(center + Vector2(-x_size, -x_size), center + Vector2(x_size, x_size), x_color, 2.5)
	draw_line(center + Vector2(x_size, -x_size), center + Vector2(-x_size, x_size), x_color, 2.5)

	draw_rect(Rect2(center.x - 3, center.y - radius - 2, 6, 4), Color(0.6, 0.55, 0.4, 1.0))
	var fuse_start: Vector2 = Vector2(center.x, center.y - radius - 2)
	var fuse_mid: Vector2 = Vector2(center.x + 5, center.y - radius - 7)
	var fuse_end: Vector2 = Vector2(center.x + 2, center.y - radius - 12)
	draw_line(fuse_start, fuse_mid, bomb_fuse_color, 2.0)
	draw_line(fuse_mid, fuse_end, bomb_fuse_color, 2.0)

	var spark_blink: float = abs(sin(anim_timer * 15.0))
	var spark_size: float = 3.0 + spark_blink * 2.0
	draw_circle(fuse_end, spark_size + 2.0, Color(1.0, 0.5, 0.1, 0.4 * spark_blink))
	draw_circle(fuse_end, spark_size, Color(1.0, 0.85, 0.2, 0.8 * spark_blink))
	draw_circle(fuse_end, spark_size * 0.4, Color(1.0, 1.0, 0.8, 0.9))

	var remaining: int = max(1, ceili(countdown_val))
	var countdown_text: String = str(remaining)
	var font = ThemeDB.fallback_font
	var ts: Vector2 = font.get_string_size(countdown_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
	var tx: float = center.x - ts.x / 2.0
	var ty: float = center.y - ts.y / 2.0 + 2
	draw_string(font, Vector2(tx + 1, ty + 1), countdown_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0, 0.8))
	var num_color: Color
	if countdown_val <= 2.0:
		var flash: float = abs(sin(anim_timer * 6.0))
		num_color = Color(1.0, 0.3 + flash * 0.3, 0.2, 1.0)
	else:
		num_color = Color(1.0, 0.85, 0.2, 0.95)
	draw_string(font, Vector2(tx, ty), countdown_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, num_color)

	var warn_text: String = "-%d" % TRAP_PENALTY
	var wts: Vector2 = font.get_string_size(warn_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
	draw_string(font, Vector2(center.x - wts.x / 2.0, center.y + radius + 10),
		warn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.3, 0.2, 0.8))

# =========================================================
# Drawing - Special Food
# =========================================================

func _draw_special_food() -> void:
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

	for ring in range(4):
		var ring_r: float = radius + (4 - ring) * 5.0
		var ring_a: float = (0.03 + ring * 0.02) * flash_alpha
		var rc: Color = palette[(color_index + ring) % palette.size()]
		rc.a = ring_a
		draw_circle(center, ring_r, rc)

	var ray_len: float = radius + 8.0
	var ray_col: Color = Color(base_color.r, base_color.g, base_color.b, 0.2 * flash_alpha)
	for k in range(8):
		var angle: float = special_blink * 0.3 + k * PI / 4.0
		draw_line(center, center + Vector2(cos(angle), sin(angle)) * ray_len, ray_col, 2.0)

	draw_circle(center, radius, base_color)
	if special_type != SpecialType.SPEED_UP and special_type != SpecialType.SPEED_DOWN:
		draw_circle(center + Vector2(-3, -4), radius * 0.25, Color(1.0, 1.0, 1.0, 0.5 * flash_alpha))

	var icon_color: Color = Color(1.0, 1.0, 1.0, 0.8 * flash_alpha)
	match special_type:
		SpecialType.SPEED_UP:
			_draw_chevron_right(center.x, center.y, 8.0, icon_color, 3.0)
			_draw_chevron_right(center.x + 8.0, center.y, 8.0, icon_color, 3.0)
		SpecialType.SPEED_DOWN:
			_draw_chevron_left(center.x, center.y, 8.0, icon_color, 3.0)
			_draw_chevron_left(center.x - 8.0, center.y, 8.0, icon_color, 3.0)
		SpecialType.MAGMA_FRUIT:
			# Draw golden flame icon (distinct from magma terrain)
			var flame_core: Color = Color(1.0, 0.95, 0.3, flash_alpha)  # Bright yellow
			var flame_mid: Color = Color(1.0, 0.75, 0.0, flash_alpha)   # Golden
			var flame_edge: Color = Color(1.0, 0.5, 0.0, flash_alpha)   # Orange edge
			draw_circle(center + Vector2(0, -3), 7.0, flame_edge)
			draw_circle(center + Vector2(0, -3), 5.0, flame_mid)
			draw_circle(center + Vector2(0, -3), 3.0, flame_core)
			# Side flames
			draw_circle(center + Vector2(-3, 2), 4.0, flame_mid)
			draw_circle(center + Vector2(3, 2), 4.0, flame_mid)
			# M letter in dark red
			draw_string(ThemeDB.fallback_font, Vector2(center.x + 5, center.y - 6),
				"M", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.1, 0.05, flash_alpha))
		_:
			var icon_char: String
			match special_type:
				SpecialType.GHOST: icon_char = "G"
				SpecialType.WALL_STOP: icon_char = "S"
				SpecialType.FOOD_RAIN: icon_char = "F"
				SpecialType.WALL_PASS: icon_char = "P"
			draw_string(ThemeDB.fallback_font, Vector2(center.x + 6, center.y - 10),
				icon_char, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 1.0, 1.0, 0.7 * flash_alpha))

# =========================================================
# Drawing - Snake
# =========================================================

func _draw_snake() -> void:
	if segments.is_empty():
		return
	var seg_count: int = segments.size()
	var alpha_factor: float = 1.0

	# Ghost alpha
	if ghost_active:
		if ghost_timer <= GHOST_WARN_THRESHOLD:
			var urgency: float = 1.0 - (ghost_timer / GHOST_WARN_THRESHOLD)
			var freq: float = lerpf(0.6, 6.0, urgency)
			alpha_factor = 0.5 + 0.5 * sin(special_blink * freq)
		else:
			alpha_factor = 0.5 + 0.5 * sin(special_blink * 0.6)

	# Eating bounce scale
	var eat_scale: float = 1.0
	if eating_anim_timer > 0.0:
		var eat_t: float = 1.0 - (eating_anim_timer / 0.3)
		eat_scale = 1.0 + sin(eat_t * PI) * 0.1

	# Precompute segment centers and widths
	var centers: Array[Vector2] = []
	var widths: Array[float] = []  # full body width at each segment
	for i in range(seg_count):
		var seg: Vector2i = segments[i]
		var cx: float = seg.x * CELL_SIZE + CELL_SIZE / 2.0
		var cy: float = seg.y * CELL_SIZE + CELL_SIZE / 2.0
		centers.append(Vector2(cx, cy))

		var t: float = float(i) / float(max(seg_count - 1, 1))
		var w: float
		if i == 0:
			w = CELL_SIZE * 0.92 * eat_scale  # Big round head
		elif i <= 2:
			# Smooth head-to-body transition
			var ht: float = float(i) / 3.0
			w = lerp(CELL_SIZE * 0.92, CELL_SIZE * 0.72, ht)
		else:
			# Body: gentle smooth taper to tail
			w = CELL_SIZE * 0.72 - t * CELL_SIZE * 0.22
			w = maxf(w, CELL_SIZE * 0.28)
		widths.append(w)

	# --- Layer 1: Continuous tubular body (draw as overlapping circles) ---
	# Draw from tail to head so head is on top
	for i in range(seg_count - 1, 0, -1):
		var seg: Vector2i = segments[i]
		if _get_terrain(seg.x, seg.y) == Terrain.FOREST:
			continue

		var c: Vector2 = centers[i]
		var half_w: float = widths[i] / 2.0
		var t: float = float(i) / float(max(seg_count - 1, 1))

		# Body color
		var body_c: Color
		if ghost_active:
			body_c = ghost_head_color.lerp(ghost_tail_color, t)
			body_c.a *= alpha_factor
		elif boosted and boost_glow > 0.1:
			body_c = head_color.lerp(tail_color, t)
			var warmth: float = t * boost_glow * 0.3
			body_c.r = min(1.0, body_c.r + warmth)
			body_c.g = min(1.0, body_c.g + warmth * 0.5)
		else:
			body_c = head_color.lerp(tail_color, t)

		# Draw body circle (large, overlapping creates smooth tube)
		draw_circle(c, half_w, body_c)

		# Connection to next segment (fill gap)
		var s1: Vector2i = segments[i]
		var s2: Vector2i = segments[i - 1]
		var grid_dist: int = abs(s1.x - s2.x) + abs(s1.y - s2.y)
		if grid_dist <= 1:
			var nc: Vector2 = centers[i - 1]
			var next_half_w: float = widths[i - 1] / 2.0
			# Draw filled rect between the two circles to bridge the gap
			var conn_w: float = min(half_w, next_half_w)
			if s1.x != s2.x:  # horizontal connection
				var x1: float = min(c.x, nc.x)
				var x2: float = max(c.x, nc.x)
				draw_rect(Rect2(x1, c.y - conn_w, x2 - x1, conn_w * 2), body_c)
			else:  # vertical connection
				var y1: float = min(c.y, nc.y)
				var y2: float = max(c.y, nc.y)
				draw_rect(Rect2(c.x - conn_w, y1, conn_w * 2, y2 - y1), body_c)

		# Belly highlight (bottom half, lighter)
		if not ghost_active:
			var belly_c: Color = Color(belly_color.r, belly_color.g, belly_color.b, 0.2)
			draw_circle(c + Vector2(0, half_w * 0.1), half_w * 0.6, belly_c)

		# Tail tip (cute rounded end)
		if i == seg_count - 1:
			var tip_c: Color
			if ghost_active:
				tip_c = Color(0.35, 0.3, 0.8, 0.5 * alpha_factor)
			else:
				tip_c = Color(0.25, 0.92, 0.48, 0.5)
			draw_circle(c, half_w * 0.6, tip_c)

	# --- Layer 2: Head (large anime-style) ---
	var seg0: Vector2i = segments[0]
	if _get_terrain(seg0.x, seg0.y) != Terrain.FOREST:
		var head_c: Vector2 = centers[0]
		var head_r: float = widths[0] / 2.0

		# Boost glow
		if boosted and boost_glow > 0.1 and not ghost_active:
			var glow_a: float = boost_glow * 0.2 * (0.6 + 0.4 * abs(sin(anim_timer * 8.0)))
			draw_circle(head_c, head_r * 1.6, Color(boost_glow_color.r, boost_glow_color.g, boost_glow_color.b, glow_a))

		# Head shadow
		draw_circle(head_c + Vector2(1.5, 2.0), head_r, Color(0.0, 0.0, 0.0, 0.12 * alpha_factor))

		# Main head circle (big and round!)
		var hc: Color
		if ghost_active:
			hc = Color(ghost_head_color.r, ghost_head_color.g, ghost_head_color.b, ghost_head_color.a * alpha_factor)
		else:
			hc = head_color
		draw_circle(head_c, head_r, hc)

		# Top highlight (roundness / 3D)
		if not ghost_active:
			var hl: Color = Color(min(1.0, hc.r + 0.12), min(1.0, hc.g + 0.1), min(1.0, hc.b + 0.1), 0.3)
			draw_circle(head_c + Vector2(-head_r * 0.2, -head_r * 0.25), head_r * 0.5, hl)

			# Belly area on head
			var bh: Color = Color(belly_color.r, belly_color.g, belly_color.b, 0.2)
			draw_circle(head_c + Vector2(0, head_r * 0.15), head_r * 0.55, bh)

		# Big anime eyes
		_draw_eyes(seg0, direction, head_c, head_r, alpha_factor)

		# Rosy blush cheeks (circle, not square)
		if not ghost_active:
			var fwd: Vector2 = Vector2(direction) * head_r * 0.1
			var perp_d: Vector2 = Vector2(-direction.y, direction.x)
			var cheek_dist: float = head_r * 0.52
			var blush_a: float = blush_color.a * alpha_factor
			draw_circle(head_c + perp_d * cheek_dist + fwd, head_r * 0.16, Color(blush_color.r, blush_color.g, blush_color.b, blush_a))
			draw_circle(head_c - perp_d * cheek_dist + fwd, head_r * 0.16, Color(blush_color.r, blush_color.g, blush_color.b, blush_a))

		# Tongue
		if tongue_flick_timer < 0.18 and tongue_flick_timer > 0.01 and not ghost_active:
			_draw_tongue(head_c, head_r, alpha_factor)

		# Eating mouth
		if mouth_open > 0.05 and not ghost_active:
			_draw_eating_mouth(head_c, head_r, alpha_factor)


		# Burning effect on head
		if is_burning and not ghost_active:
			_draw_burning_effect(head_c, head_r)

	# --- Burning effect on body ---
	if is_burning and not ghost_active and seg_count > 1:
		for i in range(1, seg_count - 1):
			if i % 2 == 0:  # Every other segment
				var seg: Vector2i = segments[i]
				if _get_terrain(seg.x, seg.y) != Terrain.FOREST:
					var c: Vector2 = centers[i]
					var r: float = widths[i] / 4.0
					_draw_burning_effect(c, r)


func _body_perpendicular(seg_idx: int) -> Vector2:
	# Deprecated, kept for compatibility
	if seg_idx <= 0 or seg_idx >= segments.size():
		return Vector2(-direction.y, direction.x)
	var diff: Vector2i = segments[seg_idx - 1] - segments[seg_idx]
	if diff.x == 0 and diff.y == 0:
		return Vector2(-direction.y, direction.x)
	return Vector2(-diff.y, diff.x).normalized()


# =========================================================
# Drawing - Anime Eyes (big, sparkly, cute)
# =========================================================
func _draw_eyes(pos: Vector2i, dir: Vector2i, center: Vector2, head_r: float, alpha_factor: float) -> void:
	# Anime-style: bigger eyes, wider spacing, larger highlights
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
		draw_arc(re, blink_w, 0.3, PI - 0.3, 12, blink_c, 2.8)
		draw_arc(le, blink_w, 0.3, PI - 0.3, 12, blink_c, 2.8)
	else:
		# Eye shadow
		draw_circle(re + Vector2(1, 1.5), eye_sz, Color(0, 0, 0, 0.15 * alpha_factor))
		draw_circle(le + Vector2(1, 1.5), eye_sz, Color(0, 0, 0, 0.15 * alpha_factor))
		# White of eyes (slightly larger for anime feel)
		draw_circle(re, eye_sz, ec)
		draw_circle(le, eye_sz, ec)
		# Iris (colored ring around pupil)
		var iris_c: Color = Color(0.18, 0.72, 0.35, 0.9 * alpha_factor)
		if ghost_active:
			iris_c = Color(0.4, 0.35, 0.9, 0.7 * alpha_factor)
		var iris_sz: float = pupil_sz * 1.35
		var ps: Vector2 = Vector2(dir) * eye_sz * 0.22
		draw_circle(re + ps, iris_sz, iris_c)
		draw_circle(le + ps, iris_sz, iris_c)
		# Pupils
		draw_circle(re + ps, pupil_sz, pc)
		draw_circle(le + ps, pupil_sz, pc)
		# Primary sparkle (large, top-left)
		var hl1: Vector2 = Vector2(-eye_sz * 0.28, -eye_sz * 0.32)
		var hl_sz: float = eye_sz * 0.30
		var hl_c: Color = Color(1.0, 1.0, 1.0, 0.95 * alpha_factor)
		draw_circle(re + hl1, hl_sz, hl_c)
		draw_circle(le + hl1, hl_sz, hl_c)
		# Secondary sparkle (smaller, bottom-right)
		var hl2: Vector2 = Vector2(eye_sz * 0.18, eye_sz * 0.12)
		draw_circle(re + hl2, hl_sz * 0.55, hl_c)
		draw_circle(le + hl2, hl_sz * 0.55, hl_c)
		# Tiny third sparkle (anime sparkle effect)
		var hl3: Vector2 = Vector2(-eye_sz * 0.05, eye_sz * 0.25)
		draw_circle(re + hl3, hl_sz * 0.3, Color(1.0, 1.0, 1.0, 0.6 * alpha_factor))
		draw_circle(le + hl3, hl_sz * 0.3, Color(1.0, 1.0, 1.0, 0.6 * alpha_factor))


# =========================================================
# Drawing - Forked Tongue
# =========================================================
func _draw_tongue(center: Vector2, head_r: float, alpha_factor: float) -> void:
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

	# Main tongue line
	draw_line(base_pos, tip_pos, t_c, 2.0)
	# Forked tips
	var fork_l: Vector2 = tip_pos + Vector2(direction) * fork_len + perp * fork_spread
	var fork_r: Vector2 = tip_pos + Vector2(direction) * fork_len - perp * fork_spread
	draw_line(tip_pos, fork_l, t_c, 1.5)
	draw_line(tip_pos, fork_r, t_c, 1.5)
	# Tiny round tips
	draw_circle(fork_l, 1.2, t_c)
	draw_circle(fork_r, 1.2, t_c)


# =========================================================
# Drawing - Eating Mouth Animation
# =========================================================
func _draw_eating_mouth(center: Vector2, head_r: float, alpha_factor: float) -> void:
	var mouth_pos: Vector2 = center + Vector2(direction) * head_r * 0.52
	var mouth_r: float = head_r * 0.28 * mouth_open
	var m_alpha: float = 0.8 * mouth_open * alpha_factor

	# Dark mouth cavity
	draw_circle(mouth_pos, mouth_r, Color(mouth_color.r, mouth_color.g, mouth_color.b, m_alpha))

	# Happy lip curve
	if mouth_open > 0.3:
		var lip_c: Color = Color(0.85, 0.25, 0.3, 0.3 * mouth_open * alpha_factor)
		var lip_r: float = mouth_r * 0.65
		draw_arc(mouth_pos + Vector2(direction) * mouth_r * 0.15, lip_r, 0.4, PI - 0.4, 16, lip_c, 1.8)

	# Little "nom nom" sparkles around mouth
	if mouth_open > 0.5:
		var sparkle_count: int = 3
		for k in range(sparkle_count):
			var s_angle: float = float(k) * TAU / float(sparkle_count) + anim_timer * 4.0
			var s_dist: float = head_r * 0.7
			var s_pos: Vector2 = mouth_pos + Vector2(cos(s_angle), sin(s_angle)) * s_dist
			var s_size: float = 2.0 + sin(anim_timer * 8.0 + k) * 1.0
			var s_alpha: float = 0.4 * mouth_open * alpha_factor
			# Star sparkle
			var sc: Color = Color(1.0, 1.0, 0.7, s_alpha)
			draw_circle(s_pos, s_size, sc)
			draw_circle(s_pos, s_size * 0.4, Color(1.0, 1.0, 1.0, s_alpha * 1.2))



# =========================================================
# Drawing - UI (Game HUD + Screens)
# =========================================================

func _draw_ui() -> void:
	var W: float = GRID_WIDTH * CELL_SIZE
	var H: float = GRID_HEIGHT * CELL_SIZE

	# ---- Left HUD: Score, Total, Best, Level ----
	var score_color: Color = Color(1, 1, 1, 1)
	if score < 0:
		score_color = Color(1, 0.3, 0.2, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(15, 28),
		Loc.t("ui_score") % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, score_color)
	draw_string(ThemeDB.fallback_font, Vector2(15, 52),
		Loc.t("ui_total") % total_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.63, 0.73, 0.85))
	draw_string(ThemeDB.fallback_font, Vector2(15, 70),
		Loc.t("ui_best") % high_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.85, 0, 1))

	# ---- Right HUD: Speed ----
	# Level info
	var level_text: String = Loc.t("ui_level") % gate_level
	draw_string(ThemeDB.fallback_font, Vector2(15, 92),
		level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.55, 0.58, 0.68, 0.7))

	# Gate progress
	var needed: int = gate_level * GATE_OPEN_SCORE_PER_LEVEL
	if not gate_open:
		var gate_text: String = Loc.t("ui_gate_closed") % [score, needed]
		draw_string(ThemeDB.fallback_font, Vector2(15, 112),
			gate_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.45, 0.48, 0.55, 0.6))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(15, 112),
			Loc.t("ui_gate_open"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.9, 0.5, 0.85))

	var speed_text: String = Loc.t("ui_speed") % display_speed
	var speed_ts: Vector2 = ThemeDB.fallback_font.get_string_size(speed_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 16)
	draw_string(ThemeDB.fallback_font, Vector2(W - 15 - speed_ts.x, 30),
		speed_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.65, 0.75, 0.85))

	if combo >= 3:
		var combo_alpha: float = min(1.0, combo_timer / 0.5)
		draw_string(ThemeDB.fallback_font, Vector2(15, 80),
			Loc.t("ui_combo") % combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.2, combo_alpha))

	# ---- Active effect countdown (top-right) ----
	var countdown_idx: int = 0
	if ghost_active:
		_draw_effect_countdown(W, H, countdown_idx, Loc.t("effect_ghost"), ghost_timer, GHOST_DURATION, ghost_bar_color, "G")
		countdown_idx += 1
	if wall_stop_active:
		_draw_effect_countdown(W, H, countdown_idx, Loc.t("effect_shield"), wall_stop_timer, WALL_STOP_DURATION, wallstop_bar_color, "S")
		countdown_idx += 1
	if wall_pass_active:
		_draw_effect_countdown(W, H, countdown_idx, Loc.t("effect_pass"), wall_pass_timer, WALL_PASS_DURATION, wallpass_bar_color, "P")
		countdown_idx += 1
	if magma_fruit_active:
		_draw_effect_countdown(W, H, countdown_idx, Loc.t("effect_magma"), magma_fruit_timer, MAGMA_FRUIT_DURATION, magma_fruit_bar_color, "🔥")
		countdown_idx += 1



	# ---- Pause screen (menu style) ----
	if paused and not game_over:
		_draw_pause_screen(W, H)
		return

	# ---- Game Over screen ----
	if game_over:
		_draw_gameover_screen(W, H)

# =========================================================
# Drawing - Pause Screen (with menu items)
# =========================================================

func _draw_pause_screen(W: float, H: float) -> void:
	var font = ThemeDB.fallback_font
	_draw_overlay(0.55)

	# Title
	_draw_centered_text(Loc.t("paused_title"), H / 2.0 - 70, 42, Color(1, 1, 1, 1))

	# Two menu items
	var pause_item_w: float = 260.0
	var pause_item_h: float = 48.0
	var pause_start_y: float = H / 2.0 - 15.0
	var pause_spacing: float = 60.0
	var pause_items: PackedStringArray = [
		Loc.t("paused_continue"),
		Loc.t("paused_return_menu"),
	]
	var pause_icons: PackedStringArray = ["▶", "◀"]

	_pause_item_rects.clear()
	for i in range(PAUSE_ITEMS_COUNT):
		var item_y: float = pause_start_y + float(i) * pause_spacing
		var ppx: float = (W - pause_item_w) / 2.0
		var ppy: float = item_y - pause_item_h / 2.0
		_pause_item_rects.append(Rect2(ppx, ppy, pause_item_w, pause_item_h))
		var hovered: bool = _pause_item_rects[i].has_point(get_global_mouse_position() - Vector2(DRAW_MARGIN, DRAW_MARGIN))
		if hovered:
			pause_selected = i
		_draw_pause_menu_item(
			pause_items[i], pause_icons[i],
			W, item_y, pause_item_w, pause_item_h,
			i == pause_selected, font
		)

	# Footer hint
	var blink: float = 0.5 + 0.4 * sin(anim_timer * 3.0)
	_draw_centered_text("ESC", H / 2.0 + 120.0, 13, Color(0.4, 0.43, 0.5, blink))

func _draw_pause_menu_item(text: String, icon: String, canvas_w: float, center_y: float,
		item_w: float, item_h: float, selected: bool, font: Font) -> void:
	var pill_x: float = (canvas_w - item_w) / 2.0
	var pill_y: float = center_y - item_h / 2.0
	var pill_rect: Rect2 = Rect2(pill_x, pill_y, item_w, item_h)

	if selected:
		var pulse: float = 0.6 + 0.4 * sin(menu_anim * 4.0)

		# Outer glow
		draw_rect(pill_rect.grow(8), Color(0.1, 0.45, 0.2, 0.06 * pulse))

		# Pill fill
		_draw_rounded_rect(pill_rect, Color(0.05, 0.16, 0.08, 0.75), 12)

		# Pill border (pulsing)
		var ba: float = 0.55 + 0.35 * pulse
		_draw_rounded_rect(pill_rect, Color(0.2, 0.95, 0.4, ba), 12, false, 2.0)

		# Left indicator dot
		var dot_x: float = pill_x + 18.0
		draw_circle(Vector2(dot_x, center_y), 3.5, Color(0.2, 1.0, 0.5, 0.85))
		draw_circle(Vector2(dot_x, center_y), 8.0, Color(0.2, 1.0, 0.5, 0.15 * pulse))

		# Text shadow + text
		var tx: float = pill_x + 36.0
		var ty: float = pill_y + (item_h - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).y) / 2.0 + font.get_ascent(19)
		draw_string(font, Vector2(tx + 1, ty + 1), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0, 0, 0, 0.35))
		draw_string(font, Vector2(tx, ty), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(1.0, 1.0, 1.0, 1.0))
	else:
		# Pill fill
		_draw_rounded_rect(pill_rect, Color(0.08, 0.1, 0.14, 0.45), 12)

		# Pill border
		_draw_rounded_rect(pill_rect, Color(0.22, 0.25, 0.32, 0.25), 12, false, 1.0)

		# Text (dim)
		var tx: float = pill_x + 36.0
		var ty: float = pill_y + (item_h - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).y) / 2.0 + font.get_ascent(17)
		draw_string(font, Vector2(tx, ty), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.5, 0.53, 0.58, 0.7))

# =========================================================
# Drawing - Game Over Screen
# =========================================================

func _draw_gameover_screen(W: float, H: float) -> void:
	_draw_overlay(0.7)
	var bx: float = W / 2.0 - 170
	var by: float = H / 2.0 - 140
	var box: Rect2 = Rect2(bx, by, 340, 330)
	_draw_rounded_rect(box, Color(0.1, 0.1, 0.15, 0.95), 12)
	var title_text: String
	var title_color: Color
	var box_border_color: Color
	var subtitle: String
	var subtitle_color: Color
	match death_reason:
		"bomb":
			title_text = Loc.t("gameover_boom")
			title_color = Color(1.0, 0.4, 0.1, 1.0)
			box_border_color = Color(1.0, 0.3, 0.1, 0.9)
			subtitle = Loc.t("gameover_bomb_sub")
			subtitle_color = Color(1.0, 0.6, 0.3, 0.9)
		"wall":
			title_text = Loc.t("gameover_title")
			title_color = Color(1, 0.3, 0.3, 1.0)
			box_border_color = Color(0.4, 0.15, 0.15, 0.8)
			subtitle = Loc.t("gameover_wall_sub")
			subtitle_color = Color(0.8, 0.5, 0.5, 0.9)
		"self":
			title_text = Loc.t("gameover_title")
			title_color = Color(1, 0.3, 0.3, 1.0)
			box_border_color = Color(0.4, 0.15, 0.15, 0.8)
			subtitle = Loc.t("gameover_self_sub")
			subtitle_color = Color(0.8, 0.5, 0.5, 0.9)
		"frozen":
			title_text = Loc.t("gameover_frozen")
			title_color = Color(0.3, 0.6, 1.0, 1.0)
			box_border_color = Color(0.2, 0.3, 0.8, 0.9)
			subtitle = Loc.t("gameover_frozen_sub")
			subtitle_color = Color(0.4, 0.6, 1.0, 0.9)
		"mountain":
			title_text = Loc.t("gameover_mountain")
			title_color = Color(0.85, 0.45, 0.25, 1.0)
			box_border_color = Color(0.6, 0.3, 0.15, 0.9)
			subtitle = Loc.t("gameover_mountain_sub")
			subtitle_color = Color(0.9, 0.55, 0.35, 0.9)
		_:
			title_text = Loc.t("gameover_title")
			title_color = Color(1, 0.3, 0.3, 1.0)
			box_border_color = Color(0.4, 0.15, 0.15, 0.8)
			subtitle = ""
			subtitle_color = Color(1, 1, 1, 1)
	_draw_rounded_rect(box, box_border_color, 12, false, 3.0)
	_draw_centered_text(title_text, H / 2.0 - 105, 42, title_color)
	if subtitle != "":
		_draw_centered_text(subtitle, H / 2.0 - 65, 18, subtitle_color)
	_draw_centered_text(Loc.t("gameover_score") % total_score, H / 2.0 - 40, 30, Color(1, 1, 1, 1))
	_draw_centered_text(Loc.t("gameover_level_score") % score, H / 2.0 - 12, 14, Color(0.55, 0.58, 0.68, 0.6))
	_draw_centered_text(Loc.t("gameover_stats") % [segments.size(), total_food_eaten],
		H / 2.0 + 3, 15, Color(0.7, 0.7, 0.7, 0.9))
	if total_score >= high_score and total_score > 0:
		_draw_centered_text(Loc.t("gameover_new_high"), H / 2.0 + 25, 22, Color(1, 0.85, 0, 1.0))
	else:
		_draw_centered_text(Loc.t("gameover_best") % high_score, H / 2.0 + 25, 22, Color(1, 0.85, 0, 0.7))
	if combo > 2:
		_draw_centered_text(Loc.t("gameover_combo") % combo, H / 2.0 + 55, 18, Color(1.0, 0.8, 0.3, 0.8))
	var ra: float = (sin(Time.get_ticks_msec() / 400.0) + 1.0) / 2.0
	_draw_centered_text(Loc.t("gameover_restart"), H / 2.0 + 80, 12, Color(0.45, 0.48, 0.52, 0.4 + ra * 0.3))

	# ---- Buttons ----
	var btn_labels: PackedStringArray = [Loc.t("gameover_new_game"), Loc.t("gameover_quit")]
	var btn_w: float = 120.0
	var btn_h: float = 40.0
	var btn_gap: float = 24.0
	var total_btn_w: float = btn_w * 2.0 + btn_gap
	var btn_start_x: float = W / 2.0 - total_btn_w / 2.0
	var btn_y: float = H / 2.0 + 108.0
	_gameover_btn_rects.clear()
	for i in range(2):
		var btn_x: float = btn_start_x + float(i) * (btn_w + btn_gap)
		var btn_y2: float = btn_y
		var br: Rect2 = Rect2(btn_x, btn_y2, btn_w, btn_h)
		_gameover_btn_rects.append(br)
		var hovered: bool = br.has_point(get_global_mouse_position() - Vector2(DRAW_MARGIN, DRAW_MARGIN))
		if hovered:
			_draw_rounded_rect(br.grow(4), Color(0.15, 0.4, 0.2, 0.2 * ra), 10)
			_draw_rounded_rect(br, Color(0.08, 0.25, 0.1, 0.85), 10)
			_draw_rounded_rect(br, Color(0.25, 0.95, 0.45, 0.75 + 0.25 * ra), 10, false, 2.0)
			var ts2: Vector2 = ThemeDB.fallback_font.get_string_size(btn_labels[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
			var tx2: float = btn_x + (btn_w - ts2.x) / 2.0
			var ty2: float = btn_y2 + (btn_h - ts2.y) / 2.0 + ThemeDB.fallback_font.get_ascent(16)
			draw_string(ThemeDB.fallback_font, Vector2(tx2, ty2), btn_labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 1.0))
		else:
			_draw_rounded_rect(br, Color(0.1, 0.12, 0.16, 0.75), 10)
			_draw_rounded_rect(br, Color(0.3, 0.35, 0.4, 0.35), 10, false, 1.5)
			var ts2: Vector2 = ThemeDB.fallback_font.get_string_size(btn_labels[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 15)
			var tx2: float = btn_x + (btn_w - ts2.x) / 2.0
			var ty2: float = btn_y2 + (btn_h - ts2.y) / 2.0 + ThemeDB.fallback_font.get_ascent(15)
			draw_string(ThemeDB.fallback_font, Vector2(tx2, ty2), btn_labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.7, 0.73, 0.78, 0.75))

# =========================================================
# Drawing - Effect Bar
# =========================================================

# =========================================================
# Wormhole System
# =========================================================

func _get_paired_wormhole_pos(pair_id: int, current_pos: Vector2i) -> Vector2i:
	for wh in wormholes:
		if wh.pair_id == pair_id and wh.pos != current_pos:
			return wh.pos
	return current_pos

func _generate_wormholes() -> void:
	wormholes.clear()
	var num_pairs: int = 1 + (randi() % 2)  # 1 or 2 pairs
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
			# Must be ground
			if tiles[y][x] != Terrain.GROUND:
				continue
			# Not in center spawn area (5x5 safe zone)
			if abs(x - center_x) <= 2 and abs(y - center_y) <= 2:
				continue
			# Not on food or existing wormhole
			var occupied: bool = false
			if pos == main_food_pos:
				occupied = true
			for wh in wormholes:
				if wh.pos == pos:
					occupied = true
			for ep in positions:
				if ep == pos:
					occupied = true
				if grid_distance(ep, pos) < WORMHOLE_MIN_DIST:
					occupied = true
			if occupied:
				continue
			positions.append(pos)
		if positions.size() == 2:
			var palette: Array = wormhole_palettes[pair_id % wormhole_palettes.size()]
			wormholes.append({"pos": positions[0], "pair_id": pair_id, "palette": palette, "phase": randf() * TAU})
			wormholes.append({"pos": positions[1], "pair_id": pair_id, "palette": palette, "phase": randf() * TAU})

func _draw_wormholes() -> void:
	for wh in wormholes:
		_draw_single_wormhole(wh)

func _draw_single_wormhole(wh: Dictionary) -> void:
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

	# Outer glow (soft, pulsing)
	for ring in range(3):
		var gr: float = radius + 6.0 + float(ring) * 4.0
		var ga: float = (0.04 + ring * 0.02) * pulse
		draw_circle(Vector2(cx, cy), gr, Color(glow_c.r, glow_c.g, glow_c.b, ga))

	# Accretion disk ring (colored border)
	var ring_width: float = 3.0 + sin(anim_timer * 1.8 + phase) * 0.5
	draw_circle(Vector2(cx, cy), radius + 1.0, Color(main_c.r, main_c.g, main_c.b, 0.6 * pulse), false, ring_width)
	draw_circle(Vector2(cx, cy), radius + 3.0, Color(light_c.r, light_c.g, light_c.b, 0.2 * pulse), false, 1.5)

	# Rotating spiral arms (3 arms)
	var num_arms: int = 3
	for arm in range(num_arms):
		var arm_offset: float = phase + float(arm) * TAU / float(num_arms)
		var pts: PackedVector2Array = PackedVector2Array()
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
			draw_polyline(pts, Color(light_c.r, light_c.g, light_c.b, spiral_alpha), 2.0)

	# Orbiting particles (4 dots)
	for dot in range(4):
		var dot_angle: float = anim_timer * 3.0 + phase + float(dot) * TAU / 4.0
		var dot_r: float = radius + 2.0 + sin(anim_timer * 5.0 + dot) * 1.5
		var dx: float = cx + cos(dot_angle) * dot_r
		var dy: float = cy + sin(dot_angle) * dot_r
		var dot_alpha: float = 0.5 + 0.3 * sin(anim_timer * 4.0 + dot * 1.5)
		var dot_size: float = 2.0 + sin(anim_timer * 3.0 + dot) * 0.5
		draw_circle(Vector2(dx, dy), dot_size + 1.5, Color(glow_c.r, glow_c.g, glow_c.b, dot_alpha * 0.3))
		draw_circle(Vector2(dx, dy), dot_size, Color(light_c.r, light_c.g, light_c.b, dot_alpha))

	# Black hole center (gradient from dark edge to pure black)
	var inner_r: float = radius * 0.65
	draw_circle(Vector2(cx, cy), inner_r + 2.0, Color(dark_c.r * 0.4, dark_c.g * 0.4, dark_c.b * 0.4, 0.7))
	draw_circle(Vector2(cx, cy), inner_r, Color(0.02, 0.02, 0.04, 1.0))
	# Subtle inner highlight
	draw_circle(Vector2(cx - 2.0, cy - 2.0), inner_r * 0.3, Color(main_c.r, main_c.g, main_c.b, 0.08 * pulse))

	# Pair ID label (small letter in center)
	var label: String = str(wh.pair_id + 1)
	var font = ThemeDB.fallback_font
	var ls: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
	draw_string(font, Vector2(cx - ls.x / 2.0 + 0.5, cy - ls.y / 2.0 + 0.5), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 0, 0, 0.5))
	draw_string(font, Vector2(cx - ls.x / 2.0, cy - ls.y / 2.0), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(main_c.r, main_c.g, main_c.b, 0.5 * pulse))


# =========================================================
# Level Gate System
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
			if pos == main_food_pos:
				continue
			# Not on or adjacent to a wormhole
			var near_wormhole: bool = false
			for wh in wormholes:
				if pos == wh.pos or grid_distance(pos, wh.pos) < 2:
					near_wormhole = true
					break
			if near_wormhole:
				continue
			available.append(pos)
	if available.is_empty():
		gate_pos = Vector2i(-1, -1)
	else:
		gate_pos = available[randi() % available.size()]

func _enter_next_level() -> void:
	var old_gate: Vector2i = gate_pos
	total_score += score
	score = 0
	gate_level += 1
	_reset_game()
	_spawn_main_food()
	_spawn_particles(old_gate, Color(1.0, 0.85, 0.2), 30, 120.0)
	_spawn_floating_text(Loc.t("float_levelup") % gate_level, old_gate, Color(1.0, 0.85, 0.2), 24)
	if audio_manager:
		audio_manager.play_gate_enter()

func _draw_gate() -> void:
	if gate_pos.x < 0:
		return
	var cx: float = gate_pos.x * CELL_SIZE + CELL_SIZE / 2.0
	var cy: float = gate_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	var r: float = CELL_SIZE / 2.0 - 1.0
	var font = ThemeDB.fallback_font
	var dest_label: String = str(gate_level + 1)

	if gate_open:
		var pulse: float = 0.7 + 0.3 * sin(gate_anim * 3.0)
		# Outer glow layers
		for i in range(3):
			var gr: float = r + 8.0 + float(i) * 5.0
			var ga: float = (0.06 + float(i) * 0.03) * pulse
			draw_circle(Vector2(cx, cy), gr, Color(1.0, 0.85, 0.2, ga))
		# Flash burst when just opened
		if gate_flash > 0.0:
			draw_circle(Vector2(cx, cy), r + 20.0, Color(1.0, 0.9, 0.3, gate_flash * 0.25))
			draw_circle(Vector2(cx, cy), r + 12.0, Color(1.0, 0.92, 0.5, gate_flash * 0.15))
		# Golden door frame (arch)
		var fc: Color = Color(1.0, 0.75, 0.1, 0.9 * pulse)
		draw_arc(Vector2(cx, cy), r + 2.0, 0, PI, 16, fc, 3.0)
		draw_line(Vector2(cx - r - 2.0, cy), Vector2(cx - r - 2.0, cy - r), fc, 3.0)
		draw_line(Vector2(cx + r + 2.0, cy), Vector2(cx + r + 2.0, cy - r), fc, 3.0)
		# Interior warm glow
		draw_circle(Vector2(cx, cy), r, Color(0.95, 0.88, 0.6, 0.5 * pulse))
		draw_circle(Vector2(cx, cy - r * 0.3), r * 0.5, Color(1.0, 0.95, 0.8, 0.4 * pulse))
		# Up arrow (bobbing)
		var bob: float = sin(gate_anim * 4.0) * 3.0
		var ac: Color = Color(1.0, 0.85, 0.2, 0.85 * pulse)
		var ax: float = cx
		var ay: float = cy + bob
		draw_line(Vector2(ax, ay + 7), Vector2(ax, ay - 7), ac, 3.0)
		draw_line(Vector2(ax - 6, ay - 1), Vector2(ax, ay - 7), ac, 3.0)
		draw_line(Vector2(ax + 6, ay - 1), Vector2(ax, ay - 7), ac, 3.0)
		# Destination level label
		var ls: Vector2 = font.get_string_size(dest_label, HORIZONTAL_ALIGNMENT_CENTER, -1, 15)
		draw_string(font, Vector2(cx - ls.x / 2.0, cy - ls.y / 2.0 + 10), dest_label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.55, 0.4, 0.05, 0.85 * pulse))
		# Orbiting sparkles
		for k in range(4):
			var sa: float = gate_anim * 2.5 + k * TAU / 4.0
			var sr: float = r + 5.0
			var sx: float = cx + cos(sa) * sr
			var sy: float = cy + sin(sa) * sr
			var sp_a: float = 0.4 + 0.4 * sin(gate_anim * 3.0 + k)
			draw_circle(Vector2(sx, sy), 2.0, Color(1.0, 0.9, 0.4, sp_a * pulse))
	else:
		# Shadow
		draw_circle(Vector2(cx + 1.5, cy + 1.5), r + 2.0, Color(0.05, 0.05, 0.08, 0.5))
		# Door body
		_draw_rounded_rect(Rect2(cx - r - 1, cy - r - 1, (r + 1) * 2, (r + 1) * 2),
			Color(0.25, 0.27, 0.32, 0.95), 6)
		# Door frame
		var fc: Color = Color(0.4, 0.42, 0.5, 0.7)
		_draw_rounded_rect(Rect2(cx - r - 1, cy - r - 1, (r + 1) * 2, (r + 1) * 2),
			fc, 6, false, 2.0)
		# Inner panel
		_draw_rounded_rect(Rect2(cx - r + 2, cy - r + 2, (r - 2) * 2, (r - 2) * 2),
			Color(0.2, 0.22, 0.28, 0.9), 4)
		# Lock icon
		var lock_cy: float = cy - 3.0
		var lock_w: float = 8.0
		var lock_h: float = 6.0
		draw_rect(Rect2(cx - lock_w / 2.0, lock_cy, lock_w, lock_h),
			Color(0.5, 0.52, 0.58, 0.6))
		draw_rect(Rect2(cx - lock_w / 2.0, lock_cy, lock_w, lock_h),
			Color(0.65, 0.67, 0.72, 0.4), false, 1.0)
		draw_arc(Vector2(cx, lock_cy), 4.0, PI, TAU, 8,
			Color(0.5, 0.52, 0.58, 0.6), 2.0)
		# Keyhole dot
		draw_circle(Vector2(cx, lock_cy + 3.0), 1.2, Color(0.35, 0.37, 0.42, 0.7))
		# Destination level label
		var ls: Vector2 = font.get_string_size(dest_label, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		draw_string(font, Vector2(cx - ls.x / 2.0, cy + 6), dest_label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.52, 0.6, 0.5))
		# Progress bar at bottom of cell
		var needed: int = gate_level * GATE_OPEN_SCORE_PER_LEVEL
		var progress: float = clampf(float(score) / float(needed), 0.0, 1.0)
		var bar_w: float = CELL_SIZE - 6.0
		var bar_h: float = 3.0
		var bar_x: float = cx - bar_w / 2.0
		var bar_y: float = cy + r + 5.0
		# Bar background
		_draw_rounded_rect(Rect2(bar_x, bar_y, bar_w, bar_h),
			Color(0.15, 0.15, 0.2, 0.6), 1.5)
		# Bar fill
		if progress > 0.01:
			var fill_w: float = bar_w * progress
			_draw_rounded_rect(Rect2(bar_x, bar_y, fill_w, bar_h),
				Color(0.4, 0.4, 0.5, 0.8), 1.5)
		# Bar border
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.5, 0.5, 0.6, 0.4), false, 1.0)

# =========================================================
# Drawing - Helpers
# =========================================================


# =========================================================
# Terrain System
# =========================================================

func _get_terrain(x: int, y: int) -> int:
	if x < 0 or x >= GRID_WIDTH or y < 0 or y >= GRID_HEIGHT:
		return Terrain.GROUND
	return tiles[y][x]

# Count neighboring mountain/volcano tiles
func _count_mountain_neighbors(x: int, y: int) -> int:
	var count: int = 0
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			if dx == 0 and dy == 0:
				continue
			var nx: int = x + dx
			var ny: int = y + dy
			if nx >= 0 and nx < GRID_WIDTH and ny >= 0 and ny < GRID_HEIGHT:
				if tiles[ny][nx] == Terrain.MOUNTAIN or tiles[ny][nx] == Terrain.VOLCANO:
					count += 1
	return count

# Check if a cell is adjacent (4-directional: up/down/left/right) to VOLCANO or MAGMA
func _is_adjacent_to_volcano_or_magma(x: int, y: int) -> bool:
	var dirs: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
	for d in dirs:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if nx >= 0 and nx < GRID_WIDTH and ny >= 0 and ny < GRID_HEIGHT:
			if tiles[ny][nx] == Terrain.VOLCANO or tiles[ny][nx] == Terrain.MAGMA:
				return true
	return false

# Generate volcano at center and flowing magma
# Rule: Each magma tile must be adjacent to volcano or magma
# Rule: Each magma cluster must be connected to at least one volcano
func _generate_volcano_and_magma(cx: int, cy: int) -> void:
	# Place volcano center (must be on existing mountain or nearby)
	var best_x: int = cx
	var best_y: int = cy
	var best_count: int = -1
	
	# Find the best spot nearby with most mountains
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var nx: int = cx + dx
			var ny: int = cy + dy
			if nx >= 2 and nx < GRID_WIDTH - 2 and ny >= 2 and ny < GRID_HEIGHT - 2:
				var count: int = _count_mountain_neighbors(nx, ny)
				if count > best_count:
					best_count = count
					best_x = nx
					best_y = ny
	
	# Place volcano
	tiles[best_y][best_x] = Terrain.VOLCANO
	
	# Generate magma flow using BFS-like approach
	# Rule: If volcano exists, magma MUST exist (at least 10 tiles)
	# Each new magma must be adjacent (4-directional) to volcano or existing magma
	var magma_queue: Array[Vector2i] = [Vector2i(best_x, best_y)]
	var placed_magma: int = 0
	var min_magma: int = 10  # At least 10 magma tiles
	var max_attempts: int = 200
	var attempts: int = 0
	
	# Continue until we have at least min_magma tiles or exhaust attempts
	while placed_magma < min_magma and attempts < max_attempts:
		attempts += 1
		
		# If queue is empty but we need more magma, restart from existing magma tiles
		if magma_queue.is_empty():
			# Find all existing magma tiles to use as new sources
			for y in range(GRID_HEIGHT):
				for x in range(GRID_WIDTH):
					if tiles[y][x] == Terrain.MAGMA or tiles[y][x] == Terrain.VOLCANO:
						magma_queue.append(Vector2i(x, y))
			# Still empty? Break to avoid infinite loop
			if magma_queue.is_empty():
				break
		
		# Pick a random position from queue (volcano or existing magma)
		var source_idx: int = randi() % magma_queue.size()
		var source: Vector2i = magma_queue[source_idx]
		
		# Try to place magma in a random direction from source (4-directional)
		var dirs: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
		dirs.shuffle()
		
		var placed: bool = false
		for d in dirs:
			var nx: int = source.x + d.x
			var ny: int = source.y + d.y
			
			if nx < 1 or nx >= GRID_WIDTH - 1 or ny < 1 or ny >= GRID_HEIGHT - 1:
				continue
			
			# Can only place on GROUND or MOUNTAIN
			if tiles[ny][nx] != Terrain.GROUND and tiles[ny][nx] != Terrain.MOUNTAIN:
				continue
			
			# Place magma - it will be adjacent to source (volcano or magma)
			tiles[ny][nx] = Terrain.MAGMA
			placed_magma += 1
			magma_queue.append(Vector2i(nx, ny))
			placed = true
			break
		
		# If couldn't place from this source, remove it from queue
		if not placed:
			magma_queue.remove_at(source_idx)
	
	# Post-process: Remove any magma not connected to volcano (shouldn't happen, but safety check)
	_validate_magma_connectivity(best_x, best_y)

# Validate and remove orphaned magma (not connected to volcano)
func _validate_magma_connectivity(volcano_x: int, volcano_y: int) -> void:
	# Flood fill from volcano to find all connected magma
	var visited: Array = []
	for y in range(GRID_HEIGHT):
		visited.append([])
		for x in range(GRID_WIDTH):
			visited[y].append(false)
	
	var queue: Array[Vector2i] = [Vector2i(volcano_x, volcano_y)]
	visited[volcano_y][volcano_x] = true
	
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		
		var dirs: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
		for d in dirs:
			var nx: int = current.x + d.x
			var ny: int = current.y + d.y
			if nx >= 0 and nx < GRID_WIDTH and ny >= 0 and ny < GRID_HEIGHT:
				if not visited[ny][nx] and (tiles[ny][nx] == Terrain.MAGMA or tiles[ny][nx] == Terrain.VOLCANO):
					visited[ny][nx] = true
					queue.append(Vector2i(nx, ny))
	
	# Remove any magma not visited (not connected to volcano)
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if tiles[y][x] == Terrain.MAGMA and not visited[y][x]:
				tiles[y][x] = Terrain.GROUND

func _generate_terrain() -> void:
	tiles.clear()
	for y in range(GRID_HEIGHT):
		var row: Array = []
		for x in range(GRID_WIDTH):
			row.append(Terrain.GROUND)
		tiles.append(row)

	# Forest: grow from edge of existing forest when possible
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
		# Fill interior holes
		_fill_interior(Terrain.FOREST, 2)

	# River: grow from edge of existing river when possible
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
		# Fill interior holes
		_fill_interior(Terrain.RIVER, 2)
	_assign_river_variants()
	
	# Mountain: generate random clusters (obstacle - crash on hit)
	var mountain_centers: Array[Vector2i] = []
	var num_mountain: int = randi_range(NUM_MOUNTAIN_CLUSTERS_MIN, NUM_MOUNTAIN_CLUSTERS_MAX)
	for _i in range(num_mountain):
		var msize: int = randi_range(MOUNTAIN_CLUSTER_MIN, MOUNTAIN_CLUSTER_MAX)
		var mx: int = randi_range(2, GRID_WIDTH - 3)
		var my: int = randi_range(2, GRID_HEIGHT - 3)
		_grow_cluster(mx, my, msize, Terrain.MOUNTAIN)
		mountain_centers.append(Vector2i(mx, my))
	
	# Generate Volcano in the center of largest mountain cluster
	if mountain_centers.size() > 0:
		var largest_center: Vector2i = mountain_centers[0]
		var max_count: int = 0
		for center in mountain_centers:
			var count: int = _count_mountain_neighbors(center.x, center.y)
			if count > max_count:
				max_count = count
				largest_center = center
		# Place volcano at the densest mountain area
		if max_count >= 3:
			_generate_volcano_and_magma(largest_center.x, largest_center.y)
	
	_generate_wormholes()
	# Clear spawn area (7x7 center) with safe margin
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
			# Pick a valid border cell and continue
			var border: Vector2i = _find_terrain_edge(terrain_type)
			if border.x >= 0:
				cx = border.x; cy = border.y
			else:
				break
		if tiles[cy][cx] == Terrain.GROUND:
			tiles[cy][cx] = terrain_type
		# Prefer continuing in same direction for connected shapes
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
				# Only fill if surrounded on 3+ sides (fills interior holes, preserves edges)
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

func _draw_terrain() -> void:
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var H: float = float(GRID_HEIGHT * CELL_SIZE)
	draw_rect(Rect2(0, 0, W, H), bg_color)
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var terrain: int = tiles[y][x]
			var px: float = float(x * CELL_SIZE)
			var py: float = float(y * CELL_SIZE)
			match terrain:
				Terrain.GROUND:
					_draw_ground_tile(x, y, px, py)
				Terrain.FOREST:
					_draw_forest_tile(x, y, px, py)
				Terrain.RIVER:
					_draw_river_tile(x, y, px, py)
				Terrain.MOUNTAIN:
					_draw_mountain_tile(x, y, px, py)
				Terrain.VOLCANO:
					_draw_volcano_tile(x, y, px, py)
				Terrain.MAGMA:
					_draw_magma_tile(x, y, px, py)

func _draw_ground_tile(x: int, y: int, px: float, py: float) -> void:
	var tile_color: Color
	if (x + y) % 2 == 0:
		tile_color = Color(0.085, 0.095, 0.14)
	else:
		tile_color = Color(0.075, 0.085, 0.125)
	draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), tile_color)
	draw_circle(Vector2(px + CELL_SIZE * 0.3, py + CELL_SIZE * 0.3), 0.8, Color(0.1, 0.11, 0.16, 0.35))
	draw_circle(Vector2(px + CELL_SIZE * 0.7, py + CELL_SIZE * 0.7), 0.8, Color(0.1, 0.11, 0.16, 0.35))

func _draw_forest_tile(x: int, y: int, px: float, py: float) -> void:
	var variant: int = (x * 73 + y * 137) % 4
	var s: int = x * 53 + y * 97
	match variant:
		0: _forest_variant_0(x, y, px, py, s)
		1: _forest_variant_1(x, y, px, py, s)
		2: _forest_variant_3(x, y, px, py, s)
		3: _forest_variant_4(x, y, px, py, s)

# --- Forest Pattern A: Dense round canopy blobs ---
func _forest_variant_0(x: int, y: int, px: float, py: float, s: int) -> void:
	var blobs: Array[Array] = []
	for i in range(5):
		blobs.append([
			px + 8.0 + float((s + i * 23) % 24),
			py + 8.0 + float((s + i * 37) % 24),
			10.0 + float((s + i * 7) % 6)])
	for b in blobs:
		draw_circle(Vector2(b[0] + 1.5, b[1] + 1.5), b[2], Color(0.02, 0.06, 0.01, 0.6))
	for b in blobs:
		draw_circle(Vector2(b[0], b[1]), b[2], Color(0.05, 0.18, 0.03, 0.95))
	for b in blobs:
		draw_circle(Vector2(b[0], b[1] - 1.0), b[2] * 0.8, Color(0.08, 0.30, 0.05, 0.85))
	for i in range(4):
		draw_circle(Vector2(px + 5.0 + float((s + i * 41) % 30), py + 5.0 + float((s + i * 53) % 30)),
			4.0, Color(0.14, 0.36, 0.08, 0.4))
	for i in range(6):
		draw_circle(Vector2(px + 3.0 + float((s + i * 29) % 34), py + 3.0 + float((s + i * 43) % 34)),
			2.0, Color(0.20, 0.44, 0.12, 0.3))

# --- Forest Pattern B: Large overlapping layered crowns ---
func _forest_variant_1(x: int, y: int, px: float, py: float, s: int) -> void:
	var positions: Array[Array] = [
		[px + CELL_SIZE * 0.3, py + CELL_SIZE * 0.35],
		[px + CELL_SIZE * 0.65, py + CELL_SIZE * 0.45],
		[px + CELL_SIZE * 0.5, py + CELL_SIZE * 0.7],
	]
	for i in range(positions.size()):
		var bx: float = positions[i][0] + float((s + i * 17) % 5)
		var by: float = positions[i][1] + float((s + i * 29) % 5)
		var r: float = 14.0 - float(i) * 1.5
		draw_circle(Vector2(bx + 1.5, by + 2.0), r, Color(0.02, 0.05, 0.01, 0.5))
		draw_circle(Vector2(bx, by), r, Color(0.04, 0.16, 0.03, 0.95))
		draw_circle(Vector2(bx - 1.0, by - 1.5), r * 0.75, Color(0.10, 0.28, 0.06, 0.7))
		draw_circle(Vector2(bx - 2.0, by - 3.0), r * 0.4, Color(0.16, 0.38, 0.10, 0.4))
	for i in range(7):
		draw_circle(Vector2(px + 4.0 + float((s + i * 31) % 32), py + 4.0 + float((s + i * 47) % 32)),
			1.5 + float(i % 3), Color(0.18, 0.42, 0.10, 0.35))


# --- Forest Pattern D: Bushy shrub cluster ---
func _forest_variant_3(x: int, y: int, px: float, py: float, s: int) -> void:
	draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.04, 0.11, 0.03))
	for i in range(6):
		var bx: float = px + 6.0 + float((s + i * 23) % 28)
		var by: float = py + 6.0 + float((s + i * 37) % 28)
		var br: float = 7.0 + float((s + i * 11) % 5)
		draw_circle(Vector2(bx + 1.0, by + 1.0), br, Color(0.02, 0.06, 0.01, 0.4))
		draw_circle(Vector2(bx, by), br, Color(0.06, 0.20, 0.04, 0.9))
		draw_circle(Vector2(bx, by), br * 0.7, Color(0.10, 0.30, 0.06, 0.6))
		draw_circle(Vector2(bx - 1.0, by - 1.0), br * 0.35, Color(0.16, 0.40, 0.10, 0.35))
	for i in range(4):
		var fx: float = px + 5.0 + float((s + i * 43) % 30)
		var fy: float = py + 5.0 + float((s + i * 59) % 30)
		draw_circle(Vector2(fx, fy), 1.5, Color(0.25, 0.45, 0.12, 0.4))
	for i in range(5):
		var lx: float = px + 3.0 + float((s + i * 29) % 34)
		var ly: float = py + 3.0 + float((s + i * 47) % 34)
		draw_line(Vector2(lx, ly), Vector2(lx + 3.0, ly - 2.0), Color(0.12, 0.30, 0.06, 0.25), 1.0)

# --- Forest Pattern E: Dark jungle with vine lines ---
func _forest_variant_4(x: int, y: int, px: float, py: float, s: int) -> void:
	draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.03, 0.09, 0.02))
	var big: Array[Array] = [
		[px + 12.0 + float((s * 3) % 8), py + 14.0 + float((s * 5) % 8), 15.0],
		[px + 28.0 + float((s * 7) % 6), py + 22.0 + float((s * 11) % 6), 13.0],
	]
	for b in big:
		draw_circle(Vector2(b[0] + 1.5, b[1] + 1.5), b[2], Color(0.01, 0.04, 0.01, 0.6))
		draw_circle(Vector2(b[0], b[1]), b[2], Color(0.04, 0.14, 0.02, 0.95))
		draw_circle(Vector2(b[0], b[1] - 1.5), b[2] * 0.8, Color(0.07, 0.24, 0.04, 0.8))
	for i in range(3):
		var sx: float = px + 5.0 + float((s + i * 31) % 30)
		var sy: float = py + 5.0 + float((s + i * 43) % 30)
		draw_circle(Vector2(sx, sy), 8.0, Color(0.05, 0.16, 0.03, 0.85))
		draw_circle(Vector2(sx, sy), 5.0, Color(0.09, 0.26, 0.05, 0.6))
	for i in range(3):
		var vx: float = px + float((s + i * 19) % 30)
		var vy: float = py
		var vpts: PackedVector2Array = PackedVector2Array()
		for d in range(0, CELL_SIZE + 1, 5):
			vpts.append(Vector2(vx + sin(float(d) * 0.5 + i) * 4.0, vy + float(d)))
		if vpts.size() >= 2:
			draw_polyline(vpts, Color(0.06, 0.20, 0.04, 0.35), 1.5)
	for i in range(6):
		draw_circle(Vector2(px + 2.0 + float((s + i * 41) % 36), py + 2.0 + float((s + i * 53) % 36)),
			1.5, Color(0.12, 0.28, 0.06, 0.3))

func _draw_river_tile(x: int, y: int, px: float, py: float) -> void:
	var variant: int
	if y >= 0 and y < river_variants.size() and x >= 0 and x < river_variants[y].size() and river_variants[y][x] >= 0:
		variant = river_variants[y][x]
	else:
		variant = (x * 89 + y * 163) % 5
	var s: int = x * 61 + y * 113
	match variant:
		0: _river_variant_0(x, y, px, py, s)
		1: _river_variant_1(x, y, px, py, s)
		2: _river_variant_2(x, y, px, py, s)
		3: _river_variant_3(x, y, px, py, s)
		4: _river_variant_4(x, y, px, py, s)

# --- River Pattern A: Horizontal sine waves ---
func _river_variant_0(x: int, y: int, px: float, py: float, s: int) -> void:
	draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.05, 0.12, 0.28))
	draw_rect(Rect2(px + 2, py + 2, CELL_SIZE - 4, CELL_SIZE - 4), Color(0.04, 0.10, 0.24, 0.5))
	var wave_off: float = anim_timer * 2.5 + float(x) * 0.9 + float(y) * 0.4
	for w in range(3):
		var wy: float = py + 8.0 + float(w) * 12.0
		var pts: PackedVector2Array = PackedVector2Array()
		for d in range(0, CELL_SIZE + 1, 3):
			var wx: float = px + float(d)
			var wwy: float = wy + sin(wave_off + float(d) * 0.28 + float(w) * 1.8) * 2.0
			pts.append(Vector2(wx, wwy))
		if pts.size() >= 2:
			draw_polyline(pts, Color(0.2, 0.38, 0.65, 0.3), 1.5)
	_river_sparkles(x, y, px, py, s)

# --- River Pattern B: Diagonal flow lines ---
func _river_variant_1(x: int, y: int, px: float, py: float, s: int) -> void:
	draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.04, 0.11, 0.26))
	var flow_off: float = anim_timer * 3.0 + float(x) * 1.2 + float(y) * 0.7
	for i in range(5):
		var ly: float = py - 10.0 + float(i) * 12.0 + fmod(flow_off, 12.0)
		var pts: PackedVector2Array = PackedVector2Array()
		for d in range(0, CELL_SIZE + 20, 3):
			var dx: float = px + float(d)
			var dy: float = ly + float(d) * 0.6 + sin(flow_off + float(d) * 0.2) * 1.5
			if dy >= py and dy <= py + CELL_SIZE:
				pts.append(Vector2(dx, dy))
		if pts.size() >= 2:
			draw_polyline(pts, Color(0.18, 0.35, 0.60, 0.35), 1.5)
	_river_sparkles(x, y, px, py, s)

# --- River Pattern C: Concentric ripples ---
func _river_variant_2(x: int, y: int, px: float, py: float, s: int) -> void:
	draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.05, 0.13, 0.30))
	draw_rect(Rect2(px + 2, py + 2, CELL_SIZE - 4, CELL_SIZE - 4), Color(0.04, 0.11, 0.25, 0.5))
	var rcx: float = px + CELL_SIZE * 0.5
	var rcy: float = py + CELL_SIZE * 0.5
	var ripple_off: float = anim_timer * 2.0 + float(x) + float(y)
	for r in range(3):
		var base_r: float = 4.0 + float(r) * 6.0
		var rr: float = base_r + sin(ripple_off + float(r) * 2.0) * 2.0
		if rr > 1.0:
			draw_circle(Vector2(rcx, rcy), rr, Color(0.15, 0.30, 0.55, 0.25), false, 1.5)
	_river_sparkles(x, y, px, py, s)

# --- River Pattern D: Deep water with caustic light ---
func _river_variant_3(x: int, y: int, px: float, py: float, s: int) -> void:
	draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.03, 0.08, 0.22))
	draw_rect(Rect2(px + 3, py + 3, CELL_SIZE - 6, CELL_SIZE - 6), Color(0.03, 0.07, 0.20, 0.6))
	var caus_off: float = anim_timer * 1.8 + float(x) * 2.1 + float(y) * 1.3
	for i in range(4):
		var lx: float = px + 6.0 + float((s + i * 23) % 28)
		var ly: float = py + 6.0 + float((s + i * 37) % 28)
		var lsize: float = 3.0 + sin(caus_off + float(i) * 1.5) * 2.0
		if lsize > 1.0:
			draw_circle(Vector2(lx, ly), lsize, Color(0.15, 0.30, 0.55, 0.3))
			draw_circle(Vector2(lx - 1.0, ly - 1.0), lsize * 0.5, Color(0.25, 0.45, 0.70, 0.2))
	_river_sparkles(x, y, px, py, s)

# --- River Pattern E: Choppy waves with foam dots ---
func _river_variant_4(x: int, y: int, px: float, py: float, s: int) -> void:
	draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.06, 0.14, 0.30))
	var chop_off: float = anim_timer * 3.5 + float(x) * 1.5 + float(y) * 0.8
	for w in range(4):
		var wy: float = py + 5.0 + float(w) * 10.0
		var pts: PackedVector2Array = PackedVector2Array()
		for d in range(0, CELL_SIZE + 1, 2):
			var wx: float = px + float(d)
			var wwy: float = wy + sin(chop_off + float(d) * 0.4 + float(w) * 2.5) * 3.0
			pts.append(Vector2(wx, wwy))
		if pts.size() >= 2:
			draw_polyline(pts, Color(0.25, 0.42, 0.65, 0.35), 1.0)
		for f in range(2):
			var fx: float = px + 8.0 + float((s + w * 17 + f * 31) % 24)
			var fy: float = wy + sin(chop_off + float(fx - px) * 0.4) * 3.0
			if fy > py and fy < py + CELL_SIZE:
				draw_circle(Vector2(fx, fy), 1.5, Color(0.5, 0.65, 0.85, 0.3))
	_river_sparkles(x, y, px, py, s)

# --- Shared: animated sparkle for all river variants ---
func _river_sparkles(x: int, y: int, px: float, py: float, s: int) -> void:
	var sp1: float = sin(anim_timer * 3.5 + float(x) * 2.3 + float(y) * 1.7)
	if sp1 > 0.65:
		draw_circle(Vector2(px + CELL_SIZE * 0.55, py + CELL_SIZE * 0.35), 1.5, Color(0.5, 0.7, 1.0, sp1 * 0.35))
	var sp2: float = sin(anim_timer * 2.8 + float(x) * 1.1 + float(y) * 2.9 + 2.0)
	if sp2 > 0.7:
		draw_circle(Vector2(px + CELL_SIZE * 0.3, py + CELL_SIZE * 0.7), 1.2, Color(0.5, 0.7, 1.0, sp2 * 0.25))

# --- Mountain tile: cohesive hill with matching background ---
func _draw_mountain_tile(x: int, y: int, px: float, py: float) -> void:
	var s: int = x * 71 + y * 131
	
	# 1. 先填充整个格子的山体背景色（与山同色系）
	var bg_color: Color = Color(0.42, 0.30, 0.20)       # 基础棕褐色背景
	var bg_shadow: Color = Color(0.38, 0.27, 0.18)      # 背景阴影色
	draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), bg_color)
	# 添加细微纹理让背景不那么单调
	for i in range(6):
		var tx: float = px + float((s + i * 17) % 36)
		var ty: float = py + float((s + i * 23) % 36)
		draw_circle(Vector2(tx, ty), 1.5, bg_shadow)
	
	# Brown earthy colors for hills
	var shadow_color: Color = Color(0.35, 0.25, 0.16)
	var base_color: Color = Color(0.48, 0.35, 0.24)
	var mid_color: Color = Color(0.58, 0.43, 0.30)
	var light_color: Color = Color(0.68, 0.52, 0.38)
	var top_color: Color = Color(0.78, 0.62, 0.46)
	
	# Helper to draw soft elliptical blob
	var _draw_soft_blob = func(center_x: float, center_y: float, w: float, h: float, color: Color, seed: int) -> void:
		var rx: float = w * 0.5
		var ry: float = h * 0.5
		var num_circles: int = 8
		for i in range(num_circles):
			var angle: float = float(i) * TAU / float(num_circles)
			var offset_x: float = cos(angle) * rx * 0.3 + float((seed + i * 7) % 5) * 0.4 - 0.8
			var offset_y: float = sin(angle) * ry * 0.3 + float((seed + i * 11) % 5) * 0.4 - 0.8
			var r: float = min(rx, ry) * 0.7
			draw_circle(Vector2(center_x + offset_x, center_y + offset_y), r, color)
		draw_circle(Vector2(center_x, center_y), min(rx, ry) * 0.9, color)
	
	# 2. 底部宽大基础（扁平椭圆）
	for i in range(4):
		var bx: float = px + 6.0 + float((s + i * 23) % 24)
		var by: float = py + 22.0 + float((s + i * 37) % 10)
		var bw: float = 16.0 + float((s + i * 13) % 8)
		var bh: float = 10.0 + float((s + i * 17) % 6)
		_draw_soft_blob.call(bx + 1.0, by + 1.0, bw, bh, shadow_color, s + i * 7)
		_draw_soft_blob.call(bx, by, bw, bh, base_color, s + i * 7)
	
	# 3. 中层隆起（椭圆堆叠）
	for i in range(3):
		var mx: float = px + 8.0 + float((s + i * 31) % 20)
		var my: float = py + 14.0 + float((s + i * 43) % 12)
		var mw: float = 14.0 + float((s + i * 17) % 6)
		var mh: float = 12.0 + float((s + i * 19) % 5)
		_draw_soft_blob.call(mx, my, mw, mh, mid_color, s + i * 11 + 100)
	
	# 4. 上层收缩（更圆）
	for i in range(3):
		var ux: float = px + 12.0 + float((s + i * 29) % 16)
		var uy: float = py + 8.0 + float((s + i * 41) % 8)
		var uw: float = 10.0 + float((s + i * 13) % 5)
		var uh: float = 9.0 + float((s + i * 17) % 4)
		_draw_soft_blob.call(ux, uy, uw, uh, light_color, s + i * 13 + 200)
	
	# 5. 顶部圆润峰（小圆堆叠）
	for i in range(2):
		var tx: float = px + 16.0 + float((s + i * 19) % 10)
		var ty: float = py + 5.0 + float((s + i * 23) % 6)
		var tw: float = 7.0 + float((s + i * 11) % 4)
		var th: float = 6.0 + float((s + i * 7) % 3)
		_draw_soft_blob.call(tx, ty, tw, th, top_color, s + i * 17 + 300)
	
	# 6. 岩石点缀（小圆点）
	for i in range(4):
		var rx: float = px + 10.0 + float((s + i * 47) % 20)
		var ry: float = py + 12.0 + float((s + i * 53) % 16)
		var rsize: float = 1.5 + float((s + i * 13) % 3)
		draw_circle(Vector2(rx + 0.5, ry + 0.5), rsize, Color(0.28, 0.20, 0.13))
		draw_circle(Vector2(rx, ry), rsize, Color(0.38, 0.28, 0.18))
		draw_circle(Vector2(rx - 0.3, ry - 0.3), rsize * 0.4, Color(0.52, 0.40, 0.28))
	
	# 7. 底部草丛（小椭圆点缀）
	for i in range(3):
		var gx: float = px + 8.0 + float((s + i * 37) % 24)
		var gy: float = py + CELL_SIZE - 3.0 + float((s + i * 29) % 4)
		draw_circle(Vector2(gx, gy), 2.5, Color(0.35, 0.45, 0.22))
		draw_circle(Vector2(gx - 0.5, gy - 0.5), 1.0, Color(0.45, 0.58, 0.28))

# --- Volcano tile: dark brown cone with magma pattern ---
func _draw_volcano_tile(x: int, y: int, px: float, py: float) -> void:
	var s: int = x * 89 + y * 157
	
	# Dark brown/black base
	var base_color: Color = Color(0.28, 0.20, 0.15)
	var dark_color: Color = Color(0.20, 0.14, 0.10)
	var rock_color: Color = Color(0.35, 0.25, 0.18)
	
	# Fill background
	draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), base_color)
	
	# Draw volcano cone (triangular shape with gradient)
	var center_x: float = px + CELL_SIZE * 0.5
	var base_y: float = py + CELL_SIZE - 2.0
	var peak_y: float = py + 6.0
	
	# Main cone body (dark triangle)
	var cone_points: PackedVector2Array = PackedVector2Array([
		Vector2(px + 4.0, base_y),
		Vector2(center_x, peak_y),
		Vector2(px + CELL_SIZE - 4.0, base_y)
	])
	draw_polygon(cone_points, PackedColorArray([dark_color]))
	
	# Left highlight
	var left_points: PackedVector2Array = PackedVector2Array([
		Vector2(px + 4.0, base_y),
		Vector2(center_x, peak_y),
		Vector2(center_x - 8.0, base_y)
	])
	draw_polygon(left_points, PackedColorArray([base_color]))
	
	# Magma pattern flowing from top to one side
	# Find flow direction based on seed
	var flow_side: int = s % 4  # 0=left, 1=right, 2=bottom-left, 3=bottom-right
	
	# Magma streams
	var magma_color: Color = Color(0.9, 0.25, 0.1)
	var magma_glow: Color = Color(1.0, 0.5, 0.2)
	
	# Central magma at peak
	draw_circle(Vector2(center_x, peak_y + 4.0), 4.0, magma_color)
	draw_circle(Vector2(center_x, peak_y + 3.0), 2.5, magma_glow)
	
	# Flowing magma stream
	match flow_side:
		0:  # Flow left
			for i in range(4):
				var mx: float = center_x - 4.0 - float(i * 5)
				var my: float = peak_y + 6.0 + float(i * 6) + float((s + i) % 3)
				draw_circle(Vector2(mx, my), 3.5 - float(i) * 0.5, magma_color)
				draw_circle(Vector2(mx, my - 1.0), 2.0 - float(i) * 0.3, magma_glow)
		1:  # Flow right
			for i in range(4):
				var mx: float = center_x + 4.0 + float(i * 5)
				var my: float = peak_y + 6.0 + float(i * 6) + float((s + i) % 3)
				draw_circle(Vector2(mx, my), 3.5 - float(i) * 0.5, magma_color)
				draw_circle(Vector2(mx, my - 1.0), 2.0 - float(i) * 0.3, magma_glow)
		2:  # Flow bottom-left
			for i in range(4):
				var mx: float = center_x - 3.0 - float(i * 4)
				var my: float = peak_y + 8.0 + float(i * 5)
				draw_circle(Vector2(mx, my), 3.5 - float(i) * 0.5, magma_color)
				draw_circle(Vector2(mx + 1.0, my - 1.0), 2.0 - float(i) * 0.3, magma_glow)
		3:  # Flow bottom-right
			for i in range(4):
				var mx: float = center_x + 3.0 + float(i * 4)
				var my: float = peak_y + 8.0 + float(i * 5)
				draw_circle(Vector2(mx, my), 3.5 - float(i) * 0.5, magma_color)
				draw_circle(Vector2(mx - 1.0, my - 1.0), 2.0 - float(i) * 0.3, magma_glow)
	
	# Dark rocks scattered on volcano
	for i in range(5):
		var rx: float = px + 6.0 + float((s + i * 23) % 28)
		var ry: float = py + 10.0 + float((s + i * 31) % 20)
		var rsize: float = 1.5 + float((s + i * 13) % 3)
		draw_circle(Vector2(rx, ry), rsize, rock_color)
	
	# Small smoke particles at top
	for i in range(3):
		var sx: float = center_x + float((s + i * 17) % 8) - 4.0
		var sy: float = peak_y - 2.0 - float((s + i * 11) % 6)
		var alpha: float = 0.3 + float((s + i * 7) % 4) / 10.0
		draw_circle(Vector2(sx, sy), 1.5 + float(i), Color(0.4, 0.35, 0.3, alpha))

# --- Burning effect: fire particles on snake ---
func _draw_burning_effect(center: Vector2, radius: float) -> void:
	var s: int = int(center.x * 100.0 + center.y * 100.0) + int(anim_timer * 60.0)
	
	# Fire colors
	var core_color: Color = Color(1.0, 0.9, 0.3)    # Yellow core
	var mid_color: Color = Color(1.0, 0.5, 0.1)     # Orange
	var edge_color: Color = Color(0.9, 0.2, 0.05)   # Red
	
	# Multiple flame particles
	var num_flames: int = 4
	for i in range(num_flames):
		var angle: float = float(i) * TAU / float(num_flames) + anim_timer * 3.0 + float(s % 10) * 0.1
		var dist: float = radius * (0.3 + float((s + i * 17) % 30) / 100.0)
		var fx: float = center.x + cos(angle) * dist
		var fy: float = center.y + sin(angle) * dist - radius * 0.2  # Flames go upward
		
		var flicker: float = 0.7 + 0.3 * sin(anim_timer * 8.0 + float(i) * 2.0)
		var fsize: float = radius * (0.25 + 0.15 * flicker)
		
		# Outer flame (red)
		draw_circle(Vector2(fx, fy), fsize, edge_color)
		# Middle flame (orange)
		draw_circle(Vector2(fx, fy - fsize * 0.2), fsize * 0.7, mid_color)
		# Core flame (yellow)
		draw_circle(Vector2(fx, fy - fsize * 0.4), fsize * 0.4, core_color)
	
	# Rising sparks
	for i in range(3):
		var spark_t: float = (anim_timer * 2.0 + float(i) * 0.7) 
		var spark_y: float = center.y - radius * 0.5 - fmod(spark_t, 1.0) * radius * 0.8
		var spark_x: float = center.x + sin(spark_t * 3.0 + float(i)) * radius * 0.3
		var spark_alpha: float = 1.0 - fmod(spark_t, 1.0)
		draw_circle(Vector2(spark_x, spark_y), 1.5, Color(1.0, 0.6, 0.2, spark_alpha))

# --- Magma tile: flowing fire-red lava streams ---
func _draw_magma_tile(x: int, y: int, px: float, py: float) -> void:
	var s: int = x * 97 + y * 163
	var anim_offset: float = anim_timer * 3.0
	
	# Dark rock base
	draw_rect(Rect2(px, py, CELL_SIZE, CELL_SIZE), Color(0.20, 0.12, 0.08))
	
	# Fire-red lava colors
	var lava_dark: Color = Color(0.7, 0.1, 0.05)      # 深红
	var lava_mid: Color = Color(0.9, 0.2, 0.05)        # 火红
	var lava_bright: Color = Color(1.0, 0.35, 0.08)    # 橙红
	var lava_core: Color = Color(1.0, 0.55, 0.15)      # 亮橙黄核心
	
	# Draw flowing lava streams (elongated, flowing shapes)
	var stream_count: int = 3
	for i in range(stream_count):
		# Flow direction based on seed and animation
		var flow_angle: float = float(s + i * 73) * 0.5 + anim_offset * 0.4
		var flow_x: float = cos(flow_angle)
		var flow_y: float = sin(flow_angle)
		
		# Stream start position
		var sx: float = px + 8.0 + float((s + i * 31) % 24)
		var sy: float = py + 8.0 + float((s + i * 47) % 24)
		
		# Draw flowing stream (series of elongated circles)
		var stream_length: int = 5
		for j in range(stream_length):
			var t: float = float(j) / float(stream_length)
			var bx: float = sx + flow_x * t * 25.0 + sin(anim_offset + t * 3.0 + float(i)) * 3.0
			var by: float = sy + flow_y * t * 25.0 + cos(anim_offset * 0.7 + t * 2.0 + float(i)) * 2.0
			var width: float = 6.0 * (1.0 - t * 0.5) + sin(anim_offset * 2.0 + float(j)) * 1.5
			
			# Outer glow (dark red)
			draw_circle(Vector2(bx, by), width + 2.0, lava_dark)
			# Mid layer (fire red)
			draw_circle(Vector2(bx, by), width, lava_mid)
			# Bright core
			if j < stream_length - 1:
				draw_circle(Vector2(bx, by), width * 0.5, lava_bright)
				# Hot core
				draw_circle(Vector2(bx + flow_x, by + flow_y), width * 0.25, lava_core)
	
	# Bubbling lava pools
	for i in range(4):
		var bx: float = px + 6.0 + float((s + i * 23) % 28)
		var by: float = py + 6.0 + float((s + i * 37) % 28)
		var pulse: float = sin(anim_offset * 2.0 + float(i) * 1.5) * 0.3 + 0.7
		var br: float = (3.0 + float((s + i * 11) % 5)) * pulse
		
		draw_circle(Vector2(bx, by), br + 1.5, lava_dark)
		draw_circle(Vector2(bx, by), br, lava_mid)
		draw_circle(Vector2(bx, by), br * 0.4, lava_bright)
	
	# Flowing cracks with fire glow
	for i in range(4):
		var cx1: float = px + 5.0 + float((s + i * 29) % 30)
		var cy1: float = py + 5.0 + float((s + i * 31) % 30)
		var angle: float = float(s + i * 53) * 0.3 + anim_offset * 0.2
		var cx2: float = cx1 + cos(angle) * 15.0
		var cy2: float = cy1 + sin(angle) * 15.0
		
		# Crack edge
		draw_line(Vector2(cx1, cy1), Vector2(cx2, cy2), lava_dark, 3.0)
		# Crack core (bright)
		draw_line(Vector2(cx1, cy1), Vector2(cx2, cy2), lava_mid, 2.0)
		# Crack center (fire)
		draw_line(Vector2(cx1, cy1), Vector2(cx2, cy2), lava_bright, 1.0)
	
	# Rising heat sparks
	for i in range(5):
		var spark_x: float = px + 6.0 + float((s + i * 17 + int(anim_offset * 5.0)) % 28)
		var spark_y: float = py + 4.0 + float((s + i * 19 + int(anim_offset * 8.0)) % 32)
		var spark_alpha: float = 0.6 + sin(anim_offset * 4.0 + float(i) * 2.0) * 0.3
		draw_circle(Vector2(spark_x, spark_y), 1.5, Color(1.0, 0.5, 0.1, spark_alpha))

func _draw_overlay(alpha: float) -> void:
	draw_rect(Rect2(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE), Color(0, 0, 0, alpha))

func _draw_centered_text(text: String, y: float, size: int, color: Color) -> void:
	var font = ThemeDB.fallback_font
	var ss := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
	var x: float = (GRID_WIDTH * CELL_SIZE - ss.x) / 2.0
	draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

# =========================================================
# Drawing - Chevron Helpers (Speed Up / Speed Down icons)
# =========================================================

func _draw_chevron_right(cx: float, cy: float, arm: float, color: Color, width: float = 3.0) -> void:
	var shadow: Color = Color(0.0, 0.0, 0.0, color.a * 0.4)
	draw_line(Vector2(cx - arm + 1.0, cy - arm + 1.0), Vector2(cx + 1.0, cy + 1.0), shadow, width)
	draw_line(Vector2(cx - arm + 1.0, cy + arm + 1.0), Vector2(cx + 1.0, cy + 1.0), shadow, width)
	draw_line(Vector2(cx - arm, cy - arm), Vector2(cx, cy), color, width)
	draw_line(Vector2(cx - arm, cy + arm), Vector2(cx, cy), color, width)

func _draw_chevron_left(cx: float, cy: float, arm: float, color: Color, width: float = 3.0) -> void:
	var shadow: Color = Color(0.0, 0.0, 0.0, color.a * 0.4)
	draw_line(Vector2(cx + arm + 1.0, cy - arm + 1.0), Vector2(cx + 1.0, cy + 1.0), shadow, width)
	draw_line(Vector2(cx + arm + 1.0, cy + arm + 1.0), Vector2(cx + 1.0, cy + 1.0), shadow, width)
	draw_line(Vector2(cx + arm, cy - arm), Vector2(cx, cy), color, width)
	draw_line(Vector2(cx + arm, cy + arm), Vector2(cx, cy), color, width)

# =========================================================
# Drawing - Active Effect Countdown (top-right corner)
# =========================================================

func _draw_effect_countdown(W: float, H: float, idx: int, label: String, timer_val: float, max_val: float, bar_color: Color, icon: String) -> void:
	var font = ThemeDB.fallback_font
	var remaining: int = ceili(timer_val)
	var progress: float = clampf(timer_val / max_val, 0.0, 1.0)

	# Pill layout
	var pill_w: float = 120.0
	var pill_h: float = 28.0
	var pill_x: float = W - pill_w - 12.0
	var pill_y: float = 10.0 + float(idx) * (pill_h + 6.0)
	var pill_rect: Rect2 = Rect2(pill_x, pill_y, pill_w, pill_h)

	# Warning pulse when time is low
	var alpha: float = 1.0
	if timer_val <= 3.0 and timer_val > 0.0:
		var warn: float = abs(sin(anim_timer * 6.0))
		if warn > 0.5:
			alpha = 0.45

	# Outer glow
	var glow_alpha: float = 0.08 * alpha * progress
	_draw_rounded_rect(pill_rect.grow(6), Color(bar_color.r, bar_color.g, bar_color.b, glow_alpha), 15)

	# Dark background
	_draw_rounded_rect(pill_rect, Color(0.05, 0.06, 0.1, 0.85 * alpha), 10)

	# Progress fill bar (left side, icon area + behind text)
	var fill_w: float = (pill_w - 4.0) * progress
	if fill_w > 2.0:
		var fill_rect: Rect2 = Rect2(pill_x + 2.0, pill_y + 2.0, fill_w, pill_h - 4.0)
		var fill_color: Color = Color(bar_color.r, bar_color.g, bar_color.b, 0.22 * alpha)
		_draw_rounded_rect(fill_rect, fill_color, 8)

	# Border (brighter when more time left)
	var border_alpha: float = (0.4 + 0.4 * progress) * alpha
	_draw_rounded_rect(pill_rect, Color(bar_color.r, bar_color.g, bar_color.b, border_alpha), 10, false, 1.5)

	# Icon (left section, colored circle + letter)
	var icon_cx: float = pill_x + 16.0
	var icon_cy: float = pill_y + pill_h / 2.0
	var icon_r: float = 9.0
	draw_circle(Vector2(icon_cx, icon_cy), icon_r, Color(bar_color.r, bar_color.g, bar_color.b, 0.3 * alpha))
	draw_circle(Vector2(icon_cx, icon_cy), icon_r - 1.0, Color(bar_color.r, bar_color.g, bar_color.b, 0.5 * alpha))
	var icon_ts: Vector2 = font.get_string_size(icon, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	draw_string(font, Vector2(icon_cx - icon_ts.x / 2.0, pill_y + (pill_h - icon_ts.y) / 2.0 + font.get_ascent(13)),
		icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 1.0, 1.0, 0.95 * alpha))

	# Countdown number (right section, large and bold)
	var num_text: String = str(remaining)
	var sec_text: String = "s"
	var num_sz: int = 18
	var sec_sz: int = 11
	var num_ts: Vector2 = font.get_string_size(num_text, HORIZONTAL_ALIGNMENT_LEFT, -1, num_sz)
	var sec_ts: Vector2 = font.get_string_size(sec_text, HORIZONTAL_ALIGNMENT_LEFT, -1, sec_sz)
	var total_tw: float = num_ts.x + sec_ts.x + 1.0
	var text_start_x: float = icon_cx + icon_r + 8.0
	var text_block_w: float = pill_x + pill_w - text_start_x - 8.0
	var text_block_x: float = text_start_x + (text_block_w - total_tw) / 2.0

	# Number (shadow + main)
	var num_ty: float = pill_y + (pill_h - num_ts.y) / 2.0 + font.get_ascent(num_sz)
	draw_string(font, Vector2(text_block_x + 1, num_ty + 1), num_text, HORIZONTAL_ALIGNMENT_LEFT, -1, num_sz, Color(0, 0, 0, 0.5 * alpha))
	draw_string(font, Vector2(text_block_x, num_ty), num_text, HORIZONTAL_ALIGNMENT_LEFT, -1, num_sz, Color(1.0, 1.0, 1.0, 1.0 * alpha))
	text_block_x += num_ts.x + 1.0

	# "s" suffix (same baseline as number)
	draw_string(font, Vector2(text_block_x, num_ty), sec_text, HORIZONTAL_ALIGNMENT_LEFT, -1, sec_sz, Color(bar_color.r, bar_color.g, bar_color.b, 0.85 * alpha))


func _draw_rounded_rect(rect: Rect2, color: Color, radius: float, filled: bool = true, width: float = -1.0) -> void:
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
		draw_colored_polygon(pts, color)
	else:
		draw_rect(rect, color, false, width)

# =========================================================
# Persistence
# =========================================================

func _load_high_score() -> void:
	var file = FileAccess.open("user://snake_highscore.txt", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		if content.is_valid_int():
			high_score = int(content)
		file.close()

func _save_high_score() -> void:
	var file = FileAccess.open("user://snake_highscore.txt", FileAccess.WRITE)
	if file:
		file.store_string(str(high_score))
		file.close()
		
# =========================================================
# 优化系统初始化
# =========================================================

func _init_particle_pool() -> void:
	_particle_pool.clear()
	_particle_active_count = 0
	
	for i in range(OPTIMIZED_MAX_PARTICLES):
		_particle_pool.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2.ZERO,
			"life": 0.0,
			"max_life": 0.0,
			"color": Color.WHITE,
			"size": 0.0,
			"active": false,
		})

func _init_floating_text_pool() -> void:
	_floating_text_pool.clear()
	_floating_text_active_count = 0
	
	for i in range(OPTIMIZED_MAX_FLOATING_TEXTS):
		_floating_text_pool.append({
			"text": "",
			"pos": Vector2.ZERO,
			"life": 0.0,
			"color": Color.WHITE,
			"size": 16,
			"active": false,
		})
