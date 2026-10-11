class_name WeaponData
extends Resource

## WeaponData: Custom Resource định nghĩa dữ liệu của từng vũ khí.
## Tách biệt hoàn toàn thông số (Data) khỏi logic thực thi.

@export_group("General")
@export var id: String = "pistol"
@export var weapon_name: String = "Pistol"
@export var icon: Texture2D

@export_group("Combat Stats")
@export var damage: int = 12
@export var fire_rate: float = 3.5          # Số phát bắn trong 1 giây
@export var energy_cost: int = 1            # Lượng mana/năng lượng tiêu hao mỗi lần bắn
@export var projectile_speed: float = 420.0
@export var projectile_lifetime: float = 1.5
@export var projectile_count: int = 1       # Số viên đạn bắn ra mỗi lần (Shotgun > 1)
@export var spread_degrees: float = 2.0     # Góc tỏa đạn (độ)
@export var recoil: float = 3.0             # Độ giật lùi vũ khí khi khai hỏa

@export_group("Projectile Visual")
@export var projectile_texture: Texture2D
@export var projectile_scale: Vector2 = Vector2.ONE
