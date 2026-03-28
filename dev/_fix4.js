const fs = require('fs');
const mp = 'G:\\autoclawcode\\scripts\\Main.gd';
const ap = 'G:\\autoclawcode\\scripts\\AudioManager.gd';
const lp = 'G:\\autoclawcode\\scripts\\LocalizationManager.gd';

let c = fs.readFileSync(mp, 'utf8');
let ac = fs.readFileSync(ap, 'utf8');
let lc = fs.readFileSync(lp, 'utf8');
let ok = true, aok = true, lok = true;

console.log('=== MAIN.GD PATCHES ===\n');

// 1. Add gate constant after MAX_WORMHOLE_PAIRS
const o1 = 'const MAX_WORMHOLE_PAIRS: int = 2\nconst WORMHOLE_MIN_DIST: int = 5';
const n1 = 'const MAX_WORMHOLE_PAIRS: int = 2\n\n# Level gate\nconst GATE_OPEN_SCORE_PER_LEVEL: int = 50\nconst WORMHOLE_MIN_DIST: int = 5';
if (c.includes(o1)) { c = c.replace(o1, n1); console.log('1  Gate constant:     OK'); }
else { console.log('1  Gate constant:     FAIL'); ok = false; }

// 2. Add gate state variables after display_speed
const o2 = 'var display_speed: float = 0.3';
const n2 = 'var display_speed: float = 0.3\n\n# Level gate\nvar gate_pos: Vector2i = Vector2i(-1, -1)\nvar gate_open: bool = false\nvar gate_level: int = 1\nvar gate_anim: float = 0.0\nvar gate_flash: float = 0.0';
if (c.includes(o2)) { c = c.replace(o2, n2); console.log('2  Gate variables:    OK'); }
else { console.log('2  Gate variables:    FAIL'); ok = false; }

// 3. Reset gate state in _reset_game (before _generate_terrain)
const o3 = '\twormhole_cooldown = false\n\t_generate_terrain()';
const n3 = '\twormhole_cooldown = false\n\tgate_open = false\n\tgate_flash = 0.0\n\t_generate_terrain()';
if (c.includes(o3)) { c = c.replace(o3, n3); console.log('3  Reset gate state:  OK'); }
else { console.log('3  Reset gate state:  FAIL'); ok = false; }

// 4. Call _generate_gate() after _generate_terrain() in _reset_game
const o4 = '\t_generate_terrain()\n\triver_penalty_timer = 0.0';
const n4 = '\t_generate_terrain()\n\t_generate_gate()\n\triver_penalty_timer = 0.0';
if (c.includes(o4)) { c = c.replace(o4, n4); console.log('4  Generate gate call: OK'); }
else { console.log('4  Generate gate call: FAIL'); ok = false; }

// 5. Set gate_level=1 when starting from main menu
const o5 = '0:  # Start Game\n\t\t\tin_menu = false\n\t\t\tgame_started = true';
const n5 = '0:  # Start Game\n\t\t\tin_menu = false\n\t\t\tgame_started = true\n\t\t\tgate_level = 1';
if (c.includes(o5)) { c = c.replace(o5, n5); console.log('5  Menu start level:  OK'); }
else { console.log('5  Menu start level:  FAIL'); ok = false; }

// 6. Set gate_level=1 when returning to menu
const o6 = '\t_reset_game()\n\t_spawn_main_food()\n\tif audio_manager:\n\t\taudio_manager.set_music_volume(0.15)';
const n6 = '\t_reset_game()\n\t_spawn_main_food()\n\tgate_level = 1\n\tif audio_manager:\n\t\taudio_manager.set_music_volume(0.15)';
if (c.includes(o6)) { c = c.replace(o6, n6); console.log('6  Return menu level: OK'); }
else { console.log('6  Return menu level: FAIL'); ok = false; }

