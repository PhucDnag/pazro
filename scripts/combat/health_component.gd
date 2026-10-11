class_name HealthComponent
extends Node

## HealthComponent: Component quản lý máu, hồi phục và nhận sát thương.
## Có thể gắn vào Player, Enemy, Boss hoặc Destructible Object.

signal health_changed(current_hp: int, max_hp: int)
signal damage_received(amount: int, knockback_dir: Vector2)
signal died

@export var max_health: int = 100
var current_health: int = 100

func _ready() -> void:
	current_health = max_health

func initialize(max_hp: int) -> void:
	max_health = max_hp
	current_health = max_hp
	health_changed.emit(current_health, max_health)

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if current_health <= 0 or amount <= 0:
		return
	
	current_health = maxi(current_health - amount, 0)
	damage_received.emit(amount, knockback_dir)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()

func heal(amount: int) -> void:
	if current_health <= 0 or amount <= 0:
		return
	
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func is_dead() -> bool:
	return current_health <= 0
