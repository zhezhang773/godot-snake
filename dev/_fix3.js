const fs = require('fs');
const mp = 'G:\\autoclawcode\\scripts\\Main.gd';
const ap = 'G:\\autoclawcode\\scripts\\AudioManager.gd';
const lp = 'G:\\autoclawcode\\scripts\\LocalizationManager.gd';
let c = fs.readFileSync(mp, 'utf8');
let ac = fs.readFileSync(ap, 'utf8');
let lc = fs.readFileSync(lp, 'utf8');
let ok = true, aok = true, lok = true;

// ============================================================
// MAIN.GD
// ============================================================

// 1. Add gate constants
const old1 = 'const MAX_WORMHOLE_PAIRS: int = 2';
const new1 = `const MAX_WORMHOLE_PAIRS: int = 2

# Level gate
const GATE_OPEN_SCORE_PER_LEVEL: int = 50`;
if (c.includes(old1)) { c = c.replace(old1, new1); console.log('1 Constants: OK'); }
else { console.log('1 Constants: FAIL'); ok = false; }

// 2. Add gate variables
const old2 = 'var display_speed: float = 0.3';
const new2 = `var display_speed: float = 0.3

# Level gate
var gate_pos: Vector2i = Vector2i(-1, -1)
var gate_open: bool = false
var gate_level: int = 1
var gate_anim: float = 0.0
var gate_flash: float = 0.0`;
if (c.includes(old2)) { c = c.replace(old2, new2); console.log('2 Variables: OK'); }
else { console.log('2 Variables: FAIL'); ok = false; }

// 3. Reset gate in _reset_game (before _generate_terrain)
const old3 = '\twormhole_cooldown = false\n\t_generate_terrain()';
const new3 = '\twormhole_cooldown = false\n\tgate_open = false\n\tgate_flash = 0.0\n\t_generate_terrain()';
if (c.includes(old3)) { c = c.replace(old3, new3); console.log('3 Reset: OK'); }
else { console.log('3 Reset: FAIL'); ok = false; }

// 4. Add gate generation after _generate_terrain() in _reset_game
const old4 = '\t_generate_terrain()\n\triver_penalty_timer = 0.0';
const new4 = '\t_generate_terrain()\n\t_generate_gate()\n\triver_penalty_timer = 0.0';
if (c.includes(old4)) { c = c.replace(old4, new4); console.log('4 Gen call: OK'); }
else { console.log('4 Gen call: FAIL'); ok = false; }

// 5. Set gate_level=1 when starting new game (menu start)
const old5a = '0:  # Start Game\n\t\t\tin_menu = false\n\t\t\tgame_started = true';
const new5a = '0:  # Start Game\n\t\t\tin_menu = false\n\t\t\tgame_started = true\n\t\t\tgate_level = 1';
if (c.includes(old5a)) { c = c.replace(old5a, new5a); console.log('5a Menu start: OK'); }
else { console.log('5a Menu start: FAIL'); ok = false; }

// 6. Set gate_level=1 in _return_to_menu
const old6 = '\t_reset_game()\n\t_spawn_main_food()\n\tif audio_manager:\n\t\taudio_manager.set_music_volume(0.15)';
const new6 = '\t_reset_game()\n\t_spawn_main_food()\n\tgate_level = 1\n\tif audio_manager:\n\t\taudio_manager.set_music_volume(0.15)';
if (c.includes(old6)) { c = c.replace(old6, new6); console.log('6 Return menu: OK'); }
else { console.log('6 Return menu: FAIL'); ok = false; }

