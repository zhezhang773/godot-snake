extends Node2D

# =========================================================
# 引用
# =========================================================
var config: GameConfig
var particle_system: ParticleSystem
var floating_text_system: FloatingTextSystem
var snake: Snake
var audio_manager: Node

# =========================================================
# 游戏状态
# =========================================================
var score: int = 0
var total_score: int = 0
var high_score: int = 0
var game_over: bool = false
var game_started: bool = false
var game_speed: float = 0.3
var speed_timer: float = 0.0
var display_speed: float = 0.3

# 关卡门
var gate_pos: Vector2i = Vector2i(-1, -1)
var gate_open: bool = false
var gate_level: int = 1
var gate_anim: float = 0.0
var gate_flash: float = 0.0

# 暂停和死亡
var paused: bool = false
var pause_selected: int = 0
var death_reason: String = ""
var combo: int = 0
var combo_timer: float = 0.0
var total_food_eaten: int = 0

# 菜单状态
var in_menu: bool = true
var current_menu_screen: int = GameConfig.MenuScreen.MAIN
var menu_selected: int = 0
var menu_anim: float = 0.0
var menu_particles: Array[Dictionary] = []

# 加速状态
var boosted: bool = false
var boost_glow: float = 0.0
var boost_hold_timer: float = 0.0
var boost_hold_dir: Vector2i = Vector2i(0, 0)

# 动画计时器
var food_pulse: float = 0.0
var screen_shake: float = 0.0
var anim_timer: float = 0.0
var special_blink: float = 0.0

# 地形
var tiles: Array = []
var river_variants: Array = []
var river_penalty_timer: float = 0.0

# 虫洞
var wormholes: Array[Dictionary] = []
var wormhole_cooldown: bool = false

# 食物
var main_food_pos: Vector2i = Vector2i(8, 8)
var extra_foods: Array[Dictionary] = []
var food_spawn_time: float = 0.0
var food_time: float = 0.0

# 陷阱
var trap_active: bool = false
var trap_revealed: bool = false
var trap_countdown: float = 0.0

# 特殊果实
var special_active: bool = false
var special_type: int = GameConfig.SpecialType.GHOST
var special_pos: Vector2i = Vector2i(-1, -1)
var special_timer: float = 0.0

# 效果
var ghost_active: bool = false
var ghost_timer: float = 0.0
var wall_stop_active: bool = false
var wall_stop_timer: float = 0.0
var wall_pass_active: bool = false
var wall_pass_timer: float = 0.0

# UI 交互
var _lang_btn_rect: Rect2 = Rect2(0, 0, 0, 0)
var _menu_item_rects: Array[Rect2] = []
var _pause_item_rects: Array[Rect2] = []
var _gameover_btn_rects: Array[Rect2] = []

# =========================================================
# 生命周期
# =========================================================

func _ready() -> void:
	randomize()
	_load_high_score()
	
	# 初始化配置和系统
	config = GameConfig.new()
	particle_system = ParticleSystem.new()
	floating_text_system = FloatingTextSystem.new()
	snake = Snake.new(GameConfig.CELL_SIZE, GameConfig.GRID_WIDTH, GameConfig.GRID_HEIGHT)
	
	# 设置蛇的引用
	snake.set_terrain(tiles)
	snake.set_particles_ref(particle_system._pool)
	
	# 添加为子节点
	add_child(config)
	add_child(particle_system)
	add_child(floating_text_system)
	add_child(snake)
	
	# 获取音频管理器
	audio_manager = get_node_or_null("AudioManager")
	
	# 初始化菜单和游戏
	_init_menu()
	_reset_game()
	_spawn_main_food()

# =========================================================
# 菜单初始化
# =========================================================

func _init_menu() -> void:
	in_menu = true
	current_menu_screen = GameConfig.MenuScreen.MAIN
	menu_selected = 0
	menu_anim = 0.0
	menu_particles.clear()
	
	var canvas_w: float = float(GameConfig.GRID_WIDTH * GameConfig.CELL_SIZE)
	var canvas_h: float = float(GameConfig.GRID_HEIGHT * GameConfig.CELL_SIZE)
	
	for i in range(GameConfig.MENU_PARTICLE_COUNT):
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
	var cw: float = float(GameConfig.GRID_WIDTH * GameConfig.CELL_SIZE)
	var ch: float = float(GameConfig.GRID_HEIGHT * GameConfig.CELL_SIZE)
	
	for p in menu_particles:
		p["x"] += p["vx"] * delta
		p["y"] += p["vy"] * delta
		
		if p["x"] < -10: p["x"] = cw + 10
		if p["x"] > cw + 10: p["x"] = -10
		if p["y"] < -10: p["y"] = ch + 10
		if p["y"] > ch + 10: p["y"] = -10

# =========================================================
# 游戏重置
# =========================================================

func _reset_game() -> void:
	snake.reset()
	
	main_food_pos = Vector2i(GameConfig.GRID_WIDTH / 2 + 3, GameConfig.GRID_HEIGHT / 2)
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
	
	# 清理粒子系统
	particle_system.clear()
	floating_text_system.clear()
	
	tiles.clear()
	river_variants.clear()
	wormholes.clear()
	wormhole_cooldown = false
	
	gate_open = false
	gate_flash = 0.0
	
	_generate_terrain()
	_generate_gate()
	
	river_penalty_timer = 0.0
	game_speed = GameConfig.INITIAL_GAME_SPEED
	
	boosted = false
	boost_glow = 0.0
	boost_hold_timer = 0.0
	boost_hold_dir = Vector2i(0, 0)
	
	paused = false
	pause_selected = 0
	
	if audio_manager:
		audio_manager.set_music_tempo(GameConfig.MUSIC_TEMPO_DEFAULT)

