extends Control

# Configurables desde el editor (Inspector), para poder reusar este
# mismo script en los lobbies de inglés y coreano con sus propios
# mapas y sin duplicar lógica.
@export var ruta_portada := "res://Escenas/portada.tscn"
@export var nombres_mapas: PackedStringArray = ["Nivel 1", "Nivel 2", "Nivel 3"]
@export var rutas_mapas: PackedStringArray = [
	"res://Escenas/nivel_1.tscn",
	"res://Escenas/nivel_2.tscn",
	"res://Escenas/nivel_3.tscn",
]
@export var texto_todos_los_niveles := "Todos los niveles (seguidos)"

@onready var selector_jugadores: SpinBox = $PanelCrear/SelectorJugadores
@onready var selector_mapa: OptionButton = $PanelCrear/SelectorMapa
@onready var boton_crear: Button = $PanelCrear/BotonCrear
@onready var etiqueta_ip: Label = $PanelCrear/EtiquetaIP
@onready var boton_copiar_ip: Button = $PanelCrear/BotonCopiarIP
@onready var etiqueta_sala_creada: Label = $PanelCrear/EtiquetaSalaCreada
@onready var boton_empezar: Button = $PanelCrear/BotonEmpezar

@onready var campo_ip: LineEdit = $PanelUnirse/CampoIP
@onready var campo_puerto: LineEdit = $PanelUnirse/CampoPuerto
@onready var campo_codigo: LineEdit = $PanelUnirse/CampoCodigo
@onready var lista_salas_lan: VBoxContainer = $PanelUnirse/ListaSalasLAN

@onready var etiqueta_estado: Label = $EtiquetaEstado
@onready var pantalla_error: ColorRect = $PantallaError
@onready var etiqueta_error: Label = $PantallaError/Etiqueta

# Pestañas "Red local (WiFi)" / "Servidor externo (Internet)". Se buscan
# con get_node_or_null porque no todas las escenas localizadas (EN/KO)
# tienen todavía estos nodos nuevos; si faltan, esta pantalla simplemente
# se queda en el modo de red local de siempre, sin romper nada.
@onready var boton_modo_local: Button = get_node_or_null("SelectorModo/BotonModoLocal")
@onready var boton_modo_externo: Button = get_node_or_null("SelectorModo/BotonModoExterno")
@onready var panel_servidor_externo: Control = get_node_or_null("PanelServidorExterno")


func _on_boton_modo_local_toggled(pressed: bool) -> void:
	if not pressed:
		return
	if boton_modo_externo:
		boton_modo_externo.button_pressed = false
	$PanelCrear.visible = true
	$PanelUnirse.visible = true
	if panel_servidor_externo:
		panel_servidor_externo.visible = false


func _on_boton_modo_externo_toggled(pressed: bool) -> void:
	if not pressed:
		return
	if boton_modo_local:
		boton_modo_local.button_pressed = false
	$PanelCrear.visible = false
	$PanelUnirse.visible = false
	if panel_servidor_externo:
		panel_servidor_externo.visible = true


func _ready() -> void:
	Red.conexion_exitosa.connect(_on_conexion_exitosa)
	Red.error_de_conexion.connect(_on_error_de_conexion)
	Red.jugador_conectado.connect(_on_jugador_conectado)
	Red.salas_actualizadas.connect(_actualizar_lista_salas_lan)
	Red.ip_publica_obtenida.connect(_on_ip_publica_obtenida)

	selector_mapa.clear()
	for nombre in nombres_mapas:
		selector_mapa.add_item(nombre)
	if rutas_mapas.size() > 1:
		selector_mapa.add_item(texto_todos_los_niveles)

	boton_empezar.visible = false
	etiqueta_sala_creada.visible = false
	boton_copiar_ip.visible = false
	Red.iniciar_busqueda_lan()


func _exit_tree() -> void:
	Red.detener_busqueda_lan()


func _on_boton_crear_pressed() -> void:
	pantalla_error.visible = false
	etiqueta_estado.text = "Abriendo sala..."
	Red.alojar_partida(Red.PUERTO_DEFECTO, int(selector_jugadores.value))


func _on_boton_unirse_pressed() -> void:
	pantalla_error.visible = false
	etiqueta_estado.text = "Conectando..."
	var puerto := Red.PUERTO_DEFECTO
	if campo_puerto.text.strip_edges().is_valid_int():
		puerto = campo_puerto.text.strip_edges().to_int()
	Red.unirse_partida(campo_ip.text, puerto, campo_codigo.text)


