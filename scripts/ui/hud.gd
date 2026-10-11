class_name HUD
extends CanvasLayer

## HUD: Quản lý giao diện người dùng thời gian thực (Head-Up Display) chuẩn Pazro.
## Hiển thị thanh Máu (Đỏ), thanh Năng lượng / Mana (Xanh Cyan), Vũ khí đang kích hoạt và gợi ý điều khiển.

var health_bar: ProgressBar:
	get:
		if not _health_bar:
			_health_bar = get_node_or_null("Margin/PanelContainer/VBox/HealthRow/HealthBar") as ProgressBar
		return _health_bar
var _health_bar: ProgressBar

var health_label: Label:
	get:
		if not _health_label:
			_health_label = get_node_or_null("Margin/PanelContainer/VBox/HealthRow/HealthLabel") as Label
		return _health_label
var _health_label: Label

var energy_bar: ProgressBar:
	get:
		if not _energy_bar:
			_energy_bar = get_node_or_null("Margin/PanelContainer/VBox/EnergyRow/EnergyBar") as ProgressBar
		return _energy_bar
var _energy_bar: ProgressBar

var energy_label: Label:
	get:
		if not _energy_label:
			_energy_label = get_node_or_null("Margin/PanelContainer/VBox/EnergyRow/EnergyLabel") as Label
		return _energy_label
var _energy_label: Label

var weapon_icon: TextureRect:
	get:
		if not _weapon_icon:
			_weapon_icon = get_node_or_null("Margin/PanelContainer/VBox/WeaponRow/WeaponIcon") as TextureRect
		return _weapon_icon
var _weapon_icon: TextureRect

var weapon_label: Label:
	get:
		if not _weapon_label:
			_weapon_label = get_node_or_null("Margin/PanelContainer/VBox/WeaponRow/WeaponLabel") as Label
		return _weapon_label
var _weapon_label: Label

var hint_label: Label:
	get:
		if not _hint_label:
			_hint_label = get_node_or_null("Margin/PanelContainer/VBox/HintLabel") as Label
		return _hint_label
var _hint_label: Label

var minimap: Minimap:
	get:
		if not _minimap:
			_minimap = get_node_or_null("MinimapMargin/Minimap") as Minimap
		return _minimap
var _minimap: Minimap

func _ready() -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus:
		if event_bus.has_signal("player_health_changed") and not event_bus.player_health_changed.is_connected(update_health):
			event_bus.player_health_changed.connect(update_health)
		if event_bus.has_signal("player_energy_changed") and not event_bus.player_energy_changed.is_connected(update_energy):
			event_bus.player_energy_changed.connect(update_energy)
		if event_bus.has_signal("weapon_switched") and not event_bus.weapon_switched.is_connected(update_weapon):
			event_bus.weapon_switched.connect(update_weapon)

func _get_event_bus() -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if not tree or not tree.root:
		return null
	return tree.root.get_node_or_null("EventBus")

## Kết nối trực tiếp với instance Player
func connect_to_player(player: Player) -> void:
	if not player:
		return
	
	if not player.health_changed.is_connected(update_health):
		player.health_changed.connect(update_health)
	if not player.energy_changed.is_connected(update_energy):
		player.energy_changed.connect(update_energy)
	if not player.weapon_switched.is_connected(update_weapon):
		player.weapon_switched.connect(update_weapon)
	
	update_health(player.current_health, player.max_health)
	update_energy(player.current_energy, player.max_energy)
	if not player.weapons_inventory.is_empty():
		update_weapon(player.weapons_inventory[player.current_weapon_index])

## Cập nhật giá trị thanh máu
func update_health(current_hp: int, max_hp: int) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	if health_label:
		health_label.text = "HP: %d / %d" % [current_hp, max_hp]

## Cập nhật giá trị thanh năng lượng (Mana)
func update_energy(current_en: int, max_en: int) -> void:
	if energy_bar:
		energy_bar.max_value = max_en
		energy_bar.value = current_en
	if energy_label:
		energy_label.text = "MP: %d / %d" % [current_en, max_en]

## Cập nhật thông tin vũ khí đang cầm
func update_weapon(weapon_data: WeaponData) -> void:
	if not weapon_data:
		return
	if weapon_icon and weapon_data.icon:
		weapon_icon.texture = weapon_data.icon
	if weapon_label:
		weapon_label.text = "%s [Q]" % weapon_data.weapon_name
