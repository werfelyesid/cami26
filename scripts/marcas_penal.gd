extends Node2D
## Dibuja las TRES ZONAS del arco durante los penales.
##
## Sirven para apuntar: la zona elegida se ve encendida. También se puede
## mostrar la zona hacia la que se tiró el arquero, para que se entienda por qué
## atajó (o por qué no).
##
## El arco, visto desde arriba, va de un lado al otro de la pantalla (arriba y
## abajo), así que las tres zonas son: arriba, centro y abajo.

const MITAD_LARGO := 60.0
## A qué altura (en fracción de la mitad del arco) queda cada zona.
const FRACCION := 0.62
## Qué tan adentro de la cancha se dibuja cada zona.
const PROFUNDIDAD := 3.6

## En false no se dibuja nada (durante el partido normal).
var activo := false
## +1 para el arco de la derecha, -1 para el de la izquierda.
var lado := 1.0
## La mitad del arco que hay ahora (en los penales es más ancho).
var mitad := 5.0
## La zona elegida: -1 arriba, 0 centro, +1 abajo.
var zona := 0
## Si está en true, se resalta también la zona del arquero.
var mostrar_zona_arquero := false
var zona_arquero := 0


func _ready() -> void:
	z_index = 5


## OJO: un nodo que se dibuja a mano (con _draw) no se vuelve a pintar solo.
## Hay que pedirlo con queue_redraw() cada vez que cambia lo que dibuja; si no,
## dibuja una sola vez (cuando todavía estaba apagado) y nunca se ve nada.
func _process(_delta: float) -> void:
	if activo:
		queue_redraw()


func _draw() -> void:
	if not activo:
		return
	var alto := mitad * FRACCION
	var x_borde := lado * MITAD_LARGO
	for z in [-1, 0, 1]:
		var rect := Rect2(
			minf(x_borde, x_borde - lado * PROFUNDIDAD),
			float(z) * alto - alto * 0.5,
			PROFUNDIDAD, alto)
		var elegida: bool = z == zona
		# La zona elegida se ve bien fuerte; las otras dos, suaves pero visibles
		# (si se ven muy poquito, el jugador no sabe que existen).
		var color := Color(1.0, 0.94, 0.35, 0.50 if elegida else 0.20)
		draw_rect(rect, color)
		draw_rect(rect, Color(1, 1, 1, 0.75 if elegida else 0.30), false, 0.20 if elegida else 0.14)
		# La zona del arquero, con una línea celeste bien visible.
		if mostrar_zona_arquero and z == zona_arquero:
			draw_rect(rect, Color(0.35, 0.85, 1.0, 0.85), false, 0.32)
