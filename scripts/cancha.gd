extends Node2D
## La cancha vista desde arriba: césped, líneas, arcos y gradas con gente.
##
## Las medidas son casi las de una cancha de verdad:
##   100 m de largo x 64 m de ancho, área de 16,5 m, punto de penal a 11 m.
##   El arco sí es más ancho que el real (10 m en vez de 7,32 m) porque el
##   balón y los jugadores son grandes: si el arco fuera chiquito, el arquero
##   taparía todo y no se podría meter ni un gol.
##
## Coordenadas del mundo:
##   x = a lo largo de la cancha (de -50 a +50, los arcos en los extremos)
##   y = a lo ancho              (de -32 a +32, las bandas)
##   1 unidad = 1 metro

const LARGO := 100.0
const MITAD_LARGO := 50.0
const ANCHO := 64.0
const MITAD_ANCHO := 32.0
const ANCHO_PORTERIA := 10.0
const MITAD_PORTERIA := ANCHO_PORTERIA * 0.5
const LARGO_RED := 2.6

## El área grande: 16,5 m de fondo y 20 m para cada lado.
## El arquero NO puede salirse de aquí (es donde puede usar las manos).
const AREA_PROFUNDIDAD := 16.5
const AREA_MITAD_ANCHO := 20.0
## A qué distancia del arco está el punto de penal.
const PUNTO_PENAL := 11.0
## El área chica, la de adelante del arco.
const CHICA_PROFUNDIDAD := 6.0
const CHICA_MITAD_ANCHO := 11.0

const VERDE_CLARO := Color(0.26, 0.60, 0.27)
const VERDE_OSCURO := Color(0.21, 0.51, 0.22)
const VERDE_FUERA := Color(0.10, 0.26, 0.12)
const BLANCO := Color(0.95, 0.97, 0.97)
const PALO := Color(0.98, 0.99, 0.99)


func _ready() -> void:
	z_index = -10
	_crear_muros()


func _draw() -> void:
	_dibujar_alrededor()
	_dibujar_cesped()
	_dibujar_lineas()
	_dibujar_arcos()


# --------------------------------------------------------- dibujo del campo ---

func _dibujar_alrededor() -> void:
	# Verde exterior + gradas.
	draw_rect(Rect2(-64.0, -45.0, 128.0, 90.0), VERDE_FUERA)
	draw_rect(Rect2(-58.0, 34.0, 116.0, 8.0), Color(0.36, 0.37, 0.41))
	draw_rect(Rect2(-58.0, -42.0, 116.0, 8.0), Color(0.36, 0.37, 0.41))
	draw_rect(Rect2(-62.0, -34.0, 7.0, 68.0), Color(0.32, 0.33, 0.37))
	draw_rect(Rect2(55.0, -34.0, 7.0, 68.0), Color(0.32, 0.33, 0.37))

	# La gente de las gradas (se dibuja una sola vez, no cuesta nada).
	var azar := RandomNumberGenerator.new()
	azar.seed = 20260920
	for i in 1100:
		var p := Vector2.ZERO
		var zona := azar.randi_range(0, 3)
		match zona:
			0:
				p = Vector2(azar.randf_range(-57.0, 57.0), azar.randf_range(34.5, 41.5))
			1:
				p = Vector2(azar.randf_range(-57.0, 57.0), azar.randf_range(-41.5, -34.5))
			2:
				p = Vector2(azar.randf_range(-61.0, -55.5), azar.randf_range(-33.0, 33.0))
			_:
				p = Vector2(azar.randf_range(55.5, 61.0), azar.randf_range(-33.0, 33.0))
		draw_circle(p, 0.36, _color_gente(azar))


func _dibujar_cesped() -> void:
	var franjas := 16
	var ancho := LARGO / float(franjas)
	for i in franjas:
		var color := VERDE_CLARO if i % 2 == 0 else VERDE_OSCURO
		draw_rect(Rect2(-MITAD_LARGO + ancho * float(i), -MITAD_ANCHO, ancho, ANCHO), color)


func _dibujar_lineas() -> void:
	var grosor := 0.18
	# Borde de la cancha.
	draw_rect(Rect2(-MITAD_LARGO, -MITAD_ANCHO, LARGO, ANCHO), BLANCO, false, grosor)
	# Línea del medio.
	draw_line(Vector2(0.0, -MITAD_ANCHO), Vector2(0.0, MITAD_ANCHO), BLANCO, grosor)
	# Círculo central y punto.
	draw_arc(Vector2.ZERO, 9.15, 0.0, TAU, 72, BLANCO, grosor)
	draw_circle(Vector2.ZERO, 0.30, BLANCO)

	# Áreas de las dos porterías.
	for s in [-1.0, 1.0]:
		var x_borde: float = s * MITAD_LARGO
		var x_grande: float = s * (MITAD_LARGO - AREA_PROFUNDIDAD)
		draw_rect(_rect(x_grande, -AREA_MITAD_ANCHO, x_borde, AREA_MITAD_ANCHO), BLANCO, false, grosor)
		var x_chica: float = s * (MITAD_LARGO - CHICA_PROFUNDIDAD)
		draw_rect(_rect(x_chica, -CHICA_MITAD_ANCHO, x_borde, CHICA_MITAD_ANCHO), BLANCO, false, grosor)
		# Punto de penal.
		draw_circle(Vector2(s * (MITAD_LARGO - PUNTO_PENAL), 0.0), 0.30, BLANCO)


