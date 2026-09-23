extends Node

@onready var jugador: CharacterBody2D = $".."
@onready var temporizador_efecto_correr: Timer = $TemporizadorEfectoCorrer

@export var duracion_efecto: float = 5.0
@export var material_efecto: Material

const PITCH_NORMAL: float = 1.0
@export var pitch_efecto_powerup: float = 2.0

func _ready() -> void:
	temporizador_efecto_correr.one_shot = true
	jugador.efecto_correr.connect(_on_jugador_efecto_correr)
	temporizador_efecto_correr.timeout.connect(_on_timeout)
	jugador.revivir.connect(_on_jugador_revivir)
	restaura_pitch_normal()

func _on_jugador_efecto_correr() -> void:
	if not is_instance_valid(jugador):
		return

	# Reiniciar/añadir el tiempo del efecto sin perder el tiempo restante.
	jugador.debe_correr = true
	jugador.activar_material(material_efecto)
	Musica.pitch_scale = pitch_efecto_powerup
	temporizador_efecto_correr.start(duracion_efecto + temporizador_efecto_correr.time_left)

func _on_timeout() -> void:
	if not is_instance_valid(jugador):
		return

	jugador.debe_correr = false
	jugador.activar_material(null)
	restaura_pitch_normal()

func detener_efecto_correr() -> void:
	temporizador_efecto_correr.stop()

	if is_instance_valid(jugador):
		jugador.debe_correr = false
		jugador.activar_material(null)

	restaura_pitch_normal()

func restaura_pitch_normal() -> void:
	Musica.pitch_scale = PITCH_NORMAL

func _on_jugador_revivir() -> void:
	detener_efecto_correr()
