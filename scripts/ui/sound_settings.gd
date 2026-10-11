class_name SoundSettings
extends Control

var sliders: Dictionary[String, HSlider] = {}
var values: Dictionary[String, Label] = {}

func _ready() -> void:
	var names: Dictionary[String, String] = {"Master": "Tổng", "Music": "Nhạc nền", "SFX": "Hiệu ứng"}
	var row: int = 0
	for bus: String in names:
		var y: float = row * 30
		PazroTheme.label(self, names[bus], Rect2(0, y, 82, 22), 11)
		var slider: HSlider = HSlider.new()
		slider.position = Vector2(87, y + 3)
		slider.size = Vector2(164, 18)
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value_changed.connect(func(value: float) -> void:
			values[bus].text = "%d%%" % int(value)
			get_node("/root/EventBus").audio_level_requested.emit(bus, value / 100.0)
		)
		add_child(slider)
		sliders[bus] = slider
		values[bus] = PazroTheme.label(self, "", Rect2(263, y, 43, 22), 11, PazroTheme.GOLD)
		row += 1
	get_node("/root/EventBus").audio_levels_changed.connect(_sync)
	get_node("/root/EventBus").audio_settings_requested.emit()

func _sync(levels: Dictionary[String, float]) -> void:
	for bus: String in sliders:
		sliders[bus].set_value_no_signal(levels[bus] * 100)
		values[bus].text = "%d%%" % int(round(levels[bus] * 100))
