extends Node
class_name GameStateManager

# =========================================================
# Configuration
# =========================================================
const SPEED_UP_AMOUNT: float = 0.005
const SPEED_DOWN_AMOUNT: float = 0.005
const SPEED_DEATH_THRESHOLD: float = 0.005
const WALL_STOP_DURATION: float = 15.0
const WALL_PASS_DURATION: float = 15.0

# =========================================================
# Game State
# =========================================================
var score: int = 0
var total_score: int = 0
var high_score: int = 0
var game_over: bool = false
var game_started: bool = false
var paused: bool = false

var game_speed: float = 0.3
var display_speed: float = 0.3

# Effects
var wall_stop_active: bool = false
var wall_stop_timer: float = 0.0
var wall_pass_active: bool = false
var wall_pass_timer: float = 0.0

# Combo
var combo: int = 0
var combo_timer: float = 0.0

# Stats
var total_food_eaten: int = 0
var death_reason: String = ""

# =========================================================
# Lifecycle
# =========================================================

func _ready() -> void:
	_load_high_score()

# =========================================================
# State Management
# =========================================================

func reset() -> void:
	score = 0
	total_score = 0
	game_over = false
	game_started = false
	paused = false
	game_speed = 0.3
	display_speed = 0.3
	
	wall_stop_active = false
	wall_stop_timer = 0.0
	wall_pass_active = false
	wall_pass_timer = 0.0
	
	combo = 0
	combo_timer = 0.0
	
	total_food_eaten = 0
	death_reason = ""

func start_game() -> void:
	game_started = true
	game_over = false
	paused = false
	score = 0

func pause_game() -> void:
	if game_started and not game_over:
		paused = true

func resume_game() -> void:
	paused = false

func end_game(reason: String = "") -> void:
	total_score += score
	game_over = true
	death_reason = reason
	
	if total_score > high_score:
		high_score = total_score
		_save_high_score()

# =========================================================
# Update
# =========================================================

func update(delta: float) -> void:
	# Combo timer
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
	
	# Effect timers
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

# =========================================================
# Score
# =========================================================

func add_score(points: int) -> void:
	score += points
	combo += 1
	combo_timer = 8.0

func add_combo_bonus(base_points: int) -> int:
	var bonus: int = base_points
	if combo >= 3:
		bonus += combo * 2
	return bonus

func subtract_score(points: int) -> void:
	score -= points
	combo = 0

func increment_food_eaten() -> void:
	total_food_eaten += 1

# =========================================================
# Speed
# =========================================================

func adjust_speed(delta: float) -> bool:
	game_speed += delta
	display_speed = game_speed
	
	if game_speed <= SPEED_DEATH_THRESHOLD:
		return false  # Frozen to death
	return true

func get_effective_speed(boost_multiplier: float = 1.0, river_penalty: float = 0.0) -> float:
	var effective: float = game_speed * boost_multiplier
	if river_penalty > 0.0:
		effective *= (1.0 + river_penalty)
	return effective

# =========================================================
# Effects
# =========================================================

func activate_wall_stop() -> void:
	wall_stop_active = true
	wall_stop_timer = WALL_STOP_DURATION

func activate_wall_pass() -> void:
	wall_pass_active = true
	wall_pass_timer = WALL_PASS_DURATION

func is_wall_stop_active() -> bool:
	return wall_stop_active

func is_wall_pass_active() -> bool:
	return wall_pass_active

func get_wall_stop_time() -> float:
	return wall_stop_timer

func get_wall_pass_time() -> float:
	return wall_pass_timer

# =========================================================
# Getters
# =========================================================

func get_score() -> int:
	return score

func get_total_score() -> int:
	return total_score

func get_high_score() -> int:
	return high_score

func get_combo() -> int:
	return combo

func get_game_speed() -> float:
	return game_speed

func get_display_speed() -> float:
	return display_speed

func is_game_over() -> bool:
	return game_over

func is_game_started() -> bool:
	return game_started

func is_paused() -> bool:
	return paused

func get_death_reason() -> String:
	return death_reason

func get_total_food_eaten() -> int:
	return total_food_eaten

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
