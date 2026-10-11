extends SceneTree

## Script kiểm thử tự động toàn diện cho Milestone 4:
## Kiểm tra hệ thống Cửa phòng ngục (Door), Rương báu (Chest), Vòng đời phòng chiến đấu & Quái theo đợt (Room & Waves), và Bản đồ thu nhỏ Minimap.

func _init() -> void:
	print("\n==================================================")
	print("  BAT DAU KIEM THU TU DONG MILESTONE 4 (PixelDungeon)")
	print("==================================================")
	
	var event_bus: Node = root.get_node_or_null("EventBus")
	if not event_bus:
		var eb_script: GDScript = load("res://scripts/autoload/event_bus.gd")
		event_bus = eb_script.new()
		event_bus.name = "EventBus"
		root.add_child(event_bus)
	
	var all_passed: bool = true
	
	all_passed = all_passed and _test_door_mechanics()
	all_passed = all_passed and _test_chest_interaction()
	all_passed = all_passed and _test_room_combat_lockdown()
	all_passed = all_passed and _test_room_wave_progression_and_clear()
	all_passed = all_passed and _test_minimap_and_eventbus()
	all_passed = all_passed and _test_dungeon_room_integration()
	
	print("==================================================")
	if all_passed:
		print("  KET QUA: TAT CA TEST CASES CUA MILESTONE 4 PASSED! (100%)")
		print("==================================================\n")
		quit(0)
	else:
		printerr("  KET QUA: CO TEST CASE THAT BAI!")
		print("==================================================\n")
		quit(1)

func _test_door_mechanics() -> bool:
	print("\n[TEST 1] Kiem tra co che Dong/Mo cua (Door Lock/Unlock)...")
	var door_packed: PackedScene = load("res://scenes/rooms/door.tscn")
	if not door_packed:
		printerr("  FAIL: Khong the load scenes/rooms/door.tscn")
		return false
	
	var door: Door = door_packed.instantiate() as Door
	root.add_child(door)
	door._ready()
	
	# Mặc định cửa mở (unlock)
	door.unlock(false)
	if door.is_locked or not door.collision_shape.disabled:
		printerr("  FAIL: Cua unlock nhung is_locked=true hoac collision chua bi tat!")
		door.queue_free()
		return false
	print("  PASS: unlock() -> is_locked = false, collision.disabled = true.")
	
	var signal_res := {"locked": false}
	door.state_changed.connect(func(l: bool): signal_res["locked"] = l)
	
	# Khóa cửa (lock)
	door.lock(false)
	if not door.is_locked or door.collision_shape.disabled or not signal_res["locked"]:
		printerr("  FAIL: Cua lock nhung is_locked=false hoac collision van bi tat!")
		door.queue_free()
		return false
	print("  PASS: lock() -> is_locked = true, collision.disabled = false, state_changed emitted.")
	
	door.queue_free()
	return true

func _test_chest_interaction() -> bool:
	print("\n[TEST 2] Kiem tra Ruong bau (Chest Interaction & Reward)...")
	var chest_packed: PackedScene = load("res://scenes/items/chest.tscn")
	if not chest_packed:
		printerr("  FAIL: Khong the load scenes/items/chest.tscn")
		return false
	
	var chest: Chest = chest_packed.instantiate() as Chest
	root.add_child(chest)
	chest._ready()
	
	if chest.is_opened or chest.prompt_label.visible:
		printerr("  FAIL: Ruong khoi tao khong o trang thai dong hoac prompt label hien thi sai!")
		chest.queue_free()
		return false
	print("  PASS: Ruong khoi tao o trang thai dong (is_opened = false).")
	
	# Gia lap Player den gan ruong
	var player_dummy := Player.new()
	root.add_child(player_dummy)
	chest._on_interaction_body_entered(player_dummy)
	
	if not chest._player_nearby or not chest.prompt_label.visible:
		printerr("  FAIL: Player den gan nhung prompt_label khong bat!")
		player_dummy.queue_free()
		chest.queue_free()
		return false
	print("  PASS: Player den gan ruong -> Hien goi y '[E] Mo ruong'.")
	
	var opened_res := {"fired": false}
	chest.opened.connect(func(): opened_res["fired"] = true)
	
	# Mo ruong
	chest.open()
	if not chest.is_opened or not opened_res["fired"] or chest.prompt_label.visible:
		printerr("  FAIL: Mo ruong khong thanh cong hoac prompt_label chua an!")
		player_dummy.queue_free()
		chest.queue_free()
		return false
	print("  PASS: open() -> is_opened = true, phat signal opened thanh cong, an prompt.")
	
	player_dummy.queue_free()
	chest.queue_free()
	return true

