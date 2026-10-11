class_name HitboxComponent
extends Area2D

## HitboxComponent: Khu vực gây sát thương khi chạm (Area2D).
## Tương tác với HurtboxComponent của phe đối địch.

signal hit_landed(hurtbox: HurtboxComponent)

@export var damage: int = 10
@export var is_player_side: bool = false
@export var knockback_force: float = 120.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		var hurtbox := area as HurtboxComponent
		# Chỉ gây sát thương cho phe đối lập
		if hurtbox.is_player_side != is_player_side:
			var knockback_dir := (hurtbox.global_position - global_position).normalized()
			if knockback_dir == Vector2.ZERO:
				knockback_dir = Vector2.RIGHT
			if hurtbox.receive_hit(damage, knockback_dir):
				hit_landed.emit(hurtbox)
