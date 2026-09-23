extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

var progreso := 0
const SAVE_FILE := "user://idioma.save"
var idioma := "espanol"

func _ready() -> void:
	cargar_idioma()

	match idioma:
		"ingles":
			label.text = "Loading..."
		"coreano":
			label.text = "로딩 중..."
		_:
			label.text = "Cargando..."

	await cargar()

func cargar_idioma() -> void:
	idioma = "espanol"

	if FileAccess.file_exists(SAVE_FILE):
		var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			var idioma_guardado := file.get_as_text().strip_edges()
			file.close()

			if idioma_guardado in ["espanol", "ingles", "coreano"]:
				idioma = idioma_guardado

func cargar() -> void:
	while progreso < 103:
		await get_tree().create_timer(0.05).timeout
		progreso += 1
		progress_bar.value = progreso

	match idioma:
		"ingles":
			label.text = "Completed"
		"coreano":
			label.text = "완료"
		_:
			label.text = "Completado"

	await get_tree().create_timer(1.0).timeout
	cambiar_escena()

func cambiar_escena() -> void:
	match idioma:
		"ingles":
			get_tree().change_scene_to_file("res://Escenas/portadaingles.tscn")
		"coreano":
			get_tree().change_scene_to_file("res://Escenas/portadacoreano.tscn")
		_:
			get_tree().change_scene_to_file("res://Escenas/portada.tscn")
