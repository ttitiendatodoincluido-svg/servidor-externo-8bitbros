class_name InputManager

static var input_enabled := true

static func is_action_just_pressed(accion: String) -> bool:
	return input_enabled and Input.is_action_just_pressed(accion)
static func is_action_pressed(accion: String) -> bool:
	return Input.is_action_pressed(accion) if input_enabled else false

static func get_axis(accion_negativa: String, accion_positiva: String) -> float:
	return Input.get_axis(accion_negativa, accion_positiva) if input_enabled else 0.0