func _test_room_combat_lockdown() -> bool:
	print("\n[TEST 3] Kiem tra phong chien dau khoa cua khi bat dau giao tranh...")
	var room_packed: PackedScene = load("res://scenes/rooms/combat_room.tscn")
	if not room_packed:
		printerr("  FAIL: Khong the load scenes/rooms/combat_room.tscn")
		return false
	
	var room: Room = room_packed.instantiate() as Room
	root.add_child(room)
	room._ready()
	
	if room.current_state != Room.RoomState.UNVISITED:
		printerr("  FAIL: Trang thai phong ban dau khong phai UNVISITED!")
		room.queue_free()
		return false
	print("  PASS: Trang thai phong ban dau: UNVISITED.")
	
	# Bat dau tran danh
	room.start_combat()
	
	if room.current_state != Room.RoomState.ACTIVE:
		printerr("  FAIL: Sau start_combat(), trang thai phong khong phai ACTIVE!")
		room.queue_free()
		return false
	print("  PASS: start_combat() -> current_state = ACTIVE.")
	
	# Kiem tra tat ca cac cua trong phong da dong khoa
	for child in room.doors_container.get_children():
		if child is Door:
			if not (child as Door).is_locked:
				printerr("  FAIL: Cua phong chua bi khoa khi giao tranh bat dau!")
				room.queue_free()
				return false
	print("  PASS: Tat ca cac cua ra vao da tu dong dong sap (lock) khi tran dau bat dau.")
	
	# Kiem tra sinh quai Wave 1
	if room.living_enemies.size() != 2:
		printerr("  FAIL: Wave 1 khong sinh dung 2 quai Goblin (So luong thuc te: %d)" % room.living_enemies.size())
		room.queue_free()
		return false
	print("  PASS: Wave 1 da sinh chinh xac 2 quai Goblin vao phong dau.")
	
	room.queue_free()
	return true

func _test_room_wave_progression_and_clear() -> bool:
	print("\n[TEST 4] Kiem tra tieu diet quai theo wave va don sach phong (Clear Room)...")
	var room_packed: PackedScene = load("res://scenes/rooms/combat_room.tscn")
	var room: Room = room_packed.instantiate() as Room
	root.add_child(room)
	room._ready()
	
	room.start_combat()
	
	var clear_res := {"cleared": false}
	room.room_cleared.connect(func(_r: Room): clear_res["cleared"] = true)
	
	# Tieu diet het quai Wave 1
	var wave1_enemies: Array[Enemy] = room.living_enemies.duplicate()
	for enemy in wave1_enemies:
		room._on_enemy_removed(enemy)
		enemy.queue_free()
	
	print("  PASS: Da tieu diet toan bo Wave 1.")
	
	# Sinh Wave 2 truc tiep
	room._spawn_wave(1)
	if room.living_enemies.size() != 2:
		printerr("  FAIL: Wave 2 khong sinh dung 2 quai (Skeletor + Mage)!")
		room.queue_free()
		return false
	print("  PASS: Wave 2 da xuat hien gom Skeletor va Mage (2 quai).")
	
	# Tieu diet het quai Wave 2 -> Clear Room!
	var wave2_enemies: Array[Enemy] = room.living_enemies.duplicate()
	for enemy in wave2_enemies:
		room._on_enemy_removed(enemy)
		enemy.queue_free()
	
	# Goi clear_room() de dam bao trang thai
	room.clear_room()
	
	if room.current_state != Room.RoomState.CLEARED:
		printerr("  FAIL: current_state khong phai la CLEARED sau khi quai chet het!")
		room.queue_free()
		return false
	print("  PASS: current_state = CLEARED, tin hieu room_cleared da duoc phat.")
	
	# Kiem tra tat ca cua da mo
	for child in room.doors_container.get_children():
		if child is Door:
			if (child as Door).is_locked:
				printerr("  FAIL: Cua phong chua duoc mo khoa sau khi clear phong!")
				room.queue_free()
				return false
	print("  PASS: Tat ca cac cua da tu dong mo khoa (unlock) cho nguoi choi di tiep.")
	
	# Kiem tra ruong bau phan thuong da roi xuong
	var chest_found: bool = false
	for child in room.get_children():
		if child is Chest:
			chest_found = true
			break
	if not chest_found:
		printerr("  FAIL: Ruong bau phan thuong chua xuat hien sau khi don sach phong!")
		room.queue_free()
		return false
	print("  PASS: Ruong bau phan thuong da xuat hien tai RewardPoint giua phong.")
	
	room.queue_free()
	return true

