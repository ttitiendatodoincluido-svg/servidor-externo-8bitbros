extends AnimationPlayer

@onready var animaciondeportada: AnimationPlayer = $"."

func _ready():
	play("animaciondeportada")
	var anim = get_animation("animaciondeportada")
	if anim:
		seek(randf_range(0, anim.length), true)
