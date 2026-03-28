# GameConfig.gd - 统一游戏配置管理
# 所有游戏常量和可调参数的单一来源

extends Node
class_name GameConfig

# =========================================================
# 网格配置
# =========================================================
const DEFAULT_CELL_SIZE: int = 40
const DEFAULT_GRID_WIDTH: int = 20
const DEFAULT_GRID_HEIGHT: int = 20
const DRAW_MARGIN: int = 30

# =========================================================
# 特殊果实配置
# =========================================================
const SPECIAL_SPAWN_CHANCE: float = 0.30
const SPECIAL_FOOD_DURATION: float = 5.0
const SPECIAL_FOOD_SCORE: int = 30

# =========================================================
# 效果持续时间
# =========================================================
const GHOST_DURATION: float = 20.0
const GHOST_WARN_THRESHOLD: float = 5.0
const WALL_STOP_DURATION: float = 15.0
const WALL_PASS_DURATION: float = 15.0
const FOOD_RAIN_MIN: int = 4
const FOOD_RAIN_MAX: int = 8

# =========================================================
# 速度控制
# =========================================================
const SPEED_UP_AMOUNT: float = 0.005
const SPEED_DOWN_AMOUNT: float = 0.005
const SPEED_DEATH_THRESHOLD: float = 0.005
const INITIAL_GAME_SPEED: float = 0.3
const MIN_GAME_SPEED: float = 0.05
const MAX_GAME_SPEED: float = 0.6

# =========================================================
# 加速（长按）
# =========================================================
const BOOST_MULTIPLIER: float = 0.5
const BOOST_HOLD_THRESHOLD: float = 0.5
const BOOST_GLOW_INCREASE: float = 0.15
const BOOST_GLOW_DECREASE: float = 0.08

# =========================================================
# 陷阱果实配置
# =========================================================
const TRAP_SPAWN_CHANCE: float = 0.10
const TRAP_PENALTY: int = 100
const TRAP_REVEAL_DIST: int = 3
const TRAP_BLINK_INTERVAL: float = 0.18
const TRAP_COUNTDOWN_MAX: float = 5.0
const TRAP_SHRINK_SEGMENTS: int = 10

# =========================================================
# 食物生命周期
# =========================================================
const FOOD_LIFETIME: float = 10.0
const FOOD_WARN_THRESHOLD: float = 3.0

# =========================================================
# 地形配置
# =========================================================
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

# =========================================================
# 虫洞配置
# =========================================================
const MAX_WORMHOLE_PAIRS: int = 2
const WORMHOLE_MIN_DIST: int = 5

# =========================================================
# 关卡门配置
# =========================================================
const GATE_OPEN_SCORE_PER_LEVEL: int = 50

# =========================================================
# 特殊果实类型
# =========================================================
enum SpecialType { GHOST, WALL_STOP, FOOD_RAIN, WALL_PASS, SPEED_UP, SPEED_DOWN }
const SPECIAL_TYPE_COUNT: int = 6

# =========================================================
# 粒子系统配置
# =========================================================
const MAX_PARTICLES: int = 80
const PARTICLE_MIN_LIFE: float = 0.3
const PARTICLE_MAX_LIFE: float = 0.8
const PARTICLE_MIN_SIZE: float = 2.0
const PARTICLE_MAX_SIZE: float = 5.0
const PARTICLE_FRICTION: float = 0.96
const PARTICLE_GRAVITY: float = 120.0

# =========================================================
# 浮动文字配置
# =========================================================
const FLOATING_TEXT_LIFETIME: float = 1.0
const FLOATING_TEXT_SPEED: float = 40.0

# =========================================================
# 屏幕震动配置
# =========================================================
const SCREEN_SHAKE_DECAY: float = 8.0
const SCREEN_SHAKE_INTENSITY: float = 4.0

# =========================================================
# 动画配置
# =========================================================
const FOOD_PULSE_SPEED: float = 5.0
const SPECIAL_BLINK_SPEED: float = 8.0
const GATE_ANIM_SPEED: float = 1.0

# =========================================================
# 蛇动画配置
# =========================================================
const EATING_ANIM_DURATION: float = 0.3
const TONGUE_FLICK_INTERVAL: float = 2.5
const TONGUE_FLICK_DURATION: float = 0.18
const BLINK_DURATION: float = 0.15
const BLINK_INTERVAL_MIN: float = 2.0
const BLINK_INTERVAL_MAX: float = 5.0

# =========================================================
# 连击系统
# =========================================================
const COMBO_DURATION: float = 8.0
const COMBO_THRESHOLD: int = 3
const COMBO_BONUS_MULTIPLIER: int = 2

# =========================================================
# 菜单配置
# =========================================================
enum MenuScreen { MAIN, HELP, HIGH_SCORE }
const MENU_ICONS: PackedStringArray = ["▶", "★", "?", "✕"]
const MENU_START_Y: float = 310.0
const MENU_SPACING: float = 70.0
const MENU_ITEM_W: float = 300.0
const MENU_ITEM_H: float = 52.0
const MENU_PARTICLE_COUNT: int = 35

