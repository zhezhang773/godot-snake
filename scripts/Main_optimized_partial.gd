# Main_optimized_final.gd
# 最终优化版本 - 基于原 Main.gd 修改
# 只优化粒子系统和浮动文字系统，其他保持不变

extends Node2D

# =========================================================
# 新增：系统引用
# =========================================================
var particle_system: Node2D
var floating_text_system: Node2D

# =========================================================
# Configuration (保持原样)
# =========================================================
const DEFAULT_CELL_SIZE: int = 40
const DEFAULT_GRID_WIDTH: int = 20
const DEFAULT_GRID_HEIGHT: int = 20
const DRAW_MARGIN: int = 30

const SPECIAL_SPAWN_CHANCE: float = 0.30
const SPECIAL_FOOD_DURATION: float = 5.0
const SPECIAL_FOOD_SCORE: int = 30

const GHOST_DURATION: float = 20.0
const GHOST_WARN_THRESHOLD: float = 5.0
const WALL_STOP_DURATION: float = 15.0
const WALL_PASS_DURATION: float = 15.0
const FOOD_RAIN_MIN: int = 4
const FOOD_RAIN_MAX: int = 8

const SPEED_UP_AMOUNT: float = 0.005
const SPEED_DOWN_AMOUNT: float = 0.005
const SPEED_DEATH_THRESHOLD: float = 0.005

const BOOST_MULTIPLIER: float = 0.5
const BOOST_HOLD_THRESHOLD: float = 0.5

const TRAP_SPAWN_CHANCE: float = 0.10
const TRAP_PENALTY: int = 100
const TRAP_REVEAL_DIST: int = 3
const TRAP_BLINK_INTERVAL: float = 0.18
const TRAP_COUNTDOWN_MAX: float = 5.0
const TRAP_SHRINK_SEGMENTS: int = 10

const FOOD_LIFETIME: float = 10.0
const FOOD_WARN_THRESHOLD: float = 3.0

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
const RIVER_SCORE_INTERVAL: float = 1.0
const RIVER_SCORE_PENALTY: int = 1

const MAX_WORMHOLE_PAIRS: int = 2
const GATE_OPEN_SCORE_PER_LEVEL: int = 50
const WORMHOLE_MIN_DIST: int = 5

enum SpecialType { GHOST, WALL_STOP, FOOD_RAIN, WALL_PASS, SPEED_UP, SPEED_DOWN }
const SPECIAL_TYPE_COUNT: int = 6

const MAX_PARTICLES: int = 80

enum MenuScreen { MAIN, HELP, HIGH_SCORE }
const MENU_ICONS: PackedStringArray = ["▶", "★", "?", "✕"]
const MENU_START_Y: float = 310.0
const MENU_SPACING: float = 70.0
const MENU_ITEM_W: float = 300.0
const MENU_ITEM_H: float = 52.0

const PAUSE_ICONS: PackedStringArray = ["▶", "◀"]
const PAUSE_ITEMS_COUNT: int = 2

# =========================================================
# Game State (保持原样)
# =========================================================
var score: int = 0
var total_score: int = 0
var high_score: int = 0
var game_over: bool = false
var game_started: bool = false
var game_speed: float = 0.15
var speed_timer: float = 0.0
var display_speed: float = 0.3

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

var tiles: Array = []
var river_variants: Array = []
var river_penalty_timer: float = 0.0

var wormholes: Array[Dictionary] = []
var wormhole_cooldown: bool = false

var wormhole_palettes: Array[Array] = [
	[Color(0.91, 0.28, 0.47), Color(1.0, 0.5, 0.65), Color(0.55, 0.12, 0.25), Color(0.91, 0.28, 0.47)],
	[Color(0.2, 0.6, 0.95), Color(0.45, 0.75, 1.0), Color(0.1, 0.3, 0.6), Color(0.2, 0.6, 0.95)],
]

var in_menu: bool = true
var current_menu_screen: int = MenuScreen.MAIN
var menu_selected: int = 0
var menu_anim: float = 0.0
var menu_particles: Array[Dictionary] = []

var boosted: bool = false
var boost_glow: float = 0.0
var boost_hold_timer: float = 0.0
var boost_hold_dir: Vector2i = Vector2i(0, 0)

