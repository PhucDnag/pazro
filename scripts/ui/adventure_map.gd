class_name AdventureMap
extends Node2D

var rooms: Array[Dictionary] = []
var current: Vector2i
var expanded: bool = false
const SYMBOLS: Dictionary[String, String] = {"start": "S", "combat": "!", "hub": "+", "runes": "R", "blocks": "P", "supply": "H", "treasure": "$", "boss": "B"}

func _ready() -> void:
	get_node("/root/EventBus").dungeon_changed.connect(_update_map)

func _update_map(_floor: int, _title: String, _seals: int, _gold: int, cell: Vector2i, map: Array[Dictionary]) -> void:
	rooms = map
	current = cell
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("show_map"):
		expanded = not expanded
		queue_redraw()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if rooms.is_empty():
		return
	var spacing: float = 32.0 if expanded else 9.0
	var origin: Vector2 = Vector2(320, 180) if expanded else Vector2(486, 28)
	var bounds: Rect2 = Rect2(Vector2(rooms[0].cell), Vector2.ZERO)
	for room: Dictionary in rooms:
		bounds = bounds.expand(Vector2(room.cell))
	var center: Vector2 = bounds.get_center()
	var font: Font = ThemeDB.fallback_font
	if expanded:
		draw_rect(Rect2(146, 75, 348, 231), Color(0.02, 0.04, 0.075, 0.97))
		draw_rect(Rect2(146, 75, 348, 231), Color("617896"), false, 1)
		draw_string(font, Vector2(170, 99), "BẢN ĐỒ TẦNG  •  M để đóng", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e6c181"))
		draw_string(font, Vector2(164, 281), "R: mật ngữ   P: đẩy khối   H: hồi phục   $: báu   B: boss", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("a8bdd5"))
	for room: Dictionary in rooms:
		var pos: Vector2 = origin + (Vector2(room.cell) - center) * spacing
		for other: Dictionary in rooms:
			if Vector2(room.cell).distance_to(Vector2(other.cell)) == 1.0:
				draw_line(pos, origin + (Vector2(other.cell) - center) * spacing, Color("51617a"), 1)
	for room: Dictionary in rooms:
		var pos: Vector2 = origin + (Vector2(room.cell) - center) * spacing
		var color: Color = Color("ddb778") if room.cell == current else (Color("4d9d96") if room.visited else Color("34465e"))
		var extent: float = 11 if expanded else 3
		draw_rect(Rect2(pos - Vector2.ONE * extent, Vector2.ONE * extent * 2), color)
		if expanded:
			draw_string(font, pos + Vector2(-4, 4), SYMBOLS.get(room.kind, "?"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
