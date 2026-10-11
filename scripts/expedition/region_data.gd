class_name RegionData
extends Resource

@export var title: String
@export var subtitle: String
@export var accent: Color
@export var floor_color: Color
@export var preview: Rect2
@export var arena_texture: Texture2D = preload("res://assets/art/arena_floor.png")
@export var waves: Array[int] = [3, 4, 5]
@export var enemies: Array[EnemyData]
@export var boss: EnemyData
@export var kill_gold: int = 12
@export var chest_gold: int = 100
@export var wave_delay: float = 2.0
