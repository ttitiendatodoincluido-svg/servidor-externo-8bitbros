extends Node

# Guarda datos que persisten entre partidas: monedas totales juntadas
# (independiente del puntaje de cada nivel, que se resetea) y qué
# skins se compraron / cuál está equipada. Se guarda en un archivo
# en la carpeta de usuario, así que sobrevive a cerrar el juego.

const RUTA_GUARDADO := "user://guardado.json"

var monedas_totales := 0
var skins_compradas: Array = ["clasico"]
var skin_seleccionada := "clasico"

signal monedas_actualizadas(total: int)


func _ready() -> void:
	cargar()


func agregar_monedas(cantidad: int) -> void:
	monedas_totales += cantidad
	monedas_actualizadas.emit(monedas_totales)
	guardar()


func comprar_skin(id: String, precio: int) -> bool:
	if skins_compradas.has(id):
		return true
	if monedas_totales < precio:
		return false

	monedas_totales -= precio
	skins_compradas.append(id)
	monedas_actualizadas.emit(monedas_totales)
	guardar()
	return true


func tiene_skin(id: String) -> bool:
	return skins_compradas.has(id)


func seleccionar_skin(id: String) -> void:
	if not skins_compradas.has(id):
		return
	skin_seleccionada = id
	guardar()


func guardar() -> void:
	var datos := {
		"monedas_totales": monedas_totales,
		"skins_compradas": skins_compradas,
		"skin_seleccionada": skin_seleccionada,
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
	if typeof(datos) != TYPE_DICTIONARY:
		return

	monedas_totales = int(datos.get("monedas_totales", 0))

	var lista = datos.get("skins_compradas", ["clasico"])
	skins_compradas = []
	if typeof(lista) == TYPE_ARRAY:
		for elemento in lista:
			skins_compradas.append(str(elemento))
	if not skins_compradas.has("clasico"):
		skins_compradas.append("clasico")

	skin_seleccionada = str(datos.get("skin_seleccionada", "clasico"))
	if not skins_compradas.has(skin_seleccionada):
		skin_seleccionada = "clasico"
