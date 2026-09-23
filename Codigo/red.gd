extends Node

# ============================================================
#  Red — maneja las partidas multijugador (modo Carrera).
#
#  IMPORTANTE: esto es conexión DIRECTA por IP. El "código de
#  sala" (ej: "EJ250") es una contraseña de sala, NO reemplaza
#  la IP: quien se une necesita la IP pública del host, y el
#  host normalmente necesita abrir ("port forward") el puerto
#  en su router para que gente fuera de su red local lo pueda
#  encontrar. Dentro de la misma red local (WiFi/router), en
#  cambio, la sala se descubre sola (ver _iniciar_difusion_sala /
#  iniciar_busqueda_lan) y no hace falta escribir la IP.
# ============================================================

const PUERTO_DEFECTO := 8910
const PUERTO_DESCUBRIMIENTO := 8911
const TIEMPO_ESPERA_CONEXION := 8.0
const MAXIMO_JUGADORES_POSIBLE := 10

var activo := false          # true cuando hay una partida multijugador en curso
var es_host := false
var codigo_sala := ""
var maximo_jugadores := 4

signal conexion_exitosa
signal error_de_conexion(mensaje: String)
signal jugador_conectado(id: int)
signal jugador_desconectado(id: int)
signal salas_actualizadas

# ---------- Servidor externo (Internet, vía Render u otro hosting) ----------
# Todo esto es ADICIONAL al sistema de red local/directa de arriba, que
# sigue funcionando exactamente igual. Este modo conecta a un servidor
# dedicado propio (ver /servidor_externo en la raíz del proyecto) que
# está siempre encendido y tiene una dirección pública fija, así que
# no hace falta IP, ni código de sala como contraseña de verdad, ni
# abrir puertos en ningún router: cualquiera con la dirección del
# servidor se puede conectar desde cualquier red.
signal conteo_sala_externa_actualizado(conteo: int, maximo: int)

var modo_externo := false       # true en el CLIENTE cuando está usando el servidor externo
var es_creador_externo := false # true si este cliente fue quien creó la sala externa
var es_servidor_dedicado := false  # true SOLO en el proceso que corre como servidor dedicado

var _max_jugadores_externo_solicitados := 4
var _sala_externa_activa := false   # (uso del servidor dedicado)
var _creador_id_externa := -1       # (uso del servidor dedicado)

var salas_encontradas := {}  # codigo -> {ip, puerto, jugadores, maximo}

# Secuencia de niveles de la carrera actual. Una carrera de un solo
# mapa es, simplemente, una secuencia de un elemento.
var secuencia_niveles: PackedStringArray = []
var indice_nivel_actual := 0

func iniciar_secuencia_de_niveles(niveles: PackedStringArray) -> void:
	secuencia_niveles = niveles
	indice_nivel_actual = 0

var tiempo_inicio_carrera_ms := 0

func iniciar_cronometro_carrera() -> void:
	tiempo_inicio_carrera_ms = Time.get_ticks_msec()

func tiempo_transcurrido_carrera() -> float:
	if tiempo_inicio_carrera_ms == 0:
		return 0.0
	return (Time.get_ticks_msec() - tiempo_inicio_carrera_ms) / 1000.0

func nivel_actual() -> String:
	if indice_nivel_actual < secuencia_niveles.size():
		return secuencia_niveles[indice_nivel_actual]
	return ""

func hay_siguiente_nivel() -> bool:
	return indice_nivel_actual + 1 < secuencia_niveles.size()

func avanzar_a_siguiente_nivel() -> String:
	indice_nivel_actual += 1
	return nivel_actual()

var _codigo_ingresado := ""
var _puerto_actual := PUERTO_DEFECTO
var _temporizador_conexion: SceneTreeTimer
var _temporizador_difusion: Timer
var _socket_difusion: PacketPeerUDP
var _socket_escucha: PacketPeerUDP


func _ready() -> void:
	# Cuando este mismo proyecto se exporta con el preset "Linux Servidor"
	# (dedicated_server=true, ver export_presets.cfg y /servidor_externo),
	# Godot activa el feature tag "dedicated_server" automáticamente. Eso
	# es lo que distingue, en el mismo código, si este proceso es el
	# juego normal de un jugador o el servidor externo alojado en Render.
	if OS.has_feature("dedicated_server"):
		_iniciar_como_servidor_dedicado()


