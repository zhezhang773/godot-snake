# ParticleSystem.gd - 优化的粒子系统
# 使用对象池模式减少 GC 压力

extends Node2D
class_name ParticleSystem

# =========================================================
# 粒子数据结构
# =========================================================
const MAX_PARTICLES: int = 100

var _pool: Array[Dictionary] = []
var _active_count: int = 0

# =========================================================
# 生命周期
# =========================================================

func _ready() -> void:
	_initialize_pool()

func _initialize_pool() -> void:
	_pool.clear()
	_active_count = 0
	
	for i in range(MAX_PARTICLES):
		_pool.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.ZERO,
			"life": 0.0,
			"max_life": 0.0,
			"color": Color.WHITE,
			"size": 0.0,
			"active": false,
			"index": i
		})

# =========================================================
# 粒子生成
# =========================================================

func spawn(grid_pos: Vector2i, color: Color, count: int = 12, spread: float = 80.0) -> void:
	var center: Vector2 = Vector2(
		grid_pos.x * GameConfig.CELL_SIZE + GameConfig.CELL_SIZE / 2.0,
		grid_pos.y * GameConfig.CELL_SIZE + GameConfig.CELL_SIZE / 2.0
	)
	
	var spawned: int = 0
	for i in range(MAX_PARTICLES):
		if spawned >= count:
			break
			
		var p: Dictionary = _pool[i]
		if not p["active"]:
			_activate_particle(p, center, color, spread)
			spawned += 1
			_active_count += 1

func _activate_particle(p: Dictionary, center: Vector2, color: Color, spread: float) -> void:
	var angle: float = randf() * TAU
	var speed: float = randf_range(30.0, spread)
	
	p["pos"] = center
	p["vel"] = Vector2(cos(angle), sin(angle)) * speed
	p["life"] = randf_range(GameConfig.PARTICLE_MIN_LIFE, GameConfig.PARTICLE_MAX_LIFE)
	p["max_life"] = p["life"]
	
	var p_color: Color = color
	p_color.h += randf_range(-0.05, 0.05)
	p_color.s += randf_range(-0.1, 0.1)
	p["color"] = p_color
	
	p["size"] = randf_range(GameConfig.PARTICLE_MIN_SIZE, GameConfig.PARTICLE_MAX_SIZE)
	p["active"] = true

# =========================================================
# 粒子更新
# =========================================================

func update(delta: float) -> void:
	for i in range(MAX_PARTICLES):
		var p: Dictionary = _pool[i]
		
		if not p["active"]:
			continue
		
		p["life"] -= delta
		
		if p["life"] <= 0.0:
			_deactivate_particle(p)
			continue
		
		# 更新位置
		p["pos"] += p["vel"] * delta
		p["vel"] *= GameConfig.PARTICLE_FRICTION
		p["vel"].y += GameConfig.PARTICLE_GRAVITY * delta

func _deactivate_particle(p: Dictionary) -> void:
	p["active"] = false
	_active_count -= 1

# =========================================================
# 渲染
# =========================================================

func draw_particles(canvas: CanvasItem) -> void:
	for i in range(MAX_PARTICLES):
		var p: Dictionary = _pool[i]
		
		if not p["active"]:
			continue
		
		var alpha: float = p["life"] / p["max_life"]
		var color: Color = p["color"]
		color.a = alpha
		var size: float = p["size"] * alpha
		
		canvas.draw_circle(p["pos"], size, color)

# =========================================================
# 工具函数
# =========================================================

func get_active_count() -> int:
	return _active_count

func is_empty() -> bool:
	return _active_count == 0

func clear() -> void:
	for i in range(MAX_PARTICLES):
		_pool[i]["active"] = false
	_active_count = 0

func get_pool_stats() -> Dictionary:
	return {
		"total": MAX_PARTICLES,
		"active": _active_count,
		"available": MAX_PARTICLES - _active_count
	}