// 7. Add gate open check in _process (before boost check)
const o7 = '\t# Check boost state\n\t_check_boost(delta)';
const n7 = '\t# Gate open check\n\tvar needed: int = gate_level * GATE_OPEN_SCORE_PER_LEVEL\n\tif score >= needed and not gate_open:\n\t\tgate_open = true\n\t\tgate_flash = 1.0\n\t\tif audio_manager:\n\t\t\taudio_manager.play_gate_open()\n\tif gate_flash > 0.0:\n\t\tgate_flash = max(0.0, gate_flash - delta * 2.5)\n\n\t# Check boost state\n\t_check_boost(delta)';
if (c.includes(o7)) { c = c.replace(o7, n7); console.log('7  Process gate check: OK'); }
else { console.log('7  Process gate check: FAIL'); ok = false; }

// 8. Add gate_anim timer update in _process
const o8 = '\tspecial_blink += delta * 8.0\n\tif screen_shake > 0.0:';
const n8 = '\tspecial_blink += delta * 8.0\n\tgate_anim += delta\n\tif screen_shake > 0.0:';
if (c.includes(o8)) { c = c.replace(o8, n8); console.log('8  Gate anim timer:   OK'); }
else { console.log('8  Gate anim timer:   FAIL'); ok = false; }

// 9. Add gate collision in _game_tick (after wormhole, before self-collision recheck)
const o9 = '\t# Re-check self-collision after teleport';
const n9 = '\t# Gate collision\n\tif new_head == gate_pos and gate_open:\n\t\t_enter_next_level()\n\t\treturn\n\n\t# Re-check self-collision after teleport';
if (c.includes(o9)) { c = c.replace(o9, n9); console.log('9  Game tick gate:     OK'); }
else { console.log('9  Game tick gate:     FAIL'); ok = false; }

// 10. Include gate position in _get_all_occupied (no food on gate)
const o10 = '\tfor wh in wormholes:\n\t\toccupied.append(wh.pos)\n\treturn occupied';
const n10 = '\tfor wh in wormholes:\n\t\toccupied.append(wh.pos)\n\tif gate_pos.x >= 0:\n\t\toccupied.append(gate_pos)\n\treturn occupied';
if (c.includes(o10)) { c = c.replace(o10, n10); console.log('10 Occupied list:     OK'); }
else { console.log('10 Occupied list:     FAIL'); ok = false; }

// 11. Draw gate in _draw() (after wormholes, before trap/food)
const o11 = '\t_draw_wormholes()\n\tif trap_active:';
const n11 = '\t_draw_wormholes()\n\t_draw_gate()\n\tif trap_active:';
if (c.includes(o11)) { c = c.replace(o11, n11); console.log('11 Draw gate call:    OK'); }
else { console.log('11 Draw gate call:    FAIL'); ok = false; }

// 12. Add level info + gate progress to HUD in _draw_ui (before speed display)
const o12 = '\tvar speed_text: String = Loc.t("ui_speed") % display_speed';
const n12 = '\t# Level info\n\tvar level_text: String = Loc.t("ui_level") % gate_level\n\tdraw_string(ThemeDB.fallback_font, Vector2(15, 102),\n\t\tlevel_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.55, 0.58, 0.68, 0.7))\n\n\t# Gate progress\n\tvar needed: int = gate_level * GATE_OPEN_SCORE_PER_LEVEL\n\tif not gate_open:\n\t\tvar gate_text: String = Loc.t("ui_gate_closed") % [score, needed]\n\t\tdraw_string(ThemeDB.fallback_font, Vector2(15, 122),\n\t\t\tgate_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.45, 0.48, 0.55, 0.6))\n\telse:\n\t\tdraw_string(ThemeDB.fallback_font, Vector2(15, 122),\n\t\t\tLoc.t("ui_gate_open"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.9, 0.5, 0.85))\n\n\tvar speed_text: String = Loc.t("ui_speed") % display_speed';
if (c.includes(o12)) { c = c.replace(o12, n12); console.log('12 HUD level info:    OK'); }
else { console.log('12 HUD level info:    FAIL'); ok = false; }

