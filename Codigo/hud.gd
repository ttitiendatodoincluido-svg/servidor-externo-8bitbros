extends CanvasLayer

@onready var contador_monedas: Label = $ContadorMonedas
@onready var contador_monedas_2: Label = $ContadorMonedas2
@onready var contador_vidas: Label = $ContadorVidas
@onready var pantalla_perdiste: ColorRect = $PantallaPerdiste
@onready var temporizador_perdiste: Timer = $PantallaPerdiste/TemporizadorPerdiste
@onready var cronometro: Label = get_node_or_null("Cronometro")
@onready var pantalla_conexion_perdida: ColorRect = get_node_or_null("PantallaConexionPerdida")
@onready var etiqueta_conexion_perdida: Label = get_node_or_null("PantallaConexionPerdida/Etiqueta")

var _tiempo_cronometro := 0.0

# Estos se buscan con get_node_or_null porque no todas las escenas que
# usan este script los tienen (por ejemplo, escenas fuera del modo Carrera).
@onready var pantalla_resultados: ColorRect = get_node_or_null("PantallaResultados")
@onready var lista_resultados: VBoxContainer = get_node_or_null("PantallaResultados/ListaResultados")
@onready var pantalla_victoria: ColorRect = get_node_or_null("PantallaVictoria")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = true
	var game_manager: Node = get_node_or_null("%GameManager")
	if game_manager and not game_manager.is_connected("puntuacion_actualizada", _on_puntuacion_actualizada):
		game_manager.connect("puntuacion_actualizada", _on_puntuacion_actualizada)

	var jugador := _buscar_jugador()
	if jugador:
		if jugador.has_signal("vidas_actualizadas") and not jugador.is_connected("vidas_actualizadas", _on_vidas_actualizadas):
			jugador.connect("vidas_actualizadas", _on_vidas_actualizadas)
			var vidas_iniciales = jugador.get("vidas")
			if vidas_iniciales != null:
				contador_vidas.text = "❤️" + str(vidas_iniciales)
		if jugador.has_signal("sin_vidas") and not jugador.is_connected("sin_vidas", _on_jugador_sin_vidas):
			jugador.connect("sin_vidas", _on_jugador_sin_vidas)

	if Red.activo and pantalla_resultados:
		Carrera.jugador_llego.connect(_on_jugador_llego)
	if Red.activo and pantalla_victoria:
		Carrera.carrera_completa.connect(_on_carrera_completa)
	if Red.activo and pantalla_conexion_perdida:
		Red.error_de_conexion.connect(_on_conexion_perdida)


func _process(delta: float) -> void:
	if not cronometro:
		return
	_tiempo_cronometro += delta
	var mins := int(_tiempo_cronometro) / 60
	var segs := int(_tiempo_cronometro) % 60
	cronometro.text = "⏱ %02d:%02d" % [mins, segs]




# Busca al Jugador entre los hermanos del HUD (mismo patrón que usa
# jugador.gd para encontrar la Meta): así funciona sin importar si el
# nodo se llama "Jugador" o cualquier otra cosa.
func _buscar_jugador() -> Node:
	var padre := get_parent()
	if padre == null:
		return null

	for nodo in padre.get_children():
		if nodo != self and nodo.has_signal("sin_vidas"):
			return nodo
	return null


func _on_puntuacion_actualizada(puntuacion_actual:int) -> void:
	contador_monedas.text = str(puntuacion_actual) 
	contador_monedas_2.text = str(puntuacion_actual)


func _on_vidas_actualizadas(vidas_actuales: int) -> void:
	contador_vidas.text = "❤️" + str(vidas_actuales)


func _on_jugador_sin_vidas() -> void:
	if pantalla_perdiste.visible:
		return
	pantalla_perdiste.visible = true
	temporizador_perdiste.start()


func _on_jugador_llego(id: int, puesto: int, nombre: String, tiempo: float) -> void:
	if not pantalla_resultados or not lista_resultados:
		return

	var quien := nombre if nombre != "" else ("Jugador %d" % id)
	var etiqueta := Label.new()
	etiqueta.text = "%dº lugar: %s — %s" % [puesto, quien, _formatear_tiempo(tiempo)]
	lista_resultados.add_child(etiqueta)
	pantalla_resultados.visible = true


func _formatear_tiempo(segundos: float) -> String:
	var mins := int(segundos) / 60
	var segs := int(segundos) % 60
	return "%02d:%02d" % [mins, segs]


func _on_conexion_perdida(mensaje: String) -> void:
	if not pantalla_conexion_perdida:
		return
	if pantalla_conexion_perdida.visible:
		return
	if etiqueta_conexion_perdida:
		etiqueta_conexion_perdida.text = mensaje
	pantalla_conexion_perdida.visible = true
	InputManager.input_enabled = false

	var temporizador := get_tree().create_timer(4.0)
	temporizador.timeout.connect(_volver_por_conexion_perdida)


func _volver_por_conexion_perdida() -> void:
	Musica.pitch_scale = 1.0
	Red.salir_de_partida()
	Carrera.reiniciar()
	get_tree().change_scene_to_file(_ruta_portada_segun_idioma())


func _ruta_portada_segun_idioma() -> String:
	# Detecta qué variante de HUD es esta por un nodo propio de cada una.
	if get_node_or_null("BotonSalidaKO"):
		return "res://Escenas/portadacoreano.tscn"
	if get_node_or_null("BotonExitPage"):
		return "res://Escenas/portadaingles.tscn"
	return "res://Escenas/portada.tscn"


func _on_carrera_completa() -> void:
	if not pantalla_victoria:
		return
	pantalla_resultados.visible = false
	pantalla_victoria.visible = true


func _on_boton_volver_lobby_pressed() -> void:
	Musica.pitch_scale = 1.0
	Red.salir_de_partida()
	Carrera.reiniciar()
	get_tree().change_scene_to_file("res://Escenas/portada.tscn")


func _on_boton_exit_page_pressed() -> void:
	Musica.pitch_scale = 1.0
	Red.salir_de_partida()
	Carrera.reiniciar()
	get_tree().change_scene_to_file("res://Escenas/portadaingles.tscn")

func _on_boton_salir_pagina_pressed() -> void:
	Musica.pitch_scale = 1.0
	Red.salir_de_partida()
	Carrera.reiniciar()
	get_tree().change_scene_to_file("res://Escenas/portada.tscn")


func _on_boton_salida_ko_pressed() -> void:
	Musica.pitch_scale = 1.0
	Red.salir_de_partida()
	Carrera.reiniciar()
	get_tree().change_scene_to_file("res://Escenas/portadacoreano.tscn")


# Estos botones ya tienen una acción configurada en el TouchScreenButton.
# Los callbacks existen para evitar errores de señal en la interfaz inglesa.
func _on_izquierda_pressed() -> void:
	pass

func _on_izquierda_2_pressed() -> void:
	pass

func _on_saltar_pressed() -> void:
	pass
