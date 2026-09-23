extends VBoxContainer

# ============================================================
#  Panel de "Servidor externo" (Internet) — pensado para el modo
#  Carrera cuando los jugadores NO están en la misma red WiFi.
#
#  Se conecta a un servidor dedicado propio y siempre encendido
#  (por ejemplo alojado gratis en Render, ver /servidor_externo
#  en la raíz del proyecto) en vez de conectarse directo entre
#  jugadores. Así nadie necesita su IP pública ni abrir puertos
#  en su router: el servidor externo ya está accesible desde
#  cualquier red por su dirección fija.
#
#  Este panel es independiente del sistema de red local/directa
#  (ver Red / multijugador.gd), que sigue funcionando igual que
#  antes en su propia pestaña. Ambos comparten la misma "Red"
#  (autoload) por debajo, solo que por un canal distinto.
# ============================================================

@export var direccion_por_defecto := "wss://8-bit-bros-chavo.onrender.com"
@export var nombres_mapas: PackedStringArray = ["Nivel 1", "Nivel 2", "Nivel 3"]
@export var rutas_mapas: PackedStringArray = [
	"res://Escenas/nivel_1.tscn",
	"res://Escenas/nivel_2.tscn",
	"res://Escenas/nivel_3.tscn",
]
@export var texto_todos_los_niveles := "Todos los niveles (seguidos)"

@onready var campo_servidor: LineEdit = $CampoServidor
@onready var selector_jugadores: SpinBox = $FilaCrear/SelectorJugadores
@onready var campo_codigo_crear: LineEdit = $FilaCrear/CampoCodigoCrear
@onready var boton_crear: Button = $FilaCrear/BotonCrear
@onready var campo_codigo_unirse: LineEdit = $FilaUnirse/CampoCodigoUnirse
@onready var boton_unirse: Button = $FilaUnirse/BotonUnirse
@onready var etiqueta_codigo: Label = $EtiquetaCodigo
@onready var selector_mapa: OptionButton = $SelectorMapa
@onready var boton_empezar: Button = $BotonEmpezar
@onready var etiqueta_estado: Label = $EtiquetaEstado


func _ready() -> void:
	campo_servidor.text = direccion_por_defecto

	selector_mapa.clear()
	for nombre in nombres_mapas:
		selector_mapa.add_item(nombre)
	if rutas_mapas.size() > 1:
		selector_mapa.add_item(texto_todos_los_niveles)

	boton_crear.pressed.connect(_on_boton_crear_pressed)
	boton_unirse.pressed.connect(_on_boton_unirse_pressed)
	boton_empezar.pressed.connect(_on_boton_empezar_pressed)

	Red.conexion_exitosa.connect(_on_conexion_exitosa)
	Red.error_de_conexion.connect(_on_error_de_conexion)
	Red.conteo_sala_externa_actualizado.connect(_on_conteo_actualizado)

	_ocultar_controles_de_sala()


func _ocultar_controles_de_sala() -> void:
	etiqueta_codigo.visible = false
	selector_mapa.visible = false
	boton_empezar.visible = false


func _on_boton_crear_pressed() -> void:
	etiqueta_estado.text = "Conectando con el servidor externo..."
	Red.conectar_servidor_externo(campo_servidor.text, campo_codigo_crear.text, true, int(selector_jugadores.value))


func _on_boton_unirse_pressed() -> void:
	etiqueta_estado.text = "Conectando con el servidor externo..."
	Red.conectar_servidor_externo(campo_servidor.text, campo_codigo_unirse.text, false, 4)


func _on_conexion_exitosa() -> void:
	if not Red.modo_externo:
		return  # esta señal la usa también el modo LAN/directo; no es asunto nuestro

	etiqueta_codigo.visible = true
	etiqueta_codigo.text = "Código de sala: %s" % Red.codigo_sala

	if Red.es_creador_externo:
		etiqueta_estado.text = "Sala creada en el servidor externo. (1/%d jugadores)\nCompartí el código con quienes se quieran unir." % Red.maximo_jugadores
		selector_mapa.visible = true
		boton_empezar.visible = true
	else:
		etiqueta_estado.text = "¡Conectado! Esperando a que el organizador empiece la carrera..."


func _on_conteo_actualizado(conteo: int, maximo: int) -> void:
	if not Red.modo_externo or not Red.es_creador_externo:
		return
	etiqueta_estado.text = "Sala creada en el servidor externo. (%d/%d jugadores)\nCompartí el código con quienes se quieran unir." % [conteo, maximo]


func _on_error_de_conexion(mensaje: String) -> void:
	if not Red.modo_externo:
		return
	etiqueta_estado.text = mensaje
	_ocultar_controles_de_sala()


func _on_boton_empezar_pressed() -> void:
	var indice := selector_mapa.selected if selector_mapa.selected >= 0 else 0
	var rutas: PackedStringArray
	if indice >= rutas_mapas.size():
		rutas = rutas_mapas
	else:
		rutas = PackedStringArray([rutas_mapas[indice]])
	Red.solicitar_inicio_carrera_externa(rutas)
