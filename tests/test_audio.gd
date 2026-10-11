extends SceneTree

var failures: int = 0

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		failures += 1
		printerr("FAIL: " + label)

func _run() -> void:
	var manager: Node = root.get_node("AudioManager")
	var bus: Node = root.get_node("EventBus")
	var catalog: AudioCatalog = manager.catalog
	check(catalog.effects.size() == 20 and catalog.music.size() == 3, "20 effects and 3 music tracks load")
	var valid_samples: bool = true
	var seamless: bool = true
	for stream: AudioStream in catalog.effects.values() + catalog.music.values():
		var wav: AudioStreamWAV = stream as AudioStreamWAV
		valid_samples = valid_samples and wav != null and wav.get_length() > 0.03 and wav.data.size() > 100
		var peak: int = 0
		var pcm: PackedByteArray = wav.data
		for i: int in range(0, pcm.size(), 2):
			peak = maxi(peak, absi(pcm.decode_s16(i)))
		valid_samples = valid_samples and peak > 500 and peak < 32767
	for stream: AudioStreamWAV in catalog.music.values():
		seamless = seamless and absi(stream.data.decode_s16(0) - stream.data.decode_s16(stream.data.size() - 2)) < 100
	check(valid_samples, "PCM assets are non-silent and do not clip")
	check(seamless, "Music loop endpoints are continuous")
	check(manager.play_effect("pistol"), "SFX voice starts")
	check(not manager.play_effect("pistol"), "Duplicate same-frame cues are throttled")
	check(not manager.play_effect("missing"), "Unknown cue ignored safely")
	for i: int in range(80):
		manager.play_effect(catalog.effects.keys()[i % catalog.effects.size()])
	check(manager.voices.size() == catalog.voice_limit, "Voice pool stays bounded under bursts")
	bus.music_requested.emit("boss")
	await create_timer(catalog.crossfade_seconds + 0.1).timeout
	check(manager.current_music == "boss", "Music event switches to boss")
	var playing_count: int = 0
	for player: AudioStreamPlayer in manager.music_players:
		if player.playing:
			playing_count += 1
			check((player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "Music is configured to loop")
	check(playing_count == 1, "Crossfade stops outgoing track")
	bus.music_requested.emit("dungeon")
	bus.music_requested.emit("boss")
	bus.music_requested.emit("menu")
	await create_timer(catalog.crossfade_seconds + 0.1).timeout
	check(manager.current_music == "menu", "Rapid room changes retain latest music")
	var original: Dictionary[String, float] = manager.levels.duplicate()
	var original_path: String = manager.settings_path
	manager.settings_path = "res://.godot/test_audio.cfg"
	manager.set_level("Master", 0.0, false)
	check(AudioServer.is_bus_mute(0), "Zero volume truly mutes Master")
	manager.set_level("Master", 0.75, false)
	manager.set_level("Music", 0.42, false)
	manager.save_settings()
	manager.set_level("Music", 1.0, false)
	manager.load_settings()
	check(is_equal_approx(manager.levels.Music, 0.42), "Settings save and reload")
	bus.game_state_changed.emit("PAUSED")
	check(not manager.play_effect("shotgun"), "Gameplay SFX blocked while paused")
	await create_timer(0.06).timeout
	check(manager.play_effect("ui"), "Menu feedback works while paused")
	var settings: SoundSettings = SoundSettings.new()
	settings.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(settings)
	check(is_equal_approx(settings.sliders.Music.value, 42.0), "Sliders reflect stored settings")
	settings.sliders.SFX.value = 27
	check(is_equal_approx(manager.levels.SFX, 0.27), "Slider changes SFX through EventBus")
	bus.game_state_changed.emit("PLAYING")
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), 0.42), "Resume restores music level after ducking")
	manager._save_timer.stop()
	for name: String in original:
		manager.set_level(name, original[name], false)
	manager.settings_path = original_path
	DirAccess.remove_absolute("res://.godot/test_audio.cfg")
	settings.queue_free()
	await process_frame
	print("AUDIO: %d failures" % failures)
	quit(0 if failures == 0 else 1)
