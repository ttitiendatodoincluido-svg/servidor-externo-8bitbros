extends Sprite2D

@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

@export var musica_final: AudioStream
@export var musica_nivel: AudioStream

signal meta_activada(cuerpo: Node2D)

var activada := false
var _cuerpos_que_llegaron := {}

func _on_area_2d_body_entered(body: Node2D) -> void:
	if Red.activo:
		if _cuerpos_que_llegaron.has(body):
			return
		_cuerpos_que_llegaron[body] = true
		meta_activada.emit(body)
		return

	if activada:
		return

	activada = true
	collision_shape_2d.set_deferred("disabled", true)
	meta_activada.emit(body)

	if musica_final:
		Musica.cambiar_musica(musica_final)
		await Musica.finished

	# No volver a cambiar la música aquí: al cambiar de escena,
	Musica.cambiar_musica(musica_nivel)
	get_tree().change_scene_to_file("res://Escenas/portada.tscn")
