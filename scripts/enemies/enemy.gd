class_name Enemy
extends CharacterBody2D

## Enemy: Lớp cơ sở cho mọi quái vật trong PixelDungeon.
## Tích hợp AI đuổi theo/bắn xa, Health/Hurtbox/Hitbox Component, Knockback, chớp trắng và số sát thương nổi.

signal defeated(score_reward: int)

@export var enemy_data: EnemyData
@export var floating_text_scene: PackedScene = preload("res://scenes/ui/floating_text.tscn")

var is_dead: bool = false
var target_player: CharacterBody2D = null
var _attack_cooldown_timer: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO

@onready var visual: Sprite2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent

var current_health: int:
	get:
		return health_component.current_health if health_component else 0

func _ready() -> void:
	add_to_group("enemies")
	
	if not health_component:
		health_component = get_node_or_null("HealthComponent") as HealthComponent
	if not hurtbox_component:
		hurtbox_component = get_node_or_null("HurtboxComponent") as HurtboxComponent
	if not hitbox_component:
		hitbox_component = get_node_or_null("HitboxComponent") as HitboxComponent
	if not visual:
		visual = get_node_or_null("Visual") as Sprite2D
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	
	if health_component:
		if not health_component.damage_received.is_connected(_on_damage_received):
			health_component.damage_received.connect(_on_damage_received)
		if not health_component.died.is_connected(_on_died):
			health_component.died.connect(_on_died)
	
	if enemy_data:
		apply_enemy_data(enemy_data)

func apply_enemy_data(data: EnemyData) -> void:
	enemy_data = data
	if visual and enemy_data.sprite_texture:
		visual.texture = enemy_data.sprite_texture
		visual.scale = Vector2.ONE * enemy_data.visual_scale
		visual.modulate = enemy_data.tint
	if health_component:
		health_component.initialize(enemy_data.max_health)
	if hitbox_component:
		hitbox_component.damage = enemy_data.contact_damage
	if enemy_data.boss and not health_component.health_changed.is_connected(_announce_boss_health):
		health_component.health_changed.connect(_announce_boss_health)
		_announce_boss_health(enemy_data.max_health, enemy_data.max_health)

func _physics_process(delta: float) -> void:
	queue_redraw()
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta
	
	# Hồi phục từ lực giật lùi (Knockback)
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 600.0 * delta)
	
	_handle_ai(delta)
	if visual:
		visual.position.y = -3.0 + (sin(Time.get_ticks_msec() * 0.015 + get_instance_id()) if velocity.length() > 1.0 else 0.0)

