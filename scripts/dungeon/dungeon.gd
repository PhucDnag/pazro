class_name Dungeon
extends Node2D

## Dungeon: Quản lý khu vực bản đồ ngục tối (Dungeon Level Layout).
## Chứa Phòng Khởi Đầu (Start Room), Hành lang (Corridor) và Đấu trường chiến đấu (CombatRoom).

var spawn_point: Marker2D:
	get:
		if not _spawn_point:
			_spawn_point = get_node_or_null("SpawnPoint") as Marker2D
		return _spawn_point
var _spawn_point: Marker2D

var combat_room: Room:
	get:
		if not _combat_room:
			_combat_room = get_node_or_null("CombatRoom") as Room
		return _combat_room
var _combat_room: Room

func _ready() -> void:
	# Thông báo vào phòng khởi đầu an toàn thông qua EventBus
	var event_bus: Node = _get_event_bus()
	if event_bus and event_bus.has_signal("room_entered"):
		event_bus.room_entered.emit("start_room")

## Trả về vị trí xuất hiện ban đầu của người chơi
func get_spawn_position() -> Vector2:
	if spawn_point:
		return spawn_point.global_position
	return Vector2.ZERO

func _get_event_bus() -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if not tree or not tree.root:
		return null
	return tree.root.get_node_or_null("EventBus")
