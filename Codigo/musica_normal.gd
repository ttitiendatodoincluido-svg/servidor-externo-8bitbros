extends Node

@export var musica_nivel: AudioStream

func _ready() -> void:
	Musica.cambiar_musica(musica_nivel)