# =========================================================
# 主循环
# =========================================================

func _process(delta: float) -> void:
	# 菜单模式
	if in_menu:
		menu_anim += delta
		_update_menu_particles(delta)
		queue_redraw()
		return
	
	# 游戏模式
	anim_timer += delta
	food_pulse += delta * GameConfig.FOOD_PULSE_SPEED
	special_blink += delta * GameConfig.SPECIAL_BLINK_SPEED
	gate_anim += delta
	
	# 屏幕震动衰减
	if screen_shake > 0.0:
		screen_shake = max(0.0, screen_shake - delta * GameConfig.SCREEN_SHAKE_DECAY)
	
	# 连击计时器
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
	
	# 更新粒子系统
	particle_system.update(delta)
	floating_text_system.update(delta)
	
	if paused:
		queue_redraw()
		return
	
	if not game_started or game_over:
		queue_redraw()
		return
	
	# 更新效果
	_update_effects(delta)
	_update_trap(delta)
	_update_food(delta)
	_update_gate()
	_check_boost(delta)
	
	# 游戏循环
	var effective_speed: float = game_speed
	if boosted:
		effective_speed = game_speed * GameConfig.BOOST_MULTIPLIER
	
	if not snake.get_segments().is_empty():
		var head: Vector2i = snake.get_head()
		if _get_terrain(head.x, head.y) == GameConfig.Terrain.RIVER:
			effective_speed *= (1.0 + GameConfig.RIVER_SPEED_PENALTY)
	
	display_speed = effective_speed
	speed_timer += delta
	
	if speed_timer >= effective_speed:
		speed_timer = 0.0
		_game_tick()
	
	queue_redraw()

# =========================================================
# 效果更新
# =========================================================

func _update_effects(delta: float) -> void:
	# 特殊果实计时器
	if special_active:
		special_timer -= delta
		if special_timer <= 0.0:
			special_active = false
			special_timer = 0.0
	
	# 幽灵效果
	if ghost_active:
		ghost_timer -= delta
		if ghost_timer <= 0.0:
			ghost_active = false
			ghost_timer = 0.0
	
	# 墙壁阻挡
	if wall_stop_active:
		wall_stop_timer -= delta
		if wall_stop_timer <= 0.0:
			wall_stop_active = false
			wall_stop_timer = 0.0
	
	# 墙壁穿越
	if wall_pass_active:
		wall_pass_timer -= delta
		if wall_pass_timer <= 0.0:
			wall_pass_active = false
			wall_pass_timer = 0.0

# =========================================================
# 陷阱更新
# =========================================================

func _update_trap(delta: float) -> void:
	if not trap_active:
		return
	
	if not trap_revealed and not snake.get_segments().is_empty():
		var head: Vector2i = snake.get_head()
		if GameConfig.grid_distance(head, main_food_pos) <= GameConfig.TRAP_REVEAL_DIST:
			trap_revealed = true
			trap_countdown = GameConfig.TRAP_COUNTDOWN_MAX
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
			combo_timer = GameConfig.COMBO_DURATION

# =========================================================
# 食物更新
# =========================================================

func _update_food(delta: float) -> void:
	food_time += delta
	
	# 主食物过期
	if not trap_active:
		var mf_age: float = food_time - food_spawn_time
		if mf_age >= GameConfig.FOOD_LIFETIME:
			combo = 0
			_spawn_main_food()
	
	# 额外食物过期
	for idx in range(extra_foods.size() - 1, -1, -1):
		var ef_age: float = food_time - extra_foods[idx].spawn_time
		if ef_age >= GameConfig.FOOD_LIFETIME:
			combo = 0
			extra_foods.remove_at(idx)

# =========================================================
# 关卡门更新
# =========================================================

func _update_gate() -> void:
	var needed: int = gate_level * GameConfig.GATE_OPEN_SCORE_PER_LEVEL
	
	if score >= needed and not gate_open:
		gate_open = true
		gate_flash = 1.0
		if audio_manager:
			audio_manager.play_gate_open()
	
	if gate_flash > 0.0:
		gate_flash = max(0.0, gate_flash - get_process_delta_time() * 2.5)

# =========================================================
# 加速检测
# =========================================================

func _check_boost(delta: float) -> void:
	var key_held: bool = _is_direction_key_held(snake.get_direction())
	
	if snake.get_direction() != boost_hold_dir:
		boost_hold_timer = 0.0
		boost_hold_dir = snake.get_direction()
	
	if key_held:
		boost_hold_timer += delta
		if boost_hold_timer >= GameConfig.BOOST_HOLD_THRESHOLD:
			boosted = true
		else:
			boosted = false
	else:
		boosted = false
		boost_hold_timer = 0.0
	
	if boosted:
		boost_glow = min(1.0, boost_glow + GameConfig.BOOST_GLOW_INCREASE)
	else:
		boost_glow = max(0.0, boost_glow - GameConfig.BOOST_GLOW_DECREASE)

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

