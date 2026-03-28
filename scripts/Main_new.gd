extends Node2D

# =========================================================
# Configuration
# =========================================================
const DEFAULT_CELL_SIZE: int = 40
const DEFAULT_GRID_WIDTH: int = 20
const DEFAULT_GRID_HEIGHT: int = 20
const DRAW_MARGIN: int = 30

# =========================================================
# Components
# =========================================================
var snake: Snake = null
var food_manager: FoodManager = null
var terrain_system: TerrainSystem = null
var effect_manager: EffectManager = null
var game_state: GameStateManager = null

# Audio
var audio_manager: Node = null

# Localization
var Loc = null

# =========================================================
# Grid / Visual
# =========================================================
var CELL_SIZE: int = DEFAULT_CELL_SIZE
var GRID_WIDTH: int = DEFAULT_GRID_WIDTH
var GRID_HEIGHT: int = DEFAULT_GRID_HEIGHT

# =========================================================
# Animation
# =========================================================
var anim_timer: float = 0.0
var food_pulse: float = 0.0
var special_blink: float = 0.0

# =========================================================
# Game Loop
# =========================================================
var speed_timer: float = 0.0
var effective_speed: float = 0.3

# =========================================================
# Menu State
# =========================================================
enum MenuScreen { MAIN, HELP, HIGH_SCORE }
var in_menu: bool = true
var current_menu_screen: int = MenuScreen.MAIN
var menu_selected: int = 0
var menu_anim: float = 0.0
var menu_particles: Array[Dictionary] = []

# Pause
var pause_selected: int = 0

# =========================================================
# Colors
# =========================================================
var bg_color: Color = Color(0.06, 0.08, 0.12, 1.0)
var grid_color: Color = Color(0.1, 0.13, 0.18, 1.0)
var border_color: Color = Color(0.3, 0.4, 0.55, 1.0)
var boost_color: Color = Color(1.0, 0.6, 0.1, 1.0)
var boost_glow_color: Color = Color(1.0, 0.45, 0.0, 0.25)
var portal_color: Color = Color(0.6, 0.2, 0.9, 0.7)
var portal_glow: Color = Color(0.8, 0.4, 1.0, 0.25)
var sponge_color: Color = Color(0.92, 0.72, 0.08, 0.92)
var sponge_highlight: Color = Color(1.0, 0.92, 0.35, 0.85)
var sponge_dark: Color = Color(0.6, 0.42, 0.05, 0.88)

# Effect bars
var ghost_bar_color: Color = Color(0.5, 0.3, 1.0, 0.7)
var wallstop_bar_color: Color = Color(0.95, 0.78, 0.15, 0.8)
var wallpass_bar_color: Color = Color(0.6, 0.25, 0.9, 0.7)

# Stored rects for mouse interaction
var _lang_btn_rect: Rect2 = Rect2(0, 0, 0, 0)
var _menu_item_rects: Array[Rect2] = []
var _pause_item_rects: Array[Rect2] = []
var _gameover_btn_rects: Array[Rect2] = []

# =========================================================
# Lifecycle
# =========================================================

func _ready() -> void:
	randomize()
	
	# Create components
	_create_components()
	
	# Setup references
	_setup_references()
	
	# Initialize
	_init_menu()
	_reset_game()
	food_manager.spawn_main_food(_get_all_occupied())

func _create_components() -> void:
	snake = Snake.new(CELL_SIZE, GRID_WIDTH, GRID_HEIGHT)
	food_manager = FoodManager.new(CELL_SIZE, GRID_WIDTH, GRID_HEIGHT)
	terrain_system = TerrainSystem.new(CELL_SIZE, GRID_WIDTH, GRID_HEIGHT)
	effect_manager = EffectManager.new()
	game_state = GameStateManager.new()