func _handle_ai(_delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	
	if not target_player or target_player.get("is_dead") == true:
		velocity = _knockback_velocity
		move_and_slide()
		return
	
	var dist: float = global_position.distance_to(target_player.global_position)
	if dist > enemy_data.detection_range:
		velocity = _knockback_velocity
		move_and_slide()
		return
	
	var dir_to_player := (target_player.global_position - global_position).normalized()
	
	# Lật mặt quái theo hướng người chơi
	if visual:
		if dir_to_player.x < -0.1:
			visual.flip_h = true
		elif dir_to_player.x > 0.1:
			visual.flip_h = false
	
	if not enemy_data.is_ranged:
		# Quái cận chiến (Goblin, Skeleton): lao thẳng vào người chơi
		velocity = (dir_to_player * enemy_data.speed) + _knockback_velocity
	else:
		# Quái đánh xa (Mage): giữ cự ly bắn
		if dist > enemy_data.preferred_distance + 20.0:
			velocity = (dir_to_player * enemy_data.speed) + _knockback_velocity
		elif dist < enemy_data.preferred_distance - 20.0:
			velocity = (-dir_to_player * enemy_data.speed * 0.8) + _knockback_velocity
		else:
			velocity = _knockback_velocity
		
		# Bắn đạn ma thuật
		if _attack_cooldown_timer <= 0.0 and dist <= enemy_data.attack_range:
			for shot: int in range(enemy_data.projectile_count):
				var angle: float = (shot - (enemy_data.projectile_count - 1) / 2.0) * enemy_data.projectile_spread
				_shoot_magic_projectile(dir_to_player.rotated(angle))
			_attack_cooldown_timer = enemy_data.attack_cooldown
	
	move_and_slide()

func _shoot_magic_projectile(direction: Vector2) -> void:
	if not enemy_data.ranged_projectile_scene:
		return
	
	var bullet_node = enemy_data.ranged_projectile_scene.instantiate()
	GameAudio.cue(self, "enemy_cast")
	if bullet_node is Projectile:
		var bullet := bullet_node as Projectile
		bullet.global_position = global_position
		bullet.setup(
			direction,
			enemy_data.ranged_projectile_speed,
			enemy_data.ranged_projectile_damage,
			2.5,
			null,
			Vector2.ONE,
			false # Đạn của kẻ thù
		)
		var container = _get_projectiles_container()
		container.add_child(bullet)

func _get_projectiles_container() -> Node2D:
	if get_parent() and get_parent().has_node("Projectiles"):
		return get_parent().get_node("Projectiles") as Node2D
	var scn = get_tree().current_scene
	if scn and scn.has_node("Projectiles"):
		return scn.get_node("Projectiles") as Node2D
	return get_parent() if get_parent() is Node2D else self

## Hàm tiếp nhận sát thương trực tiếp từ đạn hoặc vũ khí
func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	if hurtbox_component:
		hurtbox_component.receive_hit(amount, knockback_dir)
	elif health_component:
		health_component.take_damage(amount, knockback_dir)

func _on_damage_received(amount: int, knockback_dir: Vector2) -> void:
	GameAudio.cue(self, "hit")
	# Chớp trắng khi trúng đòn
	if visual:
		visual.modulate = Color(3.0, 3.0, 3.0, 1.0)
		var tween := create_tween()
		tween.tween_property(visual, "modulate", enemy_data.tint, 0.12)
	
	# Lực giật lùi (Knockback)
	var res: float = clampf(enemy_data.knockback_resistance if enemy_data else 0.0, 0.0, 1.0)
	_knockback_velocity = knockback_dir * (180.0 * (1.0 - res))
	
	# Hiện số sát thương nổi
	_spawn_damage_number(amount)

func _spawn_damage_number(amount: int) -> void:
	if not floating_text_scene or not is_inside_tree():
		return
	
	var float_node = floating_text_scene.instantiate()
	if float_node is FloatingText:
		var float_text := float_node as FloatingText
		float_text.global_position = global_position + Vector2(0, -10)
		get_parent().add_child(float_text)
		float_text.setup(amount, amount > 14, false)

func _on_died() -> void:
	if is_dead:
		return
	is_dead = true
	
	# Tắt va chạm
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hitbox_component:
		hitbox_component.set_deferred("monitoring", false)
		hitbox_component.set_deferred("monitorable", false)
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", false)
		hurtbox_component.set_deferred("monitorable", false)
	
	var reward: int = enemy_data.score_reward if enemy_data else 50
	defeated.emit(reward)
	
	# Hiệu ứng tan biến khi chết
	if visual:
		var tween := create_tween()
		tween.parallel().tween_property(visual, "scale", Vector2.ZERO, 0.25)
		tween.parallel().tween_property(visual, "modulate:a", 0.0, 0.25)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func _announce_boss_health(current: int, maximum: int) -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus:
		bus.boss_health_changed.emit(current, maximum, enemy_data.enemy_name)

func _draw() -> void:
	if not enemy_data or is_dead or not health_component:
		return
	if current_health < enemy_data.max_health:
		draw_rect(Rect2(-10, -19, 20, 2), Color("1b202c"))
		draw_rect(Rect2(-10, -19, 20.0 * current_health / enemy_data.max_health, 2), Color("ec6b68"))
	if enemy_data.is_ranged and _attack_cooldown_timer < 0.35:
		draw_arc(Vector2.ZERO, 13, 0, TAU, 20, Color("d981ed"), 1)