# =========================================================
# 游戏循环
# =========================================================

func _game_tick() -> void:
	snake.set_direction(snake.get_next_direction())
	var head: Vector2i = snake.get_head()
	var new_head: Vector2i = Vector2i(head.x + snake.get_direction().x, head.y + snake.get_direction().y)
	
	# 墙壁碰撞检测
	var hit_wall: bool = (new_head.x < 0 or new_head.x >= GameConfig.GRID_WIDTH
		or new_head.y < 0 or new_head.y >= GameConfig.GRID_HEIGHT)
	
	if hit_wall:
		if wall_pass_active:
			new_head.x = posmod(new_head.x, GameConfig.GRID_WIDTH)
			new_head.y = posmod(new_head.y, GameConfig.GRID_HEIGHT)
		elif wall_stop_active:
			if audio_manager:
				audio_manager.play_wall_hit(true)
			return
		else:
			death_reason = "wall"
			_end_game()
			return
	
	# 自身碰撞检测
	if not ghost_active:
		for seg in snake.get_segments():
			if seg == new_head:
				death_reason = "self"
				_end_game()
				return
	
	# 虫洞传送
	if not wormhole_cooldown:
		for wh in wormholes:
			if wh.pos == new_head:
				var paired_pos: Vector2i = _get_paired_wormhole_pos(wh.pair_id, wh.pos)
				particle_system.spawn(new_head, wh.palette[0], 15, 100.0)
				particle_system.spawn(paired_pos, wh.palette[0], 15, 100.0)
				floating_text_system.spawn(Loc.t("float_wormhole"), new_head, wh.palette[1], 14)
				new_head = paired_pos
				wormhole_cooldown = true
				if audio_manager:
					audio_manager.play_wormhole()
				break
	else:
		wormhole_cooldown = false
	
	# 关卡门碰撞
	if new_head == gate_pos and gate_open:
		_enter_next_level()
		return
	
	# 再次检查自身碰撞（传送后）
	if not ghost_active:
		for seg in snake.get_segments():
			if seg == new_head:
				death_reason = "self"
				_end_game()
				return
	
	# 移动蛇
	snake.move()
	var ate: bool = false
	
	# 检查是否吃到食物
	if new_head == main_food_pos:
		if trap_active:
			_eat_trap(new_head)
		else:
			_eat_food(new_head)
			ate = true
			_spawn_main_food()
	
	# 检查额外食物
	if not ate:
		for idx in range(extra_foods.size() - 1, -1, -1):
			if extra_foods[idx].pos == new_head:
				_eat_food(new_head)
				extra_foods.remove_at(idx)
				ate = true
				break
	
	# 检查特殊果实
	if special_active and new_head == special_pos:
		_eat_special_fruit(new_head)
		ate = true
	
	# 如果没有吃到食物，回退移动
	if not ate:
		snake.undo_move()
	
	# 加速粒子效果
	if boosted and not snake.get_segments().is_empty():
		if randf() < 0.4:
			var tail: Vector2i = snake.get_segments()[snake.get_segments().size() - 1]
			particle_system.spawn(tail, config.boost_color, 2, 40.0)

# =========================================================
# 吃食物
# =========================================================

func _eat_food(pos: Vector2i) -> void:
	combo += 1
	combo_timer = GameConfig.COMBO_DURATION
	
	var bonus: int = GameConfig.BASE_FOOD_SCORE
	if combo >= GameConfig.COMBO_THRESHOLD:
		bonus += combo * GameConfig.COMBO_BONUS_MULTIPLIER
	
	total_food_eaten += 1
	score += bonus
	snake.grow()
	
	particle_system.spawn(pos, Color(1.0, 0.5, 0.3), 10, 80.0)
	
	var text_color: Color = Color(1.0, 1.0, 0.5) if bonus > GameConfig.BASE_FOOD_SCORE else Color(1.0, 1.0, 1.0)
	floating_text_system.spawn("+" + str(bonus), pos, text_color, 16 if bonus <= GameConfig.BASE_FOOD_SCORE else 20)
	
	if audio_manager:
		audio_manager.play_eat_fruit()

# =========================================================
# 吃陷阱
# =========================================================

func _eat_trap(pos: Vector2i) -> void:
	score -= GameConfig.TRAP_PENALTY
	screen_shake = 1.0
	combo = 0
	
	trap_active = false
	trap_revealed = false
	trap_countdown = 0.0
	
	particle_system.spawn(pos, Color(1.0, 0.3, 0.1), 20, 120.0)
	floating_text_system.spawn("-" + str(GameConfig.TRAP_PENALTY), pos, Color(1.0, 0.3, 0.2), 20)
	floating_text_system.spawn(Loc.t("float_seg") % GameConfig.TRAP_SHRINK_SEGMENTS, pos, Color(1.0, 0.6, 0.3), 14)
	
	if audio_manager:
		audio_manager.play_bomb_explode()
	
	snake.shrink(GameConfig.TRAP_SHRINK_SEGMENTS)
	
	if snake.get_length() <= 1:
		death_reason = "bomb"
		_end_game()
		return
	
	_spawn_main_food()

# =========================================================
# 吃特殊果实
# =========================================================