func _setup_references() -> void:
	# Audio
	audio_manager = get_node_or_null("AudioManager")
	
	# Localization
	Loc = get_node_or_null("/root/Loc")
	
	# Cross-references
	snake.set_audio_manager(audio_manager)
	snake.set_terrain(terrain_system.tiles)
	snake.set_particles_ref(effect_manager.get_particles())
	
	food_manager.set_audio_manager(audio_manager)
	food_manager.set_particles_ref(effect_manager.get_particles())
	food_manager.set_floating_texts_ref(effect_manager.get_floating_texts())
	food_manager.set_localization(Loc)
	
	terrain_system.set_audio_manager(audio_manager)
	terrain_system.set_particles_ref(effect_manager.get_particles())
	terrain_system.set_floating_texts_ref(effect_manager.get_floating_texts())
	terrain_system.set_localization(Loc)

func _init_menu() -> void:
	in_menu = true
	current_menu_screen = MenuScreen.MAIN
	menu_selected = 0
	menu_anim = 0.0
	
	var canvas_w: float = float(GRID_WIDTH * CELL_SIZE)
	var canvas_h: float = float(GRID_HEIGHT * CELL_SIZE)
	
	menu_particles.clear()
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

# =========================================================
# Main Loop
# =========================================================

func _process(delta: float) -> void:
	anim_timer += delta
	food_pulse += delta * 5.0
	special_blink += delta * 8.0
	
	# Menu mode
	if in_menu:
		menu_anim += delta
		_update_menu_particles(delta)
		queue_redraw()
		return
	
	# Update components
	effect_manager.update(delta)
	game_state.update(delta)
	terrain_system.update(delta)
	snake.update_effects(delta)
	food_manager.update(delta, snake.get_head(), _get_all_occupied())
	
	// Update speed display based on snake state
	var river_penalty: float = 0.0
	if terrain_system.get_terrain(snake.get_head().x, snake.get_head().y) == TerrainSystem.Terrain.RIVER:
		river_penalty = TerrainSystem.RIVER_SPEED_PENALTY
	
	effective_speed = game_state.get_effective_speed(
		snake.get_boost_multiplier(),
		river_penalty
	)
	
	// Pause or game over
	if game_state.is_paused() or game_state.is_game_over():
		queue_redraw()
		return
	
	// Game tick
	if game_state.is_game_started():
		speed_timer += delta
		if speed_timer >= effective_speed:
			speed_timer = 0.0
			_game_tick()
	
	queue_redraw()

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

# =========================================================
# Game Tick
# =========================================================

