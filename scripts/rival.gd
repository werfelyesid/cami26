extends "res://scripts/futbolista.gd"
## El rival. Es un "bot" sencillo, sin trampas:
##
##   1. Si el balón está lejos, corre a ponerse DETRÁS del balón
##      (del lado de +X) para poder empujarlo hacia la portería tuya.
##   2. Si ya está cerca, corre hacia la portería tuya (x = -30)
##      arrastrando el balón, y de vez en cuando le pega un zapatazo.
##
## La velocidad la pone la escena del partido según la dificultad elegida.

## A qué portería ataca (la tuya, la que está en x = -30).
var porteria_objetivo := Vector3(-30.0, 0.0, 0.0)
## Velocidad que le pone el partido según la dificultad.
var velocidad_dificultad := 6.4


func _logica(_delta: float) -> void:
	velocidad = velocidad_dificultad
	if balon == null:
		direccion = Vector3.ZERO
		return

	var b: Vector3 = balon.global_position
	var d: Vector3 = b - global_position
	d.y = 0.0

	if d.length() > 2.0:
		# Todavía está lejos: se coloca detrás del balón.
		var puesto := Vector3(b.x + 1.3, 0.0, b.z + clampf(-d.z * 0.15, -0.8, 0.8))
		direccion = puesto - global_position
	else:
		# Ya está encima: empuja hacia la portería del jugador.
		direccion = porteria_objetivo - b
		patear(14.0, 1.2, 0.2)

	direccion.y = 0.0
	if direccion.length() < 0.15:
		direccion = Vector3.ZERO
