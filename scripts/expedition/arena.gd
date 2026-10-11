class_name ExpeditionArena
extends Node2D

var region: RegionData
var elapsed: float = 0.0

func _ready() -> void:
	for rect: Rect2 in [Rect2(32, 62, 576, 14), Rect2(32, 306, 576, 14), Rect2(24, 62, 16, 258), Rect2(600, 62, 16, 258)]:
		var wall: StaticBody2D = StaticBody2D.new()
		wall.position = rect.get_center()
		var collider: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = rect.size
		collider.shape = shape
		wall.add_child(collider)
		add_child(wall)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	if not region:
		return
	draw_rect(Rect2(0, 0, 640, 360), Color("060b14"))
	draw_texture_rect(region.arena_texture, Rect2(24, 60, 592, 262), false, region.floor_color.lightened(0.65))
	for x: int in [70, 180, 460, 570]:
		for y: int in [72, 288]:
			var pos: Vector2 = Vector2(x, y)
			for radius: int in [22, 15, 8]:
				draw_circle(pos, radius + sin(elapsed * 5 + x) * 1.5, Color(region.accent, 0.035))
	for i: int in range(24):
		var pos: Vector2 = Vector2(45 + (i * 97) % 546, 80 + fposmod(i * 47 - elapsed * (5 + i % 3), 220))
		draw_rect(Rect2(pos, Vector2.ONE), Color(region.accent, 0.2 + sin(elapsed + i) * 0.15))
