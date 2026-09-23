extends CharacterBody2D

const SPEED := 130.0
const RUN_SPEED := 195.0
const VIDAS_INICIALES := 3

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var efecto_correr_nodo: Node = $EfectoCorrer

var debe_correr := false
var meta_activada := false
var y_anterior_frame := 0.0
var vidas := VIDAS_INICIALES

signal efecto_correr
signal revivir
signal guarda_punto_de_control
signal vidas_actualizadas(vidas_actuales: int)
signal sin_vidas

func emitir_senal_efecto_correr() -> void:
	if not meta_activada:
		efecto_correr.emit()

func senal_revivir() -> void:
	vidas -= 1
	vidas_actualizadas.emit(vidas)
	meta_activada = false

	if vidas <= 0:
		if is_instance_valid(efecto_correr_nodo) and efecto_correr_nodo.has_method("detener_efecto_correr"):
			efecto_correr_nodo.detener_efecto_correr()
		sin_vidas.emit()
		return

	InputManager.input_enabled = true
	revivir.emit()

func guardar_punto_de_control() -> void:
	guarda_punto_de_control.emit()

var _material_skin: ShaderMaterial

func _ready() -> void:
	InputManager.input_enabled = true
	_configurar_multijugador()
	_conectar_meta()
	_conectar_hud()
	_aplicar_skin()

func _aplicar_skin() -> void:
	if not (has_node("/root/Skins") and has_node("/root/Guardado")):
		return

	var datos_skin: Dictionary = Skins.obtener(Guardado.skin_seleccionada)
	if not datos_skin.has("color"):
		return

	var shader := load("res://Recursos/shaders/tinte_piel.gdshader")
	if shader == null:
		return

	_material_skin = ShaderMaterial.new()
	_material_skin.shader = shader
	_material_skin.set_shader_parameter("color_tinte", datos_skin["color"])
	animated_sprite.material = _material_skin

func _conectar_hud() -> void:
	var padre := get_parent()
	if padre == null:
		return

	for nodo in padre.get_children():
		if nodo == self:
			continue
		if nodo.has_method("_on_vidas_actualizadas"):
			if not vidas_actualizadas.is_connected(nodo._on_vidas_actualizadas):
				vidas_actualizadas.connect(nodo._on_vidas_actualizadas)
			nodo._on_vidas_actualizadas(vidas)  # que muestre el valor actual ya mismo
		if nodo.has_method("_on_jugador_sin_vidas"):
			if not sin_vidas.is_connected(nodo._on_jugador_sin_vidas):
				sin_vidas.connect(nodo._on_jugador_sin_vidas)

func _configurar_multijugador() -> void:
	if not multiplayer.has_multiplayer_peer():
		return  # Modo un jugador: no hay nada que configurar.

	if str(name).is_valid_int():
		set_multiplayer_authority(int(name))

	var camara := get_node_or_null("Camera2D")
	if camara:
		camara.enabled = is_multiplayer_authority()

func _conectar_meta() -> void:
	# Los niveles usan distintos nombres de meta (Meta, Meta2, MetaIN,
	# Meta2KO, etc.). Buscar por la señal hace que todos funcionen igual.
	var padre := get_parent()
	if padre == null:
		return

	for nodo in padre.get_children():
		if nodo == self:
			continue

		if nodo.has_signal("meta_activada"):
			nodo.meta_activada.connect(_on_meta_activada)
		if nodo.has_signal("meta_activada2"):
			nodo.meta_activada2.connect(_on_meta_activada2)
		if nodo.has_signal("meta_activada3"):
			nodo.meta_activada3.connect(_on_meta_activada3)

func _detener_en_meta() -> void:
	if meta_activada:
		return

	meta_activada = true
	InputManager.input_enabled = false
	velocity = Vector2.ZERO

	if is_instance_valid(efecto_correr_nodo) and efecto_correr_nodo.has_method("detener_efecto_correr"):
		efecto_correr_nodo.detener_efecto_correr()

	animated_sprite.play("reposo")

func _on_meta_activada(cuerpo: Node2D = null) -> void:
	if cuerpo != null and cuerpo != self:
		return
	_detener_en_meta()
	if Red.activo:
		Carrera.jugador_local_termino()

func _on_meta_activada2(cuerpo: Node2D = null) -> void:
	if cuerpo != null and cuerpo != self:
		return
	_detener_en_meta()
	if Red.activo:
		Carrera.jugador_local_termino()

func _on_meta_activada3(cuerpo: Node2D = null) -> void:
	if cuerpo != null and cuerpo != self:
		return
	_detener_en_meta()
	if Red.activo:
		Carrera.jugador_local_termino()

func _physics_process(delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return  # Lo controla otra persona conectada: su posición llega por la red.

	y_anterior_frame = global_position.y

	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := InputManager.get_axis("mover_izquierda", "mover_derecha")

	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	if is_on_floor():
		if direction == 0:
			animated_sprite.play("reposo")
		else:
			animated_sprite.play("correr")
	else:
		animated_sprite.play("saltar2")

	if direction:
		velocity.x = direction * (RUN_SPEED if debe_correr or InputManager.is_action_pressed("correr") else SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func activar_material(nuevo_material: Material) -> void:
	animated_sprite.material = nuevo_material if nuevo_material != null else _material_skin

func aplicar_impulso_hacia_arriba(cantidad_de_impuso: float) -> void:
	velocity.y = -cantidad_de_impuso
