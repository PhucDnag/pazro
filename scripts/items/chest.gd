class_name Chest
extends StaticBody2D

## Chest: Rương báu xuất hiện làm phần thưởng sau khi dọn sạch phòng chiến đấu.
## Tương tác bằng phím E để mở, sinh số thưởng nổi và thông báo qua EventBus.

signal opened

@export var is_opened: bool = false
@export var gold_reward: int = 100
@export var closed_texture: Texture2D = preload("res://assets/sprites/props/chest_closed.png")
@export var open_texture: Texture2D = preload("res://assets/sprites/props/chest_open.png")
@export var floating_text_scene: PackedScene = preload("res://scenes/ui/floating_text.tscn")

var _player_nearby: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	if not sprite:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if not prompt_label:
		prompt_label = get_node_or_null("PromptLabel") as Label
	if not interaction_area:
		interaction_area = get_node_or_null("InteractionArea") as Area2D
	
	if interaction_area:
		if not interaction_area.body_entered.is_connected(_on_interaction_body_entered):
			interaction_area.body_entered.connect(_on_interaction_body_entered)
		if not interaction_area.body_exited.is_connected(_on_interaction_body_exited):
			interaction_area.body_exited.connect(_on_interaction_body_exited)
	
	if is_opened:
		if sprite and open_texture:
			sprite.texture = open_texture
		if prompt_label:
			prompt_label.visible = false
	else:
		if sprite and closed_texture:
			sprite.texture = closed_texture
		if prompt_label:
			prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_opened and _player_nearby and event.is_action_pressed("interact"):
		open()

## Hiệu ứng rương rơi từ trên xuống khi vừa dọn sạch phòng
func spawn_pop(target_pos: Vector2) -> void:
	global_position = target_pos + Vector2(0, -22)
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0
	
	if is_inside_tree():
		var tween := create_tween()
		tween.parallel().tween_property(self, "global_position:y", target_pos.y, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)
		tween.parallel().tween_property(self, "modulate:a", 1.0, 0.15)
	else:
		global_position = target_pos
		scale = Vector2.ONE
		modulate.a = 1.0

## Mở rương và nhận phần thưởng
func open() -> void:
	if is_opened:
		return
	is_opened = true
	
	if sprite and open_texture:
		sprite.texture = open_texture
	if prompt_label:
		prompt_label.visible = false
	
	# Hiệu ứng nảy nhẹ khi bung nắp
	if sprite and is_inside_tree():
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.08)
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)
	
	# Sinh số vàng thưởng nổi
	_spawn_reward_text()
	
	opened.emit()
	
	var event_bus: Node = _get_event_bus()
	if event_bus and event_bus.has_signal("interaction_triggered"):
		event_bus.interaction_triggered.emit("chest_opened")
		if event_bus.has_signal("reward_collected"):
			event_bus.reward_collected.emit(gold_reward)

func _spawn_reward_text() -> void:
	if not floating_text_scene or not is_inside_tree():
		return
	
	var float_node = floating_text_scene.instantiate()
	if float_node is FloatingText:
		var float_text := float_node as FloatingText
		float_text.global_position = global_position + Vector2(0, -12)
		if get_parent():
			get_parent().add_child(float_text)
		float_text.setup(gold_reward, true, false)

func _get_event_bus() -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if not tree or not tree.root:
		return null
	return tree.root.get_node_or_null("EventBus")

func _on_interaction_body_entered(body: Node2D) -> void:
	if not is_opened and body is Player:
		_player_nearby = true
		if prompt_label:
			prompt_label.visible = true

func _on_interaction_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_nearby = false
		if prompt_label:
			prompt_label.visible = false
