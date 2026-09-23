extends Node2D

const SPEED = 60

var direccion = 1
var esta_muerto := false

@onready var ray_cast_derecha: RayCast2D = $RayCastDerecha
@onready var ray_cast_izquierda: RayCast2D = $RayCastIzquierda
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var zona_de_muerte: Area2D = $ZonaDeMuerte

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("enemigos")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if esta_muerto:
		return

	if ray_cast_derecha.is_colliding():
		direccion = -1
		animated_sprite.flip_h = true
	if ray_cast_izquierda.is_colliding():
		direccion = 1
		animated_sprite.flip_h = false
	position.x += direccion * SPEED * delta


# Se llama desde ZonaDeMuerte cuando el jugador lo pisa desde arriba.
func morir() -> void:
	if esta_muerto:
		return
	esta_muerto = true

	# Deja de matar al jugador y de detectar bordes.
	zona_de_muerte.set_deferred("monitoring", false)
	ray_cast_derecha.enabled = false
	ray_cast_izquierda.enabled = false

	# Animación de "aplastado": se achica en Y y se hunde un poco antes de desaparecer.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(animated_sprite, "scale:y", 0.15, 0.15)
	tween.tween_property(animated_sprite, "position:y", animated_sprite.position.y + 10, 0.15)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
