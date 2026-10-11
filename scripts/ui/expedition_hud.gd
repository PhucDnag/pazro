class_name ExpeditionHUD
extends CanvasLayer

signal pause_requested
var health: ProgressBar
var energy: ProgressBar
var hp_text: Label
var mp_text: Label
var objective: Label
var wallet: Label
var boss_bar: ProgressBar
var boss_text: Label
var weapon: Label
var abilities: Label

func _ready() -> void:
	layer = 10
	PazroTheme.panel(self, Rect2(10, 8, 197, 47))
	PazroTheme.picture(self, preload("res://data/hero_texture.tres"), Rect2(13, 13, 32, 36))
	hp_text = PazroTheme.label(self, "100 / 100", Rect2(49, 10, 145, 16), 10)
	health = _bar(Rect2(49, 28, 145, 6), Color("e45362"), 100)
	mp_text = PazroTheme.label(self, "50 / 50", Rect2(49, 34, 145, 14), 9, Color("72d7ed"))
	energy = _bar(Rect2(105, 40, 89, 4), Color("44bde3"), 50)
	objective = PazroTheme.label(self, "Chuẩn bị chiến đấu…", Rect2(220, 10, 265, 19), 12, PazroTheme.GOLD)
	wallet = PazroTheme.label(self, "VÀNG  0", Rect2(220, 31, 150, 20), 10)
	PazroTheme.button(self, "ESC  •  Dừng", Rect2(537, 13, 91, 30), func() -> void: pause_requested.emit())
	PazroTheme.panel(self, Rect2(10, 327, 620, 26))
	weapon = PazroTheme.label(self, "Q  /  Pistol", Rect2(19, 330, 155, 19), 10, PazroTheme.GOLD)
	abilities = PazroTheme.label(self, "", Rect2(175, 330, 443, 19), 10)
	boss_text = PazroTheme.label(self, "", Rect2(210, 284, 230, 16), 10, PazroTheme.GOLD)
	boss_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar = _bar(Rect2(210, 302, 230, 5), Color("d76185"), 100)
	boss_bar.hide()
	get_node("/root/EventBus").player_health_changed.connect(_health)
	get_node("/root/EventBus").player_energy_changed.connect(_energy)
	get_node("/root/EventBus").weapon_switched.connect(_weapon)
	get_node("/root/EventBus").expedition_changed.connect(_status)
	get_node("/root/EventBus").boss_health_changed.connect(_boss)
	get_node("/root/EventBus").hero_abilities_changed.connect(_abilities)
	get_node("/root/EventBus").dungeon_changed.connect(_dungeon_status)
	add_child(AdventureMap.new())
	get_node("/root/EventBus").room_cleared.connect(func(_id: String) -> void: objective.text = "Đến rương • Nhấn E nhận thưởng")

func _bar(rect: Rect2, color: Color, maximum: int) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.position = rect.position
	bar.size = rect.size
	bar.max_value = maximum
	bar.value = maximum
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", PazroTheme.box(Color("202c40")))
	var fill: StyleBoxFlat = PazroTheme.box(color, color)
	fill.set_content_margin_all(0)
	var bg: StyleBoxFlat = PazroTheme.box(Color("202c40"))
	bg.set_content_margin_all(0)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	add_child(bar)
	bar.size = rect.size
	return bar

func _health(current: int, maximum: int) -> void:
	health.max_value = maximum
	health.value = current
	hp_text.text = "SINH LỰC   %d / %d" % [current, maximum]

func _energy(current: int, maximum: int) -> void:
	energy.max_value = maximum
	energy.value = current
	mp_text.text = "%d / %d" % [current, maximum]

func _weapon(data: WeaponData) -> void:
	weapon.text = "Q  /  " + data.weapon_name

func _status(wave: int, total: int, enemies: int, gold: int) -> void:
	objective.text = "ĐỢT %d / %d    •    %d quái còn lại" % [wave, total, enemies]
	wallet.text = "VÀNG  %04d" % gold

func _boss(current: int, maximum: int, title: String) -> void:
	boss_bar.visible = current > 0
	boss_bar.max_value = maximum
	boss_bar.value = current
	boss_text.text = title if current > 0 else ""

func _abilities(dash: float, skill: float, potions: int) -> void:
	abilities.text = "SPACE  %s   |   F  %s   |   R  Bình máu ×%d   |   E  Tương tác" % ["Lướt" if dash <= 0 else "%.1fs" % dash, "Bộc phá" if skill <= 0 else "%.1fs" % skill, potions]

func _dungeon_status(floor_index: int, title: String, seals: int, gold: int, _cell: Vector2i, _map: Array[Dictionary]) -> void:
	objective.text = "TẦNG %d  •  %s" % [floor_index, title]
	objective.add_theme_font_size_override("font_size", 11)
	wallet.size.x = 235
	wallet.text = "VÀNG %d   |   ẤN %d/2   |   M Bản đồ" % [gold, seals]

