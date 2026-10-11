class_name Player
extends CharacterBody2D

## Player: Nhân vật người chơi chính trong PixelDungeon (Pazro).
## Điều khiển di chuyển 8 hướng, ngắm bắn xoay chuột 360 độ, quản lý Máu, Năng lượng (Mana) và kho vũ khí.

signal health_changed(current_hp: int, max_hp: int)
signal energy_changed(current_energy: int, max_energy: int)
signal weapon_switched(weapon_data: WeaponData)
signal player_died

@export_group("Stats")
@export var player_data: PlayerData = preload("res://data/player/hero.tres")
@export var max_health: int = 100
@export var speed: float = 160.0
@export var max_energy: int = 50
@export var energy_regen_rate: float = 5.0 # Hồi phục 5 mana / giây

var current_health: int = 100
var current_energy: int = 50
var _energy_accumulator: float = 0.0
var is_dead: bool = false
var dash_remaining: float = 0.0
var dash_cooldown: float = 0.0
var skill_cooldown: float = 0.0
var potions: int = 3
var _dash_direction: Vector2 = Vector2.RIGHT
var _skill_flash: float = 0.0

@export_group("Inventory")
@export var weapons_inventory: Array[WeaponData] = []
var current_weapon_index: int = 0

var visual: Sprite2D:
	get:
		if not _visual:
			_visual = get_node_or_null("Visual") as Sprite2D
		return _visual
var _visual: Sprite2D

var collision_shape: CollisionShape2D:
	get:
		if not _collision_shape:
			_collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
		return _collision_shape
var _collision_shape: CollisionShape2D

var weapon_pivot: Node2D:
	get:
		if not _weapon_pivot:
			_weapon_pivot = get_node_or_null("WeaponPivot") as Node2D
		return _weapon_pivot
var _weapon_pivot: Node2D

var active_weapon: Weapon:
	get:
		if not _active_weapon:
			_active_weapon = get_node_or_null("WeaponPivot/WeaponSlot/Weapon") as Weapon
		return _active_weapon
var _active_weapon: Weapon

var camera: Camera2D:
	get:
		if not _camera:
			_camera = get_node_or_null("Camera2D") as Camera2D
		return _camera
var _camera: Camera2D

func _enter_tree() -> void:
	if weapons_inventory.is_empty():
		_setup_initial_weapons()

func _ready() -> void:
	add_to_group("player")
	max_health = player_data.max_health
	max_energy = player_data.max_energy
	speed = player_data.speed
	energy_regen_rate = player_data.energy_regen
	potions = player_data.starting_potions
	if visual:
		visual.texture = player_data.sprite_texture
		visual.scale = Vector2.ONE * player_data.sprite_scale
	var bus: Node = get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if bus and not bus.interaction_triggered.is_connected(_on_interaction):
		bus.interaction_triggered.connect(_on_interaction)
	current_health = max_health
	current_energy = max_energy
	
	_setup_initial_weapons()
	_connect_hurtbox()
	
	# Đồng bộ tín hiệu ban đầu
	health_changed.emit(current_health, max_health)
	energy_changed.emit(current_energy, max_energy)
	_notify_event_bus_health()
	_notify_event_bus_energy()

func _connect_hurtbox() -> void:
	var hurtbox: HurtboxComponent = get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox and not hurtbox.hit_received.is_connected(take_damage):
		hurtbox.hit_received.connect(take_damage)

func _setup_initial_weapons() -> void:
	if weapons_inventory.is_empty():
		# Mặc định nạp 3 vũ khí cơ bản đại diện cho thiết kế Pazro: Pistol, Shotgun, Plasma
		var pistol_res: WeaponData = load("res://data/weapons/pistol.tres")
		var shotgun_res: WeaponData = load("res://data/weapons/shotgun.tres")
		var plasma_res: WeaponData = load("res://data/weapons/plasma_blaster.tres")
		if pistol_res:
			weapons_inventory.append(pistol_res)
		if shotgun_res:
			weapons_inventory.append(shotgun_res)
		if plasma_res:
			weapons_inventory.append(plasma_res)
	
	if not weapons_inventory.is_empty() and active_weapon:
		active_weapon.apply_weapon_data(weapons_inventory[current_weapon_index])
		weapon_switched.emit(weapons_inventory[current_weapon_index])
		_notify_event_bus_weapon()

