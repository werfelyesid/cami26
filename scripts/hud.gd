extends CanvasLayer
## El marcador de arriba: los goles, el reloj, en qué parte del partido vamos,
## los mensajes grandes ("¡GOOOL!") y el botón de pausa.

## Aviso para la escena del partido: el jugador apretó pausa.
signal pausa_pedida

var marcador: Label
var reloj: Label
var franja: Label
var mensaje: Label
var barra_potencia: ProgressBar
var barra_texto: Label

var _espera_mensaje := 0.0


func _ready() -> void:
	# --- barra de arriba ---
	var barra := HBoxContainer.new()
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra.offset_top = 10.0
	barra.offset_bottom = 62.0
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	barra.add_theme_constant_override("separation", 30)
	add_child(barra)

	marcador = _etiqueta(34)
	marcador.text = "TÚ  0  -  0  RIVAL"
	barra.add_child(marcador)

	reloj = _etiqueta(34)
	reloj.text = "0:00"
	barra.add_child(reloj)

	# --- franja: en qué parte vamos ---
	franja = _etiqueta(20)
	franja.text = ""
	franja.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	franja.set_anchors_preset(Control.PRESET_TOP_WIDE)
	franja.offset_top = 64.0
	franja.offset_bottom = 96.0
	add_child(franja)

	# --- mensajes grandes en el centro ---
	mensaje = _etiqueta(90)
	mensaje.text = ""
	mensaje.visible = false
	mensaje.set_anchors_preset(Control.PRESET_CENTER)
	mensaje.grow_horizontal = Control.GROW_DIRECTION_BOTH
	mensaje.grow_vertical = Control.GROW_DIRECTION_BOTH
	mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(mensaje)

	# --- barra de potencia del tiro (abajo al centro) ---
	barra_texto = _etiqueta(24)
	barra_texto.text = "POTENCIA  1 / 10"
	barra_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	barra_texto.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	barra_texto.offset_left = -180.0
	barra_texto.offset_right = 180.0
	barra_texto.offset_top = -132.0
	barra_texto.offset_bottom = -100.0
	barra_texto.visible = false
	add_child(barra_texto)

	barra_potencia = ProgressBar.new()
	barra_potencia.min_value = 1.0
	barra_potencia.max_value = 10.0
	barra_potencia.value = 1.0
	barra_potencia.show_percentage = false
	barra_potencia.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	barra_potencia.offset_left = -170.0
	barra_potencia.offset_right = 170.0
	barra_potencia.offset_top = -92.0
	barra_potencia.offset_bottom = -62.0
	barra_potencia.visible = false
	add_child(barra_potencia)

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


## Actualiza los goles, el reloj y la franja de abajo.
func actualizar(goles_tuyos: int, goles_rival: int, segundos: float, fase: String, extra := "") -> void:
	marcador.text = "TÚ  %d  -  %d  RIVAL" % [goles_tuyos, goles_rival]
	var minutos := int(segundos) / 60
	var segs := int(segundos) % 60
	reloj.text = "%d:%02d" % [minutos, segs]
	franja.text = fase
	if extra != "":
		franja.text = "%s   ·   %s" % [fase, extra]


## Muestra un texto grande en el centro durante unos segundos.
func mostrar_mensaje(texto: String, segundos := 2.0) -> void:
	mensaje.text = texto
	mensaje.visible = true
	_espera_mensaje = segundos


## Muestra la barra de potencia (de 1 a 10). Con 0 se esconde.
func potencia(valor: float) -> void:
	var mostrar := valor > 0.05
	barra_potencia.visible = mostrar
	barra_texto.visible = mostrar
	if mostrar:
		var v := clampf(valor, 1.0, 10.0)
		barra_potencia.value = v
		barra_texto.text = "POTENCIA  %d / 10" % int(round(v))


func _pedir_pausa() -> void:
	pausa_pedida.emit()


func _etiqueta(tam: int) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 8)
	return lbl
