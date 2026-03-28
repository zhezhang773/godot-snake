const fs = require('fs');
const path = 'G:\\autoclawcode\\scripts\\Main.gd';
let c = fs.readFileSync(path, 'utf8');

// === Change 1: Remove highlight from SPEED_UP/SPEED_DOWN balls ===
const old1 = '\tdraw_circle(center + Vector2(-3, -4), radius * 0.25, Color(1.0, 1.0, 1.0, 0.5 * flash_alpha))';
const new1 = '\tif special_type != SpecialType.SPEED_UP and special_type != SpecialType.SPEED_DOWN:\n\t\tdraw_circle(center + Vector2(-3, -4), radius * 0.25, Color(1.0, 1.0, 1.0, 0.5 * flash_alpha))';
let r1 = false;
if (c.includes(old1)) { c = c.replace(old1, new1); r1 = true; }
console.log('Change 1 (highlight):', r1 ? 'OK' : 'FAIL');

// === Change 2: Remove countdown from fruit + warning flash ===
const old2a = `\tif special_type != SpecialType.SPEED_UP and special_type != SpecialType.SPEED_DOWN:
\t\tvar remaining: int = ceili(special_timer)
\t\tvar countdown_text: String = str(remaining)
\t\tvar font = ThemeDB.fallback_font
\t\tvar ts: Vector2 = font.get_string_size(countdown_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 22)
\t\tvar tx: float = center.x - ts.x / 2.0
\t\tvar ty: float = center.y - ts.y / 2.0 + 3
\t\tdraw_string(font, Vector2(tx + 1, ty + 1), countdown_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0, 0, 0, 0.7 * flash_alpha))
\t\tdraw_string(font, Vector2(tx, ty), countdown_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 1.0, 1.0, flash_alpha))

\t\tif special_timer <= 2.0 and special_timer > 0.0:
\t\t\tvar warn: float = abs(sin(special_blink * 1.5))
\t\t\tif warn > 0.5:
\t\t\t\tdraw_circle(center, radius + 3.0, Color(1.0, 1.0, 1.0, 0.15))`;
let r2 = false;
if (c.includes(old2a)) { c = c.replace(old2a, ''); r2 = true; }
console.log('Change 2 (countdown from fruit):', r2 ? 'OK' : 'FAIL');

// === Change 3: Shrink effect bars (180px wide, 10px tall, font 10) ===
const old3a = '\tvar bar_y: float = GRID_HEIGHT * CELL_SIZE - 22.0 - index * 20.0\n\tvar bar_w: float = GRID_WIDTH * CELL_SIZE - 20.0\n\tvar bar_h: float = 14.0';
const new3a = '\tvar bar_y: float = GRID_HEIGHT * CELL_SIZE - 16.0 - index * 14.0\n\tvar bar_w: float = 180.0\n\tvar bar_h: float = 10.0';
let r3a = false;
if (c.includes(old3a)) { c = c.replace(old3a, new3a); r3a = true; }
console.log('Change 3a (bar size):', r3a ? 'OK' : 'FAIL');

const old3b = '\tvar ts: Vector2 = ThemeDB.fallback_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)';
const new3b = '\tvar ts: Vector2 = ThemeDB.fallback_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)';
let r3b = false;
if (c.includes(old3b)) { c = c.replace(old3b, new3b); r3b = true; }
console.log('Change 3b (bar ts size):', r3b ? 'OK' : 'FAIL');

const old3c = '\t\ttxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.9))';
const new3c = '\t\ttxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.9))';
let r3c = false;
if (c.includes(old3c)) { c = c.replace(old3c, new3c); r3c = true; }
console.log('Change 3c (bar font):', r3c ? 'OK' : 'FAIL');

// === Change 4: Add special countdown call in _draw_ui (before effect bars) ===
const old4 = '\t# ---- Effect bars ----';
const new4 = '\t# ---- Special fruit countdown (top-right) ----\n\tif special_active and special_timer > 0.0:\n\t\t_draw_special_countdown(W, H)\n\n\t# ---- Effect bars ----';
let r4 = false;
if (c.includes(old4)) { c = c.replace(old4, new4); r4 = true; }
console.log('Change 4 (UI call):', r4 ? 'OK' : 'FAIL');

// === Change 5: Add _draw_special_countdown function (before _draw_rounded_rect) ===
const newFunc = `# =========================================================
# Drawing - Special Fruit Countdown (top-right corner)
# =========================================================

func _draw_special_countdown(W: float, H: float) -> void:
	var font = ThemeDB.fallback_font
	var remaining: int = ceili(special_timer)
	var palette: Array = special_colors[special_type]
	var base_c: Color = palette[0]

	var icon: String
	var label: String
	match special_type:
		SpecialType.GHOST:     icon = "G";  label = Loc.t("effect_ghost")
		SpecialType.WALL_STOP: icon = "S";  label = Loc.t("effect_shield")
		SpecialType.FOOD_RAIN: icon = "F";  label = Loc.t("help_rain_key")
		SpecialType.WALL_PASS: icon = "P";  label = Loc.t("effect_pass")
		SpecialType.SPEED_UP:  icon = ">>"; label = Loc.t("help_speedup_key")
		SpecialType.SPEED_DOWN: icon = "<<"; label = Loc.t("help_speeddown_key")
		_: icon = "?"; label = ""

	var text: String = icon + " " + str(remaining) + "s"
	var text_sz: int = 14
	var ts: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_sz)

	var pill_w: float = ts.x + 20.0
	var pill_h: float = 24.0
	var pill_x: float = W - pill_w - 12.0
	var pill_y: float = 12.0
	var pill_rect: Rect2 = Rect2(pill_x, pill_y, pill_w, pill_h)

	# Warning flash when time is low
	var alpha: float = 1.0
	if special_timer <= 2.0 and special_timer > 0.0:
		var warn: float = abs(sin(special_blink * 1.5))
		if warn > 0.5:
			alpha = 0.5

	# Pill background + border
	_draw_rounded_rect(pill_rect, Color(base_c.r, base_c.g, base_c.b, 0.18 * alpha), 12)
	_draw_rounded_rect(pill_rect, Color(base_c.r, base_c.g, base_c.b, 0.55 * alpha), 12, false, 1.5)

	# Text (shadow + main)
	var tx: float = pill_x + (pill_w - ts.x) / 2.0
	var ty: float = pill_y + (pill_h - ts.y) / 2.0 + 1
	draw_string(font, Vector2(tx + 1, ty + 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_sz, Color(0, 0, 0, 0.4 * alpha))
	draw_string(font, Vector2(tx, ty), text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_sz, Color(1.0, 1.0, 1.0, 0.9 * alpha))

`;

const old5 = 'func _draw_rounded_rect(rect: Rect2, color: Color, radius: float, filled: bool = true, width: float = -1.0) -> void:';
let r5 = false;
if (c.includes(old5)) { c = c.replace(old5, newFunc + old5); r5 = true; }
console.log('Change 5 (countdown function):', r5 ? 'OK' : 'FAIL');

if (r1 && r2 && r3a && r3b && r3c && r4 && r5) {
  fs.writeFileSync(path, c, 'utf8');
  console.log('All changes written successfully');
} else {
  console.log('Some changes FAILED - not writing file');
}
