class_name AdventureRoomState
extends RefCounted

var cell: Vector2i
var kind: String
var visited: bool = false
var cleared: bool = false
var claimed: bool = false
var puzzle_solved: bool = false
var sequence: Array[int] = []
var progress: int = 0
var blocks: Array[Vector2] = [Vector2(288, 158), Vector2(352, 222)]
var plates: Array[Vector2] = [Vector2(416, 158), Vector2(416, 222)]
var variant: int = 0

func title() -> String:
	match kind:
		"start": return "Nơi trú chân"
		"combat": return "Sảnh canh gác"
		"hub": return "Ngã rẽ cổ đại"
		"runes": return "Mật ngữ tinh thạch"
		"blocks": return "Cơ quan cân bằng"
		"supply": return "Suối hồi phục"
		"treasure": return "Kho báu thất lạc"
		"boss": return "Điện của kẻ canh giữ"
	return kind
