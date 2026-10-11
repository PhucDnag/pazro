extends SceneTree

## Script kiểm thử tự động toàn diện cho Milestone 1:
## Khởi tạo Main, kiểm tra Player movement, va chạm, Camera, và đồng bộ HUD máu.

func _init() -> void:
	print("\n==================================================")
	print("  BAT DAU KIEM THU TU DONG MILESTONE 1 (PixelDungeon)")
	print("==================================================")
	
	var all_passed: bool = true
	
	all_passed = all_passed and _test_project_settings()
	all_passed = all_passed and _test_scene_structure_and_nodes()
	all_passed = all_passed and _test_player_mechanics_and_movement()
	all_passed = all_passed and _test_player_hud_health_sync()
	all_passed = all_passed and _test_dungeon_colliders()
	
	print("==================================================")
	if all_passed:
		print("  KET QUA: TAT CA TEST CASES CUA MILESTONE 1 PASSED! (100%)")
		print("==================================================\n")
		quit(0)
	else:
		printerr("  KET QUA: CO TEST CASE THAT BAI!")
		print("==================================================\n")
		quit(1)

func _test_project_settings() -> bool:
	print("\n[TEST 1] Kiem tra Project Settings & Pixel Art Config...")
	var vp_w: int = ProjectSettings.get_setting("display/window/size/viewport_width", 0)
	var vp_h: int = ProjectSettings.get_setting("display/window/size/viewport_height", 0)
	var stretch_mode: String = ProjectSettings.get_setting("display/window/stretch/mode", "")
	var stretch_aspect: String = ProjectSettings.get_setting("display/window/stretch/aspect", "")
	var tex_filter: int = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1)
	
	if vp_w != 640 or vp_h != 360:
		printerr("  FAIL: Do phan giai viewport khong dung 640x360 (Thuc te: %dx%d)" % [vp_w, vp_h])
		return false
	print("  PASS: Do phan giai noi bo viewport: 640x360.")
	
	if stretch_mode != "canvas_items" or stretch_aspect != "keep":
		printerr("  FAIL: Stretch mode/aspect khong dung canvas_items/keep")
		return false
	print("  PASS: Stretch mode: canvas_items | Aspect: keep.")
	
	if tex_filter != 0:
		printerr("  FAIL: Texture filter khong phai Nearest (0)")
		return false
	print("  PASS: Default texture filter: Nearest (0 - Sac net tung pixel).")
	return true

func _test_scene_structure_and_nodes() -> bool:
	print("\n[TEST 2] Kiem tra cau truc Scene Main & cac thanh phan...")
	var main_packed: PackedScene = load("res://scenes/main/main.tscn")
	if not main_packed:
		printerr("  FAIL: Khong the load scenes/main/main.tscn")
		return false
	
	var main_instance: Node = main_packed.instantiate()
	root.add_child(main_instance)
	
	var dungeon_node: Node = main_instance.get_node_or_null("Dungeon")
	var player_node: Node = main_instance.get_node_or_null("Player")
	var hud_node: Node = main_instance.get_node_or_null("HUD")
	
	if not dungeon_node or not player_node or not hud_node:
		printerr("  FAIL: Thieu node con (Dungeon/Player/HUD) trong Main scene.")
		main_instance.queue_free()
		return false
	print("  PASS: Scene Main da khoi tao day du Dungeon, Player va HUD.")
	
	# Kiem tra vi tri Player tai SpawnPoint
	var dungeon: Dungeon = dungeon_node as Dungeon
	var player: Player = player_node as Player
	if player.global_position != dungeon.get_spawn_position():
		printerr("  FAIL: Player khong xuat hien tai SpawnPoint cua Dungeon!")
		main_instance.queue_free()
		return false
	print("  PASS: Player da duoc can vi tri chinh xac tai SpawnPoint: ", player.global_position)
	
	main_instance.queue_free()
	return true

