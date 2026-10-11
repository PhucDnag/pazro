class_name FrontEnd
extends CanvasLayer

signal region_selected(region: RegionData)
signal resume_requested
signal menu_requested
signal retry_requested

const REGIONS: Array[RegionData] = [preload("res://data/regions/crypt.tres"), preload("res://data/regions/frost.tres"), preload("res://data/regions/ember.tres")]
var page: Control
var selected: int = 0

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	show_home()

func _clear() -> void:
	if page:
		remove_child(page)
		page.queue_free()
	page = Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)

func _background() -> void:
	PazroTheme.picture(page, preload("res://assets/art/title_background.png"), Rect2(0, 0, 640, 360))
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.07, 0.28)
	shade.size = Vector2(640, 360)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(shade)

func show_home() -> void:
	_clear()
	_background()
	PazroTheme.label(page, "P A Z R O", Rect2(32, 44, 280, 66), 49)
	PazroTheme.label(page, "T R O   T À N   &   L I N H   H Ồ N", Rect2(36, 109, 260, 22), 10, PazroTheme.GOLD)
	PazroTheme.label(page, "Một ngọn lửa. Một hành trình.\nKhám phá những vùng đất đã bị lãng quên.", Rect2(36, 149, 295, 42), 12, Color("aebbc9"))
	var start: Button = PazroTheme.button(page, "BẮT ĐẦU HÀNH TRÌNH    →", Rect2(36, 216, 236, 37), show_regions, true)
	PazroTheme.button(page, "Cẩm nang chiến đấu", Rect2(36, 261, 236, 30), show_guide)
	PazroTheme.button(page, "Âm thanh", Rect2(36, 297, 236, 24), show_audio)
	PazroTheme.label(page, "2D ACTION RPG   /   SOLO EXPEDITION", Rect2(36, 326, 370, 18), 9, PazroTheme.MUTED)
	PazroTheme.label(page, "PAZRO  •  0.6", Rect2(545, 326, 90, 18), 9, PazroTheme.MUTED)
	start.grab_focus()

func show_regions() -> void:
	_clear()
	_background()
	PazroTheme.panel(page, Rect2(12, 12, 616, 337), Color(0.025, 0.045, 0.08, 0.96))
	PazroTheme.label(page, "CHỌN HÀNH TRÌNH", Rect2(27, 23, 410, 28), 21)
	PazroTheme.label(page, "Ba vùng đất • Ba kẻ canh giữ • Một người sống sót", Rect2(28, 53, 500, 20), 11, PazroTheme.MUTED)
	for i: int in range(REGIONS.size()):
		var region: RegionData = REGIONS[i]
		var x: float = 27 + i * 197
		var card: Panel = PazroTheme.panel(page, Rect2(x, 88, 188, 206))
		card.add_theme_stylebox_override("panel", PazroTheme.box(Color("111d2b"), region.accent if selected == i else Color("2d3d53")))
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = preload("res://assets/art/world_reference.png")
		atlas.region = region.preview
		PazroTheme.picture(page, atlas, Rect2(x + 6, 94, 176, 120))
		PazroTheme.label(page, "0%d  /  %s" % [i + 1, region.title], Rect2(x + 10, 221, 172, 22), 13, region.accent)
		PazroTheme.label(page, "2 tầng • Giải đố • Boss", Rect2(x + 10, 245, 170, 18), 10, PazroTheme.MUTED)
		PazroTheme.button(page, "Khám phá   →", Rect2(x + 9, 266, 170, 24), func() -> void:
			selected = i
			region_selected.emit(region)
		, selected == i)
	PazroTheme.button(page, "← Quay lại", Rect2(27, 310, 108, 25), show_home)
	PazroTheme.label(page, "WASD di chuyển  •  Chuột ngắm và bắn", Rect2(290, 313, 315, 18), 10, PazroTheme.MUTED)

func show_guide() -> void:
	_clear()
	_background()
	PazroTheme.panel(page, Rect2(48, 25, 544, 310), Color(0.025, 0.045, 0.08, 0.97))
	PazroTheme.label(page, "CẨM NANG CHIẾN ĐẤU", Rect2(69, 43, 450, 30), 22, PazroTheme.GOLD)
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = preload("res://assets/art/character_reference.png")
	atlas.region = Rect2(450, 53, 120, 155)
	PazroTheme.picture(page, atlas, Rect2(438, 89, 121, 155))
	PazroTheme.label(page, "WASD / Mũi tên    Di chuyển\nChuột trái                 Ngắm và bắn\nQ                                 Đổi 3 vũ khí\nSPACE                       Lướt, tránh sát thương\nF                                  Bộc phá diện rộng (18 mana)\nR                                 Uống bình máu (3 bình)\nE                                  Cửa / cơ quan / rương\nM                                 Bản đồ dungeon\nESC                            Tạm dừng", Rect2(70, 89, 375, 189), 11)
	PazroTheme.button(page, "Đã sẵn sàng   →", Rect2(70, 286, 185, 30), show_regions, true)
	PazroTheme.button(page, "Quay lại", Rect2(267, 286, 112, 30), show_home)

func show_pause() -> void:
	_audio_panel("TẠM DỪNG")
	PazroTheme.button(page, "Tiếp tục", Rect2(215, 218, 210, 32), func() -> void: resume_requested.emit(), true)
	PazroTheme.button(page, "Về chọn vùng", Rect2(215, 261, 210, 30), func() -> void: menu_requested.emit())

func show_audio() -> void:
	_audio_panel("ÂM THANH")
	PazroTheme.label(page, "0% để tắt • Tự lưu cài đặt", Rect2(203, 207, 240, 22), 11, PazroTheme.MUTED)
	PazroTheme.button(page, "Quay lại", Rect2(215, 261, 210, 30), show_home)

func _audio_panel(title: String) -> void:
	_clear()
	var shade: ColorRect = ColorRect.new()
	shade.size = Vector2(640, 360)
	shade.color = Color(0.015, 0.025, 0.055, 0.92)
	page.add_child(shade)
	PazroTheme.panel(page, Rect2(132, 34, 376, 292))
	var heading: Label = PazroTheme.label(page, title, Rect2(152, 49, 336, 35), 24, PazroTheme.GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var settings: SoundSettings = SoundSettings.new()
	settings.position = Vector2(166, 107)
	page.add_child(settings)

func show_result(victory: bool, gold: int) -> void:
	_overlay("CHIẾN THẮNG" if victory else "NGỌN LỬA CHƯA TẮT", "Vàng thu được: %d   •   %s" % [gold, "Kẻ canh giữ đã gục ngã." if victory else "Một hành trình mới đang đợi."])
	PazroTheme.button(page, "Chơi lại", Rect2(215, 179, 210, 32), func() -> void: retry_requested.emit(), true)
	PazroTheme.button(page, "Khám phá vùng khác", Rect2(215, 222, 210, 30), func() -> void: menu_requested.emit())

func _overlay(title: String, subtitle: String) -> void:
	_clear()
	var shade: ColorRect = ColorRect.new()
	shade.size = Vector2(640, 360)
	shade.color = Color(0.015, 0.025, 0.055, 0.83)
	page.add_child(shade)
	PazroTheme.panel(page, Rect2(131, 77, 378, 204))
	var heading: Label = PazroTheme.label(page, title, Rect2(145, 94, 350, 35), 24, PazroTheme.GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var description: Label = PazroTheme.label(page, subtitle, Rect2(145, 138, 350, 24), 11, PazroTheme.MUTED)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func dismiss() -> void:
	_clear()
	page.hide()

