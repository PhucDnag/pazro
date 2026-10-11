extends Node2D

var chamber: AdventureChamber

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if is_instance_valid(chamber):
		chamber.draw_foreground(self)