var CELL_SIZE: int = DEFAULT_CELL_SIZE
var GRID_WIDTH: int = DEFAULT_GRID_WIDTH
var GRID_HEIGHT: int = DEFAULT_GRID_HEIGHT

var segments: Array[Vector2i] = []
var direction: Vector2i = Vector2i(1, 0)
var next_direction: Vector2i = Vector2i(1, 0)
var grow_pending: int = 0

var main_food_pos: Vector2i = Vector2i(8, 8)
var extra_foods: Array[Dictionary] = []
var food_spawn_time: float = 0.0
var food_time: float = 0.0

var trap_active: bool = false
var trap_revealed: bool = false
var trap_countdown: float = 0.0

var special_active: bool = false
var special_type: int = SpecialType.GHOST
var special_pos: Vector2i = Vector2i(-1, -1)
var special_timer: float = 0.0
var special_blink: float = 0.0

var ghost_active: bool = false
var ghost_timer: float = 0.0
var wall_stop_active: bool = false
var wall_stop_timer: float = 0.0
var wall_pass_active: bool = false
var wall_pass_timer: float = 0.0

# 注意：这些数组现在由新系统管理，这里保留是为了兼容性
var particles: Array[Dictionary] = []
var floating_texts: Array[Dictionary] = []

var food_pulse: float = 0.0
var screen_shake: float = 0.0
var anim_timer: float = 0.0

var eating_anim_timer: float = 0.0
var mouth_open: float = 0.0
var tongue_timer: float = 0.0
var tongue_flick_timer: float = 0.0
var blink_timer: float = 0.0
var is_blinking: bool = false
var next_blink_time: float = 3.0

var audio_manager: Node = null

var _lang_btn_rect: Rect2 = Rect2(0, 0, 0, 0)
var _menu_item_rects: Array[Rect2] = []
var _pause_item_rects: Array[Rect2] = []
var _gameover_btn_rects: Array[Rect2] = []

# Colors (保持原样)
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

var belly_color: Color = Color(0.38, 0.94, 0.52, 1.0)
var blush_color: Color = Color(1.0, 0.45, 0.5, 0.3)
var tongue_color: Color = Color(0.95, 0.3, 0.35, 0.9)
var scale_dot_color: Color = Color(0.1, 0.6, 0.28, 0.25)
var mouth_color: Color = Color(0.12, 0.08, 0.08, 1.0)

var boost_color: Color = Color(1.0, 0.6, 0.1, 1.0)
var boost_glow_color: Color = Color(1.0, 0.45, 0.0, 0.25)

var ghost_head_color: Color = Color(0.35, 0.3, 1.0, 0.7)
var ghost_body_color: Color = Color(0.3, 0.25, 0.9, 0.6)
var ghost_tail_color: Color = Color(0.25, 0.2, 0.7, 0.5)

var sponge_color: Color = Color(0.92, 0.72, 0.08, 0.92)
var sponge_highlight: Color = Color(1.0, 0.92, 0.35, 0.85)
var sponge_dark: Color = Color(0.6, 0.42, 0.05, 0.88)
var sponge_bubble_color: Color = Color(1.0, 0.95, 0.5, 0.65)
var sponge_shine_color: Color = Color(1.0, 0.98, 0.7, 0.3)

var portal_color: Color = Color(0.6, 0.2, 0.9, 0.7)
var portal_glow: Color = Color(0.8, 0.4, 1.0, 0.25)

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
}

var ghost_bar_color: Color = Color(0.5, 0.3, 1.0, 0.7)
var wallstop_bar_color: Color = Color(0.95, 0.78, 0.15, 0.8)
var wallpass_bar_color: Color = Color(0.6, 0.25, 0.9, 0.7)
var trap_bar_color: Color = Color(0.9, 0.3, 0.1, 0.7)

# =========================================================
# 新增：优化的粒子系统（内嵌，避免外部依赖）
# =========================================================

const OPTIMIZED_MAX_PARTICLES: int = 100
var _particle_pool: Array[Dictionary] = []
var _particle_active_count: int = 0

func _init_particle_pool() -> void:
	_particle_pool.clear()
	_particle_active_count = 0
	
	for i in range(OPTIMIZED_MAX_PARTICLES):
		_particle_pool.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.ZERO,
			"life": 0.0,
			"max_life": 0.0,
			"color": Color.WHITE,
			"size": 0.0,
			"active": false,
		})

