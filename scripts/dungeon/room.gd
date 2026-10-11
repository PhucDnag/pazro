class_name Room
extends Node2D

## Room: Quản lý khu vực phòng ngục, cửa khóa, bộ sinh quái theo đợt (Waves) và rương báu phần thưởng.

signal room_combat_started(room: Room)
signal wave_started(wave_idx: int, total_waves: int)
signal room_cleared(room: Room)

enum RoomType {
	START,
	COMBAT,
	TREASURE,
	BOSS
}

enum RoomState {
	UNVISITED,
	ACTIVE,
	CLEARED
}

@export var room_type: RoomType = RoomType.COMBAT
@export var room_id: String = "combat_arena_1"
@export var total_waves: int = 2
@export var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy.tscn")
@export var chest_scene: PackedScene = preload("res://scenes/items/chest.tscn")

var current_state: RoomState = RoomState.UNVISITED
var current_wave_index: int = 0
var living_enemies: Array[Enemy] = []

@onready var doors_container: Node2D = $Doors
@onready var spawners_container: Node2D = $Spawners
@onready var enemies_container: Node2D = $Enemies
@onready var trigger_area: Area2D = $TriggerArea
@onready var reward_point: Marker2D = $RewardPoint

func _ready() -> void:
	if not doors_container:
		doors_container = get_node_or_null("Doors") as Node2D
	if not spawners_container:
		spawners_container = get_node_or_null("Spawners") as Node2D
	if not enemies_container:
		enemies_container = get_node_or_null("Enemies") as Node2D
	if not trigger_area:
		trigger_area = get_node_or_null("TriggerArea") as Area2D
	if not reward_point:
		reward_point = get_node_or_null("RewardPoint") as Marker2D
	
	if trigger_area and not trigger_area.body_entered.is_connected(_on_trigger_body_entered):
		trigger_area.body_entered.connect(_on_trigger_body_entered)
	
	if room_type == RoomType.START:
		current_state = RoomState.CLEARED
		unlock_all_doors(false)
	else:
		unlock_all_doors(false) # Mở sẵn để người chơi bước vào

func _on_trigger_body_entered(body: Node2D) -> void:
	if body is Player and current_state == RoomState.UNVISITED:
		if room_type == RoomType.COMBAT or room_type == RoomType.BOSS:
			start_combat()
		else:
			current_state = RoomState.CLEARED
			room_cleared.emit(self)

## Bắt đầu trận chiến trong phòng: Khóa tất cả các cửa và kích hoạt đợt quái đầu tiên
func start_combat() -> void:
	if current_state != RoomState.UNVISITED:
		return
	
	current_state = RoomState.ACTIVE
	lock_all_doors(true)
	
	room_combat_started.emit(self)
	
	var event_bus: Node = _get_event_bus()
	if event_bus and event_bus.has_signal("room_entered"):
		event_bus.room_entered.emit(room_id)
	
	current_wave_index = 0
	_spawn_wave(0)

func spawn_wave(wave_idx: int) -> void:
	_spawn_wave(wave_idx)

func _spawn_wave(wave_idx: int) -> void:
	current_wave_index = wave_idx
	wave_started.emit(current_wave_index + 1, total_waves)
	
	var spawners: Array = []
	if spawners_container:
		for child in spawners_container.get_children():
			if child is Marker2D:
				spawners.append(child)
	
	# Chuẩn bị dữ liệu quái cho từng wave
	var wave_enemies_data: Array[EnemyData] = _get_wave_enemy_data(wave_idx)
	
	for i in range(wave_enemies_data.size()):
		var data: EnemyData = wave_enemies_data[i]
		var spawn_pos: Vector2 = global_position
		if not spawners.is_empty():
			var marker: Marker2D = spawners[i % spawners.size()] as Marker2D
			spawn_pos = marker.global_position
		
		var enemy_inst: Enemy = enemy_scene.instantiate() as Enemy
		enemy_inst.enemy_data = data
		enemy_inst.global_position = spawn_pos
		
		if enemies_container:
			enemies_container.add_child(enemy_inst)
		else:
			add_child(enemy_inst)
		
		living_enemies.append(enemy_inst)
		enemy_inst.tree_exited.connect(func(): _on_enemy_removed(enemy_inst))
		enemy_inst.defeated.connect(func(_score: int): _on_enemy_removed(enemy_inst))

func _get_wave_enemy_data(wave_idx: int) -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	var goblin_res: EnemyData = load("res://data/enemies/goblin.tres")
	var skeleton_res: EnemyData = load("res://data/enemies/skeleton.tres")
	var mage_res: EnemyData = load("res://data/enemies/mage.tres")
	
	if wave_idx == 0:
		# Đợt 1: 2 Goblin áp sát
		if goblin_res:
			result.append(goblin_res)
			result.append(goblin_res)
	else:
		# Đợt 2: 1 Skeletor cận chiến + 1 Pháp sư Mage bắn xa
		if skeleton_res:
			result.append(skeleton_res)
		if mage_res:
			result.append(mage_res)
	
	return result

func _on_enemy_removed(enemy: Enemy) -> void:
	if not living_enemies.has(enemy):
		return
	living_enemies.erase(enemy)
	call_deferred("_check_wave_status")

func _check_wave_status() -> void:
	if not living_enemies.is_empty() or current_state != RoomState.ACTIVE:
		return
	
	if current_wave_index + 1 < total_waves:
		if is_inside_tree():
			var timer := get_tree().create_timer(0.5)
			timer.timeout.connect(func():
				if current_state == RoomState.ACTIVE and living_enemies.is_empty():
					_spawn_wave(current_wave_index + 1)
			)
		else:
			_spawn_wave(current_wave_index + 1)
	else:
		clear_room()

## Dọn sạch phòng: Mở khóa các cửa và rơi rương báu phần thưởng
func clear_room() -> void:
	if current_state == RoomState.CLEARED:
		return
	
	current_state = RoomState.CLEARED
	unlock_all_doors(true)
	
	# Rơi rương báu
	if chest_scene:
		var chest := chest_scene.instantiate() as Chest
		var drop_pos: Vector2 = reward_point.global_position if reward_point else global_position
		add_child(chest)
		chest.spawn_pop(drop_pos)
	
	room_cleared.emit(self)
	
	var event_bus: Node = _get_event_bus()
	if event_bus and event_bus.has_signal("room_cleared"):
		event_bus.room_cleared.emit(room_id)

func lock_all_doors(animate: bool = true) -> void:
	if doors_container:
		for child in doors_container.get_children():
			if child is Door:
				(child as Door).lock(animate)

func unlock_all_doors(animate: bool = true) -> void:
	if doors_container:
		for child in doors_container.get_children():
			if child is Door:
				(child as Door).unlock(animate)

func _get_event_bus() -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if not tree or not tree.root:
		return null
	return tree.root.get_node_or_null("EventBus")