func _on_conexion_exitosa() -> void:
	if Red.es_host:
		etiqueta_estado.text = "Sala creada."
		etiqueta_ip.text = "Misma red WiFi: %s   Puerto: %d\nInternet (otra red): buscando IP pública..." % [Red.obtener_ip_local(), Red.PUERTO_DEFECTO]
		boton_copiar_ip.visible = true
		etiqueta_sala_creada.visible = true
		etiqueta_sala_creada.text = "Código de sala: %s   (1/%d jugadores)" % [Red.codigo_sala, Red.maximo_jugadores]
		boton_empezar.visible = true
	else:
		etiqueta_estado.text = "¡Conectado! Esperando a que el host empiece la carrera..."


func _on_ip_publica_obtenida(ip: String) -> void:
	if not Red.es_host:
		return
	etiqueta_ip.text = "Misma red WiFi: %s   Puerto: %d\nInternet (otra red): %s   Puerto: %d" % [Red.obtener_ip_local(), Red.PUERTO_DEFECTO, ip, Red.PUERTO_DEFECTO]


func _on_jugador_conectado(_id: int) -> void:
	if Red.es_host:
		var actuales := multiplayer.get_peers().size() + 1
		etiqueta_sala_creada.text = "Código de sala: %s   (%d/%d jugadores)" % [Red.codigo_sala, actuales, Red.maximo_jugadores]


func _on_boton_empezar_pressed() -> void:
	var indice := selector_mapa.selected if selector_mapa.selected >= 0 else 0
	if indice >= rutas_mapas.size():
		Red.iniciar_secuencia_de_niveles(rutas_mapas)
	else:
		Red.iniciar_secuencia_de_niveles(PackedStringArray([rutas_mapas[indice]]))
	_avisar_inicio_carrera.rpc(Red.nivel_actual())


func _on_boton_copiar_ip_pressed() -> void:
	var ip := Red.ip_publica_cache if Red.ip_publica_cache != "" else Red.obtener_ip_local()
	DisplayServer.clipboard_set("%s:%d" % [ip, Red.PUERTO_DEFECTO])
	boton_copiar_ip.text = "¡Copiado!"
	var temporizador := get_tree().create_timer(1.5)
	temporizador.timeout.connect(func(): boton_copiar_ip.text = "Copiar IP y puerto")


@rpc("authority", "call_local", "reliable")
func _avisar_inicio_carrera(ruta_nivel: String) -> void:
	Red.iniciar_cronometro_carrera()
	get_tree().change_scene_to_file(ruta_nivel)


func _on_error_de_conexion(mensaje: String) -> void:
	etiqueta_estado.text = ""
	etiqueta_error.text = mensaje
	pantalla_error.visible = true
	boton_empezar.visible = false
	etiqueta_sala_creada.visible = false


func _on_boton_reintentar_pressed() -> void:
	pantalla_error.visible = false


func _on_boton_volver_pressed() -> void:
	Red.salir_de_partida()
	get_tree().change_scene_to_file(ruta_portada)


func _actualizar_lista_salas_lan() -> void:
	for hijo in lista_salas_lan.get_children():
		hijo.queue_free()

	for codigo in Red.salas_encontradas:
		var datos: Dictionary = Red.salas_encontradas[codigo]
		var boton := Button.new()
		boton.text = "%s  (%d/%d) — %s" % [codigo, datos.get("jugadores", 0), datos.get("maximo", 0), datos.get("ip", "")]
		boton.pressed.connect(_unirse_a_sala_lan.bind(codigo))
		lista_salas_lan.add_child(boton)


func _unirse_a_sala_lan(codigo: String) -> void:
	pantalla_error.visible = false
	etiqueta_estado.text = "Conectando..."
	Red.unirse_a_sala_encontrada(codigo)


func _on_comentarios_ko_pressed() -> void:
	OS.shell_open("https://forms.gle/8dC9XBTqjrZxFTfS9")


func _on_comentarios_pressed() -> void:
	OS.shell_open("https://docs.google.com/forms/d/e/1FAIpQLSdWV-kHnuTRUlBOZYNcekhn0a71Xn53kKeC6rr2a07PM3yFsw/viewform?usp=publish-editor")
