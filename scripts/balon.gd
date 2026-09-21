extends CharacterBody2D
## El balón del partido: rueda, se frena y rebota contra los muros y los palos.
##
## Está bien grandote para que se vea en el celular.
##
## Capas de choque (para que no se enrede con los jugadores):
##   capa 1 = muros y palos   |   capa 2 = jugadores   |   capa 4 = balón
## El balón choca SOLO con la capa 1: a los jugadores los empuja el regate,
## que se calcula a mano en futbolista.gd.

## Radio en metros (un balón de verdad mide 0,11 m... ¡este es de mentira!).
const RADIO := 1.0
const FRENADO := 1.1          # cuánto se va frenando por segundo
const REBOTE := 0.72          # con cuánta fuerza sale después de chocar
const VELOCIDAD_MAXIMA := 24.0

## Hacia dónde y qué tan rápido va (en metros por segundo).
var velocidad := Vector2.ZERO
## Si el arquero lo tiene en las manos, no se mueve solo.
var agarrado := false
## Quién fue el último que lo tocó. Sirve para saber de quién es el saque
## cuando el balón se va afuera (saca el equipo contrario, como de verdad).
var ultimo_toque = null


func _ready() -> void:
	collision_layer = 4
	# Capa 8: solo choca con los palos y las redes. Las líneas de la cancha
	# (capa 1) no lo frenan, así que se puede ir afuera.
	collision_mask = 8
	var forma := CircleShape2D.new()
	forma.radius = RADIO
	var choque := CollisionShape2D.new()
	choque.shape = forma
	add_child(choque)


func _physics_process(delta: float) -> void:
	if agarrado:
		queue_redraw()
		return

	if velocidad.length() > VELOCIDAD_MAXIMA:
		velocidad = velocidad.normalized() * VELOCIDAD_MAXIMA

	# Se mueve en dos pasitos chiquitos: así no se atraviesa los palos.
	for i in 2:
		var choque := move_and_collide(velocidad * delta * 0.5)
		if choque != null:
			velocidad = velocidad.bounce(choque.get_normal()) * REBOTE

	# Se va frenando.
	velocidad = velocidad.lerp(Vector2.ZERO, clampf(FRENADO * delta, 0.0, 1.0))
	if velocidad.length() < 0.25:
		velocidad = Vector2.ZERO

	# La rotación es solo para que se vea que rueda.
	rotation += velocidad.length() * delta * 1.2
	queue_redraw()


## Deja el balón quietecito en un lugar (saque de centro o penal).
func reiniciar(posicion: Vector2) -> void:
	velocidad = Vector2.ZERO
	agarrado = false
	position = posicion
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0.14, 0.24), RADIO, Color(0.0, 0.0, 0.0, 0.25))   # sombra
	draw_circle(Vector2.ZERO, RADIO, Color(0.97, 0.97, 0.95))
	draw_arc(Vector2.ZERO, RADIO, 0.0, TAU, 36, Color(0.15, 0.15, 0.18), 0.10)
	# Las manchas: al girar el balón, parece rodar.
	draw_circle(Vector2(-RADIO * 0.42, -RADIO * 0.30), RADIO * 0.30, Color(0.12, 0.12, 0.15))
	draw_circle(Vector2(RADIO * 0.40, -RADIO * 0.36), RADIO * 0.24, Color(0.12, 0.12, 0.15))
	draw_circle(Vector2(RADIO * 0.05, RADIO * 0.45), RADIO * 0.26, Color(0.12, 0.12, 0.15))
	draw_circle(Vector2(-RADIO * 0.30, RADIO * 0.40), RADIO * 0.18, Color(0.12, 0.12, 0.15))
	draw_circle(Vector2(RADIO * 0.52, RADIO * 0.10), RADIO * 0.16, Color(0.12, 0.12, 0.15))
