extends Node

var puntuacion = 0

@onready var puntuación_1: Label = $Puntuación1

signal puntuacion_actualizada(puntuacion_actual:int)

func incrementa_un_punto():
	puntuacion += 1
	puntuacion_actualizada.emit(puntuacion)
	puntuación_1.text = "🪙"+str(puntuacion)+"🪙"
