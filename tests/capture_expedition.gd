extends SceneTree

func _init() -> void:
	_capture.call_deferred()

func _capture() -> void:
	var session: Node = load("res://scenes/main/expedition.tscn").instantiate()
	root.add_child(session)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/title_preview.png")
	session.frontend.show_regions()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/regions_preview.png")
	session.frontend.show_audio()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/audio_preview.png")
	session.start_run(load("res://data/regions/crypt.tres"))
	await create_timer(2.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/gameplay_preview.png")
	var adventure: AdventureRun = session.world.get_node("Adventure") as AdventureRun
	for kind: String in ["runes", "blocks", "combat"]:
		for cell: Vector2i in adventure.layout.rooms:
			if adventure.layout.rooms[cell].kind == kind:
				adventure._enter_room(cell, Vector2(320, 240))
				break
		await create_timer(0.9).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/" + kind + "_preview.png")
	session.return_to_menu()
	session.queue_free()
	await process_frame
	quit()
