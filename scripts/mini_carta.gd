class_name MiniCarta
extends Control
## Una carta pequeñita, para la pantalla de la plantilla.
##
## Sirve para dos cosas:
##   - Los HUECOS de la cancha: se ve el promedio, el puesto y el nombre.
##   - La LISTA de tus cartas: además se ven las 6 estadísticas (para elegir bien).
##
## También es la que se encarga de ARRASTRAR y SOLTAR: es la pieza que se lleva
## la carta de la lista a un hueco. La pantalla (plantilla.gd) es la que decide
## si se puede soltar dónde quieres.

## La carta pequeñita que se ve pegada al dedo mientras arrastras.
const TAM_PREVIO := Vector2(78.0, 107.0)

## Los datos de la carta (vacío = hueco libre).
var carta: Dictionary = {}
## Su posición en el inventario (-1 = libre).
var indice := -1
## Dónde está esta carta: "lista", "titular" o "banquillo".
var zona := "lista"
## Qué número de hueco es (en los titulares, 0 es el arco).
var posicion := 0
## Lo que se escribe cuando el hueco está libre ("ARQ", "DEF"...).
var etiqueta := ""
## En la lista se muestran también las 6 estadísticas.
var con_estadisticas := false
## La pantalla, que sabe si una carta se puede soltar en un hueco.
var pantalla = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


## Pone una carta (o la quita, con {}).
func poner(datos: Dictionary, indice_inv: int) -> void:
	carta = datos
	indice = indice_inv
	queue_redraw()


func vaciar() -> void:
	carta = {}
	indice = -1
	queue_redraw()


func _draw() -> void:
	if carta.is_empty():
		_dibujar_vacio()
	else:
		_dibujar_carta()


func _dibujar_vacio() -> void:
	var caja := Rect2(2.0, 2.0, size.x - 4.0, size.y - 4.0)
	draw_rect(caja, Color(1, 1, 1, 0.06))
	draw_rect(caja, Color(1, 1, 1, 0.28), false, 2.0)
	if etiqueta != "":
		var fuente := ThemeDB.fallback_font
		var tam := int(size.y * 0.22)
		draw_string(fuente, Vector2(0.0, size.y * 0.60), etiqueta,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, tam, Color(1, 1, 1, 0.55))


func _dibujar_carta() -> void:
	# La piel (bronce, plata, oro o especial) de fondo.
	var piel: Texture2D = load(Cartas.piel(carta))
	if piel != null:
		draw_texture_rect(piel, Rect2(Vector2.ZERO, size), false)

	var nivel := str(carta.get("nivel", ""))
	var claro: bool = nivel == "oro" or nivel == "plata"
	var color_texto := Color(0.12, 0.12, 0.14) if claro else Color(1, 1, 1)
	var fuente := ThemeDB.fallback_font
	var nombre := str(carta.get("nombre", "")).to_upper()
	var equipo := str(carta.get("equipo", ""))

	if con_estadisticas:
		# --- Fila de la lista: promedio, nombre, club y las 6 estadísticas ---
		draw_string(fuente, Vector2(size.x * 0.03, size.y * 0.34), str(int(carta.get("ovr", 0))),
			HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.15, int(size.y * 0.30), color_texto)
		draw_string(fuente, Vector2(size.x * 0.03, size.y * 0.49), str(carta.get("puesto", "")),
			HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.15, int(size.y * 0.15), color_texto)
		draw_string(fuente, Vector2(size.x * 0.20, size.y * 0.30), nombre,
			HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.79, int(size.y * 0.20), color_texto)
		draw_string(fuente, Vector2(size.x * 0.20, size.y * 0.47), equipo,
			HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.79, int(size.y * 0.145),
			Color(color_texto.r, color_texto.g, color_texto.b, 0.78))
		_dibujar_estadisticas(color_texto)
		return

	# --- Carta de un hueco de la cancha: promedio y puesto arriba, nombre abajo ---
	draw_string(fuente, Vector2(size.x * 0.10, size.y * 0.20), str(int(carta.get("ovr", 0))),
		HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.55, int(size.y * 0.16), color_texto)
	draw_string(fuente, Vector2(size.x * 0.10, size.y * 0.30), str(carta.get("puesto", "")),
		HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.55, int(size.y * 0.085), color_texto)
	draw_string(fuente, Vector2(0.0, size.y * 0.80), nombre,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, int(size.y * 0.085), color_texto)
	draw_string(fuente, Vector2(0.0, size.y * 0.89), equipo,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, int(size.y * 0.062),
		Color(color_texto.r, color_texto.g, color_texto.b, 0.8))


## Las 6 estadísticas, en un renglón de 6 columnas (solo en la lista).
func _dibujar_estadisticas(color_texto: Color) -> void:
	var fuente := ThemeDB.fallback_font
	var pares := Cartas.estadisticas(str(carta.get("puesto", "")))
	var ancho := size.x / float(pares.size())
	var i := 0
	for par in pares:
		var clave: String = par[0]
		var x := ancho * float(i)
		var tam := int(size.y * 0.16)
		draw_string(fuente, Vector2(x + 2.0, size.y * 0.72), str(par[1]),
			HORIZONTAL_ALIGNMENT_LEFT, ancho * 0.52, int(size.y * 0.13),
			Color(color_texto.r, color_texto.g, color_texto.b, 0.72))
		draw_string(fuente, Vector2(x + ancho * 0.52, size.y * 0.72), str(int(carta.get(clave, 0))),
			HORIZONTAL_ALIGNMENT_LEFT, ancho * 0.48, tam, color_texto)
		i += 1


# ------------------------------------------------- arrastrar y soltar ---

## Empieza el arrastre: se agarra ESTA carta.
func _get_drag_data(_pos: Vector2) -> Variant:
	var datos := datos_arrastre()
	if datos.is_empty():
		return null
	# Lo que se ve pegado al dedo mientras se arrastra.
	var vista := TextureRect.new()
	vista.texture = load(Cartas.piel(carta))
	# OJO: el previo NO va dentro de un contenedor, así que nadie le pone el
	# tamaño. Sin estas dos líneas se dibuja del tamaño de la imagen (512x704)
	# y tapa media pantalla mientras arrastras.
	vista.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vista.stretch_mode = TextureRect.STRETCH_SCALE
	vista.custom_minimum_size = TAM_PREVIO
	vista.size = TAM_PREVIO
	vista.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(vista)
	return datos


## Lo que se lleva el arrastre (aparte, para poder probarlo sin arrastrar).
func datos_arrastre() -> Dictionary:
	if carta.is_empty() or pantalla == null:
		return {}
	return {"indice": indice, "zona": zona, "pos": posicion, "carta": carta}


## Un toque: se lo contamos a la pantalla (sirve para tocar y tocar).
func _gui_input(evento: InputEvent) -> void:
	if pantalla == null:
		return
	var pulsado := false
	if evento is InputEventMouseButton:
		var raton := evento as InputEventMouseButton
		pulsado = raton.pressed and raton.button_index == MOUSE_BUTTON_LEFT
	elif evento is InputEventScreenTouch:
		pulsado = (evento as InputEventScreenTouch).pressed
	if pulsado:
		pantalla.tocar(self)


func _can_drop_data(_pos: Vector2, datos: Variant) -> bool:
	if pantalla == null:
		return false
	return pantalla.puede_soltar(datos, self)


func _drop_data(_pos: Vector2, datos: Variant) -> void:
	if pantalla != null:
		pantalla.soltar(datos, self)
