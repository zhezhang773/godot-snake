const fs = require('fs');
const path = 'G:\\autoclawcode\\scripts\\Main.gd';
let c = fs.readFileSync(path, 'utf8');
let ok = 0;

function r(old, nw) {
    if (c.includes(old)) { c = c.replace(old, nw); ok++; return true; }
    console.log('FAIL:', JSON.stringify(old.substring(0, 80)));
    return false;
}

// =========================================================================
// 1. Add new animation variables after anim_timer
// =========================================================================
r(
    'var anim_timer: float = 0.0\n\n# Audio reference',
    `var anim_timer: float = 0.0

# Eating / cute animation
var eating_anim_timer: float = 0.0
var mouth_open: float = 0.0
var tongue_timer: float = 0.0
var tongue_flick_timer: float = 0.0
var blink_timer: float = 0.0
var is_blinking: bool = false
var next_blink_time: float = 3.0

# Audio reference`
);

// =========================================================================
// 2. Add cute snake colors after border_color
// =========================================================================
r(
    'var border_color: Color = Color(0.3, 0.4, 0.55, 1.0)\n\n# Boost color',
    `var border_color: Color = Color(0.3, 0.4, 0.55, 1.0)

# Cute snake colors
var belly_color: Color = Color(0.35, 0.92, 0.48, 1.0)
var blush_color: Color = Color(1.0, 0.5, 0.55, 0.35)
var tongue_color: Color = Color(0.95, 0.3, 0.35, 0.9)
var scale_dot_color: Color = Color(0.1, 0.6, 0.28, 0.25)
var mouth_color: Color = Color(0.12, 0.08, 0.08, 1.0)

# Boost color`
);

// =========================================================================
// 3. Add animation timer updates in _process()
// =========================================================================
r(
    '\tanim_timer += delta\n\tfood_pulse += delta * 5.0',
    `\tanim_timer += delta
\t# Eating animation timer
\tif eating_anim_timer > 0.0:
\t\teating_anim_timer = max(0.0, eating_anim_timer - delta)
\t\tvar eat_t: float = 1.0 - (eating_anim_timer / 0.3)
\t\tmouth_open = sin(eat_t * PI) * 0.8
\telse:
\t\tmouth_open = 0.0
\t# Tongue flick
\ttongue_timer += delta
\ttongue_flick_timer += delta
\tif tongue_timer > 2.5 and tongue_flick_timer < 0.01:
\t\ttongue_timer = 0.0
\t\ttongue_flick_timer = 0.0
\t# Blink
\tblink_timer += delta
\tif not is_blinking and blink_timer >= next_blink_time:
\t\tis_blinking = true
\t\tblink_timer = 0.0
\tif is_blinking and blink_timer >= 0.15:
\t\tis_blinking = false
\t\tblink_timer = 0.0
\t\tnext_blink_time = randf_range(2.0, 5.0)
\tfood_pulse += delta * 5.0`
);

// =========================================================================
// 4. Reset new variables in _reset_game()
// =========================================================================
r(
    '\tpaused = false\n\tpause_selected = 0\n\tif audio_manager:\n\t\taudio_manager.set_music_tempo(100.0)',
    `\tpaused = false
\tpause_selected = 0
\teating_anim_timer = 0.0
\tmouth_open = 0.0
\ttongue_timer = 0.0
\ttongue_flick_timer = 0.0
\tblink_timer = 0.0
\tis_blinking = false
\tnext_blink_time = 3.0
\tif audio_manager:
\t\taudio_manager.set_music_tempo(100.0)`
);

// =========================================================================
// 5. Trigger eating animation in _eat_food()
// =========================================================================
r(
    '\t_spawn_particles(pos, Color(1.0, 0.5, 0.3), 10, 80.0)\n\tvar text_color',
    '\teating_anim_timer = 0.3\n\t_spawn_particles(pos, Color(1.0, 0.5, 0.3), 10, 80.0)\n\tvar text_color'
);

// =========================================================================
// 6. Trigger eating animation in _eat_special_fruit()
// =========================================================================
r(
    '\t_spawn_particles(pos, Color(1.0, 0.85, 0.2), 25, 150.0)\n\t_spawn_floating_text("+%d" % bonus',
    '\teating_anim_timer = 0.3\n\t_spawn_particles(pos, Color(1.0, 0.85, 0.2), 25, 150.0)\n\t_spawn_floating_text("+%d" % bonus'
);