# ---------- Crear sala (host) ----------
func alojar_partida(puerto: int, max_jugadores: int) -> void:
	_limpiar()

	var peer := ENetMultiplayerPeer.new()
	var resultado := peer.create_server(puerto, max_jugadores)
	if resultado != OK:
		error_de_conexion.emit("No se pudo abrir el puerto %d. Prueba con otro puerto." % puerto)
		return

	multiplayer.multiplayer_peer = peer
	_puerto_actual = puerto
	maximo_jugadores = clampi(max_jugadores, 2, MAXIMO_JUGADORES_POSIBLE)
	codigo_sala = _generar_codigo()
	es_host = true
	activo = true

	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	_intentar_abrir_puerto_upnp(puerto)
	_solicitar_ip_publica()
	_iniciar_difusion_sala()
	conexion_exitosa.emit()


# ---------- Unirse a sala (cliente) ----------
func unirse_partida(ip: String, puerto: int, codigo: String) -> void:
	_limpiar()

	if ip.strip_edges().is_empty():
		error_de_conexion.emit("Ingresa una dirección IP válida.")
		return
	if codigo.strip_edges().is_empty():
		error_de_conexion.emit("Ingresa el código de la sala.")
		return

	var peer := ENetMultiplayerPeer.new()
	var resultado := peer.create_client(ip.strip_edges(), puerto)
	if resultado != OK:
		error_de_conexion.emit("No se pudo iniciar la conexión. Revisá la IP y el puerto.")
		return

	multiplayer.multiplayer_peer = peer
	_codigo_ingresado = codigo.strip_edges().to_upper()
	_puerto_actual = puerto
	es_host = false

	multiplayer.connected_to_server.connect(_on_conectado_al_servidor)
	multiplayer.connection_failed.connect(_on_fallo_conexion)
	multiplayer.server_disconnected.connect(_on_servidor_desconectado)

	_temporizador_conexion = get_tree().create_timer(TIEMPO_ESPERA_CONEXION)
	_temporizador_conexion.timeout.connect(_on_tiempo_de_espera_agotado)


func unirse_a_sala_encontrada(codigo: String) -> void:
	if not salas_encontradas.has(codigo):
		return
	var datos: Dictionary = salas_encontradas[codigo]
	unirse_partida(datos["ip"], datos["puerto"], codigo)


# ---------- Handshake de validación de código ----------
@rpc("any_peer", "reliable")
func _solicitar_ingreso(codigo_ingresado: String) -> void:
	if not multiplayer.is_server():
		return

	var id := multiplayer.get_remote_sender_id()

	if codigo_ingresado != codigo_sala:
		_respuesta_ingreso.rpc_id(id, false, "Código de sala incorrecto.")
		_rechazar_luego(id)
		return

	if multiplayer.get_peers().size() + 1 > maximo_jugadores:
		_respuesta_ingreso.rpc_id(id, false, "La sala ya está llena.")
		_rechazar_luego(id)
		return

	_respuesta_ingreso.rpc_id(id, true, "")
	jugador_conectado.emit(id)


func _rechazar_luego(id: int) -> void:
	var temporizador := get_tree().create_timer(0.3)
	temporizador.timeout.connect(func():
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer.disconnect_peer(id)
	)


@rpc("authority", "reliable")
func _respuesta_ingreso(aceptado: bool, motivo: String) -> void:
	_temporizador_conexion = null
	if aceptado:
		activo = true
		conexion_exitosa.emit()
	else:
		error_de_conexion.emit(motivo)
		_limpiar()


func _on_conectado_al_servidor() -> void:
	_solicitar_ingreso.rpc_id(1, _codigo_ingresado)


func _on_fallo_conexion() -> void:
	_temporizador_conexion = null
	_limpiar()
	error_de_conexion.emit("No se pudo conectar. Revisá tu conexión a internet, la IP y el puerto.")


func _on_servidor_desconectado() -> void:
	_limpiar()
	error_de_conexion.emit("Se perdió la conexión con el organizador.")


func _on_tiempo_de_espera_agotado() -> void:
	if not activo:
		_limpiar()
		error_de_conexion.emit("Tiempo de espera agotado. Revisá tu conexión a internet.")


func _on_peer_disconnected(id: int) -> void:
	jugador_desconectado.emit(id)

	if es_servidor_dedicado and _sala_externa_activa:
		if id == _creador_id_externa or multiplayer.get_peers().size() == 0:
			# Se fue quien creó la sala, o ya no queda nadie: se cierra
			# la sala para que el servidor quede libre para la próxima.
			_sala_externa_activa = false
			_creador_id_externa = -1
			codigo_sala = ""
			maximo_jugadores = 4
		elif _creador_id_externa != -1:
			_actualizar_conteo_sala_externa.rpc_id(_creador_id_externa, multiplayer.get_peers().size(), maximo_jugadores)