// 13. Show level reached in game over screen
const o13 = '\t_draw_centered_text(Loc.t("gameover_score") % score, H / 2.0 - 35, 28, Color(1, 1, 1, 1))\n\t_draw_centered_text(Loc.t("gameover_stats") % [segments.size(), total_food_eaten],';
const n13 = '\t_draw_centered_text(Loc.t("gameover_score") % score, H / 2.0 - 35, 28, Color(1, 1, 1, 1))\n\t_draw_centered_text(Loc.t("gameover_level") % gate_level, H / 2.0 - 12, 16, Color(0.55, 0.58, 0.68, 0.7))\n\t_draw_centered_text(Loc.t("gameover_stats") % [segments.size(), total_food_eaten],';
if (c.includes(o13)) { c = c.replace(o13, n13); console.log('13 Gameover level:    OK'); }
else { console.log('13 Gameover level:    FAIL'); ok = false; }

// 14. Set gate_level=1 on game over restart (SPACE key) — 3 tabs for if, 4 tabs for score
const o14 = '\t\t\tif event.keycode == KEY_SPACE:\n\t\t\t\tscore = 0';
const n14 = '\t\t\tif event.keycode == KEY_SPACE:\n\t\t\t\tscore = 0\n\t\t\t\tgate_level = 1';
if (c.includes(o14)) { c = c.replace(o14, n14); console.log('14 Restart SPACE lvl:  OK'); }
else { console.log('14 Restart SPACE lvl:  FAIL'); ok = false; }

// 15. Set gate_level=1 on game over restart (click New Game) — 4 tabs for case, 5 tabs for score
const o15 = '\t\t\t\t0:  # New Game\n\t\t\t\t\tscore = 0';
const n15 = '\t\t\t\t0:  # New Game\n\t\t\t\t\tscore = 0\n\t\t\t\t\tgate_level = 1';
if (c.includes(o15)) { c = c.replace(o15, n15); console.log('15 Restart click lvl:  OK'); }
else { console.log('15 Restart click lvl:  FAIL'); ok = false; }

// 16. Insert gate system functions before "Drawing - Helpers" section
const o16 = '# =========================================================\n# Drawing - Helpers\n# =========================================================\n\n\n# =========================================================\n# Terrain System\n# =========================================================';
const n16 = `# =========================================================
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
			available.append(pos)
	if available.is_empty():
		gate_pos = Vector2i(-1, -1)
	else:
		gate_pos = available[randi() % available.size()]

func _enter_next_level() -> void:
	var old_gate: Vector2i = gate_pos
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
# =========================================================`;
if (c.includes(o16)) { c = c.replace(o16, n16); console.log('16 Gate functions:    OK'); }
else { console.log('16 Gate functions:    FAIL'); ok = false; }


// ============================================================
// AUDIO MANAGER.GD PATCHES
// ============================================================
console.log('\n=== AUDIO MANAGER.GD PATCHES ===\n');

// A1: Add SFX variables
const oA1 = 'var sfx_wormhole: AudioStreamWAV';
const nA1 = 'var sfx_wormhole: AudioStreamWAV\nvar sfx_gate_open: AudioStreamWAV\nvar sfx_gate_enter: AudioStreamWAV';
if (ac.includes(oA1)) { ac = ac.replace(oA1, nA1); console.log('A1 SFX variables:     OK'); }
else { console.log('A1 SFX variables:     FAIL'); aok = false; }

// A2: Generate SFX
const oA2 = '\tsfx_wormhole = _make_wav(_synth_wormhole, 0.4, sr)';
const nA2 = '\tsfx_wormhole = _make_wav(_synth_wormhole, 0.4, sr)\n\tsfx_gate_open = _make_wav(_synth_gate_open, 0.5, sr)\n\tsfx_gate_enter = _make_wav(_synth_gate_enter, 0.6, sr)';
if (ac.includes(oA2)) { ac = ac.replace(oA2, nA2); console.log('A2 SFX generation:    OK'); }
else { console.log('A2 SFX generation:    FAIL'); aok = false; }

// A3: Add public play methods
const oA3 = 'func play_wormhole() -> void:\n\t_play_sfx(sfx_wormhole, -5.0)\n\nfunc play_game_over() -> void:';
const nA3 = 'func play_wormhole() -> void:\n\t_play_sfx(sfx_wormhole, -5.0)\n\nfunc play_gate_open() -> void:\n\t_play_sfx(sfx_gate_open, -3.0)\n\nfunc play_gate_enter() -> void:\n\t_play_sfx(sfx_gate_enter, -2.0)\n\nfunc play_game_over() -> void:';
if (ac.includes(oA3)) { ac = ac.replace(oA3, nA3); console.log('A3 Play methods:      OK'); }
else { console.log('A3 Play methods:      FAIL'); aok = false; }

