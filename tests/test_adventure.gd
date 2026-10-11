extends SceneTree

var failures: int = 0
var run: AdventureRun

func _init() -> void:
	_test.call_deferred()

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
	else:
		print("PASS: " + label)

func _test() -> void:
	var all_connected: bool = true
	var signatures: Dictionary[String, bool] = {}
	for seed_value: int in range(100):
		var layout: AdventureLayout = AdventureLayout.new()
		layout.generate(seed_value)
		var visited: Array[Vector2i] = [layout.start]
		var cursor: int = 0
		while cursor < visited.size():
			for neighbor: Vector2i in layout.neighbors(visited[cursor]):
				if not visited.has(neighbor):
					visited.append(neighbor)
			cursor += 1
		all_connected = all_connected and visited.size() == layout.rooms.size()
		var keys: Array = layout.rooms.keys()
		signatures[str(keys)] = true
	check(all_connected, "100 seeded layouts are connected")
	check(signatures.size() > 4, "Layouts vary between runs")
	run = AdventureRun.new()
	run.run_seed = 12345
	run.region = load("res://data/regions/crypt.tres")
	root.add_child(run)
	await process_frame
	run.player.set_physics_process(false)
	run.player.set_process(false)
	check(run.layout.rooms.size() >= 9 and run.current_cell == Vector2i.ZERO, "Starts in safe room of a multi-room dungeon")
	var first_direction: Vector2i = run.layout.neighbors(run.current_cell)[0] - run.current_cell
	run.player.position = AdventureChamber.door_position(first_direction)
	var interaction: InputEventAction = InputEventAction.new()
	interaction.action = "interact"
	interaction.pressed = true
	Input.parse_input_event(interaction)
	await process_frame
	await process_frame
	check(run.current_cell == first_direction, "Room transition completed")
	interaction.pressed = false
	Input.parse_input_event(interaction)
	# Isolate puzzle rules, including recovery and wrong-answer combat.
	_enter_kind("runes")
	await process_frame
	var puzzle: RoomPuzzle = run.chamber.puzzle
	puzzle.activate_rune((puzzle.state.sequence[0] + 1) % 3)
	check(puzzle.state.progress == 0 and run.chamber.remaining == 1, "Wrong rune resets sequence and summons guardian")
	puzzle.activate_rune((puzzle.state.sequence[0] + 1) % 3)
	check(run.chamber.remaining == 1, "Repeated mistakes cannot flood room with guardians")
	for rune: int in puzzle.state.sequence:
		puzzle.activate_rune(rune)
	check(puzzle.state.puzzle_solved and not puzzle.state.cleared, "Puzzle solution still requires defeating guardian")
	puzzle.activate_rune(0)
	_kill_current()
	check(run.layout.seal_count() == 1, "First seal granted once")
	var gold_after_seal: int = run.gold
	run.chamber._complete()
	check(run.gold == gold_after_seal, "Room reward cannot be duplicated")
	_enter_kind("blocks")
	await process_frame
	puzzle = run.chamber.puzzle
	check(puzzle.push_block(0, Vector2.RIGHT), "Block moves one grid cell")
	puzzle.reset_blocks()
	check(puzzle.state.blocks[0] == Vector2(288, 158), "Reset recovers a stuck puzzle")
	run.player.position = Vector2(200, 158)
	var hp: int = run.player.current_health
	puzzle.clock = run.rules.hazard_period - run.rules.hazard_active - 0.01
	puzzle.tick(0.02, run.player)
	check(run.player.current_health == hp - run.rules.hazard_damage, "Active trap damages player in danger lane")
	puzzle.tick(0.01, run.player)
	check(run.player.current_health == hp - run.rules.hazard_damage, "Trap damages at most once per pulse")
	for step: int in range(4):
		puzzle.push_block(0, Vector2.RIGHT)
	for step: int in range(2):
		puzzle.push_block(1, Vector2.RIGHT)
	check(run.layout.seal_count() == 2, "Both pressure plates grant second seal")
	var solved_cell: Vector2i = run.current_cell
	_enter_kind("hub")
	await process_frame
	run._enter_room(solved_cell, Vector2(320, 225))
	await process_frame
	check(run.chamber.state.cleared and run.chamber.puzzle.state.blocks.has(Vector2(416, 158)), "Solved puzzle persists on revisit")
	_enter_kind("treasure")
	await process_frame
	run.player.position = Vector2(320, 190)
	var damage: int = run.player.weapons_inventory[0].damage
	run.chamber.interact(run.player)
	check(run.player.weapons_inventory[0].damage == damage + run.rules.weapon_upgrade, "Treasure upgrades this run's weapons")
	var treasure_gold: int = run.gold
	run.chamber.interact(run.player)
	check(run.gold == treasure_gold, "Treasure cannot be farmed by repeated interaction")
	var cached: WeaponData = load("res://data/weapons/pistol.tres")
	check(cached.damage == damage, "Upgrade leaves shared resources untouched")
	_enter_kind("supply")
	await process_frame
	run.player.current_health = 20
	run.player.position = Vector2(320, 190)
	run.chamber.interact(run.player)
	check(run.player.current_health == 20 + run.rules.supply_heal, "Supply room heals")
	_enter_kind("combat")
	await create_timer(0.8).timeout
	check(run.chamber.locked() and run.chamber.remaining > 0, "Combat locks exits")
	var door: Vector2i = run.chamber.links.keys()[0]
	check(not run.request_exit(door), "Cannot leave active combat")
	_kill_current()
	await create_timer(0.8).timeout
	check(run.chamber.remaining > 0, "Second enemy wave spawns")
	_kill_current()
	check(run.chamber.state.cleared and not run.chamber.locked(), "Cleared combat opens exits")
	_enter_kind("boss")
	await create_timer(0.8).timeout
	check(run.chamber.remaining == 1, "Boss chamber spawns boss")
	_kill_current()
	run.player.position = Vector2(320, 190)
	run.chamber.interact(run.player)
	await process_frame
	check(run.floor_index == 2 and run.layout.seal_count() == 0, "Portal generates next floor and resets seals")
	_enter_kind("hub")
	await process_frame
	for direction: Vector2i in run.chamber.links:
		if run.chamber.links[direction] == "boss":
			check(not run.chamber.can_exit(direction), "Boss gate requires both seals on new floor")
	# Verify final portal emits victory only after the second boss.
	_enter_kind("boss")
	await create_timer(0.8).timeout
	_kill_current()
	var result: Dictionary[String, bool] = {"victory": false}
	root.get_node("EventBus").expedition_finished.connect(func(victory: bool, _gold: int) -> void: result.victory = victory)
	run.player.position = Vector2(320, 190)
	run.chamber.interact(run.player)
	await process_frame
	check(result.victory and run.finished, "Last boss portal completes adventure")
	run.queue_free()
	await process_frame
	print("ADVENTURE: %d failures" % failures)
	quit(0 if failures == 0 else 1)

func _enter_kind(kind: String) -> void:
	for cell: Vector2i in run.layout.rooms:
		if run.layout.rooms[cell].kind == kind:
			run._enter_room(cell, Vector2(320, 225))
			return

func _kill_current() -> void:
	for child: Node in run.chamber.content.get_children():
		if child is Enemy and not child.is_dead:
			child.take_damage(99999)
