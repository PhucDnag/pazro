class_name RoomPuzzle
extends Node2D

signal solved
signal mistake
var state: AdventureRoomState
var rules: AdventureData
var block_bodies: Array[StaticBody2D] = []
var clock: float = 0.0
var _last_pulse: int = -1
var _warning_pulse: int = -1
var _turret_clock: float = 0.0
var message: String = ""
const RUNES: Array[String] = ["I", "II", "III"]
const RUNE_POSITIONS: Array[Vector2] = [Vector2(208, 185), Vector2(320, 185), Vector2(432, 185)]

func _ready() -> void:
	if state.kind == "blocks":
		for pos: Vector2 in state.blocks:
			var body: StaticBody2D = StaticBody2D.new()
			body.position = pos
			var collider: CollisionShape2D = CollisionShape2D.new()
			var shape: RectangleShape2D = RectangleShape2D.new()
			shape.size = Vector2(24, 24)
			collider.shape = shape
			body.add_child(collider)
			add_child(body)
			block_bodies.append(body)

func tick(delta: float, player: Player) -> void:
	if state.cleared or state.puzzle_solved:
		return
	clock += delta
	if state.kind == "runes":
		_turret_clock += delta
		if _turret_clock >= rules.turret_period:
			_turret_clock = 0.0
			GameAudio.cue(self, "enemy_cast")
			var bullet: Projectile = rules.projectile_scene.instantiate() as Projectile
			bullet.position = Vector2(80, 125 if int(clock / rules.turret_period) % 2 == 0 else 255)
			bullet.setup(bullet.position.direction_to(player.position), rules.turret_speed, rules.hazard_damage, rules.turret_lifetime, null, Vector2.ONE, false)
			add_child(bullet)
	if state.kind == "blocks":
		var phase: float = fmod(clock, rules.hazard_period)
		var pulse: int = int(clock / rules.hazard_period)
		if phase >= rules.hazard_period - rules.hazard_active - rules.hazard_warning and _warning_pulse != pulse:
			_warning_pulse = pulse
			GameAudio.cue(self, "warning")
		if phase >= rules.hazard_period - rules.hazard_active and _last_pulse != pulse:
			if absf(player.position.y - 158) < 12 or absf(player.position.y - 222) < 12:
				_last_pulse = pulse
				player.take_damage(rules.hazard_damage)
	queue_redraw()

func interact(player_position: Vector2) -> bool:
	if state.cleared or state.puzzle_solved:
		return false
	if state.kind == "runes":
		for i: int in range(RUNE_POSITIONS.size()):
			if player_position.distance_to(RUNE_POSITIONS[i]) <= rules.interact_radius:
				activate_rune(i)
				return true
	if state.kind == "blocks":
		if player_position.distance_to(Vector2(160, 190)) <= rules.interact_radius:
			reset_blocks()
			return true
		for i: int in range(state.blocks.size()):
			if player_position.distance_to(state.blocks[i]) <= rules.interact_radius:
				var offset: Vector2 = state.blocks[i] - player_position
				var dir: Vector2 = Vector2(signf(offset.x), 0) if absf(offset.x) >= absf(offset.y) else Vector2(0, signf(offset.y))
				push_block(i, dir)
				return true
	return false

func activate_rune(index: int) -> void:
	if state.cleared or state.puzzle_solved:
		return
	if index != state.sequence[state.progress]:
		GameAudio.cue(self, "wrong")
		state.progress = 0
		message = "Sai thứ tự! Hạ lính canh rồi thử lại."
		mistake.emit()
	else:
		state.progress += 1
		GameAudio.cue(self, "rune")
		message = "Đã kích hoạt %d / 3 tinh thạch" % state.progress
		if state.progress == state.sequence.size():
			solved.emit()
	queue_redraw()