func _game_tick() -> void:
	// Move snake
	var new_head: Vector2i = snake.move()
	
	// Check wormhole
	new_head = terrain_system.check_wormhole(new_head)
	
	// Check wall collision
	if snake.check_wall_collision(new_head):
		if not game_state.is_wall_pass_active():
			if game_state.is_wall_stop_active():
				snake.undo_move()
				if audio_manager:
					audio_manager.play_wall_hit(true)
				return
			else:
				game_state.end_game("wall")
				effect_manager.trigger_screen_shake(1.0)
				if audio_manager:
					audio_manager.play_wall_hit(false)
					audio_manager.play_game_over()
				return
	
	// Wrap around for wall pass
	if game_state.is_wall_pass_active():
		new_head.x = posmod(new_head.x, GRID_WIDTH)
		new_head.y = posmod(new_head.y, GRID_HEIGHT)
	
	// Check self collision
	if snake.check_self_collision(new_head):
		game_state.end_game("self")
		effect_manager.trigger_screen_shake(1.0)
		if audio_manager:
			audio_manager.play_game_over()
		return
	
	// Check gate
	if terrain_system.check_gate_collision(new_head):
		terrain_system.enter_next_level()
		game_state.add_score(100 * terrain_system.get_gate_level())
		_reset_game()
		food_manager.spawn_main_food(_get_all_occupied())
		return
	
	// Check food collision
	var collision_type: int = food_manager.check_food_collision(new_head)
	
	match collision_type:
		0:
			// No food
			pass
		1:
			// Main food
			var bonus: int = food_manager.eat_food(new_head, game_state.get_combo())
			snake.grow()
			game_state.add_score(bonus)
			game_state.increment_food_eaten()
			food_manager.spawn_main_food(_get_all_occupied())
		2:
			// Extra food
			var bonus: int = food_manager.eat_food(new_head, game_state.get_combo())
			snake.grow()
			game_state.add_score(bonus)
			game_state.increment_food_eaten()
		3:
			// Trap
			var trap_effects: Dictionary = food_manager.eat_trap(new_head)
			snake.shrink(trap_effects["shrink"])
			game_state.subtract_score(trap_effects["penalty"])
			effect_manager.trigger_screen_shake(1.0)
			food_manager.spawn_main_food(_get_all_occupied())
			if snake.get_length() <= 1:
				game_state.end_game("bomb")
				return
		4:
			// Special food
			var special_effects: Dictionary = food_manager.eat_special_fruit(new_head, game_state.get_combo())
			snake.grow()
			game_state.add_score(special_effects["score"])
			
			if special_effects["ghost"]:
				snake.activate_ghost()
			if special_effects["wall_stop"]:
				game_state.activate_wall_stop()
			if special_effects["wall_pass"]:
				game_state.activate_wall_pass()
			if special_effects["food_rain"]:
				food_manager.spawn_food_rain(_get_all_occupied())
			
			if special_effects["speed_change"] != 0.0:
				var speed_ok: bool = game_state.adjust_speed(special_effects["speed_change"])
				if not speed_ok:
					game_state.end_game("frozen")
					return

# =========================================================
# Reset
# =========================================================

func _reset_game() -> void:
	snake.reset()
	food_manager.reset()
	terrain_system.reset()
	effect_manager.clear()
	game_state.reset()
	
	// Sync terrain with snake
	snake.set_terrain(terrain_system.tiles)

func _get_all_occupied() -> Array[Vector2i]:
	var occupied: Array[Vector2i] = snake.get_segments()
	occupied.append_array(food_manager.get_all_food_positions())
	occupied.append_array(terrain_system.get_wormhole_positions())
	
	var gate_pos: Vector2i = terrain_system.get_gate_position()
	if gate_pos.x >= 0:
		occupied.append(gate_pos)
	
	return occupied

# =========================================================
# Input
# =========================================================

func _unhandled_input(event: InputEvent) -> void:
	// Language button
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _lang_btn_rect.has_point(event.position):
			Loc.switch_language()
			return
	
	// Menu input
	if in_menu:
		_handle_menu_input(event)
		return
	
	// Pause input
	if game_state.is_paused() and not game_state.is_game_over():
		_handle_pause_input(event)
		return
	
	// Game over input
	if game_state.is_game_over():
		_handle_gameover_input(event)
		return
	
	// Pause toggle
	if not game_state.is_game_over() and game_state.is_game_started():
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			game_state.pause_game()
			pause_selected = 0
			return
	
	// Direction input
	if event is InputEventKey and event.pressed:
		_handle_direction_input(event)

func _handle_menu_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click_menu_items(event.position)
		return
	
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
		menu_selected = posmod(menu_selected - 1, 4)
	elif event.is_action_pressed("move_down") or event.keycode == KEY_DOWN or event.keycode == KEY_S:
		menu_selected = posmod(menu_selected + 1, 4)
	elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		_select_menu_item()

func _select_menu_item() -> void:
	match menu_selected:
		0:
			// Start Game
			in_menu = false
			game_state.start_game()
		1:
			// High Score
			current_menu_screen = MenuScreen.HIGH_SCORE
		2:
			// Help
			current_menu_screen = MenuScreen.HELP
		3:
			// Quit
			get_tree().quit()

