class_name Door
extends StaticBody2D

## Door: Cửa hầm ngục tự động đóng khóa khi có giao tranh và mở ra khi phòng đã dọn sạch.

signal state_changed(is_locked: bool)

@export var is_locked: bool = false
@export var open_texture: Texture2D = preload("res://assets/sprites/props/door_open.png")
@export var closed_texture: Texture2D = preload("res://assets/sprites/props/door_closed.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if not sprite:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	
	if is_locked:
		lock(false)
	else:
		unlock(false)

## Đóng sập cửa và bật va chạm chặn đường
func lock(play_anim: bool = true) -> void:
	is_locked = true
	if sprite and closed_texture:
		sprite.texture = closed_texture
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
		collision_shape.disabled = false
	
	if play_anim and is_inside_tree() and sprite:
		var tween := create_tween()
		sprite.position.y = -6.0
		tween.tween_property(sprite, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	state_changed.emit(true)

## Mở cửa kéo song sắt lên và tắt va chạm cho người chơi đi qua
func unlock(play_anim: bool = true) -> void:
	is_locked = false
	if sprite and open_texture:
		sprite.texture = open_texture
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		collision_shape.disabled = true
	
	if play_anim and is_inside_tree() and sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:v", 1.5, 0.1)
		tween.tween_property(sprite, "modulate:v", 1.0, 0.15)
	
	state_changed.emit(false)