// =========================================================================
// 7. Replace entire _draw_snake through _draw_eyes with new cute snake code
// =========================================================================
const DRAW_START = 'func _draw_snake() -> void:';
const DRAW_END = '\n# =========================================================\n# Drawing - UI (Game HUD + Screens)';
const si = c.indexOf(DRAW_START);
const ei = c.indexOf(DRAW_END);
if (si >= 0 && ei >= 0 && si < ei) {
    const NEW_CODE = `func _draw_snake() -> void:
	if segments.is_empty():
		return
	var seg_count: int = segments.size()
	var alpha_factor: float = 1.0

	# Ghost alpha
	if ghost_active:
		if ghost_timer <= GHOST_WARN_THRESHOLD:
			var urgency: float = 1.0 - (ghost_timer / GHOST_WARN_THRESHOLD)
			var freq: float = lerpf(0.6, 6.0, urgency)
			alpha_factor = 0.5 + 0.5 * sin(special_blink * freq)
		else:
			alpha_factor = 0.5 + 0.5 * sin(special_blink * 0.6)

	# Eating bounce scale
	var eat_scale: float = 1.0
	if eating_anim_timer > 0.0:
		var eat_t: float = 1.0 - (eating_anim_timer / 0.3)
		eat_scale = 1.0 + sin(eat_t * PI) * 0.15

	# Precompute centers and radii
	var centers: Array[Vector2] = []
	var radii: Array[float] = []
	for i in range(seg_count):
		var seg: Vector2i = segments[i]
		var center: Vector2 = Vector2(
			seg.x * CELL_SIZE + CELL_SIZE / 2.0,
			seg.y * CELL_SIZE + CELL_SIZE / 2.0
		)
		var t_ratio: float = float(i) / float(max(seg_count - 1, 1))
		var rad: float
		if i == 0:
			rad = CELL_SIZE * 0.48 * eat_scale
		else:
			rad = lerp(CELL_SIZE * 0.38, CELL_SIZE * 0.10, t_ratio * t_ratio)
		# Body undulation (slithering)
		if i > 0:
			var wave: float = sin(anim_timer * 5.0 + float(i) * 0.8) * 1.8
			var perp: Vector2 = _body_perpendicular(i)
			center += perp * wave
		centers.append(center)
		radii.append(rad)

	# --- Layer 1: Body connections (smooth bridges between segments) ---
	for i in range(seg_count - 1):
		var s1: Vector2i = segments[i]
		var s2: Vector2i = segments[i + 1]
		if _get_terrain(s1.x, s1.y) == Terrain.FOREST:
			continue
		if _get_terrain(s2.x, s2.y) == Terrain.FOREST:
			continue
		var c1: Vector2 = centers[i + 1]
		var c2: Vector2 = centers[i]
		var r1: float = radii[i + 1]
		var r2: float = radii[i]
		var dx: float = c2.x - c1.x
		var dy: float = c2.y - c1.y
		var dist: float = sqrt(dx * dx + dy * dy)
		if dist < 0.5:
			continue
		var nx: float = -dy / dist
		var ny: float = dx / dist
		var t_ratio: float = float(i) / float(max(seg_count - 1, 1))
		var conn_color: Color
		if ghost_active:
			conn_color = ghost_body_color.lerp(ghost_tail_color, t_ratio)
			conn_color.a *= alpha_factor * 0.85
		else:
			conn_color = body_color.lerp(tail_color, t_ratio)
			if boosted and boost_glow > 0.1:
				conn_color.r = min(1.0, conn_color.r + t_ratio * boost_glow * 0.3)
				conn_color.g = min(1.0, conn_color.g + t_ratio * boost_glow * 0.15)
		var pts = PackedVector2Array()
		pts.append(c1 + Vector2(nx, ny) * r1 * 0.88)
		pts.append(c2 + Vector2(nx, ny) * r2 * 0.88)
		pts.append(c2 - Vector2(nx, ny) * r2 * 0.88)
		pts.append(c1 - Vector2(nx, ny) * r1 * 0.88)
		draw_colored_polygon(pts, conn_color)

	# --- Layer 2: Body circles (tail to head so head is on top) ---
	for i in range(seg_count - 1, 0, -1):
		var seg: Vector2i = segments[i]
		if _get_terrain(seg.x, seg.y) == Terrain.FOREST:
			continue
		var center: Vector2 = centers[i]
		var radius: float = radii[i]
		var t_ratio: float = float(i) / float(max(seg_count - 1, 1))

		# Main body circle
		var body_c: Color
		if ghost_active:
			body_c = ghost_body_color.lerp(ghost_tail_color, t_ratio)
			body_c.a *= alpha_factor
		else:
			body_c = body_color.lerp(tail_color, t_ratio)
			if boosted and boost_glow > 0.1:
				var warmth: float = t_ratio * boost_glow * 0.3
				body_c.r = min(1.0, body_c.r + warmth)
				body_c.g = min(1.0, body_c.g + warmth * 0.5)
		draw_circle(center, radius, body_c)

		# Belly highlight (lighter underside)
		if not ghost_active and radius > 4.0:
			var belly_c: Color = Color(belly_color.r, belly_color.g, belly_color.b, 0.2)
			draw_circle(center + Vector2(0, radius * 0.18), radius * 0.55, belly_c)

		# Diamond scale pattern (every 2nd segment, skip tiny tail)
		if radius > 6.0 and i % 2 == 0:
			var dot_c: Color = Color(scale_dot_color.r, scale_dot_color.g, scale_dot_color.b, scale_dot_color.a * alpha_factor)
			for k in range(4):
				var a: float = float(k) * TAU / 4.0 + float(i) * 0.6
				var d_pos: Vector2 = center + Vector2(cos(a), sin(a)) * radius * 0.42
				draw_circle(d_pos, max(1.0, radius * 0.07), dot_c)

		# Tail tip cute highlight
		if i == seg_count - 1:
			var tip_c: Color
			if ghost_active:
				tip_c = Color(0.35, 0.3, 0.8, 0.5 * alpha_factor)
			else:
				tip_c = Color(0.22, 0.88, 0.42, 0.45)
			draw_circle(center, radius * 0.55, tip_c)

	# --- Layer 3: Head (drawn last, always on top) ---
	var seg0: Vector2i = segments[0]
	if _get_terrain(seg0.x, seg0.y) != Terrain.FOREST:
		var head_center: Vector2 = centers[0]
		var head_r: float = radii[0]

		# Boost glow aura
		if boosted and boost_glow > 0.1 and not ghost_active:
			var glow_a: float = boost_glow * 0.2 * (0.6 + 0.4 * abs(sin(anim_timer * 8.0)))
			draw_circle(head_center, head_r * 1.5, Color(boost_glow_color.r, boost_glow_color.g, boost_glow_color.b, glow_a))

		# Head shadow (gives depth)
		draw_circle(head_center + Vector2(1.5, 1.5), head_r, Color(0.0, 0.0, 0.0, 0.12 * alpha_factor))

		# Main head circle
		var head_c: Color
		if ghost_active:
			head_c = Color(ghost_head_color.r, ghost_head_color.g, ghost_head_color.b, ghost_head_color.a * alpha_factor)
			draw_circle(head_center, head_r, head_c)
			draw_circle(head_center, head_r * 1.15, Color(0.4, 0.3, 1.0, 0.06 * alpha_factor))
		else:
			head_c = head_color
			draw_circle(head_center, head_r, head_c)
			# Top-left highlight (3D roundness)
			var hl: Color = Color(min(1.0, head_c.r + 0.12), min(1.0, head_c.g + 0.08), min(1.0, head_c.b + 0.08), 0.3)
			draw_circle(head_center + Vector2(-head_r * 0.2, -head_r * 0.22), head_r * 0.45, hl)
			# Snout bump (extends head in movement direction)
			var snout_pos: Vector2 = head_center + Vector2(direction) * head_r * 0.35
			draw_circle(snout_pos, head_r * 0.52, head_c)
			# Snout highlight
			draw_circle(snout_pos + Vector2(-head_r * 0.08, -head_r * 0.12), head_r * 0.28, hl)
			# Belly area on head
			var bh: Color = Color(belly_color.r, belly_color.g, belly_color.b, 0.25)
			draw_circle(head_center + Vector2(0, head_r * 0.12), head_r * 0.42, bh)

		# Eyes (big cute eyes)
		_draw_eyes(seg0, direction, head_center, head_r, alpha_factor)

		# Rosy blush cheeks
		if not ghost_active:
			var fwd: Vector2 = Vector2(direction) * head_r * 0.12
			var perp_d: Vector2 = Vector2(-direction.y, direction.x)
			var cheek_dist: float = head_r * 0.52
			var blush_a: float = blush_color.a * alpha_factor
			draw_circle(head_center + perp_d * cheek_dist + fwd, head_r * 0.17, Color(blush_color.r, blush_color.g, blush_color.b, blush_a))
			draw_circle(head_center - perp_d * cheek_dist + fwd, head_r * 0.17, Color(blush_color.r, blush_color.g, blush_color.b, blush_a))

		# Forked tongue (flicks periodically)
		if tongue_flick_timer < 0.18 and tongue_flick_timer > 0.01 and not ghost_active:
			_draw_tongue(head_center, head_r, alpha_factor)

		# Eating mouth animation
		if mouth_open > 0.05 and not ghost_active:
			_draw_eating_mouth(head_center, head_r, alpha_factor)


func _body_perpendicular(seg_idx: int) -> Vector2:
	if seg_idx <= 0 or seg_idx >= segments.size():
		return Vector2(-direction.y, direction.x)
	var diff: Vector2i = segments[seg_idx - 1] - segments[seg_idx]
	if diff.x == 0 and diff.y == 0:
		return Vector2(-direction.y, direction.x)
	return Vector2(-diff.y, diff.x).normalized()


# =========================================================
# Drawing - Cute Eyes (big, sparkly, blinking)
# =========================================================
func _draw_eyes(pos: Vector2i, dir: Vector2i, center: Vector2, head_r: float, alpha_factor: float) -> void:
	var eye_sz: float = head_r * 0.30
	var pupil_sz: float = eye_sz * 0.50
	var eye_off: float = head_r * 0.38
	var fwd_off: float = head_r * 0.22
	var fwd: Vector2 = Vector2(dir) * fwd_off
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var re: Vector2 = center + fwd + perp * eye_off
	var le: Vector2 = center + fwd - perp * eye_off

	var ec: Color
	var pc: Color
	if ghost_active:
		ec = Color(0.7, 0.65, 1.0, 0.6 * alpha_factor)
		pc = Color(0.3, 0.2, 0.8, 0.8 * alpha_factor)
	elif boosted and boost_glow > 0.3:
		var bf: float = boost_glow * 0.3
		ec = Color(1.0, lerp(1.0, 0.85, bf), lerp(1.0, 0.7, bf), 1.0)
		pc = Color(lerp(0.1, 0.3, bf), lerp(0.1, 0.15, bf), lerp(0.1, 0.0, bf), 1.0)
	else:
		ec = eye_color
		pc = pupil_color

	if is_blinking:
		# Blink: cute closed-eye curves (arc)
		var blink_w: float = eye_sz * 0.75
		var blink_c: Color = Color(ec.r, ec.g, ec.b, ec.a)
		draw_arc(re, blink_w, 0.3, PI - 0.3, 12, blink_c, 2.5)
		draw_arc(le, blink_w, 0.3, PI - 0.3, 12, blink_c, 2.5)
	else:
		# Eye shadow
		draw_circle(re + Vector2(1, 1), eye_sz, Color(0, 0, 0, 0.12 * alpha_factor))
		draw_circle(le + Vector2(1, 1), eye_sz, Color(0, 0, 0, 0.12 * alpha_factor))
		# White of eyes
		draw_circle(re, eye_sz, ec)
		draw_circle(le, eye_sz, ec)
		# Pupils (shift toward movement direction)
		var ps: Vector2 = Vector2(dir) * eye_sz * 0.22
		draw_circle(re + ps, pupil_sz, pc)
		draw_circle(le + ps, pupil_sz, pc)
		# Primary sparkle highlights (top-left of each eye)
		var hl1: Vector2 = Vector2(-eye_sz * 0.24, -eye_sz * 0.28)
		var hl_sz: float = eye_sz * 0.25
		var hl_c: Color = Color(1.0, 1.0, 1.0, 0.93 * alpha_factor)
		draw_circle(re + hl1, hl_sz, hl_c)
		draw_circle(le + hl1, hl_sz, hl_c)
		# Secondary sparkle (smaller, bottom-right)
		var hl2: Vector2 = Vector2(eye_sz * 0.16, eye_sz * 0.08)
		draw_circle(re + hl2, hl_sz * 0.55, hl_c)
		draw_circle(le + hl2, hl_sz * 0.55, hl_c)


# =========================================================
# Drawing - Forked Tongue
# =========================================================
func _draw_tongue(center: Vector2, head_r: float, alpha_factor: float) -> void:
	var flick_t: float = tongue_flick_timer / 0.18
	var alpha: float = sin(flick_t * PI) * 0.85
	if alpha < 0.02:
		return
	var t_c: Color = Color(tongue_color.r, tongue_color.g, tongue_color.b, alpha * alpha_factor)
	var tongue_len: float = head_r * 0.6
	var base_pos: Vector2 = center + Vector2(direction) * head_r * 0.82
	var tip_pos: Vector2 = base_pos + Vector2(direction) * tongue_len
	var perp: Vector2 = Vector2(-direction.y, direction.x)
	var fork_len: float = tongue_len * 0.32
	var fork_spread: float = head_r * 0.22

	# Main tongue line
	draw_line(base_pos, tip_pos, t_c, 2.0)
	# Forked tips
	var fork_l: Vector2 = tip_pos + Vector2(direction) * fork_len + perp * fork_spread
	var fork_r: Vector2 = tip_pos + Vector2(direction) * fork_len - perp * fork_spread
	draw_line(tip_pos, fork_l, t_c, 1.5)
	draw_line(tip_pos, fork_r, t_c, 1.5)
	# Tiny round tips
	draw_circle(fork_l, 1.2, t_c)
	draw_circle(fork_r, 1.2, t_c)


# =========================================================
# Drawing - Eating Mouth Animation
# =========================================================
func _draw_eating_mouth(center: Vector2, head_r: float, alpha_factor: float) -> void:
	var mouth_pos: Vector2 = center + Vector2(direction) * head_r * 0.52
	var mouth_r: float = head_r * 0.28 * mouth_open
	var m_alpha: float = 0.8 * mouth_open * alpha_factor

	# Dark mouth cavity
	draw_circle(mouth_pos, mouth_r, Color(mouth_color.r, mouth_color.g, mouth_color.b, m_alpha))

	# Happy lip curve
	if mouth_open > 0.3:
		var lip_c: Color = Color(0.85, 0.25, 0.3, 0.3 * mouth_open * alpha_factor)
		var lip_r: float = mouth_r * 0.65
		draw_arc(mouth_pos + Vector2(direction) * mouth_r * 0.15, lip_r, 0.4, PI - 0.4, 16, lip_c, 1.8)

	# Little "nom nom" sparkles around mouth
	if mouth_open > 0.5:
		var sparkle_count: int = 3
		for k in range(sparkle_count):
			var s_angle: float = float(k) * TAU / float(sparkle_count) + anim_timer * 4.0
			var s_dist: float = head_r * 0.7
			var s_pos: Vector2 = mouth_pos + Vector2(cos(s_angle), sin(s_angle)) * s_dist
			var s_size: float = 2.0 + sin(anim_timer * 8.0 + k) * 1.0
			var s_alpha: float = 0.4 * mouth_open * alpha_factor
			# Star sparkle
			var sc: Color = Color(1.0, 1.0, 0.7, s_alpha)
			draw_circle(s_pos, s_size, sc)
			draw_circle(s_pos, s_size * 0.4, Color(1.0, 1.0, 1.0, s_alpha * 1.2))


`;

    c = c.substring(0, si) + NEW_CODE + c.substring(ei);
    ok++;
    console.log('Big draw replacement: OK');
} else {
    console.log('Big draw replacement: FAIL si=', si, 'ei=', ei);
}

// =========================================================================
// Write result
// =========================================================================
fs.writeFileSync(path, c, 'utf8');
console.log('\n' + ok + ' replacements applied successfully');
