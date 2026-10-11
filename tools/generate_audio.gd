extends SceneTree
## Original synthesized PCM assets. No network or third-party samples.
const RATE: int = 22050
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 672918
	DirAccess.make_dir_recursive_absolute("res://assets/audio")
	for id: String in ["ui", "pistol", "shotgun", "plasma_blaster", "hit", "hurt", "dash", "skill", "heal", "door", "rune", "wrong", "solve", "push", "reward", "portal", "victory", "defeat", "enemy_cast", "warning"]:
		_effect(id)
	for mode: String in ["menu", "dungeon", "boss"]:
		_music(mode)
	quit()

func _save(id: String, samples: PackedFloat32Array, _looped: bool = false) -> void:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples.size() * 2)
	var peak: float = 0.01
	for sample: float in samples:
		peak = maxf(peak, absf(sample))
	for i: int in range(samples.size()):
		var value: float = samples[i] / maxf(peak, 1.0) * 0.8
		value *= minf(1.0, float(i) / 64.0) * minf(1.0, float(samples.size() - i - 1) / 128.0)
		bytes.encode_s16(i * 2, int(clampf(value, -0.98, 0.98) * 32767))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	var error: Error = stream.save_to_wav("res://assets/audio/" + id + ".wav")
	if error != OK:
		printerr("Audio export failed: " + id)
		quit(1)
	print("Generated " + id)

func _effect(id: String) -> void:
	var duration: float = 0.24
	if id in ["skill", "solve", "reward", "portal"]: duration = 0.8
	if id in ["victory", "defeat"]: duration = 1.6
	if id == "ui": duration = 0.07
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(int(RATE * duration))
	var phase: float = 0.0
	for i: int in range(samples.size()):
		var t: float = float(i) / RATE
		var u: float = t / duration
		var frequency: float = 300.0
		var noise: float = rng.randf_range(-1.0, 1.0)
		var mix_noise: float = 0.0
		match id:
			"ui": frequency = 880.0
			"pistol": frequency = lerpf(220, 55, u); mix_noise = 0.65
			"shotgun": frequency = lerpf(130, 35, u); mix_noise = 0.85
			"plasma_blaster": frequency = lerpf(1200, 100, u)
			"hit": frequency = lerpf(420, 80, u); mix_noise = 0.6
			"hurt": frequency = lerpf(190, 70, u); mix_noise = 0.25
			"dash": frequency = lerpf(300, 1300, u); mix_noise = 0.75
			"skill": frequency = lerpf(90, 900, u); mix_noise = 0.15
			"heal": frequency = lerpf(520, 1040, u)
			"door": frequency = lerpf(140, 60, u); mix_noise = 0.55
			"rune": frequency = 660.0
			"wrong": frequency = 130.0 + sin(t * 80) * 30
			"push": frequency = 65.0; mix_noise = 0.85
			"enemy_cast": frequency = lerpf(580, 180, u)
			"warning": frequency = 740.0
			"portal": frequency = lerpf(150, 1500, u)
			"defeat": frequency = [392.0, 311.13, 261.63, 196.0][mini(3, int(u * 4))]
			_: frequency = [523.25, 659.25, 783.99, 1046.5][mini(3, int(u * 4))]
		phase += TAU * frequency / RATE
		var tone: float = sin(phase) * 0.7 + sin(phase * 2) * 0.15
		var envelope: float = pow(1.0 - u, 2.0) if duration < 0.5 else sin(PI * u) * 0.65
		samples[i] = lerpf(tone, noise, mix_noise) * envelope
	_save(id, samples)

func _music(mode: String) -> void:
	var beat: float = 0.375 if mode == "boss" else 0.5
	var duration: float = beat * 32
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(int(duration * RATE))
	var roots: Array[int] = [45, 41, 48, 43]
	var melody: Array[int] = [0, 7, 12, 3, 7, 15, 12, 7]
	for i: int in range(samples.size()):
		var t: float = float(i) / RATE
		var step: int = int(t / beat)
		var local: float = fmod(t, beat)
		var root_note: int = roots[(step / 8) as int]
		var bass_hz: float = 440.0 * pow(2, (root_note - 69.0) / 12)
		var lead_hz: float = bass_hz * pow(2, (melody[step % 8] + 12.0) / 12)
		var envelope: float = minf(local / 0.015, 1.0) * exp(-local * 6.0) * minf((beat - local) / 0.035, 1.0)
		var value: float = sin(TAU * lead_hz * local) * envelope * 0.12
		value += (sin(TAU * bass_hz * local) + 0.25 * sin(TAU * bass_hz * 2 * local)) * envelope * 0.15
		if mode != "menu":
			if step % 2 == 0:
				value += sin(TAU * (48 * local + 12 * (1 - exp(-local * 25)))) * exp(-local * 22) * 0.3
			else:
				value += rng.randf_range(-1, 1) * exp(-local * 30) * 0.12
		if mode == "boss":
			value += rng.randf_range(-1, 1) * exp(-fmod(local, beat / 2) * 65) * 0.055
		samples[i] = value
	_save(mode, samples, true)
