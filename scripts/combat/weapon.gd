class_name Weapon
extends Node2D

## Weapon: Thực thể vũ khí cầm tay trong PixelDungeon.
## Quản lý cooldown bắn, giật lùi (recoil), góc tỏa đạn và sinh đạn Projectile.

signal fired(energy_used: int)

@export var weapon_data: WeaponData
@export var bullet_scene: PackedScene = load("res://scenes/projectiles/bullet.tscn")

var _cooldown_remaining: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle

var is_ready_to_shoot: bool:
	get:
		return _cooldown_remaining <= 0.0

func _ready() -> void:
	if weapon_data:
		apply_weapon_data(weapon_data)

func apply_weapon_data(data: WeaponData) -> void:
	weapon_data = data
	if not sprite:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if not muzzle:
		muzzle = get_node_or_null("Muzzle") as Marker2D
	
	if sprite and weapon_data.icon:
		sprite.texture = weapon_data.icon
		# Đặt điểm bắt đầu nòng súng ở đầu mút của súng
		var tex_width: float = float(weapon_data.icon.get_width())
		if muzzle:
			muzzle.position = Vector2(tex_width * 0.75, 0.0)

func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta

## Bắn đạn hướng về vị trí con trỏ chuột
func shoot(target_pos: Vector2, projectiles_container: Node2D) -> bool:
	if not weapon_data or not is_ready_to_shoot:
		return false
	
	_cooldown_remaining = 1.0 / maxf(weapon_data.fire_rate, 0.1)
	
	# Hiệu ứng giật súng (Recoil Tween)
	_play_recoil()
	
	# Tính toán hướng và góc bắn
	var spawn_pos: Vector2 = muzzle.global_position if muzzle else global_position
	var base_direction := (target_pos - spawn_pos).normalized()
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT
	var base_angle: float = base_direction.angle()
	
	var count: int = maxi(weapon_data.projectile_count, 1)
	var spread_rad: float = deg_to_rad(weapon_data.spread_degrees)
	
	for i in range(count):
		var fire_angle: float = base_angle
		if count > 1:
			var step: float = spread_rad / float(count - 1)
			fire_angle = base_angle - (spread_rad / 2.0) + (step * float(i))
		elif weapon_data.spread_degrees > 0.0:
			fire_angle += randf_range(-spread_rad / 2.0, spread_rad / 2.0)
		
		var dir := Vector2.from_angle(fire_angle)
		var bullet: Projectile = bullet_scene.instantiate() as Projectile
		bullet.global_position = spawn_pos
		bullet.setup(
			dir,
			weapon_data.projectile_speed,
			weapon_data.damage,
			weapon_data.projectile_lifetime,
			weapon_data.projectile_texture,
			weapon_data.projectile_scale,
			true
		)
		projectiles_container.add_child(bullet)
	
	fired.emit(weapon_data.energy_cost)
	GameAudio.cue(self, weapon_data.id)
	return true

func _play_recoil() -> void:
	if not sprite:
		return
	var kick: float = weapon_data.recoil
	var tween := create_tween()
	tween.tween_property(sprite, "position:x", -kick, 0.04)
	tween.tween_property(sprite, "position:x", 0.0, 0.08)
