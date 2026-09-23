extends CanvasLayer

# ==========================================
# CONSTANTES Y ARCHIVOS DE GUARDADO
# ==========================================
const SAVE_FILE := "user://idioma.save"
const NICKNAME_FILE := "user://nickname.save"
const VOLUME_FILE := "user://volumen.save"
const CFG_SAVE_FILE := "user://save.cfg"

# ==========================================
# REFERENCIAS A NODOS (@onready)
# ==========================================
@onready var sonido_muelle: AudioStreamPlayer = $SonidoMuelle
@onready var nickname_put: LineEdit = _buscar_nickname_label()
@onready var insignia_notificaciones: Label = get_node_or_null("BotonCampana/Insignia")
@onready var panel_notificaciones: Control = get_node_or_null("PanelNotificaciones")
@onready var control_volumen: HSlider = get_node_or_null("HSlider")


# ==========================================
# MÉTODOS DEL CICLO DE VIDA DE GODOT
# ==========================================
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	cargar_nickname()
	_aplicar_volumen_guardado()

	if insignia_notificaciones:
		Notificaciones.notificaciones_actualizadas.connect(_actualizar_insignia_notificaciones)
		_actualizar_insignia_notificaciones()


# ==========================================
# TUTORIAL
# ==========================================
func _on_boton_tutorial_pressed() -> void:
	guardar_nickname()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Escenas/tutorial.tscn")

func _on_boton_tutorial_i_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/tutorialIN.tscn")

func _on_boton_tutorial_ko_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/tutorialCELKO.tscn")


# ==========================================
# NICKNAME (GUARDAR Y CARGAR)
# ==========================================
func _buscar_nickname_label() -> LineEdit:
	var nodo := get_node_or_null("NicknameLabel")
	if nodo == null:
		nodo = get_node_or_null("NicknameLabel2")
	return nodo

func guardar_nickname() -> void:
	if not nickname_put:
		return
		
	var nickname := nickname_put.text.strip_edges()
	if nickname == "":
		nickname = "Jugador"

	var file := FileAccess.open(NICKNAME_FILE, FileAccess.WRITE)
	if file:
		file.store_string(nickname)
		file.close()
		print("NICKNAME GUARDADO: ", nickname)
	else:
		print("ERROR: NO SE PUDO CREAR nickname.save")

func cargar_nickname() -> void:
	if not nickname_put:
		return

	if FileAccess.file_exists(NICKNAME_FILE):
		var file := FileAccess.open(NICKNAME_FILE, FileAccess.READ)
		if file:
			var nickname_guardado := file.get_as_text()
			file.close()
			nickname_put.text = nickname_guardado
			print("NICKNAME CARGADO: ", nickname_guardado)
	else:
		nickname_put.text = "Jugador"

func _on_texture_button_pressed() -> void:
	guardar_nickname()


# ==========================================
# AUDIO Y VOLUMEN
# ==========================================
func _on_h_slider_value_changed(vol: float) -> void:
	var db := linear_to_db(vol)
	AudioServer.set_bus_volume_db(0, db)
	_guardar_volumen(vol)

func _aplicar_volumen_guardado() -> void:
	var vol := _cargar_volumen()
	AudioServer.set_bus_volume_db(0, linear_to_db(vol))
	if control_volumen:
		control_volumen.value = vol

func _cargar_volumen() -> float:
	if not FileAccess.file_exists(VOLUME_FILE):
		return 1.0
	var archivo := FileAccess.open(VOLUME_FILE, FileAccess.READ)
	if not archivo:
		return 1.0
	var texto := archivo.get_as_text().strip_edges()
	archivo.close()
	if texto.is_valid_float():
		return clampf(texto.to_float(), 0.0, 1.0)
	return 1.0

func _guardar_volumen(vol: float) -> void:
	var archivo := FileAccess.open(VOLUME_FILE, FileAccess.WRITE)
	if archivo:
		archivo.store_string(str(vol))
		archivo.close()


# ==========================================
# NOTIFICACIONES
# ==========================================
func _actualizar_insignia_notificaciones() -> void:
	if not insignia_notificaciones:
		return
	var no_leidas := Notificaciones.cantidad_no_leidas()
	insignia_notificaciones.visible = no_leidas > 0
	insignia_notificaciones.text = str(no_leidas)