# 暂停菜单
const PAUSE_ICONS: PackedStringArray = ["▶", "◀"]
const PAUSE_ITEMS_COUNT: int = 2

# =========================================================
# 分数配置
# =========================================================
const BASE_FOOD_SCORE: int = 10
const SPECIAL_FOOD_BASE_SCORE: int = 30
const COMBO_BONUS_PER_FOOD: int = 2

# =========================================================
# 音频配置
# =========================================================
const MENU_MUSIC_VOLUME: float = 0.15
const GAME_MUSIC_VOLUME: float = 0.6
const MUSIC_TEMPO_DEFAULT: float = 100.0

# =========================================================
# 颜色配置
# =========================================================

# 基础颜色
var bg_color: Color = Color(0.06, 0.08, 0.12, 1.0)
var grid_color: Color = Color(0.1, 0.13, 0.18, 1.0)
var border_color: Color = Color(0.3, 0.4, 0.55, 1.0)

# 蛇颜色
var head_color: Color = Color(0.22, 0.92, 0.45, 1.0)
var body_color: Color = Color(0.18, 0.82, 0.38, 1.0)
var tail_color: Color = Color(0.12, 0.62, 0.3, 1.0)
var eye_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var pupil_color: Color = Color(0.1, 0.1, 0.1, 1.0)

# 可爱蛇的颜色
var belly_color: Color = Color(0.38, 0.94, 0.52, 1.0)
var blush_color: Color = Color(1.0, 0.45, 0.5, 0.3)
var tongue_color: Color = Color(0.95, 0.3, 0.35, 0.9)
var scale_dot_color: Color = Color(0.1, 0.6, 0.28, 0.25)
var mouth_color: Color = Color(0.12, 0.08, 0.08, 1.0)

# 加速颜色
var boost_color: Color = Color(1.0, 0.6, 0.1, 1.0)
var boost_glow_color: Color = Color(1.0, 0.45, 0.0, 0.25)

# 幽灵效果
var ghost_head_color: Color = Color(0.35, 0.3, 1.0, 0.7)
var ghost_body_color: Color = Color(0.3, 0.25, 0.9, 0.6)
var ghost_tail_color: Color = Color(0.25, 0.2, 0.7, 0.5)

# 墙壁阻挡海绵
var sponge_color: Color = Color(0.92, 0.72, 0.08, 0.92)
var sponge_highlight: Color = Color(1.0, 0.92, 0.35, 0.85)
var sponge_dark: Color = Color(0.6, 0.42, 0.05, 0.88)
var sponge_bubble_color: Color = Color(1.0, 0.95, 0.5, 0.65)
var sponge_shine_color: Color = Color(1.0, 0.98, 0.7, 0.3)

# 墙壁传送门
var portal_color: Color = Color(0.6, 0.2, 0.9, 0.7)
var portal_glow: Color = Color(0.8, 0.4, 1.0, 0.25)

# 炸弹
var bomb_body_color: Color = Color(0.25, 0.22, 0.2, 1.0)
var bomb_highlight_color: Color = Color(0.45, 0.4, 0.38, 1.0)
var bomb_fuse_color: Color = Color(0.55, 0.45, 0.25, 1.0)

# 食物颜色
var food_color: Color = Color(1.0, 0.35, 0.35, 1.0)
var food_glow_color: Color = Color(1.0, 0.2, 0.2, 0.15)

# 特殊果实颜色
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

# 效果条颜色
var ghost_bar_color: Color = Color(0.5, 0.3, 1.0, 0.7)
var wallstop_bar_color: Color = Color(0.95, 0.78, 0.15, 0.8)
var wallpass_bar_color: Color = Color(0.6, 0.25, 0.9, 0.7)
var trap_bar_color: Color = Color(0.9, 0.3, 0.1, 0.7)

# 虫洞调色板
var wormhole_palettes: Array[Array] = [
	[Color(0.91, 0.28, 0.47), Color(1.0, 0.5, 0.65), Color(0.55, 0.12, 0.25), Color(0.91, 0.28, 0.47)],
	[Color(0.2, 0.6, 0.95), Color(0.45, 0.75, 1.0), Color(0.1, 0.3, 0.6), Color(0.2, 0.6, 0.95)],
]

# =========================================================
# 性能优化配置
# =========================================================
const ENABLE_PARTICLE_POOL: bool = true
const PARTICLE_POOL_SIZE: int = 100
const ENABLE_TERRAIN_CACHE: bool = true
const ENABLE_MESH_RENDERING: bool = false  # 如果启用，需要实现 mesh 渲染

# =========================================================
# 调试配置
# =========================================================
const SHOW_FPS: bool = false
const SHOW_COLLISION_BOXES: bool = false
const LOG_PERFORMANCE_METRICS: bool = false

# =========================================================
# 工具函数
# =========================================================

static func grid_distance(a: Vector2i, b: Vector2i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y))

static func clamp_float(value: float, min_val: float, max_val: float) -> float:
	return clampf(value, min_val, max_val)

static func random_range_float(min_val: float, max_val: float) -> float:
	return randf_range(min_val, max_val)

static func random_range_int(min_val: int, max_val: int) -> int:
	return randi_range(min_val, max_val)
