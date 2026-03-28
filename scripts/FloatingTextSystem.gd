# FloatingTextSystem.gd - 浮动文字系统
# 使用对象池模式管理浮动文字

extends Node2D
class_name FloatingTextSystem

# =========================================================
# 浮动文字数据结构
# =========================================================
const MAX_FLOATING_TEXTS: int = 50

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
	
	for i in range(MAX_FLOATING_TEXTS):
		_pool.append({
			"text": "",
			"pos": Vector2.ZERO,
			"life": 0.0,
			"color": Color.WHITE,
			"size": 16,
			"active": false,
			"index": i
		})

# =========================================================
# 浮动文字生成
# =========================================================

func spawn(text: String, grid_pos: Vector2i, color: Color, size: int = 16) -> void:
	var pos: Vector2 = Vector2(
		grid_pos.x * GameConfig.CELL_SIZE + GameConfig.CELL_SIZE / 2.0,
		grid_pos.y * GameConfig.CELL_SIZE + GameConfig.CELL_SIZE / 2.0
	)
	
	# 查找可用的槽位
	for i in range(MAX_FLOATING_TEXTS):
		var ft: Dictionary = _pool[i]
		
		if not ft["active"]:
			ft["text"] = text
			ft["pos"] = pos
			ft["life"] = GameConfig.FLOATING_TEXT_LIFETIME
			ft["color"] = color
			ft["size"] = size
			ft["active"] = true
			_active_count += 1
			return

# =========================================================
# 浮动文字更新
# =========================================================

func update(delta: float) -> void:
	for i in range(MAX_FLOATING_TEXTS):
		var ft: Dictionary = _pool[i]
		
		if not ft["active"]:
			continue
		
		ft["life"] -= delta
		ft["pos"].y -= GameConfig.FLOATING_TEXT_SPEED * delta
		
		if ft["life"] <= 0.0:
			ft["active"] = false
			_active_count -= 1

# =========================================================
# 渲染
# =========================================================

func draw_floating_texts(canvas: CanvasItem) -> void:
	var font = ThemeDB.fallback_font
	
	for i in range(MAX_FLOATING_TEXTS):
		var ft: Dictionary = _pool[i]
		
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
		
		# 阴影
		canvas.draw_string(font, Vector2(x + 1, y + 1), text, 
			HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, alpha * 0.5))
		
		# 主文字
		canvas.draw_string(font, Vector2(x, y), text, 
			HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

# =========================================================
# 工具函数
# =========================================================

func get_active_count() -> int:
	return _active_count

func is_empty() -> bool:
	return _active_count == 0

func clear() -> void:
	for i in range(MAX_FLOATING_TEXTS):
		_pool[i]["active"] = false
	_active_count = 0

func get_pool_stats() -> Dictionary:
	return {
		"total": MAX_FLOATING_TEXTS,
		"active": _active_count,
		"available": MAX_FLOATING_TEXTS - _active_count
	}
