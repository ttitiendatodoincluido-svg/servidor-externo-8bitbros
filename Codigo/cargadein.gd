extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label_l: Label = $LabelL

var progreso := 0

func _ready() -> void:
	label_l.text = "Loading..."
	await cargar()

func cargar() -> void:
	while progreso < 100:
		await get_tree().create_timer(0.05).timeout
		progreso += 1
		progress_bar.value = progreso

	label_l.text = "Completed"
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Escenas/portadaingles.tscn")
