class_name Tarjeta
extends Control
## Una carta de jugador.
##
## La "piel" (el fondo con el borde y el reflejo) es una imagen PNG que se
## genera con herramientas/generar_cartas.py. Aquí encima se escriben los datos:
## el OVR y el puesto arriba a la izquierda, el avatar en el medio, el nombre,
## el club y las 4 estadísticas abajo.
##
## Se coloca todo con anclas (proporciones), así la carta se puede hacer
## grande o chica y todo queda en su sitio.

var datos: Dictionary = {}

var _color_club := Color.WHITE
var _color_texto := Color.WHITE


## Arma la carta con los datos de un jugador.
func configurar(carta: Dictionary, tamano := Vector2(240.0, 330.0)) -> void:
	datos = carta
	custom_minimum_size = tamano
	size = tamano
	_color_club = Cartas.color_de(str(carta.get("color1", "#ffffff")))
	_color_texto = _color_de_texto()
	_armar()
	queue_redraw()


## El círculo del club que va detrás del avatar.
func _draw() -> void:
	if datos.is_empty():
		return
	var centro := Vector2(size.x * 0.5, size.y * 0.44)
	var radio := size.x * 0.205
	draw_circle(centro, radio, Color(_color_club.r, _color_club.g, _color_club.b, 0.95))
	draw_arc(centro, radio, 0.0, TAU, 48, Color(1, 1, 1, 0.35), maxf(1.0, size.x * 0.008))
	# Una franja abajo con el segundo color del club, para que se reconozca.
	var franja := size.y * 0.016
	draw_rect(Rect2(0.0, size.y - franja, size.x, franja),
		Cartas.color_de(str(datos.get("color2", "#111111"))))


func _armar() -> void:
	for hijo in get_children():
		hijo.queue_free()
	if datos.is_empty():
		return

	var fondo := TextureRect.new()
	fondo.texture = load(Cartas.piel(datos))
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_SCALE
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	var avatar := TextureRect.new()
	avatar.texture = load(Cartas.AVATAR)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_colocar(avatar, 0.30, 0.255, 0.40, 0.30)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(avatar)

	# Arriba a la izquierda: el promedio (OVR) y debajo el puesto.
	_etiqueta(str(int(datos.get("ovr", 0))), 0.055, 0.030, 0.30, 0.140,
		size.y * 0.118, _color_texto, HORIZONTAL_ALIGNMENT_CENTER)
	_etiqueta(str(datos.get("puesto", "")), 0.055, 0.152, 0.30, 0.058,
		size.y * 0.050, _color_texto, HORIZONTAL_ALIGNMENT_CENTER)

	# El nombre y el club.
	_etiqueta(str(datos.get("nombre", "")).to_upper(), 0.05, 0.628, 0.90, 0.068,
		size.y * 0.058, _color_texto, HORIZONTAL_ALIGNMENT_CENTER)
	_etiqueta(str(datos.get("equipo", "")), 0.05, 0.692, 0.90, 0.048,
		size.y * 0.040, Color(_color_texto.r, _color_texto.g, _color_texto.b, 0.82),
		HORIZONTAL_ALIGNMENT_CENTER)

	# Las 4 estadísticas, en renglones.
	var alto_fila := 0.052
	var y := 0.752
	for par in Cartas.ESTADISTICAS:
		var clave: String = par[0]
		_etiqueta(str(par[1]), 0.085, y, 0.26, alto_fila,
			size.y * 0.050, Color(_color_texto.r, _color_texto.g, _color_texto.b, 0.80),
			HORIZONTAL_ALIGNMENT_LEFT)
		_etiqueta(str(int(datos.get(clave, 0))), 0.55, y, 0.365, alto_fila,
			size.y * 0.054, _color_texto, HORIZONTAL_ALIGNMENT_RIGHT)
		y += alto_fila


## Coloca un Control con anclas por proporciones (0 a 1).
func _colocar(nodo: Control, x: float, y: float, w: float, h: float) -> void:
	nodo.anchor_left = x
	nodo.anchor_top = y
	nodo.anchor_right = x + w
	nodo.anchor_bottom = y + h
	nodo.offset_left = 0.0
	nodo.offset_top = 0.0
	nodo.offset_right = 0.0
	nodo.offset_bottom = 0.0


func _etiqueta(texto: String, x: float, y: float, w: float, h: float,
		tam: float, color: Color, alineacion: int) -> void:
	var lbl := Label.new()
	lbl.text = texto
	lbl.horizontal_alignment = alineacion
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_colocar(lbl, x, y, w, h)
	lbl.add_theme_font_size_override("font_size", int(maxf(9.0, tam)))
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.30))
	lbl.add_theme_constant_override("outline_size", int(maxf(0.0, size.y * 0.005)))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)


## El texto se ve oscuro sobre las cartas claras (plata y oro) y claro sobre
## las oscuras (bronce y especial), para que siempre se lea bien.
func _color_de_texto() -> Color:
	if bool(datos.get("especial", false)):
		return Color(1, 1, 1)
	match str(datos.get("nivel", "bronce")):
		"oro":
			return Color(0.16, 0.11, 0.02)
		"plata":
			return Color(0.12, 0.14, 0.17)
		_:
			return Color(1, 1, 1)
