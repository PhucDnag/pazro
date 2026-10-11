extends SceneTree

## Script kiểm thử tự động toàn diện cho Milestone 3:
## Kiểm tra hệ thống Kẻ thù, EnemyData, Health/Hurtbox/Hitbox Component, Nhận sát thương, Knockback và Đạn tiêu diệt quái.

func _init() -> void:
	print("\n==================================================")
	print("  BAT DAU KIEM THU TU DONG MILESTONE 3 (PixelDungeon)")
	print("==================================================")
	
	var all_passed: bool = true
	
	all_passed = all_passed and _test_enemy_data_resources()
	all_passed = all_passed and _test_combat_components()
	all_passed = all_passed and _test_enemy_damage_and_knockback()
	all_passed = all_passed and _test_projectile_hitting_enemy()
	all_passed = all_passed and _test_enemy_death_lifecycle()
	all_passed = all_passed and _test_floating_damage_text()
	
	print("==================================================")
	if all_passed:
		print("  KET QUA: TAT CA TEST CASES CUA MILESTONE 3 PASSED! (100%)")
		print("==================================================\n")
		quit(0)
	else:
		printerr("  KET QUA: CO TEST CASE THAT BAI!")
		print("==================================================\n")
		quit(1)

func _test_enemy_data_resources() -> bool:
	print("\n[TEST 1] Kiem tra cac Resource EnemyData (.tres)...")
	var enemies := [
		{"path": "res://data/enemies/goblin.tres", "name": "Goblin", "hp": 30, "spd": 100.0, "dmg": 8, "ranged": false},
		{"path": "res://data/enemies/skeleton.tres", "name": "Skeletor", "hp": 55, "spd": 75.0, "dmg": 14, "ranged": false},
		{"path": "res://data/enemies/mage.tres", "name": "Mage", "hp": 40, "spd": 60.0, "dmg": 6, "ranged": true}
	]
	
	for e in enemies:
		var data: EnemyData = load(e["path"]) as EnemyData
		if not data:
			printerr("  FAIL: Khong the load: %s" % e["path"])
			return false
		if data.enemy_name != e["name"] or data.max_health != e["hp"] or data.contact_damage != e["dmg"] or data.is_ranged != e["ranged"]:
			printerr("  FAIL: Thong so khong khop cho: %s" % e["name"])
			return false
		if not data.sprite_texture:
			printerr("  FAIL: Thieu sprite_texture cho: %s" % e["name"])
			return false
		if data.is_ranged and not data.ranged_projectile_scene:
			printerr("  FAIL: Quai danh xa thieu ranged_projectile_scene cho: %s" % e["name"])
			return false
		print("  PASS: Resource hop le: %s (HP: %d, Speed: %.1f, Damage: %d, Ranged: %s)." % [data.enemy_name, data.max_health, data.speed, data.contact_damage, data.is_ranged])
	return true

func _test_combat_components() -> bool:
	print("\n[TEST 2] Kiem tra HealthComponent & HurtboxComponent...")
	var health_comp := HealthComponent.new()
	health_comp.initialize(50)
	
	var result := {"called": false, "dmg": 0}
	health_comp.damage_received.connect(func(amt: int, _dir: Vector2):
		result["called"] = true
		result["dmg"] = amt
	)
	
	health_comp.take_damage(20, Vector2.RIGHT)
	if not result["called"] or result["dmg"] != 20 or health_comp.current_health != 30:
		printerr("  FAIL: HealthComponent take_damage(20) khong dung!")
		health_comp.queue_free()
		return false
	print("  PASS: HealthComponent: 50 HP - 20 = 30 HP, phat tin hieu damage_received thanh cong.")
	
	health_comp.heal(10)
	if health_comp.current_health != 40:
		printerr("  FAIL: HealthComponent heal(10) khong dung!")
		health_comp.queue_free()
		return false
	print("  PASS: HealthComponent: 30 HP + 10 = 40 HP.")
	
	health_comp.queue_free()
	return true

