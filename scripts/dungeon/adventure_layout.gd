class_name AdventureLayout
extends RefCounted

const DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
var rooms: Dictionary[Vector2i, AdventureRoomState] = {}
var start: Vector2i = Vector2i.ZERO

func generate(seed_value: int) -> void:
	rooms.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var turns: int = rng.randi_range(0, 3)
	var mirror: bool = rng.randf() > 0.5
	var swap: bool = rng.randf() > 0.5
	var base: Dictionary[Vector2i, String] = {
		Vector2i(0, 0): "start", Vector2i(1, 0): "combat", Vector2i(2, 0): "hub",
		Vector2i(3, 0): "boss", Vector2i(2, -1): "blocks" if swap else "runes",
		Vector2i(2, 1): "runes" if swap else "blocks", Vector2i(1, 1): "supply",
		Vector2i(1, -1): "treasure", Vector2i(0, -1): "combat"
	}
	if rng.randf() > 0.5:
		base[Vector2i(0, 1)] = "combat"
	for original: Vector2i in base:
		var cell: Vector2i = original
		if mirror:
			cell.x = -cell.x
		for turn: int in range(turns):
			cell = Vector2i(-cell.y, cell.x)
		var state: AdventureRoomState = AdventureRoomState.new()
		state.cell = cell
		state.kind = base[original]
		state.variant = rng.randi_range(0, 2)
		state.sequence = [0, 1, 2]
		for i: int in range(2, 0, -1):
			var j: int = rng.randi_range(0, i)
			var tmp: int = state.sequence[i]
			state.sequence[i] = state.sequence[j]
			state.sequence[j] = tmp
		state.cleared = state.kind in ["start", "hub", "supply", "treasure"]
		rooms[cell] = state

func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction: Vector2i in DIRECTIONS:
		if rooms.has(cell + direction):
			result.append(cell + direction)
	return result

func seal_count() -> int:
	var count: int = 0
	for room: AdventureRoomState in rooms.values():
		if room.kind in ["runes", "blocks"] and room.cleared:
			count += 1
	return count