// 7. Add gate open check in _process (after food expiration, before boost)
const old7 = '\t# Check boost state\n\t_check_boost(delta)';
const new7 = '\t# Gate open check\n\tvar needed: int = gate_level * GATE_OPEN_SCORE_PER_LEVEL\n\tif score >= needed and not gate_open:\n\t\tgate_open = true\n\t\tgate_flash = 1.0\n\t\tif audio_manager:\n\t\t\taudio_manager.play_gate_open()\n\tif gate_flash > 0.0:\n\t\tgate_flash = max(0.0, gate_flash - delta * 2.5)\n\n\t# Check boost state\n\t_check_boost(delta)';
if (c.includes(old7)) { c = c.replace(old7, new7); console.log('7 Process gate check: OK'); }
else { console.log('7 Process gate check: FAIL'); ok = false; }

// 8. Add gate collision in _game_tick (after wormhole teleport, before re-check self-collision)
const old8 = '\t# Re-check self-collision after teleport';
const new8 = '\t# Gate collision\n\tif new_head == gate_pos and gate_open:\n\t\t_enter_next_level()\n\t\treturn\n\n\t# Re-check self-collision after teleport';
if (c.includes(old8)) { c = c.replace(old8, new8); console.log('8 Game tick gate: OK'); }
else { console.log('8 Game tick gate: FAIL'); ok = false; }

// 9. Add gate to _get_all_occupied
const old9 = '\tfor wh in wormholes:\n\t\toccupied.append(wh.pos)\n\treturn occupied';
const new9 = '\tfor wh in wormholes:\n\t\toccupied.append(wh.pos)\n\tif gate_pos.x >= 0:\n\t\toccupied.append(gate_pos)\n\treturn occupied';
if (c.includes(old9)) { c = c.replace(old9, new9); console.log('9 Occupied: OK'); }
else { console.log('9 Occupied: FAIL'); ok = false; }

// 10. Add _draw_gate in _draw (after _draw_wormholes, before food)
const old10 = '\t_draw_wormholes()\n\tif trap_active:';
const new10 = '\t_draw_wormholes()\n\t_draw_gate()\n\tif trap_active:';
if (c.includes(old10)) { c = c.replace(old10, new10); console.log('10 Draw call: OK'); }
else { console.log('10 Draw call: FAIL'); ok = false; }

// 11. Add level info to HUD (_draw_ui)
const old11 = 'var speed_text: String = Loc.t("ui_speed") % display_speed';
const new11 = 'var level_text: String = Loc.t("ui_level") % gate_level\n\tdraw_string(ThemeDB.fallback_font, Vector2(15, 102),\n\t\tlevel_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.55, 0.58, 0.68, 0.7))\n\n\t# Gate progress\n\tvar needed: int = gate_level * GATE_OPEN_SCORE_PER_LEVEL\n\tif not gate_open:\n\t\tvar gate_text: String = Loc.t("ui_gate_closed") % [score, needed]\n\t\tvar gate_ts: Vector2 = ThemeDB.fallback_font.get_string_size(gate_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 14)\n\t\tdraw_string(ThemeDB.fallback_font, Vector2(15, 122),\n\t\t\tgate_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.45, 0.48, 0.55, 0.6))\n\telse:\n\t\tdraw_string(ThemeDB.fallback_font, Vector2(15, 122),\n\t\t\tLoc.t("ui_gate_open"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.9, 0.5, 0.85))\n\n\tvar speed_text: String = Loc.t("ui_speed") % display_speed';
if (c.includes(old11)) { c = c.replace(old11, new11); console.log('11 HUD: OK'); }
else { console.log('11 HUD: FAIL'); ok = false; }

