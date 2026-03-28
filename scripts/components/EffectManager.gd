extends Node
class_name EffectManager

# =========================================================
# Configuration
# =========================================================
const MAX_PARTICLES: int = 80
const MAX_FLOATING_TEXTS: int = 50

# =========================================================
# State
# =========================================================
var particles: Array[Dictionary] = []
var floating_texts: Array[Dictionary] = []
var screen_shake: float = 0.0

# =========================================================
# Update
# =========================================================

func update(delta: float) -> void:
	_update_particles(delta)
	_update_floating_texts(delta)
	
	if screen_shake > 0.0:
		screen_shake = max(0.0, screen_shake - delta * 8.0)

func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p["life"] -= delta
		if p["life"] <= 0.0:
			particles.remove_at(i)
			continue
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.96
		p["vel"].y += 120.0 * delta

func _update_floating_texts(delta: float) -> void:
	for i in range(floating_texts.size() - 1, -1, -1):
		var ft: Dictionary = floating_texts[i]
		ft["life"] -= delta
		if ft["life"] <= 0.0:
			floating_texts.remove_at(i)
			continue
		ft["pos"].y -= 40.0 * delta

# =========================================================
# Spawning
# =========================================================

func spawn_particles(pos: Vector2, color: Color, count: int = 12, spread: float = 80.0, max_life: float = 0.8) -> void:
	for i in range(count):
		if particles.size() >= MAX_PARTICLES:
			break
		
		var angle: float = randf() * TAU
		var speed: float = randf_range(30.0, spread)
		var vel: Vector2 = Vector2(cos(angle), sin(angle)) * speed
		var life: float = randf_range(0.3, max_life)
		var size: float = randf_range(2.0, 5.0)
		
		var p_color: Color = color
		p_color.h += randf_range(-0.05, 0.05)
		p_color.s += randf_range(-0.1, 0.1)
		
		particles.append({
			"pos": pos, "vel": vel,
			"life": life, "max_life": life,
			"color": p_color, "size": size,
		})

func spawn_floating_text(text: String, pos: Vector2, color: Color, size: int = 16) -> void:
	if floating_texts.size() >= MAX_FLOATING_TEXTS:
		floating_texts.remove_at(0)
	
	floating_texts.append({
		"text": text, "pos": pos,
		"life": 1.0, "color": color, "size": size,
	})

func trigger_screen_shake(intensity: float = 1.0) -> void:
	screen_shake = intensity

# =========================================================
# Drawing
# =========================================================

func draw(canvas: CanvasItem, shake_offset: Vector2 = Vector2.ZERO) -> void:
	canvas.draw_set_transform(shake_offset, 0.0, Vector2.ONE)
	
	_draw_particles(canvas)
	_draw_floating_texts(canvas)
	
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_particles(canvas: CanvasItem) -> void:
	for p in particles:
		var alpha: float = p["life"] / p["max_life"]
		var color: Color = p["color"]
		color.a = alpha
		var size: float = p["size"] * alpha
		canvas.draw_circle(p["pos"], size, color)

func _draw_floating_texts(canvas: CanvasItem) -> void:
	var font = ThemeDB.fallback_font
	
	for ft in floating_texts:
		var alpha: float = ft["life"]
		var color: Color = ft["color"]
		color.a = alpha
		var text: String = ft["text"]
		var size: int = ft["size"]
		
		var ss: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
		var x: float = ft["pos"].x - ss.x / 2.0
		var y: float = ft["pos"].y - ss.y / 2.0
		
		# Shadow
		canvas.draw_string(font, Vector2(x + 1, y + 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, alpha * 0.5))
		# Main text
		canvas.draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

# =========================================================
# Getters
# =========================================================

func get_particles() -> Array[Dictionary]:
	return particles

func get_floating_texts() -> Array[Dictionary]:
	return floating_texts

func get_screen_shake() -> float:
	return screen_shake

func get_shake_offset() -> Vector2:
	if screen_shake <= 0.0:
		return Vector2.ZERO
	return Vector2(
		randf_range(-1, 1) * screen_shake * 4.0,
		randf_range(-1, 1) * screen_shake * 4.0
	)

# =========================================================
# Clear
# =========================================================

func clear() -> void:
	particles.clear()
	floating_texts.clear()
	screen_shake = 0.0