# ---------- Salir / limpieza ----------
func salir_de_partida() -> void:
	_limpiar()


func _limpiar() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

	activo = false
	es_host = false
	modo_externo = false
	es_creador_externo = false
	codigo_sala = ""
	secuencia_niveles = []
	indice_nivel_actual = 0
	tiempo_inicio_carrera_ms = 0

	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
	if multiplayer.connected_to_server.is_connected(_on_conectado_al_servidor):
		multiplayer.connected_to_server.disconnect(_on_conectado_al_servidor)
	if multiplayer.connection_failed.is_connected(_on_fallo_conexion):
		multiplayer.connection_failed.disconnect(_on_fallo_conexion)
	if multiplayer.server_disconnected.is_connected(_on_servidor_desconectado):
		multiplayer.server_disconnected.disconnect(_on_servidor_desconectado)

	_detener_difusion_sala()
	detener_busqueda_lan()


# ---------- Descubrimiento en la red local (LAN) ----------
# El host anuncia su sala por difusión UDP cada 1 segundo. Cualquiera
# que tenga la pantalla de "unirse" abierta en la MISMA red local la
# ve aparecer sola en la lista, sin escribir la IP.

func _iniciar_difusion_sala() -> void:
	_socket_difusion = PacketPeerUDP.new()
	_socket_difusion.set_broadcast_enabled(true)

	_temporizador_difusion = Timer.new()
	_temporizador_difusion.wait_time = 1.0
	_temporizador_difusion.timeout.connect(_emitir_anuncio_sala)
	add_child(_temporizador_difusion)
	_temporizador_difusion.start()
	_emitir_anuncio_sala()


func _emitir_anuncio_sala() -> void:
	if not _socket_difusion:
		return
	var datos := {
		"codigo": codigo_sala,
		"puerto": _puerto_actual,
		"jugadores": multiplayer.get_peers().size() + 1,
		"maximo": maximo_jugadores,
	}
	_socket_difusion.set_dest_address("255.255.255.255", PUERTO_DESCUBRIMIENTO)
	_socket_difusion.put_packet(JSON.stringify(datos).to_utf8_buffer())


func _detener_difusion_sala() -> void:
	if _temporizador_difusion:
		_temporizador_difusion.stop()
		_temporizador_difusion.queue_free()
		_temporizador_difusion = null
	if _socket_difusion:
		_socket_difusion.close()
		_socket_difusion = null


func iniciar_busqueda_lan() -> void:
	if _socket_escucha:
		return
	_socket_escucha = PacketPeerUDP.new()
	if _socket_escucha.bind(PUERTO_DESCUBRIMIENTO) != OK:
		_socket_escucha = null
		return
	salas_encontradas.clear()


func detener_busqueda_lan() -> void:
	if _socket_escucha:
		_socket_escucha.close()
		_socket_escucha = null


func _process(_delta: float) -> void:
	if not _socket_escucha:
		return

	var hubo_novedades := false
	while _socket_escucha.get_available_packet_count() > 0:
		var ip := _socket_escucha.get_packet_ip()
		var paquete := _socket_escucha.get_packet()
		var datos = JSON.parse_string(paquete.get_string_from_utf8())
		if typeof(datos) == TYPE_DICTIONARY and datos.has("codigo"):
			datos["ip"] = ip
			salas_encontradas[datos["codigo"]] = datos
			hubo_novedades = true

	if hubo_novedades:
		salas_actualizadas.emit()


func obtener_ip_local() -> String:
	for direccion in IP.get_local_addresses():
		if direccion.begins_with("192.168.") or direccion.begins_with("10.") or _es_ip_172_privada(direccion):
			return direccion
	return "No encontrada"


# ---------- Conexión desde fuera de la red local (internet) ----------
# Intenta abrir el puerto solo en el router del host (si soporta UPnP,
# algo muy común en routers hogareños/de proveedor de internet). Si el
# router no soporta UPnP o lo tiene desactivado, esto simplemente no
# hace nada — el host va a tener que abrir el puerto a mano igual.
func _intentar_abrir_puerto_upnp(puerto: int) -> void:
	var upnp := UPNP.new()
	if upnp.discover() != UPNP.UPNP_RESULT_SUCCESS:
		return
	if upnp.get_gateway() == null or not upnp.get_gateway().is_valid_gateway():
		return

	upnp.add_port_mapping(puerto, puerto, "8-Bit Bros Chavo", "UDP")
	upnp.add_port_mapping(puerto, puerto, "8-Bit Bros Chavo", "TCP")


