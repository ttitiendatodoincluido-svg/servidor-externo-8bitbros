extends Node

# Guarda una lista simple de notificaciones (título + mensaje) que se
# muestran en el panel de la campana, en la portada. Persisten en
# disco, y se recuerda cuáles ya se leyeron.

const RUTA_GUARDADO := "user://notificaciones.json"
const RUTA_IDIOMA := "user://idioma.save"

var lista: Array = []  # cada una: {id, titulo, mensaje, leida, enlace}
var _iniciales_agregadas := false

signal notificaciones_actualizadas


func _ready() -> void:
	cargar()
	asegurar_notificaciones_iniciales()


# Se puede llamar varias veces (cada portada lo hace en su _ready);
# solo agrega las notificaciones de bienvenida la primera vez que
# corre el juego, en el idioma que esté guardado en ese momento.
func asegurar_notificaciones_iniciales() -> void:
	if _iniciales_agregadas:
		return
	_iniciales_agregadas = true

	match idioma_actual():
		"ingles":
			agregar(
				"Welcome!",
				"Thanks for playing 8-Bit Bros. Explore the Wardrobe to get new skins with the coins you collect."
			)
			agregar(
				"Race Mode",
				"You can now compete against your friends in Multiplayer → Race. Up to 10 players in the same match!"
			)
		"coreano":
			agregar(
				"환영합니다!",
				"8-Bit Bros를 플레이해 주셔서 감사합니다. 옷장에서 모은 코인으로 새로운 스킨을 확인해 보세요."
			)
			agregar(
				"레이스 모드",
				"이제 멀티플레이어 → 레이스에서 친구들과 경쟁할 수 있습니다. 한 게임에 최대 10명까지 참여할 수 있어요!"
			)
		_:
			agregar(
				"¡Bienvenido!",
				"Gracias por jugar 8-Bit Bros. Explora el Vestidor para conseguir skins nuevas con las monedas que recolectes."
			)
			agregar(
				"Modo Carrera",
				"Ahora puedes competir contra tus amigos en Multijugador → Carrera. ¡Suma hasta 10 jugadores en una misma partida!"
			)

	guardar()


# Lee el idioma que el jugador tiene elegido ("espanol"/"ingles"/"coreano"),
# el mismo archivo que ya usa hud_portada.gd para recordar la elección.
func idioma_actual() -> String:
	if not FileAccess.file_exists(RUTA_IDIOMA):
		return "espanol"
	var archivo := FileAccess.open(RUTA_IDIOMA, FileAccess.READ)
	if not archivo:
		return "espanol"
	var idioma := archivo.get_as_text().strip_edges()
	archivo.close()
	return idioma if idioma != "" else "espanol"


func agregar(titulo: String, mensaje: String, enlace: String = "") -> void:
	lista.push_front({
		"id": Time.get_unix_time_from_system(),
		"titulo": titulo,
		"mensaje": mensaje,
		"leida": false,
		"enlace": enlace,
	})
	notificaciones_actualizadas.emit()
	guardar()


func marcar_todas_leidas() -> void:
	var hubo_cambios := false
	for n in lista:
		if not n.get("leida", false):
			n["leida"] = true
			hubo_cambios = true
	if hubo_cambios:
		notificaciones_actualizadas.emit()
		guardar()


func cantidad_no_leidas() -> int:
	var cantidad := 0
	for n in lista:
		if not n.get("leida", false):
			cantidad += 1
	return cantidad


func guardar() -> void:
	var datos := {
		"lista": lista,
		"iniciales_agregadas": _iniciales_agregadas,
	}
	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()


func cargar() -> void:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return

	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if not archivo:
		return

	var texto := archivo.get_as_text()
	archivo.close()

	var datos = JSON.parse_string(texto)

	# Compatibilidad con el formato viejo (guardaba solo la lista, sin la bandera).
	if typeof(datos) == TYPE_ARRAY:
		lista = datos
		_iniciales_agregadas = not lista.is_empty()
		return

	if typeof(datos) == TYPE_DICTIONARY:
		lista = datos.get("lista", [])
		_iniciales_agregadas = bool(datos.get("iniciales_agregadas", false))