func _eat_special_fruit(pos: Vector2i) -> void:
	var bonus: int = GameConfig.SPECIAL_FOOD_BASE_SCORE + combo * 5
	score += bonus
	combo += 1
	combo_timer = GameConfig.COMBO_DURATION
	
	particle_system.spawn(pos, Color(1.0, 0.85, 0.2), 25, 150.0)
	floating_text_system.spawn("+" + str(bonus), pos, Color(1.0, 0.85, 0.2), 22)
	
	if audio_manager:
		audio_manager.play_eat_fruit()
	
	match special_type:
		GameConfig.SpecialType.GHOST:
			ghost_active = true
			ghost_timer = GameConfig.GHOST_DURATION
			floating_text_system.spawn(Loc.t("float_ghost"), pos, Color(0.7, 0.4, 1.0), 20)
		
		GameConfig.SpecialType.WALL_STOP:
			wall_stop_active = true
			wall_stop_timer = GameConfig.WALL_STOP_DURATION
			floating_text_system.spawn(Loc.t("float_shield"), pos, Color(1.0, 0.85, 0.2), 20)
		
		GameConfig.SpecialType.FOOD_RAIN:
			_spawn_food_rain()
			floating_text_system.spawn(Loc.t("float_rain"), pos, Color(1.0, 0.8, 0.2), 20)
		
		GameConfig.SpecialType.WALL_PASS:
			wall_pass_active = true
			wall_pass_timer = GameConfig.WALL_PASS_DURATION
			floating_text_system.spawn(Loc.t("float_wallpass"), pos, Color(0.7, 0.3, 1.0), 20)
		
		GameConfig.SpecialType.SPEED_UP:
			game_speed += GameConfig.SPEED_UP_AMOUNT
			floating_text_system.spawn(Loc.t("float_speedup"), pos, Color(1.0, 0.5, 0.1), 20)
		
		GameConfig.SpecialType.SPEED_DOWN:
			game_speed -= GameConfig.SPEED_DOWN_AMOUNT
			floating_text_system.spawn(Loc.t("float_speeddown"), pos, Color(0.3, 0.6, 1.0), 20)
			
			if game_speed <= GameConfig.SPEED_DEATH_THRESHOLD:
				death_reason = "frozen"
				_end_game()
				special_active = false
				special_timer = 0.0
				return
	
	special_active = false
	special_timer = 0.0

# =========================================================
# 食物生成
# =========================================================

func _get_all_occupied() -> Array[Vector2i]:
	var occupied: Array[Vector2i] = snake.get_segments().duplicate()
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
	
	for x in range(GameConfig.GRID_WIDTH):
		for y in range(GameConfig.GRID_HEIGHT):
			var cell = Vector2i(x, y)
			if not cell in occupied:
				available.append(cell)
	
	return available

func _spawn_main_food() -> void:
	var available: Array[Vector2i] = _get_available_cells()
	if available.is_empty():
		return
	
	main_food_pos = available[randi() % available.size()]
	food_spawn_time = food_time
	
	if randf() < GameConfig.SPECIAL_SPAWN_CHANCE and not special_active:
		_try_spawn_special()
	
	if randf() < GameConfig.TRAP_SPAWN_CHANCE and not trap_active:
		trap_active = true
		trap_revealed = false
		trap_countdown = 0.0

func _try_spawn_special() -> void:
	var available: Array[Vector2i] = _get_available_cells()
	if available.is_empty():
		return
	
	special_pos = available[randi() % available.size()]
	special_type = randi() % GameConfig.SPECIAL_TYPE_COUNT
	special_active = true
	special_timer = GameConfig.SPECIAL_FOOD_DURATION
	
	if audio_manager:
		audio_manager.play_special_appear()

# =========================================================
# 食物雨
# =========================================================

func _spawn_food_rain() -> void:
	var count: int = GameConfig.random_range_int(GameConfig.FOOD_RAIN_MIN, GameConfig.FOOD_RAIN_MAX)
	
	for _i in range(count):
		var available: Array[Vector2i] = _get_available_cells()
		if available.is_empty():
			break
		
		var pos: Vector2i = available[randi() % available.size()]
		extra_foods.append({"pos": pos, "spawn_time": food_time})

# =========================================================
# 关卡系统
# =========================================================

func _enter_next_level() -> void:
	var old_gate: Vector2i = gate_pos
	total_score += score
	score = 0
	gate_level += 1
	
	_reset_game()
	_spawn_main_food()
	
	particle_system.spawn(old_gate, Color(1.0, 0.85, 0.2), 30, 120.0)
	floating_text_system.spawn(Loc.t("float_levelup") % gate_level, old_gate, Color(1.0, 0.85, 0.2), 24)
	
	if audio_manager:
		audio_manager.play_gate_enter()

# =========================================================
# 游戏结束
# =========================================================

func _end_game() -> void:
	total_score += score
	game_over = true
	screen_shake = 2.0
	
	if not snake.get_segments().is_empty():
		for seg in snake.get_segments():
			particle_system.spawn(seg, Color(1.0, 0.3, 0.2), 5, 100.0)
	
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
		audio_manager.set_music_volume(GameConfig.MENU_MUSIC_VOLUME)
	
	boosted = false
	boost_glow = 0.0
	boost_hold_timer = 0.0
	boost_hold_dir = Vector2i(0, 0)

# =========================================================
# 地形系统
# =========================================================

