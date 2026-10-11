class_name Main
extends Node2D

## Main: Điều phối khởi tạo màn chơi chính, liên kết Dungeon, Player và HUD.

@onready var dungeon: Dungeon = $Dungeon
@onready var player: Player = $Player
@onready var hud: HUD = $HUD

func _ready() -> void:
	# Đặt vị trí ban đầu của Player tại điểm Spawn của Dungeon
	if dungeon and player:
		player.global_position = dungeon.get_spawn_position()
	
	# Kết nối HUD với Player
	if hud and player:
		hud.connect_to_player(player)
	
	print("[Main] Đã khởi tạo màn chơi PixelDungeon thành công!")

func _unhandled_input(event: InputEvent) -> void:
	# Phím tắt debug tiện lợi để kiểm tra phản hồi của HUD và hiệu ứng sát thương
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H and player:
			player.take_damage(15)
		elif event.keycode == KEY_J and player:
			player.heal(15)
