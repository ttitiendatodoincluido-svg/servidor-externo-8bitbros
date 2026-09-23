extends Sprite2D

@onready var sonido_punto_de_control: AudioStreamPlayer = $SonidoPuntoDeControl
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

@export var tinte_desactivado: Color = Color.WHITE

func _on_area_2d_body_entered(body: Node2D) -> void:
	sonido_punto_de_control.play()
	collision_shape_2d.set_deferred("disabled", true)
	self_modulate = tinte_desactivado
	body.guardar_punto_de_control()