func _get_terrain(x: int, y: int) -> int:
	if x < 0 or x >= GameConfig.GRID_WIDTH or y < 0 or y >= GameConfig.GRID_HEIGHT:
		return GameConfig.Terrain.GROUND
	return tiles[y][x]

func _generate_terrain() -> void:
	tiles.clear()
	
	for y in range(GameConfig.GRID_HEIGHT):
		var row: Array = []
		for x in range(GameConfig.GRID_WIDTH):
			row.append(GameConfig.Terrain.GROUND)
		tiles.append(row)
	
	# 生成森林
	var num_forest: int = GameConfig.random_range_int(GameConfig.NUM_FOREST_CLUSTERS_MIN, GameConfig.NUM_FOREST_CLUSTERS_MAX)
	for _i in range(num_forest):
		var fsize: int = GameConfig.random_range_int(GameConfig.FOREST_CLUSTER_MIN, GameConfig.FOREST_CLUSTER_MAX)
		var edge: Vector2i = _find_terrain_edge(GameConfig.Terrain.FOREST)
		var fx: int; var fy: int
		
		if edge.x >= 0:
			fx = edge.x; fy = edge.y
		else:
			fx = GameConfig.random_range_int(2, GameConfig.GRID_WIDTH - 3)
			fy = GameConfig.random_range_int(2, GameConfig.GRID_HEIGHT - 3)
		
		_grow_cluster(fx, fy, fsize, GameConfig.Terrain.FOREST)
		_fill_interior(GameConfig.Terrain.FOREST, 2)
	
	# 生成河流
	var num_river: int = GameConfig.random_range_int(GameConfig.NUM_RIVER_CLUSTERS_MIN, GameConfig.NUM_RIVER_CLUSTERS_MAX)
	for _i in range(num_river):
		var rsize: int = GameConfig.random_range_int(GameConfig.RIVER_CLUSTER_MIN, GameConfig.RIVER_CLUSTER_MAX)
		var edge: Vector2i = _find_terrain_edge(GameConfig.Terrain.RIVER)
		var rx: int; var ry: int
		
		if edge.x >= 0:
			rx = edge.x; ry = edge.y
		else:
			rx = GameConfig.random_range_int(2, GameConfig.GRID_WIDTH - 3)
			ry = GameConfig.random_range_int(2, GameConfig.GRID_HEIGHT - 3)
		
		_grow_cluster(rx, ry, rsize, GameConfig.Terrain.RIVER)
		_fill_interior(GameConfig.Terrain.RIVER, 2)
	
	_assign_river_variants()
	_generate_wormholes()
	
	# 清理中心区域
	var cx: int = GameConfig.GRID_WIDTH / 2
	var cy: int = GameConfig.GRID_HEIGHT / 2
	
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var tx: int = cx + dx
			var ty: int = cy + dy
			if tx >= 0 and tx < GameConfig.GRID_WIDTH and ty >= 0 and ty < GameConfig.GRID_HEIGHT:
				tiles[ty][tx] = GameConfig.Terrain.GROUND

func _find_terrain_edge(terrain_type: int) -> Vector2i:
	var edges: Array[Vector2i] = []
	var dirs_x: Array = [1, -1, 0, 0]
	var dirs_y: Array = [0, 0, 1, -1]
	
	for y in range(GameConfig.GRID_HEIGHT):
		for x in range(GameConfig.GRID_WIDTH):
			if tiles[y][x] == terrain_type:
				for d in range(4):
					var nx: int = x + dirs_x[d]
					var ny: int = y + dirs_y[d]
					
					if nx >= 0 and nx < GameConfig.GRID_WIDTH and ny >= 0 and ny < GameConfig.GRID_HEIGHT:
						if tiles[ny][nx] == GameConfig.Terrain.GROUND:
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
		if cx < 0 or cx >= GameConfig.GRID_WIDTH or cy < 0 or cy >= GameConfig.GRID_HEIGHT:
			var border: Vector2i = _find_terrain_edge(terrain_type)
			if border.x >= 0:
				cx = border.x; cy = border.y
			else:
				break
		
		if tiles[cy][cx] == GameConfig.Terrain.GROUND:
			tiles[cy][cx] = terrain_type
		
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
		
		for y in range(GameConfig.GRID_HEIGHT):
			for x in range(GameConfig.GRID_WIDTH):
				if tiles[y][x] != GameConfig.Terrain.GROUND:
					continue
				
				var neighbor_count: int = 0
				for d in range(4):
					var nx: int = x + dirs_x[d]
					var ny: int = y + dirs_y[d]
					
					if nx >= 0 and nx < GameConfig.GRID_WIDTH and ny >= 0 and ny < GameConfig.GRID_HEIGHT:
						if tiles[ny][nx] == terrain_type:
							neighbor_count += 1
				
				if neighbor_count >= 3:
					tiles[y][x] = terrain_type
					changed = true