// 12. Insert gate functions before _draw_rounded_rect
const gateFunctions = `# =========================================================
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
	gate_level += 1
	gate_open = false
	gate_flash = 0.0
	_spawn_particles(gate_pos, Color(1.0, 0.85, 0.2), 30, 120.0)
	_spawn_floating_text(Loc.t("float_levelup") % gate_level, gate_pos, Color(1.0, 0.85, 0.2), 24)
	if audio_manager:
		audio_manager.play_gate_enter()
	_reset_game()
	_spawn_main_food()

func _draw_gate() -> void:
	if gate_pos.x < 0:
		return
	var cx: float = gate_pos.x * CELL_SIZE + CELL_SIZE / 2.0
	var cy: float = gate_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	var r: float = CELL_SIZE / 2.0 - 1.0
	var font = ThemeDB.fallback_font
	var label: String = str(gate_level + 1)

	if gate_open:
		# Open gate: golden glow, pulsing
		var pulse: float = 0.7 + 0.3 * sin(gate_anim * 3.0)
		# Glow layers
		for i in range(3):
			var gr: float = r + 8.0 + float(i) * 5.0
			var ga: float = (0.06 + float(i) * 0.03) * pulse
			draw_circle(Vector2(cx, cy), gr, Color(1.0, 0.85, 0.2, ga))
		# Flash burst when just opened
		if gate_flash > 0.0:
			draw_circle(Vector2(cx, cy), r + 18.0, Color(1.0, 0.9, 0.3, gate_flash * 0.2))
		# Door frame (arch shape)
		draw_arc(Vector2(cx, cy), r + 2.0, 0, PI, 16, Color(1.0, 0.75, 0.1, 0.9 * pulse), 3.0)
		draw_line(Vector2(cx - r - 2.0, cy), Vector2(cx - r - 2.0, cy - r), Color(1.0, 0.75, 0.1, 0.9 * pulse), 3.0)
		draw_line(Vector2(cx + r + 2.0, cy), Vector2(cx + r + 2.0, cy - r), Color(1.0, 0.75, 0.1, 0.9 * pulse), 3.0)
		# Interior: bright warm glow
		draw_circle(Vector2(cx, cy), r, Color(0.95, 0.88, 0.6, 0.5 * pulse))
		draw_circle(Vector2(cx, cy - r * 0.3), r * 0.5, Color(1.0, 0.95, 0.8, 0.4 * pulse))
		# Arrow indicator
		var arrow_bob: float = sin(gate_anim * 4.0) * 3.0
		_draw_chevron_up(cx, cy + arrow_bob, 8.0, Color(1.0, 0.85, 0.2, 0.8 * pulse), 3.0)
		# Level label
		var ls: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		draw_string(font, Vector2(cx - ls.x / 2.0, cy - ls.y / 2.0 + 8), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.45, 0.05, 0.8 * pulse))
	else:
		# Closed gate: gray, locked look
		# Shadow
		draw_circle(Vector2(cx + 1.5, cy + 1.5), r + 2.0, Color(0.05, 0.05, 0.08, 0.5))
		# Door body
		draw_circle(Vector2(cx, cy), r + 2.0, Color(0.25, 0.27, 0.32, 0.95))
		# Door frame (darker arch)
		draw_arc(Vector2(cx, cy), r + 2.0, 0, PI, 16, Color(0.4, 0.42, 0.5, 0.7), 2.5)
		draw_line(Vector2(cx - r - 2.0, cy), Vector2(cx - r - 2.0, cy - r), Color(0.4, 0.42, 0.5, 0.7), 2.5)
		draw_line(Vector2(cx + r + 2.0, cy), Vector2(cx + r + 2.0, cy - r), Color(0.4, 0.42, 0.5, 0.7), 2.5)
		# Inner panel
		draw_circle(Vector2(cx, cy), r - 1.0, Color(0.2, 0.22, 0.28, 0.9))
		# Lock icon (simple)
		var lock_y: float = cy - 4.0
		var lock_w: float = 8.0
		var lock_h: float = 6.0
		draw_rect(Rect2(cx - lock_w / 2.0, lock_y, lock_w, lock_h), Color(0.5, 0.52, 0.58, 0.6))
		draw_rect(Rect2(cx - lock_w / 2.0, lock_y, lock_w, lock_h), Color(0.6, 0.62, 0.68, 0.4), false, 1.0)
		draw_arc(Vector2(cx, lock_y), 4.0, PI, TAU, 8, Color(0.5, 0.52, 0.58, 0.6), 2.0)
		# Level label
		var ls: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
		draw_string(font, Vector2(cx - ls.x / 2.0, cy + 6), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.52, 0.6, 0.5))
		# Progress bar below gate
		var needed: int = gate_level * GATE_OPEN_SCORE_PER_LEVEL
		var progress: float = clampf(float(score) / float(needed), 0.0, 1.0)
		var bar_w: float = CELL_SIZE - 4.0
		var bar_h: float = 3.0
		var bar_x: float = cx - bar_w / 2.0
		var bar_y: float = cy + r + 5.0
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.15, 0.15, 0.2, 0.6), true)
		if progress > 0.01:
			var fill_w: float = bar_w * progress
			draw_rect(Rect2(bar_x, bar_y, fill_w, bar_h), Color(0.4, 0.4, 0.5, 0.8), true)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.5, 0.5, 0.6, 0.4), false, 1.0)

func _draw_chevron_up(cx: float, cy: float, arm: float, color: Color, width: float = 3.0) -> void:
	var shadow: Color = Color(0.0, 0.0, 0.0, color.a * 0.4)
	draw_line(Vector2(cx - arm + 1.0, cy + arm + 1.0), Vector2(cx + 1.0, cy + 1.0), shadow, width)
	draw_line(Vector2(cx + arm + 1.0, cy + arm + 1.0), Vector2(cx + 1.0, cy + 1.0), shadow, width)
	draw_line(Vector2(cx - arm, cy + arm), Vector2(cx, cy), color, width)
	draw_line(Vector2(cx + arm, cy + arm), Vector2(cx, cy), color, width)


`;