func _process(delta: float) -> void:
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	skill_cooldown = maxf(0.0, skill_cooldown - delta)
	_skill_flash = maxf(0.0, _skill_flash - delta)
	queue_redraw()
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus:
		bus.hero_abilities_changed.emit(dash_cooldown, skill_cooldown, potions)
	if is_dead:
		return
	
	_handle_energy_regen(delta)
	_handle_shooting()

func _physics_process(_delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if dash_remaining > 0.0:
		dash_remaining -= _delta
		velocity = _dash_direction * player_data.dash_speed
		move_and_slide()
	else:
		_handle_movement()
	_handle_aim()
	if visual:
		visual.position.y = -3.0 + (sin(Time.get_ticks_msec() * 0.018) * 1.3 if velocity.length() > 1.0 else 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	
	if event.is_action_pressed("switch_weapon"):
		switch_weapon()
	if event.is_action_pressed("dash"):
		try_dash()
	if event.is_action_pressed("skill"):
		try_skill()
	if event.is_action_pressed("potion"):
		use_potion()

func _handle_movement() -> void:
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector.normalized() * speed
	move_and_slide()

func get_aim_target_position() -> Vector2:
	if is_inside_tree() and get_viewport():
		return get_global_mouse_position()
	return global_position + Vector2.RIGHT * 100.0

func _handle_aim() -> void:
	var mouse_pos: Vector2 = get_aim_target_position()
	
	if weapon_pivot:
		var aim_angle: float = (mouse_pos - weapon_pivot.global_position).angle()
		weapon_pivot.rotation = aim_angle
		
		# Lật mặt nhân vật và lật trục Y của súng khi ngắm bên trái (tránh bị súng lộn ngược)
		if mouse_pos.x < global_position.x - 2.0:
			if visual:
				visual.flip_h = true
			weapon_pivot.scale.y = -1.0
		elif mouse_pos.x > global_position.x + 2.0:
			if visual:
				visual.flip_h = false
			weapon_pivot.scale.y = 1.0

func _handle_shooting() -> void:
	if Input.is_action_pressed("attack"):
		try_shoot()

## Xử lý bắn vũ khí đang cầm
func try_shoot(target_position: Vector2 = Vector2.INF) -> bool:
	if is_dead or not active_weapon or not active_weapon.is_ready_to_shoot:
		return false
	
	var cost: int = active_weapon.weapon_data.energy_cost if active_weapon.weapon_data else 0
	if current_energy < cost:
		return false
	
	var target_pos: Vector2 = target_position
	if target_pos == Vector2.INF:
		target_pos = get_aim_target_position()
	
	var container: Node2D = _get_projectiles_container()
	var shot_success: bool = active_weapon.shoot(target_pos, container)
	
	if shot_success:
		if cost > 0:
			current_energy = maxi(current_energy - cost, 0)
			energy_changed.emit(current_energy, max_energy)
			_notify_event_bus_energy()
		return true
	
	return false

## Tráo đổi vũ khí tiếp theo trong kho
func switch_weapon(next_idx: int = -1) -> void:
	if weapons_inventory.is_empty() or not active_weapon:
		return
	
	if next_idx >= 0 and next_idx < weapons_inventory.size():
		current_weapon_index = next_idx
	else:
		current_weapon_index = (current_weapon_index + 1) % weapons_inventory.size()
	
	var new_weapon_data: WeaponData = weapons_inventory[current_weapon_index]
	active_weapon.apply_weapon_data(new_weapon_data)
	weapon_switched.emit(new_weapon_data)
	_notify_event_bus_weapon()

## Tự hồi phục năng lượng dần theo thời gian
func _handle_energy_regen(delta: float) -> void:
	if current_energy >= max_energy:
		_energy_accumulator = 0.0
		return
	
	_energy_accumulator += energy_regen_rate * delta
	if _energy_accumulator >= 1.0:
		var points_to_add: int = int(_energy_accumulator)
		_energy_accumulator -= float(points_to_add)
		current_energy = mini(current_energy + points_to_add, max_energy)
		energy_changed.emit(current_energy, max_energy)
		_notify_event_bus_energy()

func _get_projectiles_container() -> Node2D:
	if get_parent() and get_parent().has_node("Projectiles"):
		return get_parent().get_node("Projectiles") as Node2D
	if is_inside_tree():
		var current_scn: Node = get_tree().current_scene
		if current_scn and current_scn.has_node("Projectiles"):
			return current_scn.get_node("Projectiles") as Node2D
	if get_parent() is Node2D:
		return get_parent() as Node2D
	return self

## Nhận sát thương và kích hoạt hiệu ứng chớp đỏ
func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0 or dash_remaining > 0.0:
		return
	
	current_health = maxi(current_health - amount, 0)
	GameAudio.cue(self, "hurt")
	health_changed.emit(current_health, max_health)
	_notify_event_bus_health()
	
	if knockback_dir != Vector2.ZERO:
		velocity += knockback_dir * 140.0
	
	# Hiệu ứng trúng đòn chớp đỏ
	if visual:
		visual.modulate = Color(2.0, 0.4, 0.4, 1.0)
		var tween := create_tween()
		tween.tween_property(visual, "modulate", Color.WHITE, 0.15)
	
	if current_health <= 0:
		die()

## Hồi phục lượng máu
func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	
	current_health = mini(current_health + amount, max_health)
	GameAudio.cue(self, "heal")
	health_changed.emit(current_health, max_health)
	_notify_event_bus_health()

## Hồi phục năng lượng
func restore_energy(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	
	current_energy = mini(current_energy + amount, max_energy)
	energy_changed.emit(current_energy, max_energy)
	_notify_event_bus_energy()

## Xử lý khi người chơi cạn máu
func die() -> void:
	if is_dead:
		return
	is_dead = true
	player_died.emit()
	
	if is_inside_tree():
		var event_bus: Node = get_node_or_null("/root/EventBus")
		if event_bus and event_bus.has_signal("player_died"):
			event_bus.player_died.emit()

func _notify_event_bus_health() -> void:
	if not is_inside_tree():
		return
	var event_bus: Node = get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("player_health_changed"):
		event_bus.player_health_changed.emit(current_health, max_health)

func _notify_event_bus_energy() -> void:
	if not is_inside_tree():
		return
	var event_bus: Node = get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("player_energy_changed"):
		event_bus.player_energy_changed.emit(current_energy, max_energy)

func _notify_event_bus_weapon() -> void:
	if not is_inside_tree() or weapons_inventory.is_empty():
		return
	var event_bus: Node = get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("weapon_switched"):
		event_bus.weapon_switched.emit(weapons_inventory[current_weapon_index])

func try_dash() -> bool:
	if is_dead or dash_cooldown > 0.0:
		return false
	_dash_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _dash_direction == Vector2.ZERO:
		_dash_direction = (get_aim_target_position() - global_position).normalized()
	dash_remaining = player_data.dash_duration
	dash_cooldown = player_data.dash_cooldown
	GameAudio.cue(self, "dash")
	return true

func _on_interaction(action: String) -> void:
	if action == "enemy_reward":
		restore_energy(player_data.kill_energy)

func try_skill() -> bool:
	if is_dead or skill_cooldown > 0.0 or current_energy < player_data.skill_cost:
		return false
	current_energy -= player_data.skill_cost
	skill_cooldown = player_data.skill_cooldown
	_skill_flash = 0.35
	GameAudio.cue(self, "skill")
	_notify_event_bus_energy()
	energy_changed.emit(current_energy, max_energy)
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy and global_position.distance_to(enemy.global_position) <= player_data.skill_radius:
			enemy.take_damage(player_data.skill_damage, global_position.direction_to(enemy.global_position))
	return true

func use_potion() -> bool:
	if is_dead or potions <= 0 or current_health == max_health:
		return false
	potions -= 1
	heal(player_data.potion_heal)
	return true

func _draw() -> void:
	if _skill_flash > 0.0:
		draw_arc(Vector2.ZERO, player_data.skill_radius * (1.0 - _skill_flash / 0.4), 0, TAU, 48, Color(0.3, 0.85, 1.0, _skill_flash * 2.0), 3.0)
	if dash_remaining > 0.0:
		draw_line(Vector2.ZERO, -_dash_direction * 26.0, Color("6ce5ff"), 4)
