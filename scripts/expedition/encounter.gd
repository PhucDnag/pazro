class_name Encounter
extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const CHEST_SCENE: PackedScene = preload("res://scenes/items/chest.tscn")
var region: RegionData
var wave: int = -1
var gold: int = 0
var remaining: int = 0
var finished: bool = false
var waiting: bool = false

func _ready() -> void:
	get_node("/root/EventBus").player_died.connect(_on_player_died)
	get_node("/root/EventBus").reward_collected.connect(_collect_reward)
	_queue_wave()

func _queue_wave() -> void:
	if waiting or finished:
		return
	waiting = true
	await get_tree().create_timer(region.wave_delay, false).timeout
	if not is_inside_tree() or finished:
		return
	waiting = false
	spawn_next_wave()

func spawn_next_wave() -> void:
	if finished:
		return
	wave += 1
	var boss_wave: bool = wave >= region.waves.size()
	remaining = 1 if boss_wave else region.waves[wave]
	for i: int in range(remaining):
		var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
		var data: EnemyData = region.boss if boss_wave else region.enemies[(i + wave) % region.enemies.size()]
		enemy.enemy_data = data.duplicate() as EnemyData
		enemy.enemy_data.detection_range = 700.0
		enemy.position = Vector2(480, 185) if boss_wave else Vector2(100 + (i * 137 + wave * 53) % 440, 105 if i % 2 == 0 else 273)
		enemy.defeated.connect(_on_defeated)
		add_child(enemy)
		var tween: Tween = enemy.create_tween()
		enemy.modulate.a = 0.15
		tween.tween_property(enemy, "modulate:a", 1.0, 0.4)
	_broadcast()

func _on_defeated(_score: int) -> void:
	if finished:
		return
	remaining -= 1
	gold += region.kill_gold
	get_node("/root/EventBus").interaction_triggered.emit("enemy_reward")
	_broadcast()
	if remaining == 0:
		if wave >= region.waves.size():
			_spawn_reward.call_deferred()
		else:
			_queue_wave()

func _spawn_reward() -> void:
	if finished:
		return
	# Remove lingering hostile bullets before the reward phase.
	for bullet: Node in get_tree().get_nodes_in_group("hostile_projectiles"):
		bullet.queue_free()
	var chest: Chest = CHEST_SCENE.instantiate() as Chest
	chest.gold_reward = region.chest_gold
	add_child(chest)
	chest.spawn_pop(Vector2(320, 190))
	get_node("/root/EventBus").room_cleared.emit("expedition")

func _collect_reward(amount: int) -> void:
	if finished:
		return
	gold += amount
	finished = true
	_broadcast()
	get_node("/root/EventBus").expedition_finished.emit(true, gold)

func _on_player_died() -> void:
	if finished:
		return
	finished = true
	get_node("/root/EventBus").expedition_finished.emit(false, gold)

func _broadcast() -> void:
	get_node("/root/EventBus").expedition_changed.emit(wave + 1, region.waves.size() + 1, remaining, gold)

