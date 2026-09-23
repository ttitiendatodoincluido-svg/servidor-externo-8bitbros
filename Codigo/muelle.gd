extends AnimatedSprite2D

@onready var sonido_muelle: AudioStreamPlayer = $SonidoMuelle

@export var fuerza_impulso:float = 400


func _on_area_2d_body_entered(body: Node2D) -> void:
	body.aplicar_impulso_hacia_arriba(fuerza_impulso)
	play("activado")
	sonido_muelle.play()