func _on_boton_campana_pressed() -> void:
	if panel_notificaciones:
		panel_notificaciones.abrir()


# ==========================================
# SELECCIÓN Y CONFIGURACIÓN DE IDIOMAS
# ==========================================
func guardar_idioma(idioma: String) -> void:
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(idioma)
		file.close()

func _on_boton_espanol_pressed() -> void:
	guardar_nickname()
	guardar_idioma("espanol")
	get_tree().change_scene_to_file("res://Escenas/carga.tscn")

func _on_boton_ingles_pressed() -> void:
	guardar_nickname()
	guardar_idioma("ingles")
	get_tree().change_scene_to_file("res://Escenas/cargain.tscn")

func _on_boton_coreano_pressed() -> void:
	guardar_nickname()
	guardar_idioma("coreano")
	get_tree().change_scene_to_file("res://Escenas/cargako.tscn")

func _on_boton_cam_idio_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/idiomas.tscn")

func _on_boton_cha_lan_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/idiomas_in.tscn")

func _on_boton_exit_language_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/info.tscn")


# ==========================================
# MENÚ PRINCIPAL Y COMENZAR
# ==========================================
func _on_boton_comenzar_pressed() -> void:
	guardar_nickname()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	sonido_muelle.play()
	get_tree().change_scene_to_file("res://Escenas/menu.tscn")

func _on_boton_start_pressed() -> void:
	guardar_nickname()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	sonido_muelle.play()
	get_tree().change_scene_to_file("res://Escenas/menuIN.tscn")

func _on_boton_comenzar_ko_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/menuKO.tscn")


# ==========================================
# SELECCIÓN DE NIVELES
# ==========================================
func _on_boton_1_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/nivel_1.tscn")

func _on_boton_2_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/nivel_2.tscn")

func _on_boton_3_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/nivel_3.tscn")

func _on_boton_l_1_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/nivel_1_en.tscn")

func _on_boton_l_2_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/nivel_2_en.tscn")

func _on_boton_l_3_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/nivel_3_en.tscn")

func _on_boton_1ko_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/nivel_1_ko.tscn")

func _on_boton_2ko_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/nivel_2_ko.tscn")

func _on_boton_3ko_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/nivel_3_ko.tscn")

# ==========================================
# MULTIJUGADOR
# ==========================================
func _on_boton_multijugador_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/multijugador.tscn")

func _on_boton_multiplayer_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/multijugador_en.tscn")

func _on_boton_multijugador_ko_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/multijugador_ko.tscn")


# ==========================================
# VESTIDOR / PERSONALIZACIÓN
# ==========================================
func _on_boton_vestidor_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/vestidor.tscn")

func _on_boton_vestidor_ingles_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/vestidor_en.tscn")

func _on_boton_vestidor_ko_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/vestidor_ko.tscn")


# ==========================================
# AJUSTES
# ==========================================
func _on_boton_ajustes_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/ajustes.tscn")

func _on_boton_info_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/ajustesin.tscn")

func _on_boton_ajustes_ko_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/ajustesko.tscn")


# ==========================================
# INFORMACIÓN Y ACERCA DE
# ==========================================
func _on_boton_acerca_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/acerca.tscn")

func _on_boton_acerca_in_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/info.tscn")

func _on_boton_acerca_ko_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/acercaKO.tscn")

func _on_boton_infor_rela_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/inforrela.tscn")

func _on_boton_rela_inf_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/inforrela.tscn")

func _on_boton_rela_inf_in_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/inforrelaIN.tscn")

func _on_boton_infor_rela_ko_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/inforrelaKO.tscn")


# ==========================================
# NAVEGACIÓN Y SALIDAS (PORTADA / SALIR)
# ==========================================
func _on_boton_salida_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/portada.tscn")

func _on_boton_salida_in_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/portadaingles.tscn")

func _on_boton_exit_en_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/portadaingles.tscn")

func _on_boton_exit_page_pressed() -> void:
	guardar_nickname()
	sonido_muelle.play()
	get_tree().change_scene_to_file("res://Escenas/portadaingles.tscn")