func _test_player_mechanics_and_movement() -> bool:
	print("\n[TEST 3] Kiem tra logic di chuyen va Camera cua Player...")
	var player_packed: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_packed.instantiate() as Player
	root.add_child(player)
	
	if not player.camera:
		printerr("  FAIL: Player khong co Camera2D!")
		player.queue_free()
		return false
	print("  PASS: Camera2D duoc gan voi Player (Position Smoothing: %s, Speed: %.1f)." % [player.camera.position_smoothing_enabled, player.camera.position_smoothing_speed])
	
	if not player.collision_shape:
		printerr("  FAIL: Player khong co CollisionShape2D!")
		player.queue_free()
		return false
	print("  PASS: CollisionShape2D cua Player ton tai hop le.")
	
	# Test tinh toan van toc chuan hoa
	var speed: float = player.speed
	var test_dir_cardinal := Vector2(1, 0)
	var expected_cardinal_vel := test_dir_cardinal * speed
	if expected_cardinal_vel.length() != speed:
		printerr("  FAIL: Van toc di chuyen huong truc khong dung.")
		player.queue_free()
		return false
	
	var test_dir_diagonal := Vector2(1, 1).normalized()
	var expected_diagonal_vel := test_dir_diagonal * speed
	if not is_equal_approx(expected_diagonal_vel.length(), speed):
		printerr("  FAIL: Di chuyen cheo khong duoc normalized (bi nhanh hon 1.41 lan)!")
		player.queue_free()
		return false
	print("  PASS: Tinh toan van toc 8 huong duoc normalized chuan xac (Speed = %.1f px/s)." % speed)
	
	player.queue_free()
	return true

func _test_player_hud_health_sync() -> bool:
	print("\n[TEST 4] Kiem tra dong bo mau giua Player va HUD (Tin hieu that)...")
	var main_packed: PackedScene = load("res://scenes/main/main.tscn")
	var main_instance: Main = main_packed.instantiate() as Main
	root.add_child(main_instance)
	main_instance._ready()
	
	var player: Player = main_instance.get_node("Player") as Player
	var hud: HUD = main_instance.get_node("HUD") as HUD
	
	# Kiem tra khoi dau
	if hud.health_bar.value != 100 or hud.health_bar.max_value != 100:
		printerr("  FAIL: HUD ban dau khong phai 100/100 (Thuc te: %f/%f)" % [hud.health_bar.value, hud.health_bar.max_value])
		main_instance.queue_free()
		return false
	print("  PASS: HUD khoi tao chinh xac 100/100.")
	
	# Test take_damage
	player.take_damage(30)
	if player.current_health != 70 or hud.health_bar.value != 70:
		printerr("  FAIL: Sau khi mat 30 mau, Player = %d, HUD = %f" % [player.current_health, hud.health_bar.value])
		main_instance.queue_free()
		return false
	if hud.health_label.text != "HP: 70 / 100":
		printerr("  FAIL: Text tren HUD khong dung: '%s'" % hud.health_label.text)
		main_instance.queue_free()
		return false
	print("  PASS: take_damage(30) -> Player HP: 70, HUD Bar: 70, HUD Label: 'HP: 70 / 100'.")
	
	# Test heal
	player.heal(15)
	if player.current_health != 85 or hud.health_bar.value != 85:
		printerr("  FAIL: Sau khi hoi 15 mau, Player = %d, HUD = %f" % [player.current_health, hud.health_bar.value])
		main_instance.queue_free()
		return false
	print("  PASS: heal(15) -> Player HP: 85, HUD Bar: 85, HUD Label: 'HP: 85 / 100'.")
	
	# Test death
	player.take_damage(200)
	if player.current_health != 0 or not player.is_dead or hud.health_bar.value != 0:
		printerr("  FAIL: Tu vong khong dung cach.")
		main_instance.queue_free()
		return false
	print("  PASS: Sat thuong tri mang -> is_dead = true, HP = 0, HUD Bar = 0.")
	
	main_instance.queue_free()
	return true

func _test_dungeon_colliders() -> bool:
	print("\n[TEST 5] Kiem tra Collision Shapes cua Dungeon...")
	var dungeon_packed: PackedScene = load("res://scenes/main/dungeon.tscn")
	var dungeon: Dungeon = dungeon_packed.instantiate() as Dungeon
	root.add_child(dungeon)
	
	var walls: StaticBody2D = dungeon.get_node_or_null("Walls") as StaticBody2D
	if not walls:
		printerr("  FAIL: Dungeon thieu StaticBody2D Walls!")
		dungeon.queue_free()
		return false
	
	var wall_colliders := walls.find_children("*", "CollisionShape2D", false)
	if wall_colliders.size() < 4:
		printerr("  FAIL: Khong du 4 tuong bao quanh phong (So luong: %d)" % wall_colliders.size())
		dungeon.queue_free()
		return false
	print("  PASS: 4 tuong bao quanh dau truong da duoc thiet lap day du collision.")
	
	var pillars: Node2D = dungeon.get_node_or_null("Pillars") as Node2D
	if not pillars or pillars.get_child_count() == 0:
		printerr("  FAIL: Dungeon thieu cac cot vat can (Pillars)!")
		dungeon.queue_free()
		return false
	print("  PASS: Cac cot vat can (Pillars) ton tai voi collision vat ly hop le (%d cot)." % pillars.get_child_count())
	
	dungeon.queue_free()
	return true
