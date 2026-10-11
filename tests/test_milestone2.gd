extends SceneTree

## Script kiểm thử tự động toàn diện cho Milestone 2:
## Kiểm tra hệ thống WeaponData, Weapon, Bắn đạn Projectile, Tiêu hao năng lượng và HUD sync.

func _init() -> void:
	print("\n==================================================")
	print("  BAT DAU KIEM THU TU DONG MILESTONE 2 (PixelDungeon)")
	print("==================================================")
	
	var all_passed: bool = true
	
	all_passed = all_passed and _test_weapon_resources()
	all_passed = all_passed and _test_player_weapon_inventory_and_switching()
	all_passed = all_passed and _test_shooting_and_projectile_spawning()
	all_passed = all_passed and _test_energy_consumption_and_hud_sync()
	all_passed = all_passed and _test_projectile_wall_collision()
	
	print("==================================================")
	if all_passed:
		print("  KET QUA: TAT CA TEST CASES CUA MILESTONE 2 PASSED! (100%)")
		print("==================================================\n")
		quit(0)
	else:
		printerr("  KET QUA: CO TEST CASE THAT BAI!")
		print("==================================================\n")
		quit(1)

func _test_weapon_resources() -> bool:
	print("\n[TEST 1] Kiem tra cac Resource WeaponData (.tres)...")
	var weapons_to_check := [
		{"path": "res://data/weapons/pistol.tres", "name": "Pistol", "dmg": 12, "cost": 1, "count": 1},
		{"path": "res://data/weapons/shotgun.tres", "name": "Shotgun", "dmg": 8, "cost": 3, "count": 5},
		{"path": "res://data/weapons/plasma_blaster.tres", "name": "Plasma Blaster", "dmg": 16, "cost": 2, "count": 1}
	]
	
	for w in weapons_to_check:
		var res: WeaponData = load(w["path"]) as WeaponData
		if not res:
			printerr("  FAIL: Khong the load resource: %s" % w["path"])
			return false
		if res.weapon_name != w["name"] or res.damage != w["dmg"] or res.energy_cost != w["cost"] or res.projectile_count != w["count"]:
			printerr("  FAIL: Thong so khong khop cho: %s" % w["name"])
			return false
		if not res.icon or not res.projectile_texture:
			printerr("  FAIL: Thieu icon hoac projectile_texture cho: %s" % w["name"])
			return false
		print("  PASS: Resource hop le: %s (Dmg: %d, Cost: %d, Bullets: %d)." % [res.weapon_name, res.damage, res.energy_cost, res.projectile_count])
	return true

func _test_player_weapon_inventory_and_switching() -> bool:
	print("\n[TEST 2] Kiem tra kho vu khi va co che doi sung (Switch Weapon phim Q)...")
	var main_packed: PackedScene = load("res://scenes/main/main.tscn")
	var main_instance: Main = main_packed.instantiate() as Main
	root.add_child(main_instance)
	var player: Player = main_instance.get_node("Player") as Player
	player._ready()
	main_instance._ready()
	if not player or not player.active_weapon:
		printerr("  FAIL: Player hoac Active Weapon khong ton tai!")
		main_instance.queue_free()
		return false
	
	# Mac dinh la vu khi dau tien (Pistol)
	if player.active_weapon.weapon_data.id != "pistol":
		printerr("  FAIL: Vu khi khoi dau khong phai Pistol (Thuc te: %s)" % player.active_weapon.weapon_data.id)
		main_instance.queue_free()
		return false
	print("  PASS: Vu khi mac dinh khoi dau: Pistol.")
	
	# Doi sang Shotgun
	player.switch_weapon()
	if player.active_weapon.weapon_data.id != "shotgun":
		printerr("  FAIL: Doi sung lan 1 khong ra Shotgun (Thuc te: %s)" % player.active_weapon.weapon_data.id)
		main_instance.queue_free()
		return false
	print("  PASS: switch_weapon() -> Chuyen sang Shotgun thanh cong.")
	
	# Doi sang Plasma Blaster
	player.switch_weapon()
	if player.active_weapon.weapon_data.id != "plasma_blaster":
		printerr("  FAIL: Doi sung lan 2 khong ra Plasma Blaster (Thuc te: %s)" % player.active_weapon.weapon_data.id)
		main_instance.queue_free()
		return false
	print("  PASS: switch_weapon() -> Chuyen sang Plasma Blaster thanh cong.")
	
	# Vong lai Pistol
	player.switch_weapon()
	if player.active_weapon.weapon_data.id != "pistol":
		printerr("  FAIL: Vong lap doi sung khong tro ve Pistol")
		main_instance.queue_free()
		return false
	print("  PASS: switch_weapon() -> Quay vong ve lai Pistol thanh cong.")
	
	main_instance.queue_free()
	return true

