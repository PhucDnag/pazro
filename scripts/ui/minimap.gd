class_name Minimap
extends Control

## Minimap: Bản đồ thu nhỏ góc trên bên phải giao diện theo đúng phong cách UI Pazro.
## Hiển thị trạng thái các phòng (Đang khóa/chiến đấu, Đã dọn sạch, Chưa tới) và vị trí người chơi.

var rooms_status: Dictionary = {
	"start_room": "cleared",
	"combat_arena_1": "unvisited",
	"boss_room": "unvisited"
}
var current_room_id: String = "start_room"

var room_rects: Dictionary = {
	"start_room": Rect2(8.0, 16.0, 14.0, 12.0),
	"combat_arena_1": Rect2(30.0, 13.0, 18.0, 18.0),
	"boss_room": Rect2(54.0, 16.0, 12.0, 12.0)
}

@onready var map_canvas: Control = $MapCanvas

func _ready() -> void:
	if not map_canvas:
		map_canvas = get_node_or_null("MapCanvas") as Control
	
	if map_canvas:
		if not map_canvas.draw.is_connected(_on_map_canvas_draw):
			map_canvas.draw.connect(_on_map_canvas_draw)
	
	connect_to_event_bus(_get_event_bus())
	redraw_map()

func connect_to_event_bus(bus: Node) -> void:
	if bus:
		if bus.has_signal("room_entered") and not bus.room_entered.is_connected(_on_room_entered):
			bus.room_entered.connect(_on_room_entered)
		if bus.has_signal("room_cleared") and not bus.room_cleared.is_connected(_on_room_cleared):
			bus.room_cleared.connect(_on_room_cleared)

func _get_event_bus() -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if not tree or not tree.root:
		return null
	return tree.root.get_node_or_null("EventBus")

func set_player_room(room_id: String) -> void:
	current_room_id = room_id
	if rooms_status.has(room_id) and rooms_status[room_id] != "cleared":
		rooms_status[room_id] = "active"
	redraw_map()

func set_room_state(room_id: String, state: String) -> void:
	rooms_status[room_id] = state
	redraw_map()

func _on_room_entered(room_id: String) -> void:
	set_player_room(room_id)

func _on_room_cleared(room_id: String) -> void:
	rooms_status[room_id] = "cleared"
	redraw_map()

func redraw_map() -> void:
	if map_canvas:
		map_canvas.queue_redraw()
	queue_redraw()

func _on_map_canvas_draw() -> void:
	if not map_canvas:
		return
	
	# Vẽ các đường hành lang kết nối (Corridors)
	var corridor_color := Color(0.28, 0.33, 0.44, 0.9)
	map_canvas.draw_rect(Rect2(22.0, 20.0, 8.0, 4.0), corridor_color, true)
	map_canvas.draw_rect(Rect2(48.0, 20.0, 6.0, 4.0), corridor_color, true)
	
	# Vẽ từng phòng theo trạng thái
	for r_id in room_rects.keys():
		var rect: Rect2 = room_rects[r_id]
		var status: String = rooms_status.get(r_id, "unvisited")
		
		var fill_color: Color
		var border_color: Color
		
		match status:
			"active":
				# Phòng đang có giao tranh - Cảnh báo đỏ rực
				fill_color = Color(0.85, 0.22, 0.25, 0.9)
				border_color = Color(1.0, 0.45, 0.45, 1.0)
			"cleared":
				# Phòng đã hoàn thành / an toàn - Xanh dương Pazro
				fill_color = Color(0.18, 0.42, 0.65, 0.85)
				border_color = Color(0.42, 0.78, 0.98, 1.0)
			_:
				# Phòng chưa tới - Tối mờ
				fill_color = Color(0.11, 0.13, 0.19, 0.75)
				border_color = Color(0.25, 0.30, 0.40, 0.85)
		
		# Tô màu lòng phòng
		map_canvas.draw_rect(rect, fill_color, true)
		# Viền phòng sắc nét 1px Nearest
		map_canvas.draw_rect(rect, border_color, false, 1.0)
	
	# Vẽ biểu tượng người chơi (Chấm sáng vàng / trắng nhấp nháy tại phòng hiện tại)
	if room_rects.has(current_room_id):
		var cur_rect: Rect2 = room_rects[current_room_id]
		var p_center := cur_rect.get_center()
		map_canvas.draw_circle(p_center, 2.5, Color(1.0, 0.88, 0.35, 1.0))
		map_canvas.draw_arc(p_center, 3.5, 0.0, TAU, 8, Color.WHITE, 1.0)