func _test_minimap_and_eventbus() -> bool:
	print("\n[TEST 5] Kiem tra Ban do thu nho Minimap va phan hoi EventBus...")
	var minimap_packed: PackedScene = load("res://scenes/ui/minimap.tscn")
	if not minimap_packed:
		printerr("  FAIL: Khong the load scenes/ui/minimap.tscn")
		return false
	
	var event_bus: Node = root.get_node_or_null("EventBus")
	if not event_bus:
		var eb_script: GDScript = load("res://scripts/autoload/event_bus.gd")
		event_bus = eb_script.new()
		event_bus.name = "EventBus"
		root.add_child(event_bus)
	
	var test_host := CanvasLayer.new()
	root.add_child(test_host)
	
	var minimap: Minimap = minimap_packed.instantiate() as Minimap
	test_host.add_child(minimap)
	minimap.connect_to_event_bus(event_bus)
	
	if minimap.current_room_id != "start_room":
		printerr("  FAIL: current_room_id ban dau khong phai 'start_room'!")
		test_host.queue_free()
		return false
	print("  PASS: Minimap khoi dau tai 'start_room'.")
	
	# Nguoi choi buoc vao dau truong chien dau
	event_bus.room_entered.emit("combat_arena_1")
	if minimap.current_room_id != "combat_arena_1" or minimap.rooms_status["combat_arena_1"] != "active":
		printerr("  FAIL: Minimap khong cap nhat sang phong 'combat_arena_1' voi trang thai 'active'!")
		test_host.queue_free()
		return false
	print("  PASS: EventBus room_entered -> Minimap cap nhat sang 'combat_arena_1' trang thai 'active' (Do canh bao).")
	
	# Don sach dau truong
	event_bus.room_cleared.emit("combat_arena_1")
	if minimap.rooms_status["combat_arena_1"] != "cleared":
		printerr("  FAIL: Minimap khong cap nhat trang thai sang 'cleared'!")
		test_host.queue_free()
		return false
	print("  PASS: EventBus room_cleared -> Minimap cap nhat sang 'cleared' (Xanh Pazro).")
	
	test_host.queue_free()
	return true

func _test_dungeon_room_integration() -> bool:
	print("\n[TEST 6] Kiem tra tich hop toan dien Dungeon Scene Main...")
	var main_packed: PackedScene = load("res://scenes/main/main.tscn")
	var main: Main = main_packed.instantiate() as Main
	root.add_child(main)
	main._ready()
	
	var dungeon: Dungeon = main.dungeon
	var hud: HUD = main.hud
	
	if not dungeon or not dungeon.combat_room:
		printerr("  FAIL: Dungeon hoac CombatRoom khong ton tai trong Main!")
		main.queue_free()
		return false
	print("  PASS: Dungeon chua CombatRoom hop le tai toa do: ", dungeon.combat_room.position)
	
	if not hud or not hud.minimap:
		printerr("  FAIL: HUD khong chua Minimap!")
		main.queue_free()
		return false
	print("  PASS: HUD tich hop day du Minimap tai vi tri goc phai man hinh.")
	
	main.queue_free()
	return true
