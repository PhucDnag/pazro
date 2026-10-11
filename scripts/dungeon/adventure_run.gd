class_name AdventureRun
extends Node2D

var region: RegionData
var rules: AdventureData = preload("res://data/adventure.tres")
var layout: AdventureLayout = AdventureLayout.new()
var current_cell: Vector2i
var chamber: AdventureChamber
var player: Player
var floor_index: int = 1
var gold: int = 0
var run_seed: int = 0
var finished: bool = false
var _transitioning: bool = false
var projectiles: Node2D

func _ready() -> void:
	projectiles = Node2D.new()
	projectiles.name = "Projectiles"
	add_child(projectiles)
	player = load("res://scenes/player/player.tscn").instantiate() as Player
	(player.get_node("Camera2D") as Camera2D).enabled = false
	add_child(player)
	player.z_index = 3
	get_node("/root/EventBus").player_died.connect(_on_player_died)
	if run_seed == 0:
		run_seed = randi()
	_start_floor()

func _start_floor() -> void:
	layout.generate(run_seed + floor_index * 1009)
	current_cell = layout.start
	_enter_room(current_cell, Vector2(320, 225))

func _enter_room(cell: Vector2i, spawn: Vector2) -> void:
	if is_instance_valid(chamber):
		remove_child(chamber)
		chamber.queue_free()
	for child: Node in projectiles.get_children():
		projectiles.remove_child(child)
		child.queue_free()
	get_node("/root/EventBus").boss_health_changed.emit(0, 1, "")
	current_cell = cell
	get_node("/root/EventBus").music_requested.emit("boss" if layout.rooms[cell].kind == "boss" else "dungeon")
	chamber = AdventureChamber.new()
	chamber.state = layout.rooms[cell]
	chamber.region = region
	chamber.rules = rules
	chamber.floor_index = floor_index
	chamber.seals = layout.seal_count()
	for neighbor: Vector2i in layout.neighbors(cell):
		chamber.links[neighbor - cell] = layout.rooms[neighbor].kind
	chamber.changed.connect(_room_cleared)
	chamber.enemy_reward.connect(_enemy_reward)
	chamber.reward_requested.connect(_claim_reward)
	chamber.portal_requested.connect(_portal)
	add_child(chamber)
	move_child(chamber, 0)
	var foreground: Node2D = load("res://scripts/dungeon/chamber_foreground.gd").new()
	foreground.chamber = chamber
	chamber.add_child(foreground)
	player.position = spawn
	player.velocity = Vector2.ZERO
	player.dash_remaining = 0
	_broadcast()

func _process(delta: float) -> void:
	if chamber and not finished:
		chamber.tick(delta, player)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not finished and not _transitioning:
		if chamber.interact(player):
			get_viewport().set_input_as_handled()
			return
		for direction: Vector2i in chamber.links:
			if player.position.distance_to(AdventureChamber.door_position(direction)) <= rules.interact_radius:
				request_exit(direction)
				get_viewport().set_input_as_handled()
				return

func request_exit(direction: Vector2i) -> bool:
	if _transitioning or finished or not chamber.can_exit(direction):
		return false
	_transitioning = true
	_travel.call_deferred(direction)
	return true

func _travel(direction: Vector2i) -> void:
	if not is_inside_tree() or finished:
		return
	var spawn: Vector2 = AdventureChamber.door_position(-direction) + Vector2(direction) * 27
	GameAudio.cue(self, "door")
	_enter_room(current_cell + direction, spawn)
	_transitioning = false

func _room_cleared() -> void:
	GameAudio.cue(self, "solve")
	gold += rules.room_gold
	chamber.seals = layout.seal_count()
	_broadcast()

func _enemy_reward() -> void:
	gold += region.kill_gold
	get_node("/root/EventBus").interaction_triggered.emit("enemy_reward")
	_broadcast()

func _claim_reward() -> void:
	GameAudio.cue(self, "reward")
	if chamber.state.kind == "supply":
		player.heal(rules.supply_heal)
		player.restore_energy(player.max_energy)
		player.potions += rules.supply_potions
	else:
		gold += rules.treasure_gold
		# Per-run copies keep cached weapon resources pristine on retry.
		for i: int in range(player.weapons_inventory.size()):
			var weapon: WeaponData = player.weapons_inventory[i].duplicate() as WeaponData
			weapon.damage += rules.weapon_upgrade
			player.weapons_inventory[i] = weapon
		player.switch_weapon(player.current_weapon_index)
	_broadcast()

func _portal() -> void:
	if _transitioning or finished:
		return
	_transitioning = true
	_advance_floor.call_deferred()

func _advance_floor() -> void:
	GameAudio.cue(self, "portal")
	if floor_index >= rules.floors:
		finished = true
		get_node("/root/EventBus").expedition_finished.emit(true, gold)
	else:
		floor_index += 1
		player.heal(rules.floor_heal)
		_start_floor()
	_transitioning = false

func _on_player_died() -> void:
	if finished:
		return
	finished = true
	get_node("/root/EventBus").expedition_finished.emit(false, gold)

func _broadcast() -> void:
	var map: Array[Dictionary] = []
	for cell: Vector2i in layout.rooms:
		var state: AdventureRoomState = layout.rooms[cell]
		var discovered: bool = state.visited
		for neighbor: Vector2i in layout.neighbors(cell):
			discovered = discovered or layout.rooms[neighbor].visited
		if discovered:
			map.append({"cell": cell, "kind": state.kind, "visited": state.visited, "cleared": state.cleared})
	get_node("/root/EventBus").dungeon_changed.emit(floor_index, chamber.state.title(), layout.seal_count(), gold, current_cell, map)
