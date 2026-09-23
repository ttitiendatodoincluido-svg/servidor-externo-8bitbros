extends AudioStreamPlayer

func cambiar_musica(musica: AudioStream) -> void:
	stream = musica
	play()
