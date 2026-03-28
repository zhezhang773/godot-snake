extends Control
class_name TouchController

# =========================================================
# Configuration
# =========================================================
const SWIPE_THRESHOLD: float = 50.0
const SWIPE_TIME_THRESHOLD: float = 0.5
const DPad_SIZE: float = 120.0
const DPad_BUTTON_SIZE: float = 45.0

# =========================================================
# State
# =========================================================
var swipe_start_pos: Vector2 = Vector2.ZERO
var swipe_start_time: float = 0.0
var is_swiping: bool = false

var dpad_center: Vector2 = Vector2.ZERO
var dpad_visible: bool = false
var active_dpad_direction: Vector2i = Vector2i(0, 0)

# Direction callback
var on_direction_changed: Callable = Callable()

# =========================================================
# Lifecycle
# =========================================================

func _ready() -> void:
	// Connect input signals
	gui_input.connect(_on_gui_input)

func set_direction_callback(callback: Callable) -> void:
	on_direction_changed = callback

# =========================================================
# Input Handling
# =========================================================

func _on_gui_input(event: InputEvent) -> void:
	// Handle touch/swipe
	if event is InputEventScreenTouch:
		_handle_touch(event)
		return
	
	// Handle mouse (for desktop testing)
	if event is InputEventMouseButton:
		_handle_mouse(event)
		return

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		// Touch started - potential swipe
		swipe_start_pos = event.position
		swipe_start_time = Time.get_ticks_msec() / 1000.0
		is_swiping = true
		
		// Show D-pad
		_show_dpad(event.position)
	else:
		// Touch ended - check swipe
		if is_swiping:
			_check_swipe(event.position)
			is_swiping = false
			_hide_dpad()

func _handle_mouse(event: InputEventMouseButton) -> void:
	if event.pressed:
		swipe_start_pos = event.position
		swipe_start_time = Time.get_ticks_msec() / 1000.0
		is_swiping = true
		_show_dpad(event.position)
	else:
		if is_swiping:
			_check_swipe(event.position)
			is_swiping = false
			_hide_dpad()

func _check_swipe(end_pos: Vector2) -> void:
	var swipe_vector: Vector2 = end_pos - swipe_start_pos
	var swipe_time: float = Time.get_ticks_msec() / 1000.0 - swipe_start_time
	
	// Check if swipe is valid
	if swipe_time > SWIPE_TIME_THRESHOLD:
		return  // Too slow
	
	var swipe_length: float = swipe_vector.length()
	if swipe_length < SWIPE_THRESHOLD:
		return  // Too short
	
	// Determine direction
	var direction: Vector2i = Vector2i(0, 0)
	
	if abs(swipe_vector.x) > abs(swipe_vector.y):
		// Horizontal swipe
		direction = Vector2i(1 if swipe_vector.x > 0 else -1, 0)
	else:
		// Vertical swipe
		direction = Vector2i(0, 1 if swipe_vector.y > 0 else -1)
	
	// Trigger callback
	if on_direction_changed.is_valid():
		on_direction_changed.call(direction)

// =========================================================
// Virtual D-Pad
// =========================================================

func _show_dpad(center: Vector2) -> void:
	dpad_center = center
	dpad_visible = true
	queue_redraw()

func _hide_dpad() -> void:
	dpad_visible = false
	active_dpad_direction = Vector2i(0, 0)
	queue_redraw()