signal ip_publica_obtenida(ip: String)
var ip_publica_cache := ""

# La IP local (obtener_ip_local) solo sirve para la misma red WiFi.
# Para que alguien se una desde OTRA conexión a internet hace falta
# la IP pública del host — esto se la pide a un servicio externo
# simple que solo devuelve la IP con la que salís a internet.
func _solicitar_ip_publica() -> void:
	var peticion := HTTPRequest.new()
	add_child(peticion)
	peticion.request_completed.connect(_on_ip_publica_respuesta.bind(peticion))
	peticion.request("https://api.ipify.org")


func _on_ip_publica_respuesta(resultado: int, codigo_respuesta: int, _headers: PackedStringArray, cuerpo: PackedByteArray, peticion: HTTPRequest) -> void:
	peticion.queue_free()
	if resultado != HTTPRequest.RESULT_SUCCESS or codigo_respuesta != 200:
		return
	var ip := cuerpo.get_string_from_utf8().strip_edges()
	if ip == "":
		return
	ip_publica_cache = ip
	ip_publica_obtenida.emit(ip)


func _es_ip_172_privada(direccion: String) -> bool:
	if not direccion.begins_with("172."):
		return false
	var partes := direccion.split(".")
	if partes.size() < 2 or not partes[1].is_valid_int():
		return false
	var segundo := partes[1].to_int()
	return segundo >= 16 and segundo <= 31


func _generar_codigo() -> String:
	var letras := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var codigo := ""
	for i in 2:
		codigo += letras[randi() % letras.length()]
	codigo += str(randi() % 900 + 100)
	return codigo


# ============================================================
#  SERVIDOR EXTERNO — lado CLIENTE
#  (lo usa panel_servidor_externo.gd; nada de esto toca el
#  sistema de red local/directa de más arriba)
# ============================================================

func conectar_servidor_externo(direccion: String, codigo: String, crear: bool, max_jugadores: int) -> void:
	_limpiar()

	if direccion.strip_edges().is_empty():
		error_de_conexion.emit("Ingresá la dirección del servidor externo.")
		return
	if not crear and codigo.strip_edges().is_empty():
		error_de_conexion.emit("Ingresá el código de la sala.")
		return

	var peer := WebSocketMultiplayerPeer.new()
	var resultado := peer.create_client(direccion.strip_edges())
	if resultado != OK:
		error_de_conexion.emit("No se pudo iniciar la conexión con el servidor externo. Revisá la dirección (debe empezar con wss:// o ws://).")
		return

	multiplayer.multiplayer_peer = peer
	modo_externo = true
	es_creador_externo = crear
	es_host = false
	_codigo_ingresado = codigo.strip_edges().to_upper()
	_max_jugadores_externo_solicitados = clampi(max_jugadores, 2, MAXIMO_JUGADORES_POSIBLE)

	multiplayer.connected_to_server.connect(_on_conectado_al_servidor_externo)
	multiplayer.connection_failed.connect(_on_fallo_conexion)
	multiplayer.server_disconnected.connect(_on_servidor_desconectado)

	_temporizador_conexion = get_tree().create_timer(TIEMPO_ESPERA_CONEXION)
	_temporizador_conexion.timeout.connect(_on_tiempo_de_espera_agotado)


func _on_conectado_al_servidor_externo() -> void:
	if es_creador_externo:
		_solicitar_creacion_sala_externa.rpc_id(1, _codigo_ingresado, _max_jugadores_externo_solicitados)
	else:
		_solicitar_ingreso_sala_externa.rpc_id(1, _codigo_ingresado)


# Igual que _on_boton_empezar_pressed en el modo LAN/directo, pero acá
# quien "empieza la carrera" no es la autoridad (el servidor externo lo
# es), así que primero se lo tiene que pedir con un RPC y es el
# servidor el que, si corresponde, avisa a todos que arrancó.
func solicitar_inicio_carrera_externa(rutas_niveles: PackedStringArray) -> void:
	_pedido_iniciar_carrera_externa.rpc_id(1, rutas_niveles)


