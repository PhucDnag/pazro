class_name EnemyData
extends Resource

## EnemyData: Custom Resource định nghĩa dữ liệu cho từng loại quái vật.
## Tách biệt hoàn toàn thông số kẻ thù khỏi logic hành vi.

@export_group("General")
@export var id: String = "goblin"
@export var enemy_name: String = "Goblin"
@export var sprite_texture: Texture2D

@export_group("Stats")
@export var max_health: int = 30
@export var speed: float = 95.0
@export var contact_damage: int = 8
@export var knockback_resistance: float = 0.0 # 0.0 = bình thường, 1.0 = không bị giật lùi

@export_group("Behavior")
@export var detection_range: float = 240.0
@export var is_ranged: bool = false
@export var attack_range: float = 24.0
@export var attack_cooldown: float = 1.0

@export_group("Ranged Attack (Nếu là quái đánh xa)")
@export var ranged_projectile_scene: PackedScene
@export var ranged_projectile_speed: float = 180.0
@export var ranged_projectile_damage: int = 10
@export var preferred_distance: float = 130.0

@export_group("Rewards")
@export var score_reward: int = 50
@export var boss: bool = false
@export var projectile_count: int = 1
@export var projectile_spread: float = 0.0
@export var visual_scale: float = 1.0
@export var tint: Color = Color.WHITE
