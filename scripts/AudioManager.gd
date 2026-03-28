extends Node

# =========================================================
# AudioManager - All audio generated procedurally
# =========================================================

# === Nodes ===
var music_player: AudioStreamPlayer = null

# === Music State ===
var music_gen: AudioStreamGenerator
var music_pb: AudioStreamPlayback = null
var _music_time: float = 0.0
var _music_volume: float = 0.0
var _target_volume: float = 0.0
var _music_tempo: float = 100.0
var _target_tempo: float = 100.0

# Pentatonic scale (C major pentatonic, 2 octaves)
var scale: Array[float] = [
	130.81, 146.83, 164.81, 196.00, 220.00,  # C3 D3 E3 G3 A3
	261.63, 293.66, 329.63, 392.00, 440.00,  # C4 D4 E4 G4 A4
	523.25, 587.33, 659.25,                     # C5 D5 E5
]

# 16-step patterns (scale indices, -1 = rest)
var melody_pattern: Array[int] = [7, -1, 9, -1, 10, -1, 9, -1, 7, -1, 6, -1, 5, -1, 6, -1]
var bass_pattern: Array[int] = [0, -1, -1, -1, 3, -1, -1, -1, 2, -1, -1, -1, 0, -1, -1, -1]
var kick_pattern: Array[int] = [1, -1, -1, -1, 1, -1, -1, -1, 1, -1, -1, -1, 1, -1, -1, -1]
var hihat_pattern: Array[int] = [1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1]
var arp_pattern: Array[int] = [5, 7, 9, 10, 9, 7, 5, 3, 4, 5, 7, 9, 7, 5, 4, 3]

# Pre-generated SFX
var sfx_eat_fruit: AudioStreamWAV
var sfx_special_appear: AudioStreamWAV
var sfx_bomb_tick: AudioStreamWAV
var sfx_bomb_tick_urgent: AudioStreamWAV
var sfx_bomb_explode: AudioStreamWAV
var sfx_wall_hit: AudioStreamWAV
var sfx_wall_soft_hit: AudioStreamWAV
var sfx_game_over: AudioStreamWAV
var sfx_wormhole: AudioStreamWAV
var sfx_gate_open: AudioStreamWAV
var sfx_gate_enter: AudioStreamWAV

# =========================================================
# Lifecycle
# =========================================================

func _ready() -> void:
	# Create music player node programmatically
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	_generate_all_sfx()
	_setup_music()

func _process(delta: float) -> void:
	# Smooth volume transition
	_music_volume = lerpf(_music_volume, _target_volume, delta * 5.0)
	# Smooth tempo transition
	_music_tempo = lerpf(_music_tempo, _target_tempo, delta * 3.0)
	# Fill music buffer
	if music_pb != null:
		_fill_music_buffer()

# =========================================================
# Public API
# =========================================================

func set_music_volume(vol: float) -> void:
	_target_volume = clampf(vol, 0.0, 1.0)

func set_music_tempo(bpm: float) -> void:
	_target_tempo = clampf(bpm, 60.0, 220.0)

func play_eat_fruit() -> void:
	_play_sfx(sfx_eat_fruit, -8.0)

func play_special_appear() -> void:
	_play_sfx(sfx_special_appear, -5.0)

func play_bomb_tick(urgent: bool = false) -> void:
	if urgent:
		_play_sfx(sfx_bomb_tick_urgent, -3.0)
	else:
		_play_sfx(sfx_bomb_tick, -6.0)

func play_bomb_explode() -> void:
	_play_sfx(sfx_bomb_explode, 0.0)

func play_wall_hit(soft: bool = false) -> void:
	if soft:
		_play_sfx(sfx_wall_soft_hit, -6.0)
	else:
		_play_sfx(sfx_wall_hit, -2.0)

func play_wormhole() -> void:
	_play_sfx(sfx_wormhole, -5.0)

func play_gate_open() -> void:
	_play_sfx(sfx_gate_open, -3.0)

func play_gate_enter() -> void:
	_play_sfx(sfx_gate_enter, -2.0)

func play_game_over() -> void:
	_play_sfx(sfx_game_over, 0.0)

# =========================================================
# Music Setup
# =========================================================

func _setup_music() -> void:
	music_gen = AudioStreamGenerator.new()
	music_gen.mix_rate = 22050
	music_gen.buffer_length = 0.1
	music_player.stream = music_gen
	music_player.play()
	music_pb = music_player.get_stream_playback()

