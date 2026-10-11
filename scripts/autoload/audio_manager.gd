extends Node
## Persistent audio service. Gameplay only emits EventBus cues.
var catalog: AudioCatalog
var voices: Array[AudioStreamPlayer] = []
var music_players: Array[AudioStreamPlayer] = []
var current_music: String = ""
var levels: Dictionary[String, float] = {}
var settings_path: String = "user://audio.cfg"
var _last_played: Dictionary[String, int] = {}
var _voice_cursor: int = 0
var _music_slot: int = 0
var _fade: Tween
var _save_timer: Timer
var _paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	catalog = load("res://data/audio/catalog.tres") as AudioCatalog
	for bus: String in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
	levels = {"Master": catalog.default_master, "Music": catalog.default_music, "SFX": catalog.default_sfx}
	load_settings()
	for i: int in range(catalog.voice_limit):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = "SFX"
		voice.volume_db = catalog.effect_db
		add_child(voice)
		voices.append(voice)
	for i: int in range(2):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		music_players.append(player)
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.3
	_save_timer.timeout.connect(save_settings)
	add_child(_save_timer)
	var bus: Node = get_node("/root/EventBus")
	bus.sound_requested.connect(play_effect)
	bus.music_requested.connect(play_music)
	bus.game_state_changed.connect(_on_state)
	bus.expedition_finished.connect(_on_result)
	bus.audio_level_requested.connect(set_level)
	bus.audio_settings_requested.connect(func() -> void: bus.audio_levels_changed.emit(levels.duplicate()))
	play_music("menu")

func play_effect(id: String) -> bool:
	if not catalog.effects.has(id):
		return false
	if _paused and id != "ui":
		return false
	var now: int = Time.get_ticks_msec()
	if now - _last_played.get(id, -100000) < int(catalog.repeat_interval * 1000):
		return false
	_last_played[id] = now
	var chosen: AudioStreamPlayer = voices[_voice_cursor]
	for voice: AudioStreamPlayer in voices:
		if not voice.playing:
			chosen = voice
			break
	_voice_cursor = (_voice_cursor + 1) % voices.size()
	chosen.stop()
	chosen.stream = catalog.effects[id]
	chosen.play()
	return true

func play_music(id: String) -> void:
	if id == current_music or not catalog.music.has(id):
		return
	current_music = id
	if _fade and _fade.is_valid():
		_fade.kill()
	var old: AudioStreamPlayer = music_players[_music_slot]
	_music_slot = 1 - _music_slot
	var next: AudioStreamPlayer = music_players[_music_slot]
	var stream: AudioStreamWAV = catalog.music[id].duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	next.stream = stream
	next.volume_db = -60
	next.play()
	_fade = create_tween().set_parallel(true)
	_fade.tween_property(old, "volume_db", -60.0, catalog.crossfade_seconds)
	_fade.tween_property(next, "volume_db", catalog.music_db, catalog.crossfade_seconds)
	_fade.chain().tween_callback(old.stop)

func _on_state(state: String) -> void:
	_paused = state == "PAUSED"
	_apply_level("Music")
	if state in ["PAUSED", "MAIN_MENU"]:
		for voice: AudioStreamPlayer in voices:
			voice.stop()
	if state in ["MAIN_MENU", "VICTORY", "GAME_OVER"]:
		play_music("menu")
	elif state == "PLAYING" and current_music == "menu":
		play_music("dungeon")

func _on_result(victory: bool, _gold: int) -> void:
	play_effect("victory" if victory else "defeat")

func set_level(bus: String, value: float, persist: bool = true) -> void:
	if not levels.has(bus) or not is_finite(value):
		return
	levels[bus] = clampf(value, 0, 1)
	_apply_level(bus)
	if persist:
		_save_timer.start()

func _apply_level(bus: String) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	var gain: float = levels[bus]
	if bus == "Music" and _paused:
		gain *= 0.35
	AudioServer.set_bus_mute(index, gain <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(gain, 0.0001)))

func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(settings_path) == OK:
		for bus: String in levels:
			var value: Variant = config.get_value("audio", bus, levels[bus])
			if (value is float or value is int) and is_finite(float(value)):
				levels[bus] = clampf(float(value), 0, 1)
	for bus: String in levels:
		_apply_level(bus)

func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	for bus: String in levels:
		config.set_value("audio", bus, levels[bus])
	var error: Error = config.save(settings_path)
	if error != OK:
		push_warning("Không lưu được âm lượng: %s" % error_string(error))

func _exit_tree() -> void:
	if _fade and _fade.is_valid():
		_fade.kill()
	for player: AudioStreamPlayer in music_players + voices:
		player.stop()
		player.stream = null
	if is_instance_valid(_save_timer) and not _save_timer.is_stopped():
		save_settings()
