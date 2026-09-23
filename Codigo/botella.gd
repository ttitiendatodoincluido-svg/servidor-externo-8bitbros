extends Sprite2D

@onready var sonido_powerup: AudioStreamPlayer = $SonidoPowerup
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not is_instance_valid(body):
		return

	# Desactivar inmediatamente el área evita que el jugador active
	# el power-up varias veces antes de que termine el sonido.
	collision_shape.set_deferred("disabled", true)
	visible = false
	sonido_powerup.play()
	body.emitir_senal_efecto_correr()

func _on_sonido_powerup_finished() -> void:
	queue_free()