@rpc("any_peer", "reliable")
func _pedido_iniciar_carrera_externa(rutas_niveles: PackedStringArray) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if id != _creador_id_externa or rutas_niveles.is_empty():
		return

	iniciar_secuencia_de_niveles(rutas_niveles)
	iniciar_cronometro_carrera()
	_iniciar_carrera_externa.rpc(nivel_actual())


@rpc("authority", "call_local", "reliable")
func _iniciar_carrera_externa(ruta_nivel: String) -> void:
	get_tree().change_scene_to_file(ruta_nivel)


# ============================================================
#  SERVIDOR EXTERNO — lado SERVIDOR DEDICADO
#  (solo corre dentro del build exportado con dedicated_server=true,
#  el que se aloja en Render; ver /servidor_externo/README.md)
# ============================================================

func _iniciar_como_servidor_dedicado() -> void:
	es_servidor_dedicado = true

	# Render (y la mayoría de hostings similares) le pasan al proceso
	# el puerto que tiene que escuchar en la variable de entorno PORT;
	# TLS (wss://) lo maneja Render por fuera, así que acá adentro
	# siempre se escucha en texto plano (ws://).
	var puerto := PUERTO_DEFECTO
	var puerto_env := OS.get_environment("PORT")
	if puerto_env.is_valid_int():
		puerto = puerto_env.to_int()

	var peer := WebSocketMultiplayerPeer.new()
	var resultado := peer.create_server(puerto)
	if resultado != OK:
		push_error("Servidor externo: no se pudo escuchar en el puerto %d." % puerto)
		get_tree().quit(1)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("Servidor externo escuchando en el puerto %d..." % puerto)


@rpc("any_peer", "reliable")
func _solicitar_creacion_sala_externa(codigo_deseado: String, max_jugadores: int) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()

	if _sala_externa_activa:
		_respuesta_ingreso_externo.rpc_id(id, false, "Ya hay una partida en curso en este servidor externo. Probá de nuevo en un rato, o usá la red local mientras tanto.")
		_rechazar_luego(id)
		return

	_sala_externa_activa = true
	_creador_id_externa = id
	maximo_jugadores = clampi(max_jugadores, 2, MAXIMO_JUGADORES_POSIBLE)
	codigo_sala = codigo_deseado.strip_edges().to_upper() if codigo_deseado.strip_edges() != "" else _generar_codigo()

	_respuesta_ingreso_externo.rpc_id(id, true, codigo_sala)
	_actualizar_conteo_sala_externa.rpc_id(id, 1, maximo_jugadores)


@rpc("any_peer", "reliable")
func _solicitar_ingreso_sala_externa(codigo_ingresado: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()

	if not _sala_externa_activa:
		_respuesta_ingreso_externo.rpc_id(id, false, "Todavía no hay ninguna sala creada con ese código en este servidor.")
		_rechazar_luego(id)
		return
	if codigo_ingresado.strip_edges().to_upper() != codigo_sala:
		_respuesta_ingreso_externo.rpc_id(id, false, "Código de sala incorrecto.")
		_rechazar_luego(id)
		return
	# +1 acá porque, a diferencia del modo LAN, en este modo el creador
	# de la sala SÍ cuenta como un jugador conectado (get_peers) más.
	if multiplayer.get_peers().size() + 1 > maximo_jugadores:
		_respuesta_ingreso_externo.rpc_id(id, false, "La sala ya está llena.")
		_rechazar_luego(id)
		return

	_respuesta_ingreso_externo.rpc_id(id, true, codigo_sala)
	if _creador_id_externa != -1:
		_actualizar_conteo_sala_externa.rpc_id(_creador_id_externa, multiplayer.get_peers().size(), maximo_jugadores)


@rpc("authority", "reliable")
func _respuesta_ingreso_externo(aceptado: bool, dato: String) -> void:
	_temporizador_conexion = null
	if aceptado:
		activo = true
		codigo_sala = dato
		conexion_exitosa.emit()
	else:
		error_de_conexion.emit(dato)
		_limpiar()


@rpc("authority", "reliable")
func _actualizar_conteo_sala_externa(conteo: int, maximo: int) -> void:
	maximo_jugadores = maximo
	conteo_sala_externa_actualizado.emit(conteo, maximo)


# Cuenta cuántos jugadores REALES hay en la partida en curso. En modo
# LAN/directo el host también juega (por eso +1); en modo servidor
# externo, el servidor dedicado no juega, así que no se suma.
func total_jugadores_activos() -> int:
	var conectados := multiplayer.get_peers().size()
	return conectados if es_servidor_dedicado else conectados + 1
