class_name PlayerData
extends Resource
@export var sprite_texture: Texture2D = preload("res://data/hero_texture.tres")
@export var sprite_scale: float = 0.06

@export var max_health: int = 100
@export var max_energy: int = 50
@export var speed: float = 160.0
@export var energy_regen: float = 5.0
@export var dash_speed: float = 450.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 1.2
@export var skill_cost: int = 18
@export var skill_damage: int = 35
@export var skill_radius: float = 85.0
@export var skill_cooldown: float = 4.0
@export var potion_heal: int = 40
@export var starting_potions: int = 3
@export var kill_energy: int = 3
