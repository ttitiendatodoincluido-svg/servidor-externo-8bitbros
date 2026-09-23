extends Node

# Se coloca en un nivel jugable para habilitar el modo Carrera.
# Si no hay una partida de Red activa, no hace nada y el nivel
# funciona exactamente igual que en un jugador.

const JUGADOR_ESCENA := preload("res://Escenas/jugador.tscn")
const SEPARACION_SPAWN := 24.0

@onready var spawner: MultiplayerSpawner = get_parent().get_node("MultiplayerSpawner")

var _proximo_indice := 0
var _posicion_base := Vector2.ZERO


func _ready() -> void:
	print("GESTOR _ready — Red.activo=", Red.activo, " es_server=", multiplayer.is_server(), " peer=", multiplayer.multiplayer_peer)
	if not Red.activo:
		return  # Modo un jugador: el "Jugador" del nivel se usa tal cual.

	var jugador_estatico: Node2D = get_parent().get_node_or_null("Jugador")
	if jugador_estatico:
		_posicion_base = jugador_estatico.position
		var camara_vieja := jugador_estatico.get_node_or_null("Camera2D")
		if camara_vieja:
			camara_vieja.enabled = false
		jugador_estatico.queue_free()

	spawner.spawn_function = _construir_jugador

	if multiplayer.is_server():
		Carrera.iniciar_carrera()
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

		call_deferred("_spawn_jugadores_iniciales")


func _spawn_jugadores_iniciales() -> void:
	if not Red.es_servidor_dedicado:
		_spawn_jugador(1)  # el propio host también juega (solo en modo LAN/directo)
	for id in multiplayer.get_peers():
		_spawn_jugador(id)


func _on_peer_connected(id: int) -> void:
	_spawn_jugador(id)


func _on_peer_disconnected(id: int) -> void:
	var nodo := get_parent().get_node_or_null(str(id))
	if nodo:
		nodo.queue_free()


func _spawn_jugador(id: int) -> void:
	var datos := {
		"id": id,
		"posicion_x": _posicion_base.x + _proximo_indice * SEPARACION_SPAWN,
		"posicion_y": _posicion_base.y,
	}
	_proximo_indice += 1
	spawner.spawn(datos)


# Se ejecuta en TODOS los pares (host y clientes) para construir la
# misma escena de forma consistente cuando el host llama a spawn().
func _construir_jugador(datos: Dictionary) -> Node:
	var nuevo := JUGADOR_ESCENA.instantiate()
	nuevo.name = str(datos["id"])
	nuevo.position = Vector2(datos["posicion_x"], datos["posicion_y"])

	var camara := Camera2D.new()
	camara.position = Vector2(1, -6)
	camara.zoom = Vector2(4, 4)
	camara.limit_bottom = 120
	camara.position_smoothing_enabled = true
	camara.limit_smoothed = true
	camara.enabled = (datos["id"] == multiplayer.get_unique_id())
	nuevo.add_child(camara)

	return nuevo