func _fill_music_buffer() -> void:
	var available: int = music_pb.get_frames_available()
	if available <= 0:
		return
	var fill: int = mini(available, 8192)
	var sr: float = float(music_gen.mix_rate)
	var step_dur: float = 60.0 / _music_tempo / 4.0  # 16th note
	var buf = PackedVector2Array()
	buf.resize(fill)

	for i in range(fill):
		var t: float = _music_time
		var step: int = int(t / step_dur) % 16
		var phase: float = fmod(t, step_dur) / step_dur
		var sample: float = 0.0

		# --- Melody (sine + overtone for warmth) ---
		if melody_pattern[step] >= 0:
			var freq: float = scale[melody_pattern[step]]
			var env: float = exp(-phase * 14.0) * 0.18
			sample += sin(2.0 * PI * freq * t) * env
			sample += sin(2.0 * PI * freq * 2.01 * t) * env * 0.12
			sample += sin(2.0 * PI * freq * 3.0 * t) * env * 0.04

		# --- Arpeggio (softer, atmospheric) ---
		if arp_pattern[step] >= 0:
			var freq: float = scale[arp_pattern[step]] * 2.0  # One octave up
			var env: float = exp(-phase * 10.0) * 0.06
			sample += sin(2.0 * PI * freq * t) * env

		# --- Bass (deep sine) ---
		if bass_pattern[step] >= 0:
			var freq: float = scale[bass_pattern[step]]
			var env: float = exp(-phase * 6.0) * 0.30
			sample += sin(2.0 * PI * freq * t) * env
			# Sub harmonic for weight
			sample += sin(2.0 * PI * freq * 0.5 * t) * env * 0.15

		# --- Kick (pitch-swept sine) ---
		if kick_pattern[step] > 0:
			var kick_freq: float = 200.0 * exp(-phase * 30.0) + 45.0
			var kick_env: float = exp(-phase * 18.0) * 0.35
			sample += sin(2.0 * PI * kick_freq * t) * kick_env

		# --- Hi-hat (cheap noise approximation) ---
		if hihat_pattern[step] > 0:
			var hh_env: float = exp(-phase * 30.0) * 0.05
			var noise: float = sin(t * 12345.67) * 0.4 + sin(t * 76543.21) * 0.3 + sin(t * 34567.89) * 0.2 + sin(t * 11111.11) * 0.1
			sample += noise * hh_env

		sample = clampf(sample * _music_volume, -1.0, 1.0)
		buf[i] = Vector2(sample, sample)
		_music_time += 1.0 / sr

	music_pb.push_buffer(buf)

# =========================================================
# SFX Generation
# =========================================================

func _generate_all_sfx() -> void:
	var sr: int = 22050
	sfx_eat_fruit = _make_wav(_synth_eat_fruit, 0.18, sr)
	sfx_special_appear = _make_wav(_synth_special_appear, 0.45, sr)
	sfx_bomb_tick = _make_wav(_synth_bomb_tick, 0.10, sr)
	sfx_bomb_tick_urgent = _make_wav(_synth_bomb_tick_urgent, 0.07, sr)
	sfx_bomb_explode = _make_wav(_synth_bomb_explode, 0.5, sr)
	sfx_wall_hit = _make_wav(_synth_wall_hit, 0.25, sr)
	sfx_wall_soft_hit = _make_wav(_synth_wall_soft_hit, 0.18, sr)
	sfx_game_over = _make_wav(_synth_game_over, 0.6, sr)
	sfx_wormhole = _make_wav(_synth_wormhole, 0.4, sr)
	sfx_gate_open = _make_wav(_synth_gate_open, 0.5, sr)
	sfx_gate_enter = _make_wav(_synth_gate_enter, 0.6, sr)

