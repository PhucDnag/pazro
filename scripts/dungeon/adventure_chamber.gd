class_name AdventureChamber
extends Node2D

signal changed
signal enemy_reward
signal reward_requested
signal portal_requested

var state: AdventureRoomState
var region: RegionData
var rules: AdventureData
var floor_index: int = 1
var links: Dictionary[Vector2i, String] = {}
var seals: int = 0
var remaining: int = 0
var puzzle: RoomPuzzle
var content: Node2D
var hint: Label
var detail: Label
var _wave: int = 0
var _waiting: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

static func door_position(direction: Vector2i) -> Vector2:
	if direction == Vector2i.LEFT: return Vector2(57, 190)
	if direction == Vector2i.RIGHT: return Vector2(583, 190)
	if direction == Vector2i.UP: return Vector2(320, 90)
	return Vector2(320, 291)

func _ready() -> void:
	_rng.seed = state.variant + floor_index * 731
	var arena: ExpeditionArena = ExpeditionArena.new()
	arena.region = region
	add_child(arena)
	content = Node2D.new()
	add_child(content)
	hint = PazroTheme.label(self, "", Rect2(77, 103, 488, 18), 9, Color("efcf9d"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail = PazroTheme.label(self, "", Rect2(68, 267, 504, 20), 10, Color("afcbd4"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if state.kind in ["runes", "blocks"]:
		puzzle = RoomPuzzle.new()
		puzzle.state = state
		puzzle.rules = rules
		puzzle.solved.connect(_on_puzzle_solved)
		puzzle.mistake.connect(_on_mistake)
		content.add_child(puzzle)
	if state.kind == "combat":
		_create_cover()
	if not state.cleared and state.kind in ["combat", "boss"]:
		_waiting = true
		_begin_combat.call_deferred()
	state.visited = true
	_refresh()

func _begin_combat() -> void:
	await get_tree().create_timer(0.65, false).timeout
	if not is_inside_tree():
		return
	_waiting = false
	_wave += 1
	var count: int = 1 if state.kind == "boss" else rules.combat_count + (floor_index - 1) * rules.floor_enemy_bonus
	for i: int in range(count):
		var data: EnemyData = region.boss if state.kind == "boss" else region.enemies[_rng.randi_range(0, region.enemies.size() - 1)]
		_spawn_enemy(data, Vector2(155 + (i * 113) % 340, 125 if i % 2 == 0 else 245))
	_refresh()

func _spawn_enemy(data: EnemyData, pos: Vector2) -> void:
	var enemy: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate() as Enemy
	enemy.enemy_data = data.duplicate() as EnemyData
	enemy.enemy_data.detection_range = rules.detection_range
	enemy.position = pos
	enemy.defeated.connect(_on_enemy_defeated)
	remaining += 1
	content.add_child(enemy)

func _on_enemy_defeated(_score: int) -> void:
	remaining -= 1
	enemy_reward.emit()
	if remaining == 0:
		if state.kind == "combat" and _wave < rules.combat_waves:
			_waiting = true
			_begin_combat.call_deferred()
		elif state.kind in ["combat", "boss"] or state.puzzle_solved:
			_complete()
	_refresh()

func _on_puzzle_solved() -> void:
	state.puzzle_solved = true
	if remaining == 0:
		_complete()
	_refresh()

func _on_mistake() -> void:
	if remaining == 0:
		_spawn_enemy(region.enemies[0], Vector2(490, 240))
	_refresh()

func _complete() -> void:
	if state.cleared:
		return
	state.cleared = true
	_clear_bullets()
	changed.emit()

func locked() -> bool:
	return remaining > 0 or _waiting

func can_exit(direction: Vector2i) -> bool:
	return links.has(direction) and not locked() and (links[direction] != "boss" or seals >= 2)

func tick(delta: float, player: Player) -> void:
	if puzzle:
		puzzle.tick(delta, player)
	_refresh()

func interact(player: Player) -> bool:
	if locked() and not puzzle:
		return false
	if puzzle and puzzle.interact(player.position):
		return true
	if player.position.distance_to(Vector2(320, 190)) <= rules.interact_radius:
		if state.kind in ["treasure", "supply"] and not state.claimed:
			state.claimed = true
			reward_requested.emit()
			_refresh()
			return true
		if state.kind == "boss" and state.cleared:
			portal_requested.emit()
			return true
	return false

func _refresh() -> void:
	if puzzle:
		hint.text = puzzle.clue()
		detail.text = puzzle.message
	elif state.kind == "combat":
		hint.text = "Cửa bị khóa • Đợt %d / %d • %d quái" % [maxi(1, _wave), rules.combat_waves, remaining] if not state.cleared else "Đã dọn phòng. Đến cửa và nhấn E để khám phá tiếp."
	elif state.kind == "boss":
		hint.text = "Kẻ canh giữ đã thức tỉnh!" if not state.cleared else "Đến cổng giữa phòng • E xuống tầng / kết thúc hành trình"
	elif state.kind == "treasure":
		hint.text = "Rương cổ: đến gần và nhấn E nhận vàng + nâng cấp vũ khí." if not state.claimed else "Rương đã mở. Vũ khí mạnh hơn cho phần còn lại của lượt chơi."
	elif state.kind == "supply":
		hint.text = "Suối hồi phục: E hồi máu, nạp mana và thêm một bình máu." if not state.claimed else "Suối đã cạn trong lượt chơi này."
	else:
		hint.text = "Tìm hai ấn phong để mở điện boss • Đến cửa nhấn E • M xem bản đồ"
	queue_redraw()

func _clear_bullets() -> void:
	for node: Node in get_tree().get_nodes_in_group("hostile_projectiles"):
		node.queue_free()

func _create_cover() -> void:
	for pos: Vector2 in [Vector2(245, 148 + state.variant * 32), Vector2(395, 244 - state.variant * 32)]:
		var body: StaticBody2D = StaticBody2D.new()
		body.position = pos
		var collider: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(28, 28)
		collider.shape = shape
		body.add_child(collider)
		var graphic: Polygon2D = Polygon2D.new()
		graphic.polygon = PackedVector2Array([Vector2(-14, -14), Vector2(14, -14), Vector2(14, 14), Vector2(-14, 14)])
		graphic.color = Color("49566b")
		body.add_child(graphic)
		content.add_child(body)

func draw_foreground(canvas: Node2D) -> void:
	var font: Font = ThemeDB.fallback_font
	for direction: Vector2i in links:
		var pos: Vector2 = door_position(direction)
		var open: bool = can_exit(direction)
		var color: Color = Color("6de5d0") if open else Color("e57670")
		canvas.draw_rect(Rect2(pos - Vector2(15, 12), Vector2(30, 24)), Color("132332"))
		canvas.draw_rect(Rect2(pos - Vector2(15, 12), Vector2(30, 24)), color, false, 2)
		canvas.draw_string(font, pos + Vector2(-4, 4), "E" if open else "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
		if links[direction] == "boss":
			canvas.draw_string(font, pos + Vector2(-13, -17), "BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)
	if state.kind in ["treasure", "supply"]:
		var color: Color = Color("76634b") if state.claimed else (Color("e7b96e") if state.kind == "treasure" else Color("6ddbd5"))
		canvas.draw_circle(Vector2(320, 190), 24, Color(color, 0.15))
		canvas.draw_rect(Rect2(306, 180, 28, 20), color, false, 3)
		canvas.draw_string(font, Vector2(316, 195), "+" if state.kind == "supply" else "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	if state.kind == "boss" and state.cleared:
		canvas.draw_arc(Vector2(320, 190), 24, 0, TAU, 32, Color("7be7f2"), 4)
		canvas.draw_string(font, Vector2(315, 195), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