func _on_boton_salida_ko_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/portadacoreano.tscn")

func _on_boton_salida_redes_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/ajustes.tscn")

func _on_boton_salida_redes_in_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/ajustesin.tscn")

func _on_boton_salida_redes_ko_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/ajustesko.tscn")

func _on_boton_salir_pressed() -> void:
	guardar_nickname()
	sonido_muelle.play()
	get_tree().quit()


# ==========================================
# REDES SOCIALES Y CONTACTO
# ==========================================
func _on_boton_red_soc_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/redessociales.tscn")

func _on_boton_red_soc_in_pressed() -> void:
	guardar_nickname()
	get_tree().change_scene_to_file("res://Escenas/redessocialesin.tscn")

func _on_youtube_pressed() -> void:
	OS.shell_open("https://youtube.com/@samuraigameroficial?si=VMOXKCcLXfLQkbF8")

func _on_whatsapp_pressed() -> void:
	OS.shell_open("https://whatsapp.com/channel/0029VbCcOzKATRSqnkOodh228")

func _on_gmail_pressed() -> void:
	OS.shell_open("https://mail.google.com/mail/?view=cm&fs=1&to=soportetecnico8bitbros@gmail.com&su=Necesito ayuda con esto&body=Hola, mi problema es...")


# ==========================================
# DESCARGAS UPTODOWN
# ==========================================
func _on_uptodown_w_pressed() -> void:
	OS.shell_open("https://8-bit-bros.uptodown.com/windows")

func _on_uptodown_a_pressed() -> void:
	OS.shell_open("https://8-bit-bros.uptodown.com/android")

func _on_uptodown_m_pressed() -> void:
	OS.shell_open("https://8-bit-bros.uptodown.com/mac")


# ==========================================
# FORMULARIOS Y OPINIONES
# ==========================================
func _on_comentarios_pressed() -> void:
	OS.shell_open("https://docs.google.com/forms/d/e/1FAIpQLSdWV-kHnuTRUlBOZYNcekhn0a71Xn53kKeC6rr2a07PM3yFsw/viewform?usp=publish-editor")

func _on_comentarios_ko_pressed() -> void:
	OS.shell_open("https://forms.gle/8dC9XBTqjrZxFTfS9")


# ==========================================
# POLÍTICAS Y TÉRMINOS
# ==========================================
func _on_politica_pressed() -> void:
	OS.shell_open("https://docs.google.com/document/d/1dOTDChr6krEG-tum1dY2OPgBMCAkOBHPumFdvHoVrt8/edit?usp=sharing")

func _on_terminosdeuso_pressed() -> void:
	OS.shell_open("https://docs.google.com/document/d/1uNcRZcGzr9wbrIeUY4mcq49Jq02sNpK2b1VYRzJB4II/edit?usp=sharing")

func _on_politica_in_pressed() -> void:
	OS.shell_open("https://docs.google.com/document/d/1QCxNoFwlaBhdXQ5F7DGhUL7vu0SJVRpw4_5x1qZxzX4/edit?usp=sharing")

func _on_terminosdeuso_in_pressed() -> void:
	OS.shell_open("https://docs.google.com/document/d/1bx1uYAeraywMq-7jCGWCLZ5ujPoIW4dHg7dXtgOCawQ/edit?usp=sharing")

func _on_politica_ko_pressed() -> void:
	OS.shell_open("https://docs.google.com/document/d/1EHAkpCV6XcshzmHUXYpi_u_gYiFnA2nYwt1K7tsgjac/edit?usp=sharing")

func _on_terminosdeuso_ko_pressed() -> void:
	OS.shell_open("https://docs.google.com/document/d/1NEU2XVbZyW3pBZPfSpr6Ujr4EhC91-y_Ks-2pgFngIU/edit?usp=sharing")


# ==========================================
# MÉTODOS AUXILIARES DE ARCHIVO
# ==========================================
func guardar_escena(ruta_escena: String) -> void:
	var config := ConfigFile.new()
	config.set_value("juego", "ultima_escena", ruta_escena)
	config.save(CFG_SAVE_FILE)
