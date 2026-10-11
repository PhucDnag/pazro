class_name PazroTheme
extends RefCounted

const INK: Color = Color("0a1120")
const GOLD: Color = Color("e4b66c")
const MUTED: Color = Color("8295ad")
const WHITE: Color = Color("e9edf4")

static func box(color: Color, border: Color = Color("2d3d53")) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	return style

static func label(parent: Node, text: String, rect: Rect2, font_size: int = 12, color: Color = WHITE) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
	var node: Button = Button.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", 12)
	node.add_theme_stylebox_override("normal", box(Color("563029") if primary else INK, GOLD if primary else Color("34475e")))
	node.add_theme_stylebox_override("hover", box(Color("344358"), GOLD))
	node.add_theme_stylebox_override("pressed", box(Color("6a4935"), GOLD))
	node.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), GOLD))
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style: StyleBoxFlat = node.get_theme_stylebox(state) as StyleBoxFlat
		style.content_margin_top = 3
		style.content_margin_bottom = 3
	node.pressed.connect(action)
	node.button_down.connect(func() -> void: GameAudio.cue(node, "ui"))
	parent.add_child(node)
	node.size = rect.size
	return node

static func picture(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var node: TextureRect = TextureRect.new()
	node.texture = texture
	node.position = rect.position
	node.size = rect.size
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.size = rect.size
	return node

static func panel(parent: Node, rect: Rect2, color: Color = INK) -> Panel:
	var node: Panel = Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", box(color))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node