func _spawn_optimized_particles(grid_pos: Vector2i, color: Color, count: int = 12, spread: float = 80.0) -> void:
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
			p["vel"] = Vector2(cos(angle), sin(angle)) * speed
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

func _update_optimized_particles(delta: float) -> void:
	for i in range(OPTIMIZED_MAX_PARTICLES):
		var p: Dictionary = _particle_pool[i]
		
		if not p["active"]:
			continue
		
		p["life"] -= delta
		
		if p["life"] <= 0.0:
			p["active"] = false
			_particle_active_count -= 1
			continue
		
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.96
		p["vel"].y += 120.0 * delta

func _draw_optimized_particles() -> void:
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
# 新增：优化的浮动文字系统（内嵌）
# =========================================================

const OPTIMIZED_MAX_FLOATING_TEXTS: int = 50
var _floating_text_pool: Array[Dictionary] = []
var _floating_text_active_count: int = 0

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

func _spawn_optimized_floating_text(text: String, grid_pos: Vector2i, color: Color, size: int = 16) -> void:
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

func _update_optimized_floating_texts(delta: float) -> void:
	for i in range(OPTIMIZED_MAX_FLOATING_TEXTS):
		var ft: Dictionary = _floating_text_pool[i]
		
		if not ft["active"]:
			continue
		
		ft["life"] -= delta
		ft["pos"].y -= 40.0 * delta
		
		if ft["life"] <= 0.0:
			ft["active"] = false
			_floating_text_active_count -= 1

func _draw_optimized_floating_texts() -> void:
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
# 修改后的函数（使用新系统）
# =========================================================

# 替换原来的 _spawn_particles
func _spawn_particles(grid_pos: Vector2i, color: Color, count: int = 12, spread: float = 80.0) -> void:
	_spawn_optimized_particles(grid_pos, color, count, spread)

# 替换原来的 _update_particles
func _update_particles(delta: float) -> void:
	_update_optimized_particles(delta)

# 替换原来的 _draw_particles
func _draw_particles() -> void:
	_draw_optimized_particles()

# 替换原来的 _spawn_floating_text
func _spawn_floating_text(text: String, grid_pos: Vector2i, color: Color, size: int = 16) -> void:
	_spawn_optimized_floating_text(text, grid_pos, color, size)

# 替换原来的 _update_floating_texts
func _update_floating_texts(delta: float) -> void:
	_update_optimized_floating_texts(delta)

# 替换原来的 _draw_floating_texts
func _draw_floating_texts() -> void:
	_draw_optimized_floating_texts()

# =========================================================
# 修改 _ready 初始化新系统
# =========================================================

func _ready() -> void:
	randomize()
	_load_high_score()
	audio_manager = get_node_or_null("AudioManager")
	
	# 初始化新系统
	_init_particle_pool()
	_init_floating_text_pool()
	
	_init_menu()
	_reset_game()
	_spawn_main_food()

# =========================================================
# 修改 _reset_game 清理新系统
# =========================================================

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
	
	# 清理新系统
	for i in range(OPTIMIZED_MAX_PARTICLES):
		_particle_pool[i]["active"] = false
	_particle_active_count = 0
	
	for i in range(OPTIMIZED_MAX_FLOATING_TEXTS):
		_floating_text_pool[i]["active"] = false
	_floating_text_active_count = 0
	
	tiles.clear()
	river_variants.clear()
	wormholes.clear()
	wormhole_cooldown = false
	gate_open = false
	gate_flash = 0.0
	_generate_terrain()
	_generate_gate()
	river_penalty_timer = 0.0
	game_speed = 0.3
	boosted = false
	boost_glow = 0.0
	boost_hold_timer = 0.0
	boost_hold_dir = Vector2i(0, 0)
	paused = false
	pause_selected = 0

# =========================================================
# 其余代码保持原样（从原 Main.gd 复制）
# 包括：
# - 所有输入处理函数
# - 所有游戏逻辑函数
# - 所有绘制函数
# - 地形系统
# - 虫洞系统
# - 关卡门系统
# - 存档系统
# =========================================================

# 注意：由于文件长度限制，这里只显示修改的部分
# 实际使用时，需要将原 Main.gd 的所有其他函数复制到这里

# [请复制原 Main.gd 中从第 200 行到文件末尾的所有代码]
