extends Node

func _input(event):
	if event.is_action_pressed("tamano"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_vestidor_ingles_pressed() -> void:
	pass # Replace with function body.
