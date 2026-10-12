extends CanvasLayer
## Lo que se ve en pantalla durante los penales.
##
## Si tiras tú: te recuerda que apuntas con el joystick y que un toque en TIRO
## tira ya, y que mantenerlo cargado da más fuerza.
##
## Si tira el rival: te salen tres botones para elegir a dónde se tira TU
## arquero, con una cuenta atrás. Si no eliges en 4 segundos, se tira al azar.
##
## Va arriba al centro, que es el único hueco libre: abajo están el joystick y
## los botones de TIRO/PASE/CAMBIAR.

## Avisa a la escena del partido a qué zona se quiere tirar el arquero.
signal zona_elegida(zona: int)

## Cuánto tiempo hay para elegir. Si se acaba, se tira al azar.
const SEGUNDOS_DECISION := 4.0

const ZONAS := [-1, 0, 1]
const NOMBRES := {"-1": "ARRIBA", "0": "CENTRO", "1": "ABAJO"}

var _panel: VBoxContainer
var _titulo: Label
var _ayuda: Label
var _cuenta: Label
var _fila: HBoxContainer
var _botones: Array = []
var _zona := 0


func _ready() -> void:
	layer = 4

	_panel = VBoxContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.offset_top = 104.0
	_panel.offset_bottom = 104.0
	_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_theme_constant_override("separation", 6)
	add_child(_panel)

	_titulo = _etiqueta(26, Color(1, 1, 1))
	_ayuda = _etiqueta(17, Color(1, 1, 1, 0.85))
	_cuenta = _etiqueta(22, Color(1, 0.92, 0.6))

	_fila = HBoxContainer.new()
	_fila.alignment = BoxContainer.ALIGNMENT_CENTER
	_fila.add_theme_constant_override("separation", 14)
	_panel.add_child(_fila)

	for z in ZONAS:
		var boton := Button.new()
		boton.text = str(NOMBRES[str(z)])
		boton.custom_minimum_size = Vector2(150.0, 56.0)
		boton.add_theme_font_size_override("font_size", 20)
		boton.pressed.connect(_elegir.bind(int(z)))
		_fila.add_child(boton)
		_botones.append(boton)

	visible = false


## Muestra el cartel. `mi_turno` = true si el penal lo tiras tú.
func mostrar(mi_turno: bool) -> void:
	visible = true
	if mi_turno:
		_titulo.text = "¡TU PENAL!"
		_ayuda.text = "Apunta con el joystick (arriba / centro / abajo).\n" \
			+ "TIRO: un toque tira ya · mantener cargado da más fuerza (pero menos puntería)"
		_cuenta.text = ""
		_fila.visible = false
	else:
		_titulo.text = "PENAL DEL RIVAL"
		_ayuda.text = "Elige a dónde se tira tu arquero"
		_fila.visible = true
		_cuenta.text = ""


func ocultar() -> void:
	visible = false


## La zona que se está eligiendo (para que se vea resaltada).
func poner_zona(zona: int) -> void:
	_zona = zona
	for i in _botones.size():
		var b: Button = _botones[i]
		b.button_pressed = int(ZONAS[i]) == zona
		b.modulate = Color(1, 1, 1) if int(ZONAS[i]) == zona else Color(0.82, 0.82, 0.82)


## La cuenta atrás que queda para decidir.
func poner_cuenta(segundos: float) -> void:
	if _fila.visible:
		_cuenta.text = "te quedan %d segundos..." % int(ceilf(maxf(0.0, segundos)))


## Se acabó el tiempo o ya se decidió: se apagan los botones.
func cerrar_decision(texto: String) -> void:
	_fila.visible = false
	_cuenta.text = texto


func _elegir(zona: int) -> void:
	zona_elegida.emit(zona)


func _etiqueta(tam: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 6)
	_panel.add_child(lbl)
	return lbl