func _make_wav(synth: Callable, duration: float, sample_rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var s: float = synth.call(t, duration)
		s = clampf(s, -1.0, 1.0)
		var val: int = int(s * 32700)
		val = clampi(val, -32768, 32767)
		pcm[i * 2] = val & 0xFF
		pcm[i * 2 + 1] = (val >> 8) & 0xFF
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# --- Eat Fruit: ascending bell-like chime ---
func _synth_eat_fruit(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 8.0)
	# Two quick ascending tones: C5 -> E5 -> G5
	var freq: float
	if t < dur * 0.33:
		freq = 523.25  # C5
	elif t < dur * 0.66:
		freq = 659.25  # E5
	else:
		freq = 783.99  # G5
	var wave: float = sin(2.0 * PI * freq * t)
	# Add harmonic for bell quality
	wave += sin(2.0 * PI * freq * 2.76 * t) * 0.3
	wave += sin(2.0 * PI * freq * 5.4 * t) * 0.1
	return wave * env * 0.6

# --- Special Fruit Appear: sparkle shimmer ---
func _synth_special_appear(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 5.0) * 1.2
	# Rising tone with shimmer
	var base_freq: float = 800.0 + t * 1200.0
	var wave: float = sin(2.0 * PI * base_freq * t)
	# Sparkle: multiple high harmonics that fade differently
	wave += sin(2.0 * PI * base_freq * 1.5 * t) * exp(-t * 8.0) * 0.4
	wave += sin(2.0 * PI * base_freq * 2.0 * t) * exp(-t * 12.0) * 0.3
	wave += sin(2.0 * PI * base_freq * 3.0 * t) * exp(-t * 16.0) * 0.15
	# Add arpeggio sparkle notes
	for k in range(3):
		var note_t: float = t - k * 0.08
		if note_t > 0:
			var note_env: float = exp(-note_t * 20.0) * 0.25
			var sparkle_freq: float = 1200.0 + k * 400.0
			wave += sin(2.0 * PI * sparkle_freq * note_t) * note_env
	return wave * env * 0.35

# --- Bomb Tick: short electronic beep ---
func _synth_bomb_tick(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 12.0)
	var wave: float = sin(2.0 * PI * 800.0 * t)
	# Square-ish: add odd harmonics
	wave += sin(2.0 * PI * 800.0 * 3.0 * t) * 0.3 * env
	return wave * env * 0.55

# --- Bomb Tick Urgent: higher, shorter, sharper ---
func _synth_bomb_tick_urgent(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 15.0)
	var wave: float = sin(2.0 * PI * 1200.0 * t)
	wave += sin(2.0 * PI * 1200.0 * 3.0 * t) * 0.35 * env
	return wave * env * 0.6

# --- Bomb Explode: low boom + noise burst ---
func _synth_bomb_explode(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 4.0)
	# Low frequency boom
	var boom_freq: float = 80.0 * exp(-t * 8.0) + 40.0
	var boom: float = sin(2.0 * PI * boom_freq * t) * env * 0.8
	# Noise burst
	var noise: float = sin(t * 12345.67) * 0.3 + sin(t * 76543.21) * 0.3 + sin(t * 34567.89) * 0.2 + sin(t * 11111.11) * 0.2
	noise *= exp(-t * 10.0) * 0.5
	# Mid-range crunch
	var crunch: float = sin(2.0 * PI * 200.0 * t) * exp(-t * 6.0) * 0.3
	return (boom + noise + crunch) * 0.6

# --- Wall Hit: sharp thud + high crack ---
func _synth_wall_hit(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 12.0)
	var thud: float = sin(2.0 * PI * 120.0 * t) * env * 0.6
	var crack: float = sin(2.0 * PI * 1800.0 * t) * exp(-t * 30.0) * 0.4
	var noise: float = (sin(t * 12345.67) * 0.3 + sin(t * 76543.21) * 0.3 + sin(t * 34567.89) * 0.2) * exp(-t * 15.0) * 0.3
	return (thud + crack + noise) * env * 0.65

# --- Wall Soft Hit: gentle padded bump (Wall Stop active) ---
func _synth_wall_soft_hit(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 8.0)
	var tone: float = sin(2.0 * PI * 200.0 * t) * env * 0.4
	tone += sin(2.0 * PI * 400.0 * t) * env * 0.15
	var pad: float = sin(2.0 * PI * 100.0 * t) * exp(-t * 6.0) * 0.25
	return (tone + pad) * 0.5

# --- Game Over: descending sad tone + noise ---
func _synth_game_over(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 3.5)
	var base_freq: float = 440.0 - t * 300.0
	var tone: float = sin(2.0 * PI * base_freq * t) * env * 0.5
	var detune: float = sin(2.0 * PI * (base_freq * 1.056) * t) * env * 0.3
	var rumble: float = sin(2.0 * PI * 60.0 * t) * exp(-t * 5.0) * 0.35
	var noise: float = (sin(t * 12345.67) * 0.3 + sin(t * 76543.21) * 0.3 + sin(t * 34567.89) * 0.2) * exp(-t * 6.0) * 0.2
	return (tone + detune + rumble + noise) * 0.55

# =========================================================
# SFX Playback
# =========================================================

# --- Wormhole: warbling descending sweep ---
# --- Gate Open: ascending chime with resolve ---
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

func _synth_wormhole(t: float, dur: float) -> float:
	var env: float = exp(-t / dur * 6.0) * 0.8
	var freq: float = 600.0 * exp(-t * 5.0) + 80.0
	var wave: float = sin(2.0 * PI * freq * t)
	wave += sin(2.0 * PI * freq * 1.5 * t) * exp(-t * 8.0) * 0.4
	wave += sin(2.0 * PI * freq * 0.5 * t) * 0.3
	var wobble: float = sin(t * 25.0) * 0.15
	return (wave + wobble) * env * 0.5

func _play_sfx(stream: AudioStreamWAV, volume_db: float = 0.0) -> void:
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
