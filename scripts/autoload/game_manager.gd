extends Node

## GameManager: Quản lý vòng đời trò chơi và trạng thái chung.

enum State {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY
}

var current_state: State = State.PLAYING

func _ready() -> void:
	_ensure_input_mappings()

func set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	EventBus.game_state_changed.emit(State.keys()[new_state])

## Đảm bảo các phím điều khiển luôn tồn tại trong InputMap kể cả khi chưa cấu hình trong editor
func _ensure_input_mappings() -> void:
	_register_key_action("move_left", KEY_A, KEY_LEFT)
	_register_key_action("move_right", KEY_D, KEY_RIGHT)
	_register_key_action("move_up", KEY_W, KEY_UP)
	_register_key_action("move_down", KEY_S, KEY_DOWN)
	_register_key_action("interact", KEY_E)
	_register_key_action("switch_weapon", KEY_Q)
	_register_key_action("dash", KEY_SPACE)
	_register_key_action("skill", KEY_F)
	_register_key_action("potion", KEY_R)
	_register_key_action("show_map", KEY_M)
	_register_mouse_action("attack", MOUSE_BUTTON_LEFT)

func _register_key_action(action_name: StringName, primary_key: Key, secondary_key: Key = KEY_NONE) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var ev1 := InputEventKey.new()
		ev1.physical_keycode = primary_key
		InputMap.action_add_event(action_name, ev1)
		
		if secondary_key != KEY_NONE:
			var ev2 := InputEventKey.new()
			ev2.physical_keycode = secondary_key
			InputMap.action_add_event(action_name, ev2)

func _register_mouse_action(action_name: StringName, mouse_button: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var ev := InputEventMouseButton.new()
		ev.button_index = mouse_button
		InputMap.action_add_event(action_name, ev)