func _test_shooting_and_projectile_spawning() -> bool:
	print("\n[TEST 3] Kiem tra co che ban sung va sinh dan (Projectiles)...")
	var main_packed: PackedScene = load("res://scenes/main/main.tscn")
	var main_instance: Main = main_packed.instantiate() as Main
	root.add_child(main_instance)
	var player: Player = main_instance.get_node("Player") as Player
	player._ready()
	main_instance._ready()
	var proj_container: Node2D = main_instance.get_node("Projectiles") as Node2D
	
	# Ban phat dau voi Pistol
	var initial_bullet_count: int = proj_container.get_child_count()
	var shot_success: bool = player.try_shoot()
	if not shot_success:
		printerr("  FAIL: try_shoot() that bai!")
		main_instance.queue_free()
		return false
	
	var new_bullet_count: int = proj_container.get_child_count()
	if new_bullet_count != initial_bullet_count + 1:
		printerr("  FAIL: Dan khong duoc them vao Projectiles container!")
		main_instance.queue_free()
		return false
	
	var bullet: Projectile = proj_container.get_child(initial_bullet_count) as Projectile
	if bullet.damage != 12 or bullet.speed != 450.0:
		printerr("  FAIL: Thong so vien dan Pistol khong dung (Dmg: %d, Spd: %f)" % [bullet.damage, bullet.speed])
		main_instance.queue_free()
		return false
	print("  PASS: Ban Pistol tao 1 vien dan bay hop le (Damage: 12, Speed: 450).")
	
	# Kiem tra cooldown: ban ngay lap tuc phai tra ve false
	var immediate_shot: bool = player.try_shoot()
	if immediate_shot:
		printerr("  FAIL: Ban ngay lap tuc khong bi chan boi cooldown!")
		main_instance.queue_free()
		return false
	print("  PASS: Cooldown ngan ban lien tiep thanh cong.")
	
	# Test Shotgun ban chum 5 vien
	player.switch_weapon() # Chuyen sang Shotgun
	player.active_weapon._cooldown_remaining = 0.0 # Reset cooldown cho test
	var count_before_shotgun: int = proj_container.get_child_count()
	var shotgun_shot: bool = player.try_shoot()
	if not shotgun_shot:
		printerr("  FAIL: Ban Shotgun that bai!")
		main_instance.queue_free()
		return false
	
	var count_after_shotgun: int = proj_container.get_child_count()
	if count_after_shotgun != count_before_shotgun + 5:
		printerr("  FAIL: Shotgun khong sinh dung 5 vien dan (Sinh: %d)" % (count_after_shotgun - count_before_shotgun))
		main_instance.queue_free()
		return false
	print("  PASS: Ban Shotgun sinh chinh xac chum 5 vien dan toa ra.")
	
	main_instance.queue_free()
	return true

func _test_energy_consumption_and_hud_sync() -> bool:
	print("\n[TEST 4] Kiem tra tieu hao Mana va dong bo HUD Energy...")
	var main_packed: PackedScene = load("res://scenes/main/main.tscn")
	var main_instance: Main = main_packed.instantiate() as Main
	root.add_child(main_instance)
	var player: Player = main_instance.get_node("Player") as Player
	var hud: HUD = main_instance.get_node("HUD") as HUD
	player._ready()
	hud._ready()
	main_instance._ready()
	
	if hud.energy_bar.value != 50 or hud.energy_label.text != "MP: 50 / 50":
		printerr("  FAIL: HUD Energy ban dau khong phai 50/50")
		main_instance.queue_free()
		return false
	print("  PASS: HUD Energy ban dau khoi tao chinh xac: 50 / 50.")
	
	# Ban Pistol tieu hao 1 energy
	player.try_shoot()
	if player.current_energy != 49 or hud.energy_bar.value != 49:
		printerr("  FAIL: Sau khi ban Pistol, Energy = %d, HUD = %f" % [player.current_energy, hud.energy_bar.value])
		main_instance.queue_free()
		return false
	print("  PASS: Ban Pistol -> Energy giam 1 (Player: 49, HUD: 49).")
	
	# Chuyen sang Shotgun (ton 3 energy)
	player.switch_weapon()
	player.active_weapon._cooldown_remaining = 0.0
	player.try_shoot()
	if player.current_energy != 46 or hud.energy_bar.value != 46:
		printerr("  FAIL: Sau khi ban Shotgun, Energy = %d, HUD = %f" % [player.current_energy, hud.energy_bar.value])
		main_instance.queue_free()
		return false
	print("  PASS: Ban Shotgun -> Energy giam 3 (Player: 46, HUD: 46).")
	
	# Kiem tra HUD cap nhat ten va icon vu khi
	if not hud.weapon_label.text.begins_with("Shotgun"):
		printerr("  FAIL: HUD chua cap nhat ten vu khi sang Shotgun: '%s'" % hud.weapon_label.text)
		main_instance.queue_free()
		return false
	print("  PASS: HUD Weapon Label cap nhat chinh xac sang '%s'." % hud.weapon_label.text)
	
	main_instance.queue_free()
	return true

func _test_projectile_wall_collision() -> bool:
	print("\n[TEST 5] Kiem tra va cham dan va tuong (Projectile Wall Collision)...")
	var bullet_packed: PackedScene = load("res://scenes/projectiles/bullet.tscn")
	var bullet: Projectile = bullet_packed.instantiate() as Projectile
	root.add_child(bullet)
	
	var wall := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	col.shape = shape
	wall.add_child(col)
	root.add_child(wall)
	
	# Gia lap dan va cham tuong
	bullet._on_body_entered(wall)
	if not bullet.is_queued_for_deletion():
		printerr("  FAIL: Dan khong duoc queue_free() khi dam vao StaticBody2D tuong!")
		bullet.queue_free()
		wall.queue_free()
		return false
	print("  PASS: Dan va cham tuong StaticBody2D va tu dong huy hop le (Queue Free).")
	
	wall.queue_free()
	return true
