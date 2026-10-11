class_name HurtboxComponent
extends Area2D

## HurtboxComponent: Khu vực nhận đòn va chạm (Area2D).
## Chuyển tiếp sát thương tới HealthComponent và quản lý thời gian bất tử ngắn (i-frames).

signal hit_received(damage: int, knockback_dir: Vector2)

@export var is_player_side: bool = false
@export var health_component: HealthComponent
@export var invincibility_duration: float = 0.15

var is_invincible: bool = false
var _invincible_timer: float = 0.0

func _process(delta: float) -> void:
	if is_invincible:
		_invincible_timer -= delta
		if _invincible_timer <= 0.0:
			is_invincible = false

## Nhận đòn đánh từ Hitbox hoặc Projectile
func receive_hit(damage: int, knockback_dir: Vector2 = Vector2.ZERO) -> bool:
	if is_invincible or damage <= 0:
		return false
	
	if health_component:
		health_component.take_damage(damage, knockback_dir)
	
	hit_received.emit(damage, knockback_dir)
	
	if invincibility_duration > 0.0:
		is_invincible = true
		_invincible_timer = invincibility_duration
	
	return true
