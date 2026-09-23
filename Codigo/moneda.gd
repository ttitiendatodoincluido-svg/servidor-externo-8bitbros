extends Area2D

@onready var game_manager: Node = %GameManager
@onready var sonido_moneda: AudioStreamPlayer = $SonidoMoneda
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var autodestruir : bool = true
signal reproducir_animacion_destruccion(body: Node2D)

func _on_body_entered(_body: Node2D) -> void:
	game_manager.incrementa_un_punto()
	Guardado.agregar_monedas(1)
	sonido_moneda.play()
	collision_shape.call_deferred("set", "disabled", "true")
	if autodestruir:
		animated_sprite.visible = false
		sonido_moneda.finished.connect(_on_finished)
	else:
		reproducir_animacion_destruccion.emit()
	
func _on_finished () -> void:
	queue_free()
