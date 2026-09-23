extends Control

@export var texto_titulo := "🔔 Notificaciones"
@export var texto_vacio := "No tienes notificaciones por ahora."

@onready var fondo: ColorRect = $Fondo
@onready var titulo: Label = $Titulo
@onready var etiqueta_vacio: Label = $Panel/EtiquetaVacio
@onready var lista_contenedor: VBoxContainer = $Panel/ScrollContainer/Lista


func _ready() -> void:
	visible = false
	titulo.text = texto_titulo
	etiqueta_vacio.text = texto_vacio
	Notificaciones.notificaciones_actualizadas.connect(_actualizar_lista)


func abrir() -> void:
	visible = true
	_actualizar_lista()
	Notificaciones.marcar_todas_leidas()


func cerrar() -> void:
	visible = false


func _actualizar_lista() -> void:
	for hijo in lista_contenedor.get_children():
		hijo.queue_free()

	if Notificaciones.lista.is_empty():
		etiqueta_vacio.visible = true
		return

	etiqueta_vacio.visible = false
	for notificacion in Notificaciones.lista:
		lista_contenedor.add_child(_crear_tarjeta(notificacion))


func _crear_tarjeta(notificacion: Dictionary) -> Control:
	var panel := PanelContainer.new()

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 4)
	panel.add_child(caja)

	var titulo := Label.new()
	titulo.text = str(notificacion.get("titulo", ""))
	titulo.add_theme_font_size_override("font_size", 18)
	caja.add_child(titulo)

	var mensaje := Label.new()
	mensaje.text = str(notificacion.get("mensaje", ""))
	mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD
	caja.add_child(mensaje)

	var enlace := str(notificacion.get("enlace", ""))
	if enlace != "":
		var boton_enlace := Button.new()
		boton_enlace.text = "Abrir"
		boton_enlace.focus_mode = Control.FOCUS_NONE
		boton_enlace.pressed.connect(func(): OS.shell_open(enlace))
		caja.add_child(boton_enlace)

	return panel


func _on_boton_cerrar_pressed() -> void:
	cerrar()


func _on_fondo_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		cerrar()
