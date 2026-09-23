extends Node

@onready var moneda: Area2D = $".."
@onready var animated_sprite: AnimatedSprite2D = $"../AnimatedSprite2D"

@export var distancia_a_recorrer: float = 20
@export var duracion_animacion : float = 0.5

func _ready() -> void:
	moneda.reproducir_animacion_destruccion.connect(_on_reproducir_animacion_destruccion)
	moneda.autodestruir = false

func _on_reproducir_animacion_destruccion() -> void:
	var tween = get_tree().create_tween().bind_node(moneda).set_parallel(true)
	tween.tween_property(moneda, "position", moneda.position + Vector2.UP * distancia_a_recorrer, duracion_animacion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(animated_sprite, "self_modulate", Color(Color.WHITE, 0), duracion_animacion)
	await tween.finished
	moneda.queue_free()