func _handle_pause_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click_pause_items(event.position)
		return
	
	if not event is InputEventKey or not event.pressed:
		return
	
	if event.keycode == KEY_ESCAPE:
		game_state.resume_game()
		return
	
	if event.is_action_pressed("move_up") or event.keycode == KEY_UP or event.keycode == KEY_W:
		pause_selected = posmod(pause_selected - 1, 2)
	elif event.is_action_pressed("move_down") or event.keycode == KEY_DOWN or event.keycode == KEY_S:
		pause_selected = posmod(pause_selected + 1, 2)
	elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		_select_pause_item()

func _select_pause_item() -> void:
	match pause_selected:
		0:
			// Continue
			game_state.resume_game()
		1:
			// Return to Menu
			_return_to_menu()

func _handle_gameover_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click_gameover_buttons(event.position)
		return
	
	if not event is InputEventKey or not event.pressed:
		return
	
	if event.keycode == KEY_SPACE:
		// New Game
		_reset_game()
		food_manager.spawn_main_food(_get_all_occupied())
		game_state.start_game()
		pause_selected = 0
	elif event.keycode == KEY_ESCAPE:
		_return_to_menu()

func _handle_direction_input(event: InputEvent) -> void:
	var current_dir: Vector2i = snake.get_next_direction()
	
	if (event.is_action_pressed("move_up") or event.keycode == KEY_UP) and current_dir.y != 1:
		snake.set_direction(Vector2i(0, -1))
	elif (event.is_action_pressed("move_down") or event.keycode == KEY_DOWN) and current_dir.y != -1:
		snake.set_direction(Vector2i(0, 1))
	elif (event.is_action_pressed("move_left") or event.keycode == KEY_LEFT) and current_dir.x != 1:
		snake.set_direction(Vector2i(-1, 0))
	elif (event.is_action_pressed("move_right") or event.keycode == KEY_RIGHT) and current_dir.x != -1:
		snake.set_direction(Vector2i(1, 0))

func _return_to_menu() -> void:
	in_menu = true
	current_menu_screen = MenuScreen.MAIN
	menu_selected = 0
	game_state.reset()
	_reset_game()
	food_manager.spawn_main_food(_get_all_occupied())

// Mouse click handlers
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
				0:  // New Game
					_reset_game()
					food_manager.spawn_main_food(_get_all_occupied())
					game_state.start_game()
					pause_selected = 0
				1:  // Quit
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
# Drawing
# =========================================================

func _draw() -> void:
	var vp_size: float = GRID_WIDTH * CELL_SIZE + DRAW_MARGIN * 2
	draw_rect(Rect2(0, 0, vp_size, vp_size), bg_color)
	
	// Menu mode
	if in_menu:
		draw_set_transform(Vector2(DRAW_MARGIN, DRAW_MARGIN), 0.0, Vector2.ONE)
		_draw_menu_bg()
		_draw_menu_screen()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_language_button()
		return
	
	// Game mode
	var shake_offset: Vector2 = effect_manager.get_shake_offset()
	draw_set_transform(shake_offset + Vector2(DRAW_MARGIN, DRAW_MARGIN), 0.0, Vector2.ONE)
	
	// Draw game elements
	terrain_system.draw(self, anim_timer)
	food_manager.draw(self, anim_timer)
	snake.draw(self, anim_timer, 0.5 if snake.is_ghost_active() else 1.0)
	effect_manager.draw(self)
	
	// Draw border
	if game_state.is_wall_stop_active():
		_draw_wall_sponge_border()
	elif game_state.is_wall_pass_active():
		_draw_wall_portal_border()
	else:
		draw_rect(Rect2(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE), border_color, false, 3.0)
	
	// Draw UI
	_draw_ui()
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_language_button()

// Simplified drawing functions - would need full implementation
func _draw_menu_bg() -> void:
	// Placeholder - needs full implementation
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var H: float = float(GRID_HEIGHT * CELL_SIZE)
	draw_rect(Rect2(0, 0, W, H), bg_color)
	
	// Draw particles
	for p in menu_particles:
		var a: float = p["alpha"] * (0.4 + 0.6 * abs(sin(menu_anim * 1.2 + p["phase"])))
		var c: Color = Color(p["color"])
		c.a = a
		draw_circle(Vector2(p["x"], p["y"]), p["size"], c)