func _assign_river_variants() -> void:
	var dirs_x: Array = [1, -1, 0, 0]
	var dirs_y: Array = [0, 0, 1, -1]
	
	river_variants.clear()
	
	for y in range(GameConfig.GRID_HEIGHT):
		var row: Array = []
		for x in range(GameConfig.GRID_WIDTH):
			row.append(-1)
		river_variants.append(row)
	
	for y in range(GameConfig.GRID_HEIGHT):
		for x in range(GameConfig.GRID_WIDTH):
			if tiles[y][x] == GameConfig.Terrain.RIVER and river_variants[y][x] == -1:
				var rv: int = randi() % 5
				var queue: Array[Vector2i] = [Vector2i(x, y)]
				river_variants[y][x] = rv
				
				while queue.size() > 0:
					var cur: Vector2i = queue.pop_front()
					
					for d in range(4):
						var nx: int = cur.x + dirs_x[d]
						var ny: int = cur.y + dirs_y[d]
						
						if nx >= 0 and nx < GameConfig.GRID_WIDTH and ny >= 0 and ny < GameConfig.GRID_HEIGHT:
							if tiles[ny][nx] == GameConfig.Terrain.RIVER and river_variants[ny][nx] == -1:
								river_variants[ny][nx] = rv
								queue.append(Vector2i(nx, ny))

# =========================================================
# 虫洞系统
# =========================================================

func _get_paired_wormhole_pos(pair_id: int, current_pos: Vector2i) -> Vector2i:
	for wh in wormholes:
		if wh.pair_id == pair_id and wh.pos != current_pos:
			return wh.pos
	return current_pos

func _generate_wormholes() -> void:
	wormholes.clear()
	var num_pairs: int = 1 + (randi() % 2)
	var center_x: int = GameConfig.GRID_WIDTH / 2
	var center_y: int = GameConfig.GRID_HEIGHT / 2
	
	for pair_id in range(num_pairs):
		var positions: Array[Vector2i] = []
		
		for _attempt in range(200):
			if positions.size() >= 2:
				break
			
			var x: int = GameConfig.random_range_int(1, GameConfig.GRID_WIDTH - 2)
			var y: int = GameConfig.random_range_int(1, GameConfig.GRID_HEIGHT - 2)
			var pos: Vector2i = Vector2i(x, y)
			
			if tiles[y][x] != GameConfig.Terrain.GROUND:
				continue
			
			if abs(x - center_x) <= 2 and abs(y - center_y) <= 2:
				continue
			
			var occupied: bool = false
			if pos == main_food_pos:
				occupied = true
			
			for wh in wormholes:
				if wh.pos == pos:
					occupied = true
			
			for ep in positions:
				if ep == pos or GameConfig.grid_distance(ep, pos) < GameConfig.WORMHOLE_MIN_DIST:
					occupied = true
			
			if occupied:
				continue
			
			positions.append(pos)
		
		if positions.size() == 2:
			var palette: Array = GameConfig.wormhole_palettes[pair_id % GameConfig.wormhole_palettes.size()]
			wormholes.append({"pos": positions[0], "pair_id": pair_id, "palette": palette, "phase": randf() * TAU})
			wormholes.append({"pos": positions[1], "pair_id": pair_id, "palette": palette, "phase": randf() * TAU})

# =========================================================
# 关卡门系统
# =========================================================

func _generate_gate() -> void:
	var available: Array[Vector2i] = []
	var center_x: int = GameConfig.GRID_WIDTH / 2
	var center_y: int = GameConfig.GRID_HEIGHT / 2
	
	for x in range(GameConfig.GRID_WIDTH):
		for y in range(GameConfig.GRID_HEIGHT):
			var pos: Vector2i = Vector2i(x, y)
			
			if tiles[y][x] != GameConfig.Terrain.GROUND:
				continue
			
			if abs(x - center_x) <= 3 and abs(y - center_y) <= 3:
				continue
			
			if x < 1 or x >= GameConfig.GRID_WIDTH - 1 or y < 1 or y >= GameConfig.GRID_HEIGHT - 1:
				continue
			
			if pos == main_food_pos:
				continue
			
			var near_wormhole: bool = false
			for wh in wormholes:
				if pos == wh.pos or GameConfig.grid_distance(pos, wh.pos) < 2:
					near_wormhole = true
					break
			
			if near_wormhole:
				continue
			
			available.append(pos)
	
	if available.is_empty():
		gate_pos = Vector2i(-1, -1)
	else:
		gate_pos = available[randi() % available.size()]

# =========================================================
# 存档
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
# 返回主菜单
# =========================================================

func _return_to_menu() -> void:
	in_menu = true
	current_menu_screen = GameConfig.MenuScreen.MAIN
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
		audio_manager.set_music_volume(GameConfig.MENU_MUSIC_VOLUME)

# =========================================================
# 输入处理
# =========================================================

