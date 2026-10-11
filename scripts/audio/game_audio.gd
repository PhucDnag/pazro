class_name GameAudio
extends RefCounted

static func cue(source: Node, id: String) -> void:
	if not source.is_inside_tree():
		return
	var bus: Node = source.get_node_or_null("/root/EventBus")
	if bus:
		bus.sound_requested.emit(id)
