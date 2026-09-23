extends Node

@onready var sonido_revivir: AudioStreamPlayer = $SonidoRevivir

var posicion_respawn: Vector2

func _ready() -> void:
	var jugador = get_parent()
	_guardar_punto_de_control()
	jugador.revivir.connect(_revivir_jugador)
	jugador.guarda_punto_de_control.connect(_guardar_punto_de_control)

func _revivir_jugador() -> void:
	sonido_revivir.play()
	get_parent().position = posicion_respawn 
	get_parent().velocity = Vector2.ZERO

func _guardar_punto_de_control() -> void:
	posicion_respawn = get_parent().position
