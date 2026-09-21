extends Control
## Los controles del celular: joystick a la izquierda y tres botones a la
## derecha (TIRO, PASE y CAMBIAR).
##
## Se dibujan a mano con círculos (draw_circle), así no hacen falta imágenes
## ni escenas.
##
## Truco: en project.godot está puesto
##   input_devices/pointing/emulate_touch_from_mouse = true
## así que en la compu el mouse se comporta como el dedo.
##
## OJO (nos pasó): el tamaño de la pantalla hay que preguntarlo con
## get_viewport_rect().size, NO con `size` en _ready(), porque en ese momento
## el Control todavía mide 0 y los botones quedan en cualquier parte.

const RADIO_JOY := 125.0
const RADIO_KNOB := 54.0
const R_TIRO := 92.0
const R_PASE := 62.0
const R_CAMBIAR := 56.0

## Cuánto está inclinado el joystick, de -1 a 1 en cada eje.
var mover := Vector2.ZERO
## true mientras se tiene apretado cada botón.
var disparar := false
var pasar := false
## Se pone en true al tocar CAMBIAR; el partido lo apaga cuando lo usa.
var cambiar := false

var _indice_joy := -1
var _base_joy := Vector2.ZERO
var _base_joy_quieta := Vector2.ZERO
var _knob := Vector2.ZERO
var _indice_tiro := -1
var _indice_pase := -1
var _indice_cambiar := -1
var _centro_tiro := Vector2.ZERO
var _centro_pase := Vector2.ZERO
var _centro_cambiar := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	recalcular()
	resized.connect(recalcular)
	get_viewport().size_changed.connect(recalcular)


## Coloca el joystick y los botones según el tamaño de la pantalla.
func recalcular() -> void:
	var s: Vector2 = get_viewport_rect().size
	if s.x < 10.0 or s.y < 10.0:
		return
	_base_joy_quieta = Vector2(RADIO_JOY + 65.0, s.y - RADIO_JOY - 85.0)
	if _indice_joy == -1:
		_base_joy = _base_joy_quieta
		_knob = Vector2.ZERO
	_centro_tiro = Vector2(s.x - R_TIRO - 50.0, s.y - R_TIRO - 65.0)
	_centro_pase = Vector2(s.x - R_TIRO * 2.0 - R_PASE - 100.0, s.y - R_PASE - 55.0)
	_centro_cambiar = Vector2(s.x - R_CAMBIAR - 34.0, s.y - R_TIRO * 2.0 - R_CAMBIAR - 120.0)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_al_tocar(t.index, t.position)
		else:
			_al_soltar(t.index)
		queue_redraw()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _indice_joy:
			var v := d.position - _base_joy
			if v.length() > RADIO_JOY:
				v = v.normalized() * RADIO_JOY
			_knob = v
			mover = v / RADIO_JOY
			queue_redraw()


func _al_tocar(indice: int, pos: Vector2) -> void:
	var s: Vector2 = get_viewport_rect().size

	# Primero los botones: son lo más importante.
	if _indice_tiro == -1 and pos.distance_to(_centro_tiro) <= R_TIRO * 1.3:
		_indice_tiro = indice
		disparar = true
		return
	if _indice_pase == -1 and pos.distance_to(_centro_pase) <= R_PASE * 1.4:
		_indice_pase = indice
		pasar = true
		return
	if _indice_cambiar == -1 and pos.distance_to(_centro_cambiar) <= R_CAMBIAR * 1.4:
		_indice_cambiar = indice
		cambiar = true
		return

	# Si no, es el joystick: sirve en toda la mitad izquierda de la pantalla.
	if _indice_joy == -1 and pos.x < s.x * 0.55 and pos.y > s.y * 0.25:
		_indice_joy = indice
		_base_joy = pos
		_knob = Vector2.ZERO
		mover = Vector2.ZERO


func _al_soltar(indice: int) -> void:
	if indice == _indice_tiro:
		_indice_tiro = -1
		disparar = false
	if indice == _indice_pase:
		_indice_pase = -1
		pasar = false
	if indice == _indice_cambiar:
		_indice_cambiar = -1
	if indice == _indice_joy:
		_indice_joy = -1
		_knob = Vector2.ZERO
		mover = Vector2.ZERO
		_base_joy = _base_joy_quieta


func _draw() -> void:
	# --- joystick ---
	draw_circle(_base_joy, RADIO_JOY, Color(1, 1, 1, 0.12))
	draw_arc(_base_joy, RADIO_JOY, 0.0, TAU, 48, Color(1, 1, 1, 0.45), 3.0)
	draw_circle(_base_joy + _knob, RADIO_KNOB, Color(1, 1, 1, 0.38))
	draw_arc(_base_joy + _knob, RADIO_KNOB, 0.0, TAU, 32, Color(1, 1, 1, 0.75), 3.0)

	# --- botones ---
	_dibujar_boton(_centro_tiro, R_TIRO, "TIRO", Color(0.95, 0.35, 0.25), disparar)
	_dibujar_boton(_centro_pase, R_PASE, "PASE", Color(0.25, 0.55, 0.95), pasar)
	_dibujar_boton(_centro_cambiar, R_CAMBIAR, "CAMBIAR", Color(0.95, 0.80, 0.15), _indice_cambiar != -1)


func _dibujar_boton(centro: Vector2, radio: float, texto: String, color: Color, apretado: bool) -> void:
	var relleno := color
	relleno.a = 0.78 if apretado else 0.42
	draw_circle(centro, radio, relleno)
	draw_arc(centro, radio, 0.0, TAU, 48, Color(1, 1, 1, 0.85 if apretado else 0.55), 4.0)

	var fuente := ThemeDB.fallback_font
	var tam := int(radio * 0.40)
	var ancho := radio * 2.0
	draw_string(fuente, Vector2(centro.x - radio, centro.y + float(tam) * 0.36), texto,
		HORIZONTAL_ALIGNMENT_CENTER, ancho, tam, Color(1, 1, 1, 0.95))