const insertBefore = '# =========================================================\n# Drawing - Helpers\n# =========================================================';
if (c.includes(insertBefore)) { c = c.replace(insertBefore, gateFunctions + insertBefore); console.log('12 Gate functions: OK'); }
else { console.log('12 Gate functions: FAIL'); ok = false; }

// 13. Add gate_anim update in _process (game mode section, after special_blink)
const old13 = '\tspecial_blink += delta * 8.0';
const new13 = '\tspecial_blink += delta * 8.0\n\tgate_anim += delta';
if (c.includes(old13)) { c = c.replace(old13, new13); console.log('13 Gate anim: OK'); }
else { console.log('13 Gate anim: FAIL'); ok = false; }

// 14. Add gate info in gameover screen (after gameover_score, before gameover_stats)
const old14 = '\t_draw_centered_text(Loc.t("gameover_score") % score, H / 2.0 - 35, 28, Color(1, 1, 1, 1))';
const new14 = '\t_draw_centered_text(Loc.t("gameover_score") % score, H / 2.0 - 35, 28, Color(1, 1, 1, 1))\n\t_draw_centered_text(Loc.t("gameover_level") % gate_level, H / 2.0 - 12, 16, Color(0.55, 0.58, 0.68, 0.7))';
if (c.includes(old14)) { c = c.replace(old14, new14); console.log('14 Gameover level: OK'); }
else { console.log('14 Gameover level: FAIL'); ok = false; }

// ============================================================
// AUDIO MANAGER.GD
// ============================================================

// A1: Add SFX variable
const oldA1 = 'var sfx_wormhole: AudioStreamWAV';
const newA1 = 'var sfx_wormhole: AudioStreamWAV\nvar sfx_gate_open: AudioStreamWAV\nvar sfx_gate_enter: AudioStreamWAV';
if (ac.includes(oldA1)) { ac = ac.replace(oldA1, newA1); console.log('A1 SFX vars: OK'); }
else { console.log('A1 SFX vars: FAIL'); aok = false; }

