class_name Projectile
extends Area2D

## Projectile: Thực thể đạn bay trong PixelDungeon.
## Tự động di chuyển theo hướng, kiểm tra va chạm tường/kẻ thù và tự hủy kèm hiệu ứng tia lửa.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 420.0
var damage: int = 12
var lifetime: float = 1.5
var from_player: bool = true

var _time_alive: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if not from_player:
		add_to_group("hostile_projectiles")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(
	dir: Vector2,
	spd: float,
	dmg: int,
	life: float,
	tex: Texture2D = null,
	proj_scale: Vector2 = Vector2.ONE,
	is_player_bullet: bool = true
) -> void:
	direction = dir.normalized()
	speed = spd
	damage = dmg
	lifetime = life
	from_player = is_player_bullet
	rotation = direction.angle()
	
	if tex:
		if not sprite:
			sprite = get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.texture = tex
			sprite.scale = proj_scale

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_time_alive += delta
	if _time_alive >= lifetime:
		_spawn_impact_and_free()

func _on_body_entered(body: Node2D) -> void:
	# Bỏ qua chính phe mình
	if from_player and body is Player:
		return
	if not from_player and not (body is Player) and body is Enemy:
		return
	
	# Va chạm thực thể có hàm take_damage
	if body.has_method("take_damage"):
		body.take_damage(damage, direction)
		_spawn_impact_and_free()
		return
	
	# Va chạm tường hoặc vật cản tĩnh (StaticBody2D)
	if body is StaticBody2D or body is TileMap or body is TileMapLayer:
		_spawn_impact_and_free()

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		var hurtbox := area as HurtboxComponent
		# Chỉ gây sát thương cho phe đối nghịch
		if hurtbox.is_player_side != from_player:
			hurtbox.receive_hit(damage, direction)
			_spawn_impact_and_free()

func _spawn_impact_and_free() -> void:
	_create_hit_spark()
	queue_free()

func _create_hit_spark() -> void:
	if not is_inside_tree():
		return
	
	var spark_tex: Texture2D = load("res://assets/sprites/vfx/hit_spark.png")
	if not spark_tex:
		return
	
	var spark := Sprite2D.new()
	spark.texture = spark_tex
	spark.global_position = global_position
	spark.scale = Vector2(1.2, 1.2)
	get_parent().add_child(spark)
	
	var tween := spark.create_tween()
	tween.parallel().tween_property(spark, "scale", Vector2.ZERO, 0.12)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.12)
	tween.tween_callback(spark.queue_free)
