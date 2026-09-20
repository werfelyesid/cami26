extends CanvasLayer
## El marcador de arriba: los goles, el reloj, los mensajes grandes
## ("¡GOOOL!") y el botón de pausa.

## Aviso para la escena del partido: el jugador apretó pausa.
signal pausa_pedida

var marcador: Label
var reloj: Label
var mensaje: Label

var _espera_mensaje := 0.0


func _ready() -> void:
	# --- barra de arriba ---
	var barra := HBoxContainer.new()
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra.offset_top = 12.0
	barra.offset_bottom = 74.0
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	barra.add_theme_constant_override("separation", 36)
	add_child(barra)

	marcador = _etiqueta(38)
	marcador.text = "TÚ  0  -  0  RIVAL"
	barra.add_child(marcador)

	reloj = _etiqueta(38)
	reloj.text = "0:00"
	barra.add_child(reloj)

	# --- mensajes grandes en el centro ---
	mensaje = _etiqueta(96)
	mensaje.text = ""
	mensaje.visible = false
	mensaje.set_anchors_preset(Control.PRESET_CENTER)
	mensaje.grow_horizontal = Control.GROW_DIRECTION_BOTH
	mensaje.grow_vertical = Control.GROW_DIRECTION_BOTH
	mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(mensaje)

	# --- botón de pausa, arriba a la derecha ---
	var pausa := Button.new()
	pausa.text = "II"
	pausa.custom_minimum_size = Vector2(64.0, 64.0)
	pausa.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pausa.offset_left = -78.0
	pausa.offset_top = 12.0
	pausa.offset_right = -14.0
	pausa.offset_bottom = 76.0
	pausa.add_theme_font_size_override("font_size", 26)
	pausa.pressed.connect(_pedir_pausa)
	add_child(pausa)


func _process(delta: float) -> void:
	if _espera_mensaje > 0.0:
		_espera_mensaje -= delta
		if _espera_mensaje <= 0.0:
			mensaje.visible = false


## Actualiza los goles y el reloj.
func actualizar(goles_tuyos: int, goles_rival: int, segundos: float) -> void:
	marcador.text = "TÚ  %d  -  %d  RIVAL" % [goles_tuyos, goles_rival]
	var minutos := int(segundos) / 60
	var segs := int(segundos) % 60
	reloj.text = "%d:%02d" % [minutos, segs]


## Muestra un texto grande en el centro durante unos segundos.
func mostrar_mensaje(texto: String, segundos := 2.0) -> void:
	mensaje.text = texto
	mensaje.visible = true
	_espera_mensaje = segundos


func _pedir_pausa() -> void:
	pausa_pedida.emit()


func _etiqueta(tam: int) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 8)
	return lbl