func _unhandled_input(event: InputEvent) -> void:
	# 语言按钮点击
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _lang_btn_rect.has_point(event.position):
			Loc.switch_language()
			return
	
	# 菜单输入
	if in_menu:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_click_menu_items(event.position)
			return
		_handle_menu_input(event)
		return
	
	# 暂停状态
	if paused and not game_over:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_click_pause_items(event.position)
			return
		_handle_pause_input(event)
		return
	
	# 游戏结束
	if game_over:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_click_gameover_buttons(event.position)
			return
		
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_SPACE:
				score = 0
				total_score = 0
				gate_level = 1
				game_speed = GameConfig.INITIAL_GAME_SPEED
				speed_timer = 0.0
				game_over = false
				game_started = true
				paused = false
				pause_selected = 0
				
				_reset_game()
				_spawn_main_food()
				
				if audio_manager:
					audio_manager.set_music_volume(GameConfig.GAME_MUSIC_VOLUME)
			elif event.keycode == KEY_ESCAPE:
				_return_to_menu()
		return
	
	# 暂停切换
	if not game_over and game_started and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		paused = true
		pause_selected = 0
		return
	
	# 方向输入
	if event is InputEventKey and event.pressed:
		var next_dir: Vector2i = snake.get_next_direction()
		
		if (event.is_action_pressed("move_up") or event.keycode == KEY_UP) and next_dir.y != 1:
			snake.set_direction(Vector2i(0, -1))
		elif (event.is_action_pressed("move_down") or event.keycode == KEY_DOWN) and next_dir.y != -1:
			snake.set_direction(Vector2i(0, 1))
		elif (event.is_action_pressed("move_left") or event.keycode == KEY_LEFT) and next_dir.x != 1:
			snake.set_direction(Vector2i(-1, 0))
		elif (event.is_action_pressed("move_right") or event.keycode == KEY_RIGHT) and next_dir.x != -1:
			snake.set_direction(Vector2i(1, 0))

# =========================================================
# 菜单输入处理
# =========================================================

func _handle_menu_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	
	match current_menu_screen:
		GameConfig.MenuScreen.MAIN:
			_handle_main_menu_input(event)
		GameConfig.MenuScreen.HELP, GameConfig.MenuScreen.HIGH_SCORE:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				current_menu_screen = GameConfig.MenuScreen.MAIN

func _handle_main_menu_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or event.keycode == KEY_UP or event.keycode == KEY_W:
		menu_selected = posmod(menu_selected - 1, _get_menu_names().size())
	elif event.is_action_pressed("move_down") or event.keycode == KEY_DOWN or event.keycode == KEY_S:
		menu_selected = posmod(menu_selected + 1, _get_menu_names().size())
	elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		_select_menu_item()

func _select_menu_item() -> void:
	match menu_selected:
		0:  # 开始游戏
			in_menu = false
			game_started = true
			score = 0
			total_score = 0
			gate_level = 1
			game_speed = GameConfig.INITIAL_GAME_SPEED
			speed_timer = 0.0
			
			if audio_manager:
				audio_manager.set_music_volume(GameConfig.GAME_MUSIC_VOLUME)
		
		1:  # 最高分
			current_menu_screen = GameConfig.MenuScreen.HIGH_SCORE
		
		2:  # 帮助
			current_menu_screen = GameConfig.MenuScreen.HELP
		
		3:  # 退出
			get_tree().quit()

func _get_menu_names() -> PackedStringArray:
	return PackedStringArray([
		Loc.t("menu_start"),
		Loc.t("menu_highscore"),
		Loc.t("menu_help"),
		Loc.t("menu_quit"),
	])

# =========================================================
# 暂停菜单输入处理
# =========================================================

func _handle_pause_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	
	if event.keycode == KEY_ESCAPE:
		paused = false
		return
	
	if event.is_action_pressed("move_up") or event.keycode == KEY_UP or event.keycode == KEY_W:
		pause_selected = posmod(pause_selected - 1, GameConfig.PAUSE_ITEMS_COUNT)
	elif event.is_action_pressed("move_down") or event.keycode == KEY_DOWN or event.keycode == KEY_S:
		pause_selected = posmod(pause_selected + 1, GameConfig.PAUSE_ITEMS_COUNT)
	elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		_select_pause_item()

func _select_pause_item() -> void:
	match pause_selected:
		0:  # 继续
			paused = false
		1:  # 返回菜单
			_return_to_menu()

# =========================================================
# 鼠标点击处理
# =========================================================

func _click_menu_items(mouse_pos: Vector2) -> void:
	var local_pos: Vector2 = mouse_pos - Vector2(GameConfig.DRAW_MARGIN, GameConfig.DRAW_MARGIN)
	
	for i in range(_menu_item_rects.size()):
		if _menu_item_rects[i].has_point(local_pos):
			menu_selected = i
			_select_menu_item()
			return

func _click_gameover_buttons(mouse_pos: Vector2) -> void:
	var local_pos: Vector2 = mouse_pos - Vector2(GameConfig.DRAW_MARGIN, GameConfig.DRAW_MARGIN)
	
	for i in range(_gameover_btn_rects.size()):
		if _gameover_btn_rects[i].has_point(local_pos):
			match i:
				0:  # 新游戏
					score = 0
					total_score = 0
					gate_level = 1
					game_speed = GameConfig.INITIAL_GAME_SPEED
					speed_timer = 0.0
					game_over = false
					game_started = true
					paused = false
					pause_selected = 0
					
					_reset_game()
					_spawn_main_food()
					
					if audio_manager:
						audio_manager.set_music_volume(GameConfig.GAME_MUSIC_VOLUME)
				
				1:  # 退出
					_return_to_menu()
			return

func _click_pause_items(mouse_pos: Vector2) -> void:
	var local_pos: Vector2 = mouse_pos - Vector2(GameConfig.DRAW_MARGIN, GameConfig.DRAW_MARGIN)
	
	for i in range(_pause_item_rects.size()):
		if _pause_item_rects[i].has_point(local_pos):
			pause_selected = i
			_select_pause_item()
			return

# =========================================================
# 渲染
# =========================================================