func _test_enemy_damage_and_knockback() -> bool:
	print("\n[TEST 3] Kiem tra Enemy nhan sat thuong va giat lui (Knockback)...")
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy.tscn")
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	root.add_child(enemy)
	enemy._ready()
	
	var initial_hp: int = enemy.current_health
	var knockback_dir := Vector2(1, 0)
	enemy.take_damage(12, knockback_dir)
	
	if enemy.current_health != initial_hp - 12:
		printerr("  FAIL: Enemy take_damage(12) khong tru mau dung (HP: %d, Ky vong: %d)" % [enemy.current_health, initial_hp - 12])
		enemy.queue_free()
		return false
	print("  PASS: Enemy Goblin nhan 12 sat thuong -> Con lai %d HP." % enemy.current_health)
	
	if enemy._knockback_velocity.x <= 0.0:
		printerr("  FAIL: Knockback velocity khong duoc day theo huong danh!")
		enemy.queue_free()
		return false
	print("  PASS: Knockback velocity duoc ap dung hop le: ", enemy._knockback_velocity)
	
	enemy.queue_free()
	return true

func _test_projectile_hitting_enemy() -> bool:
	print("\n[TEST 4] Kiem tra dan Player ban trung Hurtbox cua Enemy...")
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy.tscn")
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	root.add_child(enemy)
	enemy._ready()
	
	var bullet_scene: PackedScene = load("res://scenes/projectiles/bullet.tscn")
	var bullet: Projectile = bullet_scene.instantiate() as Projectile
	root.add_child(bullet)
	bullet.setup(Vector2.RIGHT, 400.0, 15, 2.0, null, Vector2.ONE, true)
	
	var hp_before: int = enemy.current_health
	# Dan va cham truc tiep voi HurtboxComponent cua Enemy
	bullet._on_area_entered(enemy.hurtbox_component)
	
	if enemy.current_health != hp_before - 15:
		printerr("  FAIL: Dan Player khong gay sat thuong qua HurtboxComponent (HP: %d, Ky vong: %d)" % [enemy.current_health, hp_before - 15])
		enemy.queue_free()
		bullet.queue_free()
		return false
	print("  PASS: Dan ban trung Hurtbox -> Enemy bi tru dung 15 HP.")
	
	if not bullet.is_queued_for_deletion():
		printerr("  FAIL: Dan khong tu huy khi ban trung Enemy!")
		enemy.queue_free()
		bullet.queue_free()
		return false
	print("  PASS: Dan tu dong huy hop le (Queue Free) sau khi ban trung muc tieu.")
	
	enemy.queue_free()
	return true

func _test_enemy_death_lifecycle() -> bool:
	print("\n[TEST 5] Kiem tra vong doi tu vong cua Enemy khi het mau...")
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy.tscn")
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	root.add_child(enemy)
	enemy._ready()
	
	var death_result := {"fired": false, "score": 0}
	enemy.defeated.connect(func(score: int):
		death_result["fired"] = true
		death_result["score"] = score
	)
	
	# Gay sat thuong tri mang
	enemy.take_damage(100)
	
	if not enemy.is_dead:
		printerr("  FAIL: is_dead khong bang true sau sat thuong tri mang!")
		enemy.queue_free()
		return false
	print("  PASS: Enemy is_dead = true.")
	
	if not death_result["fired"] or death_result["score"] <= 0:
		printerr("  FAIL: defeated signal khong phat kem diem thuong!")
		enemy.queue_free()
		return false
	print("  PASS: defeated signal phat thanh cong voi diem thuong: %d diem." % death_result["score"])
	
	enemy.queue_free()
	return true

func _test_floating_damage_text() -> bool:
	print("\n[TEST 6] Kiem tra so sat thuong noi (Floating Damage Text)...")
	var float_scene: PackedScene = load("res://scenes/ui/floating_text.tscn")
	var float_node: FloatingText = float_scene.instantiate() as FloatingText
	root.add_child(float_node)
	float_node.setup(24, true, false)
	
	if float_node.label.text != "24":
		printerr("  FAIL: FloatingText hien thi text sai: '%s'" % float_node.label.text)
		float_node.queue_free()
		return false
	print("  PASS: FloatingText khoi tao dung chuoi sat thuong: '%s'." % float_node.label.text)
	
	float_node.queue_free()
	return true
