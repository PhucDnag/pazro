extends Node2D

var frontend: FrontEnd
var world: Node2D
var active_region: RegionData
var ended: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	frontend = FrontEnd.new()
	add_child(frontend)
	frontend.region_selected.connect(start_run)
	frontend.resume_requested.connect(resume_run)
	frontend.menu_requested.connect(return_to_menu)
	frontend.retry_requested.connect(func() -> void: start_run(active_region))
	EventBus.expedition_finished.connect(_finish)
	GameManager.set_state(GameManager.State.MAIN_MENU)

func start_run(region: RegionData) -> void:
	_clear_world()
	get_tree().paused = false
	active_region = region
	ended = false
	frontend.dismiss()
	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	var hud: ExpeditionHUD = ExpeditionHUD.new()
	world.add_child(hud)
	hud.pause_requested.connect(pause_run)
	var adventure: AdventureRun = AdventureRun.new()
	adventure.name = "Adventure"
	adventure.region = region
	world.add_child(adventure)
	GameManager.set_state(GameManager.State.PLAYING)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and world and not ended:
		if get_tree().paused:
			resume_run()
		else:
			pause_run()
		get_viewport().set_input_as_handled()

func pause_run() -> void:
	if ended:
		return
	get_tree().paused = true
	GameManager.set_state(GameManager.State.PAUSED)
	frontend.show_pause()

func resume_run() -> void:
	get_tree().paused = false
	frontend.dismiss()
	GameManager.set_state(GameManager.State.PLAYING)

func return_to_menu() -> void:
	_clear_world()
	get_tree().paused = false
	GameManager.set_state(GameManager.State.MAIN_MENU)
	frontend.show_regions()

func _clear_world() -> void:
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
		world = null

func _finish(victory: bool, gold: int) -> void:
	ended = true
	get_tree().paused = true
	GameManager.set_state(GameManager.State.VICTORY if victory else GameManager.State.GAME_OVER)
	frontend.show_result(victory, gold)