func _draw() -> void:
	var vp_size: float = GameConfig.GRID_WIDTH * GameConfig.CELL_SIZE + GameConfig.DRAW_MARGIN * 2
	draw_rect(Rect2(0, 0, vp_size, vp_size), config.bg_color)
	
	# 菜单模式
	if in_menu:
		draw_set_transform(Vector2(GameConfig.DRAW_MARGIN, GameConfig.DRAW_MARGIN), 0.0, Vector2.ONE)
		_draw_menu_bg()
		_draw_menu_screen()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_language_button()
		return
	
	# 游戏模式
	var shake_offset: Vector2 = Vector2.ZERO
	if screen_shake > 0.0:
		shake_offset = Vector2(
			randf_range(-1, 1) * screen_shake * GameConfig.SCREEN_SHAKE_INTENSITY,
			randf_range(-1, 1) * screen_shake * GameConfig.SCREEN_SHAKE_INTENSITY
		)
	
	draw_set_transform(shake_offset + Vector2(GameConfig.DRAW_MARGIN, GameConfig.DRAW_MARGIN), 0.0, Vector2.ONE)
	
	_draw_background()
	_draw_wormholes()
	_draw_gate()
	
	if trap_active:
		_draw_trap()
	else:
		var mf_age: float = food_time - food_spawn_time
		var mf_blink: bool = mf_age > (GameConfig.FOOD_LIFETIME - GameConfig.FOOD_WARN_THRESHOLD)
		_draw_food(main_food_pos, mf_blink)
	
	for ef in extra_foods:
		var ef_age: float = food_time - ef.spawn_time
		var ef_blink: bool = ef_age > (GameConfig.FOOD_LIFETIME - GameConfig.FOOD_WARN_THRESHOLD)
		_draw_food(ef.pos, ef_blink)
	
	if special_active:
		_draw_special_food()
	
	snake.draw(self, anim_timer, 1.0)
	
	particle_system.draw_particles(self)
	floating_text_system.draw_floating_texts(self)
	
	_draw_boost_indicator()
	_draw_ui()
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# =========================================================
# 背景绘制
# =========================================================

func _draw_background() -> void:
	if wall_pass_active:
		_draw_wall_portal()
	elif wall_stop_active:
		draw_rect(Rect2(0, 0, GameConfig.GRID_WIDTH * GameConfig.CELL_SIZE, GameConfig.GRID_HEIGHT * GameConfig.CELL_SIZE), config.border_color, false, 2.0)
		_draw_wall_sponge()
	elif ghost_active:
		draw_rect(Rect2(0, 0, GameConfig.GRID_WIDTH * GameConfig.CELL_SIZE, GameConfig.GRID_HEIGHT * GameConfig.CELL_SIZE), config.border_color, false, 3.0)
	elif boosted:
		var b_pulse: float = 0.5 + 0.5 * abs(sin(special_blink * 1.0))
		var b_alpha: float = 0.4 + 0.4 * b_pulse * boost_glow
		draw_rect(Rect2(0, 0, GameConfig.GRID_WIDTH * GameConfig.CELL_SIZE, GameConfig.GRID_HEIGHT * GameConfig.CELL_SIZE),
			Color(config.boost_color.r, config.boost_color.g, config.boost_color.b, b_alpha), false, 3.0)
	else:
		draw_rect(Rect2(0, 0, GameConfig.GRID_WIDTH * GameConfig.CELL_SIZE, GameConfig.GRID_HEIGHT * GameConfig.CELL_SIZE), config.border_color, false, 3.0)

# =========================================================
# 由于篇幅限制，其他绘制函数保持原样
# 需要将所有绘制代码迁移到这个新文件中
# =========================================================

# 占位符函数（实际实现需要从原 Main.gd 复制）
func _draw_menu_bg() -> void:
	pass

func _draw_menu_screen() -> void:
	pass

func _draw_language_button() -> void:
	pass

func _draw_food(pos: Vector2i, blink: bool = false) -> void:
	pass

func _draw_trap() -> void:
	pass

func _draw_bomb(pos: Vector2i, countdown_val: float) -> void:
	pass

func _draw_special_food() -> void:
	pass

func _draw_wormholes() -> void:
	pass

func _draw_single_wormhole(wh: Dictionary) -> void:
	pass

func _draw_gate() -> void:
	pass

func _draw_boost_indicator() -> void:
	pass

func _draw_ui() -> void:
	pass

func _draw_pause_screen(W: float, H: float) -> void:
	pass

func _draw_gameover_screen(W: float, H: float) -> void:
	pass

func _draw_wall_portal() -> void:
	pass

func _draw_wall_sponge() -> void:
	pass

func _draw_terrain() -> void:
	pass

func _draw_ground_tile(x: int, y: int, px: float, py: float) -> void:
	pass

func _draw_forest_tile(x: int, y: int, px: float, py: float) -> void:
	pass

func _draw_river_tile(x: int, y: int, px: float, py: float) -> void:
	pass

func _draw_effect_countdown(W: float, H: float, idx: int, label: String, timer_val: float, max_val: float, bar_color: Color, icon: String) -> void:
	pass

func _draw_centered_text(text: String, y: float, size: int, color: Color) -> void:
	pass

func _draw_rounded_rect(rect: Rect2, color: Color, radius: float, filled: bool = true, width: float = -1.0) -> void:
	pass