func _draw_menu_screen() -> void:
	// Placeholder - needs full implementation
	match current_menu_screen:
		MenuScreen.MAIN:
			_draw_main_menu()
		MenuScreen.HELP:
			_draw_help_screen()
		MenuScreen.HIGH_SCORE:
			_draw_highscore_screen()

func _draw_main_menu() -> void:
	// Placeholder
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var H: float = float(GRID_HEIGHT * CELL_SIZE)
	var font = ThemeDB.fallback_font
	
	// Title
	var title_text: String = "🐍 SNAKE GAME"
	var title_size: int = 62
	var ss: Vector2 = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size)
	var tx: float = (W - ss.x) / 2.0
	draw_string(font, Vector2(tx, 130.0), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color(0.2, 1.0, 0.5, 1.0))
	
	// Menu items (simplified)
	var items: Array = ["Start Game", "High Score", "Help", "Quit"]
	var start_y: float = 310.0
	var spacing: float = 70.0
	
	_menu_item_rects.clear()
	for i in range(items.size()):
		var item_y: float = start_y + float(i) * spacing
		var text: String = items[i]
		var size: int = 24 if i == menu_selected else 20
		var color: Color = Color(1.0, 1.0, 1.0, 1.0) if i == menu_selected else Color(0.5, 0.53, 0.58, 0.7)
		
		var text_ss: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		var text_tx: float = (W - text_ss.x) / 2.0
		draw_string(font, Vector2(text_tx, item_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
		
		// Store rect for mouse interaction
		_menu_item_rects.append(Rect2(text_tx - 20, item_y - 26, text_ss.x + 40, 52))

func _draw_help_screen() -> void:
	// Placeholder
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2((W - 200) / 2.0, 100.0), "HELP - Coming Soon!", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(1.0, 1.0, 1.0, 1.0))

func _draw_highscore_screen() -> void:
	// Placeholder
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var font = ThemeDB.fallback_font
	
	var title_text: String = "HIGH SCORE"
	var title_size: int = 36
	var ss: Vector2 = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size)
	draw_string(font, Vector2((W - ss.x) / 2.0, 180.0), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color(1.0, 0.85, 0.0, 1.0))
	
	var score_text: String = str(game_state.get_high_score())
	var score_size: int = 72
	var score_ss: Vector2 = font.get_string_size(score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, score_size)
	draw_string(font, Vector2((W - score_ss.x) / 2.0, 390.0), score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, score_size, Color(1.0, 0.85, 0.0, 1.0))

func _draw_wall_sponge_border() -> void:
	// Placeholder - needs full implementation
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var H: float = float(GRID_HEIGHT * CELL_SIZE)
	var thickness: float = 14.0
	
	var sc: Color = Color(sponge_color.r, sponge_color.g, sponge_color.b, 0.95)
	draw_rect(Rect2(-thickness, -thickness, W + thickness * 2, thickness), sc)
	draw_rect(Rect2(-thickness, H, W + thickness * 2, thickness), sc)
	draw_rect(Rect2(-thickness, 0, thickness, H), sc)
	draw_rect(Rect2(W, 0, thickness, H), sc)

func _draw_wall_portal_border() -> void:
	// Placeholder - needs full implementation
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var H: float = float(GRID_HEIGHT * CELL_SIZE)
	var thickness: float = 6.0
	
	var pc: Color = Color(portal_color.r, portal_color.g, portal_color.b, 0.6)
	draw_rect(Rect2(0, -thickness, W, thickness), pc)
	draw_rect(Rect2(0, H, W, thickness), pc)
	draw_rect(Rect2(-thickness, 0, thickness, H), pc)
	draw_rect(Rect2(W, 0, thickness, H), pc)

