extends Control
## Una cancha chiquita, dibujada, para la pantalla de la plantilla.
##
## Es solo decorativa: muestra el césped, las líneas, el círculo del medio y las
## áreas, para que los huecos de los jugadores se vean "sobre la cancha".

const VERDE := Color(0.13, 0.36, 0.18)
const VERDE_CLARO := Color(0.16, 0.42, 0.21)
const LINEA := Color(0.92, 0.96, 0.92, 0.55)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w := size.x
	var h := size.y

	# El césped, con franjas.
	draw_rect(Rect2(0.0, 0.0, w, h), VERDE)
	var franjas := 6
	for i in franjas:
		if i % 2 == 0:
			draw_rect(Rect2(0.0, h * float(i) / float(franjas), w, h / float(franjas)), VERDE_CLARO)

	# El borde y la línea del medio.
	var grosor := 2.5
	draw_rect(Rect2(6.0, 6.0, w - 12.0, h - 12.0), LINEA, false, grosor)
	draw_line(Vector2(6.0, h * 0.5), Vector2(w - 6.0, h * 0.5), LINEA, grosor)

	# El círculo del medio y el punto.
	var radio := minf(w, h) * 0.11
	draw_arc(Vector2(w * 0.5, h * 0.5), radio, 0.0, TAU, 48, LINEA, grosor)
	draw_circle(Vector2(w * 0.5, h * 0.5), 2.5, LINEA)

	# Las dos áreas.
	var ancho_area := w * 0.42
	var alto_area := h * 0.11
	draw_rect(Rect2(w * 0.5 - ancho_area * 0.5, 6.0, ancho_area, alto_area), LINEA, false, grosor)
	draw_rect(Rect2(w * 0.5 - ancho_area * 0.5, h - 6.0 - alto_area, ancho_area, alto_area), LINEA, false, grosor)
