class_name FloatingText
extends Node2D

## FloatingText: Số sát thương nổi (Floating Damage Number) phong cách retro.
## Tự động nhảy lên, mờ dần và giải phóng bộ nhớ.

@onready var label: Label = $Label

func setup(amount: int, is_critical: bool = false, is_player_hurt: bool = false) -> void:
	if not label:
		label = get_node_or_null("Label") as Label
	if not label:
		return
	
	label.text = str(amount)
	
	if is_player_hurt:
		label.add_theme_color_override("font_color", Color(0.95, 0.2, 0.2, 1.0)) # Đỏ khi Player bị đánh
	elif is_critical:
		label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1, 1.0)) # Cam đậm khi crit
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4, 1.0)) # Vàng sáng
	
	_animate()

func _animate() -> void:
	scale = Vector2(0.5, 0.5)
	modulate.a = 1.0
	
	var target_y: float = position.y - 18.0
	var drift_x: float = position.x + randf_range(-8.0, 8.0)
	
	var tween := create_tween()
	# Phóng to nhẹ tạo lực nảy (pop)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)
	# Bay lên và trôi ngang
	tween.parallel().tween_property(self, "position:y", target_y, 0.4)
	tween.parallel().tween_property(self, "position:x", drift_x, 0.4)
	# Mờ dần và tự hủy
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