func _update_dpad_direction(touch_pos: Vector2) -> void:
	if not dpad_visible:
		return
	
	var relative: Vector2 = touch_pos - dpad_center
	
	// Determine which D-pad button is pressed
	var button_radius: float = DPad_BUTTON_SIZE / 2.0
	var up_pos: Vector2 = dpad_center + Vector2(0, -DPad_SIZE / 3.0)
	var down_pos: Vector2 = dpad_center + Vector2(0, DPad_SIZE / 3.0)
	var left_pos: Vector2 = dpad_center + Vector2(-DPad_SIZE / 3.0, 0)
	var right_pos: Vector2 = dpad_center + Vector2(DPad_SIZE / 3.0, 0)
	
	var new_direction: Vector2i = Vector2i(0, 0)
	
	if relative.distance_to(up_pos) < button_radius * 1.5:
		new_direction = Vector2i(0, -1)
	elif relative.distance_to(down_pos) < button_radius * 1.5:
		new_direction = Vector2i(0, 1)
	elif relative.distance_to(left_pos) < button_radius * 1.5:
		new_direction = Vector2i(-1, 0)
	elif relative.distance_to(right_pos) < button_radius * 1.5:
		new_direction = Vector2i(1, 0)
	
	if new_direction != active_dpad_direction and new_direction != Vector2i(0, 0):
		active_dpad_direction = new_direction
		if on_direction_changed.is_valid():
			on_direction_changed.call(new_direction)
		queue_redraw()

// =========================================================
// Drawing
// =========================================================

func _draw() -> void:
	if not dpad_visible:
		return
	
	// Draw D-pad background
	var dpad_rect: Rect2 = Rect2(
		dpad_center.x - DPad_SIZE / 2.0,
		dpad_center.y - DPad_SIZE / 2.0,
		DPad_SIZE,
		DPad_SIZE
	)
	
	// Semi-transparent background
	var bg_color: Color = Color(0.2, 0.2, 0.2, 0.5)
	_draw_rounded_rect(dpad_rect, bg_color, 20)
	
	// Draw D-pad buttons
	var button_size: float = DPad_BUTTON_SIZE
	var button_color: Color = Color(0.4, 0.4, 0.4, 0.8)
	var active_color: Color = Color(0.3, 0.8, 0.5, 0.9)
	
	// Up
	_draw_dpad_button(Vector2(0, -DPad_SIZE / 3.0), button_size, 
		button_color, active_dpad_direction == Vector2i(0, -1))
	// Down
	_draw_dpad_button(Vector2(0, DPad_SIZE / 3.0), button_size,
		button_color, active_dpad_direction == Vector2i(0, 1))
	// Left
	_draw_dpad_button(Vector2(-DPad_SIZE / 3.0, 0), button_size,
		button_color, active_dpad_direction == Vector2i(-1, 0))
	// Right
	_draw_dpad_button(Vector2(DPad_SIZE / 3.0, 0), button_size,
		button_color, active_dpad_direction == Vector2i(1, 0))

func _draw_dpad_button(offset: Vector2, size: float, color: Color, is_active: bool) -> void:
	var pos: Vector2 = dpad_center + offset
	var rect: Rect2 = Rect2(pos.x - size / 2.0, pos.y - size / 2.0, size, size)
	
	if is_active:
		_draw_rounded_rect(rect, Color(0.3, 0.8, 0.5, 0.9), 10)
		_draw_rounded_rect(rect, Color(0.4, 0.9, 0.6, 0.5), 10, false, 2.0)
	else:
		_draw_rounded_rect(rect, color, 10)
		_draw_rounded_rect(rect, Color(0.5, 0.5, 0.5, 0.4), 10, false, 1.5)

func _draw_rounded_rect(rect: Rect2, color: Color, radius: float, filled: bool = true, width: float = -1.0) -> void:
	if filled:
		draw_rect(rect, color)
		// Simple rounded corners
		var tl: Vector2 = rect.position
		var tr: Vector2 = Vector2(rect.position.x + rect.size.x, rect.position.y)
		var bl: Vector2 = Vector2(rect.position.x, rect.position.y + rect.size.y)
		var br: Vector2 = rect.position + rect.size
		
		draw_circle(tl + Vector2(radius, radius), radius, color)
		draw_circle(tr + Vector2(-radius, radius), radius, color)
		draw_circle(bl + Vector2(radius, -radius), radius, color)
		draw_circle(br + Vector2(-radius, -radius), radius, color)
	else:
		draw_rect(rect, color, false, width)

// =========================================================
// Utility
// =========================================================

func set_visible(visible: bool) -> void:
	visible = visible

func get_dpad_visible() -> bool:
	return dpad_visible