func _dibujar_arcos() -> void:
	for s in [-1.0, 1.0]:
		var x: float = s * MITAD_LARGO
		var x_red: float = x + s * LARGO_RED
		# La red (unas rayitas blancas).
		var color_red := Color(1.0, 1.0, 1.0, 0.45)
		draw_rect(_rect(x, -MITAD_PORTERIA, x_red, MITAD_PORTERIA), Color(1.0, 1.0, 1.0, 0.12))
		for i in 11:
			var y := -MITAD_PORTERIA + float(i) * (ANCHO_PORTERIA / 10.0)
			draw_line(Vector2(x, y), Vector2(x_red, y), color_red, 0.06)
		for i in 4:
			var xr: float = x + s * LARGO_RED * float(i) / 3.0
			draw_line(Vector2(xr, -MITAD_PORTERIA), Vector2(xr, MITAD_PORTERIA), color_red, 0.06)
		# Los palos (bien gruesos, para que se vean y reboten).
		draw_circle(Vector2(x, -MITAD_PORTERIA), 0.28, PALO)
		draw_circle(Vector2(x, MITAD_PORTERIA), 0.28, PALO)


## Arma un Rect2 con dos esquinas, sin importar el orden.
func _rect(x1: float, y1: float, x2: float, y2: float) -> Rect2:
	return Rect2(minf(x1, x2), minf(y1, y2), absf(x2 - x1), absf(y2 - y1))


## Devuelve el área grande de una portería.
## signo = -1 para el arco de la izquierda, +1 para el de la derecha.
func area_porteria(signo: float) -> Rect2:
	var x: float = signo * (MITAD_LARGO - AREA_PROFUNDIDAD)
	return Rect2(minf(x, signo * MITAD_LARGO), -AREA_MITAD_ANCHO, AREA_PROFUNDIDAD, AREA_MITAD_ANCHO * 2.0)


## Elige un color al azar para la gente de las gradas.
func _color_gente(azar: RandomNumberGenerator) -> Color:
	var opciones := [
		Color(0.20, 0.42, 0.85), Color(0.95, 0.95, 0.95), Color(0.95, 0.80, 0.15),
		Color(0.85, 0.20, 0.20), Color(0.20, 0.65, 0.35), Color(0.55, 0.30, 0.75),
		Color(0.15, 0.15, 0.20),
	]
	return opciones[azar.randi_range(0, opciones.size() - 1)]


# ------------------------------------------------------------------ muros ---

func _crear_muros() -> void:
	# Capa 1: son las paredes. El balón y los jugadores chocan con ellas.
	# Bandas (arriba y abajo).
	_muro(Vector2(0.0, MITAD_ANCHO + 0.5), Vector2(LARGO + 2.0, 1.0))
	_muro(Vector2(0.0, -MITAD_ANCHO - 0.5), Vector2(LARGO + 2.0, 1.0))

	for s in [-1.0, 1.0]:
		var x: float = s * (MITAD_LARGO + 0.5)
		var largo := MITAD_ANCHO - MITAD_PORTERIA
		var cy := MITAD_PORTERIA + largo * 0.5
		# Fondos, dejando libre la boca del arco.
		_muro(Vector2(x, cy), Vector2(1.0, largo))
		_muro(Vector2(x, -cy), Vector2(1.0, largo))
		# El bolsillo que hay detrás del arco.
		var x_fondo: float = s * (MITAD_LARGO + LARGO_RED)
		_muro(Vector2(x_fondo, 0.0), Vector2(1.0, ANCHO_PORTERIA + 1.0))
		var x_medio: float = s * (MITAD_LARGO + LARGO_RED * 0.5)
		_muro(Vector2(x_medio, MITAD_PORTERIA + 0.25), Vector2(LARGO_RED, 0.5))
		_muro(Vector2(x_medio, -MITAD_PORTERIA - 0.25), Vector2(LARGO_RED, 0.5))
		# Los palos del arco (rebotan).
		_muro(Vector2(s * MITAD_LARGO, MITAD_PORTERIA), Vector2(0.56, 0.56))
		_muro(Vector2(s * MITAD_LARGO, -MITAD_PORTERIA), Vector2(0.56, 0.56))


func _muro(centro: Vector2, tam: Vector2) -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.position = centro
	cuerpo.collision_layer = 1
	cuerpo.collision_mask = 0
	add_child(cuerpo)
	var forma := RectangleShape2D.new()
	forma.size = tam
	var choque := CollisionShape2D.new()
	choque.shape = forma
	cuerpo.add_child(choque)