func push_block(index: int, direction: Vector2) -> bool:
	if state.cleared or state.puzzle_solved or index < 0 or index >= state.blocks.size() or direction.length() != 1.0:
		return false
	var target: Vector2 = state.blocks[index] + direction * 32
	if not Rect2(112, 112, 416, 160).has_point(target) or state.blocks.has(target):
		message = "Không đẩy được. Dùng bệ RESET nếu bị kẹt."
		return false
	state.blocks[index] = target
	GameAudio.cue(self, "push")
	block_bodies[index].position = target
	message = "Đẩy cả hai khối lên hai đĩa sáng."
	var all_covered: bool = true
	for plate: Vector2 in state.plates:
		all_covered = all_covered and state.blocks.has(plate)
	if all_covered:
		solved.emit()
	queue_redraw()
	return true

func reset_blocks() -> void:
	GameAudio.cue(self, "push")
	state.blocks = [Vector2(288, 158), Vector2(352, 222)]
	for i: int in range(block_bodies.size()):
		block_bodies[i].position = state.blocks[i]
	message = "Đã đặt lại khối. Đứng phía đối diện hướng cần đẩy, nhấn E."
	queue_redraw()

func clue() -> String:
	if state.puzzle_solved and not state.cleared:
		return "Cơ quan đã giải! Hạ lính canh còn lại để nhận ấn phong."
	if state.cleared or state.puzzle_solved:
		return "Đã nhận ấn phong. Cơ quan đã ngừng hoạt động."
	if state.kind == "runes":
		return "Bia đá: %s → %s → %s  |  Đến gần trụ, nhấn E. Né đạn!" % [RUNES[state.sequence[0]], RUNES[state.sequence[1]], RUNES[state.sequence[2]]]
	return "E đẩy khối lên đĩa sáng • Né dải đỏ • Bệ trái: E đặt lại"

func _draw() -> void:
	if not state:
		return
	var font: Font = ThemeDB.fallback_font
	if state.kind == "runes":
		for turret: Vector2 in [Vector2(80, 125), Vector2(80, 255)]:
			draw_rect(Rect2(turret - Vector2(9, 9), Vector2(18, 18)), Color("3c3456"))
			draw_colored_polygon(PackedVector2Array([turret + Vector2(10, 0), turret + Vector2(-4, -5), turret + Vector2(-4, 5)]), Color("d59cf2"))
			if not state.puzzle_solved and not state.cleared:
				draw_arc(turret, 13, -PI / 2, -PI / 2 + TAU * _turret_clock / rules.turret_period, 24, Color("c193e5"), 2)
		for i: int in range(3):
			var pos: Vector2 = RUNE_POSITIONS[i]
			var lit: bool = state.sequence.slice(0, state.progress).has(i)
			var color: Color = Color("6ee6d2") if lit else Color("b791ef")
			draw_circle(pos, 20, Color(color, 0.12))
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -14), pos + Vector2(9, 0), pos + Vector2(0, 14), pos + Vector2(-9, 0)]), color)
			draw_string(font, pos + Vector2(-8, 30), RUNES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		return
	for plate: Vector2 in state.plates:
		draw_rect(Rect2(plate - Vector2(15, 15), Vector2(30, 30)), Color("67e4ba"), false, 2)
	for pos: Vector2 in state.blocks:
		draw_rect(Rect2(pos - Vector2(12, 12), Vector2(24, 24)), Color("7a7c97"))
		draw_rect(Rect2(pos - Vector2(9, 9), Vector2(18, 18)), Color("c1b2a2"), false, 2)
	draw_circle(Vector2(160, 190), 16, Color("263b52"))
	draw_string(font, Vector2(143, 194), "RESET", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("7fe1f0"))
	if not state.cleared and not state.puzzle_solved:
		var phase: float = fmod(clock, rules.hazard_period)
		if phase > rules.hazard_period - rules.hazard_warning - rules.hazard_active:
			var active: bool = phase >= rules.hazard_period - rules.hazard_active
			for y: int in [158, 222]:
				draw_rect(Rect2(65, y - 10, 510, 20), Color(1, 0.2, 0.2, 0.4 if active else 0.1))