// A2: Add generation
const oldA2 = '\tsfx_wormhole = _make_wav(_synth_wormhole, 0.4, sr)';
const newA2 = '\tsfx_wormhole = _make_wav(_synth_wormhole, 0.4, sr)\n\tsfx_gate_open = _make_wav(_synth_gate_open, 0.5, sr)\n\tsfx_gate_enter = _make_wav(_synth_gate_enter, 0.6, sr)';
if (ac.includes(oldA2)) { ac = ac.replace(oldA2, newA2); console.log('A2 SFX gen: OK'); }
else { console.log('A2 SFX gen: FAIL'); aok = false; }

// A3: Add public methods
const oldA3 = 'func play_wormhole() -> void:\n\t_play_sfx(sfx_wormhole, -5.0)\n\nfunc play_game_over() -> void:';
const newA3 = `func play_wormhole() -> void:
	_play_sfx(sfx_wormhole, -5.0)

func play_gate_open() -> void:
	_play_sfx(sfx_gate_open, -3.0)

func play_gate_enter() -> void:
	_play_sfx(sfx_gate_enter, -2.0)

func play_game_over() -> void:`;
if (ac.includes(oldA3)) { ac = ac.replace(oldA3, newA3); console.log('A3 SFX methods: OK'); }
else { console.log('A3 SFX methods: FAIL'); aok = false; }

// A4: Add synth functions
const oldA4 = 'func _synth_wormhole(t: float, dur: float) -> float:';
const newA4 = `# --- Gate Open: ascending chime with resolve ---
func _synth_gate_open(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 4.0)
	var freq: float = 440.0 + t * 600.0
	var wave: float = sin(2.0 * PI * freq * t)
	wave += sin(2.0 * PI * freq * 1.5 * t) * exp(-t * 6.0) * 0.35
	wave += sin(2.0 * PI * freq * 2.0 * t) * exp(-t * 10.0) * 0.2
	# Sparkle notes
	for k in range(3):
		var nt: float = t - k * 0.06
		if nt > 0:
			var ne: float = exp(-nt * 18.0) * 0.3
			wave += sin(2.0 * PI * (880.0 + k * 220.0) * nt) * ne
	return wave * env * 0.45

# --- Gate Enter: triumphant ascending fanfare ---
func _synth_gate_enter(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 3.5) * 1.2
	# Ascending triad: C5 -> E5 -> G5
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
	# Shimmer
	wave += sin(2.0 * PI * (freq * 1.5) * t) * exp(-t * 8.0) * 0.15
	return wave * env * 0.45

func _synth_wormhole(t: float, dur: float) -> float:`;
if (ac.includes(oldA4)) { ac = ac.replace(oldA4, newA4); console.log('A4 SFX synth: OK'); }
else { console.log('A4 SFX synth: FAIL'); aok = false; }

// ============================================================
// LOCALIZATION
// ============================================================

const oldL1 = '\t"ui_speed":             {"en": "Speed: %.3fs",         "zh": "速度: %.3fs"},';
const newL1 = `\t"ui_speed":             {"en": "Speed: %.3fs",         "zh": "速度: %.3fs"},
	"ui_level":             {"en": "Lv.%d",                 "zh": "第%d关"},
	"ui_gate_closed":       {"en": "Gate %d/%d",             "zh": "大门 %d/%d"},
	"ui_gate_open":         {"en": "Gate OPEN!",            "zh": "大门已开!"},
	"gameover_level":       {"en": "Level: %d",             "zh": "关卡: %d"},
	"float_levelup":        {"en": "LEVEL %d!",             "zh": "第%d关!"},`;
if (lc.includes(oldL1)) { lc = lc.replace(oldL1, newL1); console.log('L1 Loc: OK'); }
else { console.log('L1 Loc: FAIL'); lok = false; }

// ============================================================
if (ok && aok && lok) {
    fs.writeFileSync(mp, c, 'utf8');
    fs.writeFileSync(ap, ac, 'utf8');
    fs.writeFileSync(lp, lc, 'utf8');
    console.log('\n✅ All 3 files written!');
} else {
    console.log('\n❌ FAILED');
    process.exit(1);
}