// A4: Add synth functions before _synth_wormhole
const oA4 = 'func _synth_wormhole(t: float, dur: float) -> float:';
const nA4 = `# --- Gate Open: ascending chime with resolve ---
func _synth_gate_open(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 4.0)
	var freq: float = 440.0 + t * 600.0
	var wave: float = sin(2.0 * PI * freq * t)
	wave += sin(2.0 * PI * freq * 1.5 * t) * exp(-t * 6.0) * 0.35
	wave += sin(2.0 * PI * freq * 2.0 * t) * exp(-t * 10.0) * 0.2
	for k in range(3):
		var nt: float = t - k * 0.06
		if nt > 0:
			var ne: float = exp(-nt * 18.0) * 0.3
			wave += sin(2.0 * PI * (880.0 + k * 220.0) * nt) * ne
	return wave * env * 0.45

# --- Gate Enter: triumphant ascending fanfare ---
func _synth_gate_enter(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 3.5) * 1.2
	var freq: float
	if t < dur * 0.33:
		freq = 523.25
	elif t < dur * 0.66:
		freq = 659.25
	else:
		freq = 783.99
	var wave: float = sin(2.0 * PI * freq * t)
	wave += sin(2.0 * PI * freq * 2.0 * t) * 0.2
	wave += sin(2.0 * PI * freq * 0.5 * t) * 0.25
	wave += sin(2.0 * PI * (freq * 1.5) * t) * exp(-t * 8.0) * 0.15
	return wave * env * 0.45

func _synth_wormhole(t: float, dur: float) -> float:`;
if (ac.includes(oA4)) { ac = ac.replace(oA4, nA4); console.log('A4 Synth functions:   OK'); }
else { console.log('A4 Synth functions:   FAIL'); aok = false; }


// ============================================================
// LOCALIZATION PATCHES
// ============================================================
console.log('\n=== LOCALIZATION PATCHES ===\n');

// L1: Add gate-related translation keys after ui_speed
const oL1 = '\t"ui_speed":             {"en": "Speed: %.3fs",         "zh": "速度: %.3fs"},';
const nL1 = `\t"ui_speed":             {"en": "Speed: %.3fs",         "zh": "速度: %.3fs"},
	"ui_level":             {"en": "Lv.%d",                 "zh": "第%d关"},
	"ui_gate_closed":       {"en": "Gate %d/%d",             "zh": "大门 %d/%d"},
	"ui_gate_open":         {"en": "Gate OPEN!",            "zh": "大门已开!"},
	"gameover_level":       {"en": "Level: %d",             "zh": "关卡: %d"},
	"float_levelup":        {"en": "LEVEL %d!",             "zh": "第%d关!"},`;
if (lc.includes(oL1)) { lc = lc.replace(oL1, nL1); console.log('L1 Translation keys: OK'); }
else { console.log('L1 Translation keys: FAIL'); lok = false; }

// ============================================================
// WRITE FILES
// ============================================================
console.log('\n=== WRITING FILES ===\n');

if (ok) { fs.writeFileSync(mp, c, 'utf8'); console.log('Main.gd:              WRITTEN'); }
else { console.log('Main.gd:              SKIPPED (errors)'); }

if (aok) { fs.writeFileSync(ap, ac, 'utf8'); console.log('AudioManager.gd:     WRITTEN'); }
else { console.log('AudioManager.gd:     SKIPPED (errors)'); }

if (lok) { fs.writeFileSync(lp, lc, 'utf8'); console.log('LocalizationManager: WRITTEN'); }
else { console.log('LocalizationManager: SKIPPED (errors)'); }

if (ok && aok && lok) {
	console.log('\n✅ All patches applied successfully!');
} else {
	console.log('\n❌ Some patches failed!');
	process.exit(1);
}
