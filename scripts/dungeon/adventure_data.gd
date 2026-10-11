class_name AdventureData
extends Resource

@export var floors: int = 2
@export var combat_count: int = 4
@export var combat_waves: int = 2
@export var floor_enemy_bonus: int = 1
@export var detection_range: float = 700.0
@export var room_gold: int = 24
@export var treasure_gold: int = 80
@export var weapon_upgrade: int = 3
@export var supply_heal: int = 35
@export var supply_potions: int = 1
@export var floor_heal: int = 25
@export var hazard_damage: int = 9
@export var hazard_period: float = 3.0
@export var hazard_warning: float = 0.8
@export var hazard_active: float = 0.55
@export var turret_period: float = 2.0
@export var turret_speed: float = 115.0
@export var turret_lifetime: float = 5.0
@export var interact_radius: float = 31.0
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/magic_bullet.tscn")
