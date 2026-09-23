extends Node

# Lleva la cuenta de llegadas durante una carrera multijugador.
# El servidor (host) es la autoridad: decide el orden real de
# llegada y lo reparte a todos con un RPC.
#
# Cuando la carrera tiene varios niveles seguidos (ver Red.secuencia_niveles),
# al terminar todos una etapa se pasa solos al siguiente nivel; si ya no
# queda ninguno, se corona a todos con la pantalla de victoria.

const NICKNAME_FILE := "user://nickname.save"

var en_curso := false
var llegadas: Array = []  # cada una: {id, nombre, tiempo}, en orden de llegada

signal jugador_llego(id: int, puesto: int, nombre: String, tiempo: float)
signal carrera_terminada
signal carrera_completa  # se completaron TODOS los niveles seleccionados


func iniciar_carrera() -> void:
	llegadas.clear()
	en_curso = true


func jugador_local_termino() -> void:
	if not en_curso:
		return
	var id := multiplayer.get_unique_id()
	var nombre := _leer_nickname_local()
	var tiempo := Red.tiempo_transcurrido_carrera()
	if multiplayer.is_server():
		_registrar_llegada(id, nombre, tiempo)
	else:
		_registrar_llegada.rpc_id(1, id, nombre, tiempo)


func _leer_nickname_local() -> String:
	if not FileAccess.file_exists(NICKNAME_FILE):
		return "Jugador"
	var archivo := FileAccess.open(NICKNAME_FILE, FileAccess.READ)
	if not archivo:
		return "Jugador"
	var nombre := archivo.get_as_text().strip_edges()
	archivo.close()
	return nombre if nombre != "" else "Jugador"


@rpc("any_peer", "reliable")
func _registrar_llegada(id: int, nombre: String, tiempo: float) -> void:
	if not multiplayer.is_server():
		return
	for entrada in llegadas:
		if entrada["id"] == id:
			return

	llegadas.append({"id": id, "nombre": nombre, "tiempo": tiempo})
	var puesto := llegadas.size()
	_anunciar_llegada.rpc(id, puesto, nombre, tiempo)

	var total_jugadores := Red.total_jugadores_activos()
	if llegadas.size() >= total_jugadores:
		en_curso = false
		_anunciar_fin.rpc()

		# Después de un momento (para que se alcance a ver el resultado
		# de esta etapa), se pasa a la próxima o se corona a todos.
		var temporizador := get_tree().create_timer(3.0)
		temporizador.timeout.connect(_avanzar_etapa)


func _avanzar_etapa() -> void:
	if not multiplayer.is_server():
		return

	if Red.hay_siguiente_nivel():
		var siguiente := Red.avanzar_a_siguiente_nivel()
		llegadas.clear()
		en_curso = true
		_cargar_siguiente_etapa.rpc(siguiente)
	else:
		_anunciar_carrera_completa.rpc()


@rpc("authority", "call_local", "reliable")
func _cargar_siguiente_etapa(ruta_nivel: String) -> void:
	get_tree().change_scene_to_file(ruta_nivel)


@rpc("authority", "call_local", "reliable")
func _anunciar_llegada(id: int, puesto: int, nombre: String, tiempo: float) -> void:
	jugador_llego.emit(id, puesto, nombre, tiempo)


@rpc("authority", "call_local", "reliable")
func _anunciar_fin() -> void:
	carrera_terminada.emit()


@rpc("authority", "call_local", "reliable")
func _anunciar_carrera_completa() -> void:
	carrera_completa.emit()


func reiniciar() -> void:
	en_curso = false
	llegadas.clear()
