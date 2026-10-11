extends SceneTree

var failures: int = 0

func _init() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)
	else:
		print("PASS: " + message)

func _run() -> void:
	var session: Node2D = load("res://scenes/main/expedition.tscn").instantiate()
	root.add_child(session)
	await process_frame
	check(session.frontend.page.get_child_count() > 5, "Title screen built")
	session.frontend.show_regions()
	check(FrontEnd.REGIONS.size() == 3, "Three playable regions")
	for region: RegionData in FrontEnd.REGIONS:
		check(region.enemies.size() == 3 and region.boss.boss, region.title + " resources")
	session.start_run(FrontEnd.REGIONS[0])
	await process_frame
	var player: Player = get_first_node_in_group("player") as Player
	check(player != null and player.current_health == 100, "Player and health initialized")
	check(player.try_shoot(Vector2(500, 200)), "Player fires a real projectile")
	var bullets: Node2D = session.world.get_node("Adventure/Projectiles") as Node2D
	check(bullets.get_child_count() == 1 and bullets.get_child(0) is Projectile, "Projectile scene has working script")
	player.restore_energy(50)
	check(player.try_dash(), "Dash activates")
	player.take_damage(10)
	check(player.current_health == 100, "Dash grants invulnerability")
	check(not player.try_dash(), "Dash cooldown enforced")
	player.dash_remaining = 0
	player.take_damage(50)
	check(player.use_potion() and player.current_health == 90 and player.potions == 2, "Potion consumes one charge and heals")
	player.current_energy = 0
	check(not player.try_skill(), "Skill rejects insufficient mana")
	player.restore_energy(50)
	check(player.try_skill() and player.current_energy == 32, "Skill consumes mana")
	check(not player.try_skill(), "Skill cooldown enforced")
	session.pause_run()
	check(paused, "Pause freezes gameplay")
	session.resume_run()
	check(not paused, "Resume unfreezes gameplay")
	check(session.world.get_node("Adventure") is AdventureRun, "Dungeon run replaces single arena")
	session.return_to_menu()
	await process_frame
	check(not paused and get_nodes_in_group("enemies").is_empty(), "Menu cleans up previous run")
	session.start_run(FrontEnd.REGIONS[1])
	await process_frame
	player = get_first_node_in_group("player") as Player
	check(player.current_health == 100 and player.potions == 3, "Restart resets inventory and health")
	player.die()
	check(session.ended and paused, "Death shows game over")
	session.return_to_menu()
	session.queue_free()
	await process_frame
	print("EXPEDITION TESTS: %d failures" % failures)
	quit(1 if failures > 0 else 0)