func _draw_ui() -> void:
	// Draw HUD
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var font = ThemeDB.fallback_font
	
	// Score
	draw_string(font, Vector2(15, 28), "Score: %d" % game_state.get_score(), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 1, 1))
	draw_string(font, Vector2(15, 52), "Best: %d" % game_state.get_high_score(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.85, 0, 1))
	
	// Level
	var level_text: String = "Level: %d" % terrain_system.get_gate_level()
	draw_string(font, Vector2(15, 92), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.55, 0.58, 0.68, 0.7))
	
	// Speed
	var speed_text: String = "Speed: %.3f" % effective_speed
	var speed_ss: Vector2 = font.get_string_size(speed_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 16)
	draw_string(font, Vector2(W - 15 - speed_ss.x, 30), speed_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.65, 0.75, 0.85))
	
	// Combo
	if game_state.get_combo() >= 3:
		var combo_alpha: float = min(1.0, game_state.combo_timer / 0.5)
		draw_string(font, Vector2(15, 80), "Combo: x%d" % game_state.get_combo(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.2, combo_alpha))
	
	// Pause screen
	if game_state.is_paused() and not game_state.is_game_over():
		_draw_pause_screen()
	
	// Game over screen
	if game_state.is_game_over():
		_draw_gameover_screen()

func _draw_pause_screen() -> void:
	// Placeholder
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var H: float = float(GRID_HEIGHT * CELL_SIZE)
	var font = ThemeDB.fallback_font
	
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.55))
	
	var title_text: String = "PAUSED"
	var title_size: int = 42
	var ss: Vector2 = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size)
	draw_string(font, Vector2((W - ss.x) / 2.0, H / 2.0 - 70), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color(1, 1, 1, 1))

func _draw_gameover_screen() -> void:
	// Placeholder
	var W: float = float(GRID_WIDTH * CELL_SIZE)
	var H: float = float(GRID_HEIGHT * CELL_SIZE)
	var font = ThemeDB.fallback_font
	
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.7))
	
	var title_text: String = "GAME OVER"
	var title_size: int = 42
	var ss: Vector2 = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size)
	draw_string(font, Vector2((W - ss.x) / 2.0, H / 2.0 - 105), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color(1, 0.3, 0.3, 1))
	
	var score_text: String = "Score: %d" % game_state.get_total_score()
	var score_size: int = 30
	var score_ss: Vector2 = font.get_string_size(score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, score_size)
	draw_string(font, Vector2((W - score_ss.x) / 2.0, H / 2.0 - 40), score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, score_size, Color(1, 1, 1, 1))

func _draw_language_button() -> void:
	// Simplified version
	var grid_w: float = float(GRID_WIDTH * CELL_SIZE)
	var grid_h: float = float(GRID_HEIGHT * CELL_SIZE)
	var btn_w: float = 64.0
	var btn_h: float = 28.0
	var btn_x: float = DRAW_MARGIN + grid_w - btn_w - 6.0
	var btn_y: float = DRAW_MARGIN + grid_h - btn_h - 6.0
	var font = ThemeDB.fallback_font
	
	_lang_btn_rect = Rect2(btn_x, btn_y, btn_w, btn_h)
	
	// Background
	draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), Color(0.12, 0.14, 0.2, 0.88))
	draw_rect(Rect2(btn_x, btn_y, btn_w, btn_h), Color(0.4, 0.45, 0.55, 0.55), false, 1.5)
	
	// Text
	var lang_text: String = "CN/EN" if Loc and Loc.current_language == "en" else "中/英"
	var ss: Vector2 = font.get_string_size(lang_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
	var tx: float = btn_x + (btn_w - ss.x) / 2.0
	var ty: float = btn_y + (btn_h - ss.y) / 2.0 + font.get_ascent(11)
	draw_string(font, Vector2(tx, ty), lang_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.7, 0.9, 0.7))
