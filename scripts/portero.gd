extends "res://scripts/futbolista.gd"
## El arquero.
##
## Se queda sobre la línea de su portería siguiendo al balón de lado a lado,
## y cuando el balón se le arrima lo despeja con un pelotazo hacia la mitad
## de la cancha. No regatea (eso lo apaga la escena del partido).

## En qué X está su línea de portería (la pone el partido).
var linea_x := 28.8
## Hacia dónde despeja el balón (hacia el centro de la cancha).
var despeje := Vector3(-1.0, 0.0, 0.0)


func _logica(_delta: float) -> void:
	if balon == null:
		direccion = Vector3.ZERO
		return

	var b: Vector3 = balon.global_position

	# Se mueve de lado a lado siguiendo el balón, pero sin salirse de la portería.
	var objetivo := Vector3(linea_x, 0.0, clampf(b.z, -2.3, 2.3))
	direccion = objetivo - global_position
	direccion.y = 0.0
	if direccion.length() < 0.15:
		direccion = Vector3.ZERO

	# Si el balón le queda al alcance, lo manda lejos.
	var d: Vector3 = b - global_position
	d.y = 0.0
	if d.length() < 2.0 and _espera_pateo <= 0.0:
		_espera_pateo = 0.7
		balon.apply_central_impulse((despeje.normalized() * 13.0 + Vector3.UP * 4.0) * balon.mass)
