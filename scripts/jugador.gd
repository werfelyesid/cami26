extends "res://scripts/futbolista.gd"
## TU jugador.
##
## Se mueve con el joystick del celular (controles) o con el teclado
## de la compu (W A S D o las flechas), y patea con los botones.

## Los controles táctiles. La escena del partido los conecta aquí.
var controles = null


func _logica(_delta: float) -> void:
	var v := Vector2.ZERO
	# Teclado, para probar en la compu.
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1.0
	# Joystick del celular.
	if controles != null:
		v.x += controles.mover.x
		v.y += controles.mover.y
	if v.length() > 1.0:
		v = v.normalized()

	# Ojo: en la pantalla, "arriba" es -y; en el mundo 3D, "hacia el fondo" es -Z.
	direccion = Vector3(v.x, 0.0, v.y)

	# Patear.
	var quiere_tiro := Input.is_key_pressed(KEY_SPACE)
	var quiere_pase := Input.is_key_pressed(KEY_SHIFT)
	if controles != null:
		quiere_tiro = quiere_tiro or controles.disparar
		quiere_pase = quiere_pase or controles.pasar

	if quiere_tiro:
		patear(17.0, 3.4, 0.0)
	elif quiere_pase:
		patear(10.0, 0.6, 0.0)
