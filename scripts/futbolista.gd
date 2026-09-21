extends CharacterBody2D
## Un jugador de fútbol, de cualquiera de los dos equipos.
##
## El mismo script sirve para todos:
##   - Si `controlado` es true -> lo manejas tú (joystick del celular o teclado).
##   - Si es false             -> juega solo, según su ROL y su NÚMERO.
##
## Los números son los del fútbol de verdad:
##   1 = arquero · 2,3,4,5 = defensas · 6,8 = medios · 9,10,11 = delanteros

const Balon = preload("res://scripts/balon.gd")

## Los roles. El partido los pone con estos números: 0, 1, 2, 3.
enum Rol { ARQUERO, DEFENSA, MEDIO, DELANTERO }

## Cuánto más grandes se ven (2.0 = el doble).
## Ojo: si se agrandan mucho, el balón ya no cabe entre el arquero y el palo.
const ESCALA := 2.0
## Radio con el que se dibuja.
const RADIO := 0.70 * ESCALA
## Radio con el que choca (un poco más chicó, para poder acercarse al balón).
const RADIO_CHOQUE := 0.85
## Las manitas del arquero: un tercio de su tamaño.
const MANITA := RADIO / 3.0

# --- Quién es ---
var numero := 9
var rol := Rol.MEDIO
var equipo := 0                      # 0 = tu equipo, 1 = el rival
var controlado := false
var color_camiseta := Color(0.15, 0.35, 0.9)
var color_numero := Color(1, 1, 1)
var color_piel := Color(0.85, 0.64, 0.47)
var color_pelo := Color(0.14, 0.10, 0.08)

# --- Dónde juega ---
var arco_propio := -30.0             # el arco que defiende
var arco_rival := 30.0               # el arco donde ataca
var formacion := Vector2.ZERO        # su puesto en la cancha
var area_propia := Rect2()           # el área donde puede estar el arquero

# --- Cómo juega ---
var velocidad := 7.5
var aceleracion := 45.0
var en_penal := false                # true = está por tirar un penal (apunta con el joystick)
var quieto := false                  # true = no se mueve ni un dedo (lo usa el arquero en los penales)
var sacando := false                 # true = está por hacer un saque (no camina, solo saca)
var saque_con_mano := false          # el saque de banda se hace con las manos
var _tiempo_saque := 0.0

# --- Potencia del tiro y esprint ---
var potencia := 0.0                  # de 1 a 10: la fuerza que estás cargando
var cargando := false                # true mientras tienes apretado TIRO
var factor_velocidad := 1.0          # 1 = normal, 1.35 = esprintando
var _espera_especial := 0.0          # para no repetir la barrida del arquero
var _quiere_agarrar := false         # el arquero que manejas ataja si aprietas TIRO

# --- Lo que le dice el partido en cada cuadro ---
var balon = null
var todos := []                      # todos los jugadores del partido
var dueno_balon = null               # quién tiene el balón ahora
var soy_mas_cercano := false         # el más cercano de MI equipo al balón
var puede_tocar := false             # si es el dueño, puede ir empujando el balón
var sin_tocar := false               # durante un saque del otro equipo: no la toca y se aleja
var controles = null                 # los controles táctiles (si lo controlas tú)

var direccion := Vector2.ZERO
var hacia := Vector2.UP

var _espera_pateo := 0.0
var _agarrando := false              # el arquero tiene el balón en las manos
var _tiempo_agarre := 0.0
var _alcance_atajada := 0.0


func _ready() -> void:
	# Capa 2: jugadores. Chocan con la capa 1 (las líneas de la cancha, que para
	# ellos son paredes) y con la 8 (palos y redes).
	collision_layer = 2
	collision_mask = 9
	var forma := CircleShape2D.new()
	forma.radius = RADIO_CHOQUE
	var choque := CollisionShape2D.new()
	choque.shape = forma
	add_child(choque)
	_alcance_atajada = RADIO + MANITA + Balon.RADIO
	queue_redraw()


func _physics_process(delta: float) -> void:
	_espera_pateo = maxf(0.0, _espera_pateo - delta)
	_espera_especial = maxf(0.0, _espera_especial - delta)
	factor_velocidad = 1.0

	# Si le toca sacar, se queda quieto y saca (con las manos o con el pie).
	if sacando:
		_sacar(delta)
		_mover(delta)
		queue_redraw()
		return

	if controlado:
		_leer_entrada(delta)
	elif rol != Rol.ARQUERO and _agarrando:
		direccion = Vector2.ZERO
	else:
		_pensar()

	_mover(delta)
	if rol == Rol.ARQUERO:
		_atajar(delta)
	else:
		_tocar_balon(delta)
		_bloquear_balon()
	queue_redraw()


## Mueve al jugador y decide hacia dónde mira.
func _mover(delta: float) -> void:
	if quieto:
		direccion = Vector2.ZERO
		velocity = Vector2.ZERO
	velocity = velocity.move_toward(direccion.normalized() * velocidad * factor_velocidad, aceleracion * delta)
	move_and_slide()

	var signo := signf(arco_rival - arco_propio)

	if rol == Rol.ARQUERO:
		# El arquero nunca se sale de su área (ahí es donde puede usar las manos).
		position.x = clampf(position.x, area_propia.position.x + RADIO_CHOQUE, area_propia.end.x - RADIO_CHOQUE)
		position.y = clampf(position.y, area_propia.position.y + RADIO_CHOQUE, area_propia.end.y - RADIO_CHOQUE)
		# Siempre mira hacia la cancha.
		rotation = angulo_hacia(Vector2(signo, 0.0))
	else:
		if velocity.length() > 0.7:
			rotation = lerp_angle(rotation, angulo_hacia(velocity), minf(1.0, 14.0 * delta))

	# La "naricita" del dibujo apunta hacia arriba (-y): por eso se lee así.
	hacia = Vector2.UP.rotated(rotation)


## El regate: el dueño del balón lo va empujando por delante.
func _tocar_balon(_delta: float) -> void:
	if balon == null or not puede_tocar or sin_tocar:
		return
	var d: Vector2 = balon.position - position
	var distancia := d.length()
	var alcance: float = RADIO + Balon.RADIO + 0.5
	if distancia > alcance or distancia < 0.01:
		return
	if hacia.dot(d / distancia) < 0.2:
		return
	balon.ultimo_toque = self
	# Con el balón en los pies se corre un poquito más lento (es realista).
	balon.velocidad = balon.velocidad.lerp(hacia * maxf(velocidad * 0.88, 5.0), 0.35)


## Tapar la pateada: si el balón viene hacia mí y no soy el dueño, rebota en mí.
func _bloquear_balon() -> void:
	if balon == null or puede_tocar or balon.agarrado or sin_tocar:
		return
	var d: Vector2 = balon.position - position
	var distancia := d.length()
	if distancia > RADIO + Balon.RADIO or distancia < 0.01:
		return
	var normal := d / distancia
	var v: Vector2 = balon.velocidad
	if v.dot(normal) > -1.0:
		return                       # el balón no viene hacia mí
	balon.ultimo_toque = self
	balon.velocidad = v.bounce(normal) * 0.55 + normal * 2.0


## El arquero: ataja el balón con las manos y después lo despeja.
func _atajar(delta: float) -> void:
	if balon == null:
		return

	if _agarrando:
		# El balón queda en las manos: lo lleva adelante.
		balon.position = position + hacia * (RADIO + Balon.RADIO * 0.4)
		balon.velocidad = Vector2.ZERO

		# Si lo manejas tú, lo sueltas cuando patees (no se suelta solo).
		if controlado:
			return

		_tiempo_agarre -= delta
		if _tiempo_agarre <= 0.0:
			_agarrando = false
			balon.agarrado = false
			# Antes de soltarlo, busca un compañero (¡también pasa el balón!).
			var companero = _companero_para_pasar()
			if companero != null:
				hacia = (companero.position - position).normalized()
			else:
				# Sin nadie a la vista: la revienta hacia el medio de la cancha.
				hacia = Vector2(signf(arco_rival - arco_propio), 0.0)
			rotation = angulo_hacia(hacia)
			balon.ultimo_toque = self
			balon.velocidad = hacia * 20.0
		return

	var d: Vector2 = balon.position - position
	# El arquero que manejas tú solo ataja cuando aprietas TIRO.
	if controlado and not _quiere_agarrar:
		return
	if d.length() <= _alcance_atajada and area_propia.has_point(balon.position):
		balon.ultimo_toque = self
		if balon.velocidad.length() > 13.0:
			# Pelotazo fuerte: el arquero la rechaza y el balón REBOTA.
			var normal := d.normalized()
			balon.velocidad = balon.velocidad.bounce(normal) * 0.5 + normal * 5.0
			_espera_pateo = 0.3
		else:
			# Pelota suave: la agarra con las manos.
			_agarrando = true
			balon.agarrado = true
			_tiempo_agarre = 1.0


## Patea el balón. Devuelve true si lo alcanzó a tocar.
func patear(fuerza: float, giro_minimo := 0.15) -> bool:
	if balon == null or _espera_pateo > 0.0 or sin_tocar:
		return false
	var d: Vector2 = balon.position - position
	var distancia := d.length()
	if distancia > RADIO + Balon.RADIO + 1.0 or distancia < 0.01:
		return false
	if hacia.dot(d / distancia) < giro_minimo:
		return false
	_espera_pateo = 0.35
	if _agarrando:
		_agarrando = false
		balon.agarrado = false
	balon.ultimo_toque = self
	balon.velocidad = hacia * fuerza
	return true


# ------------------------------------------------------- si lo manejas tú ---

func _leer_entrada(delta: float) -> void:
	var v := Vector2.ZERO
	# Teclado, para probar en la compu.
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1.0
	# Joystick del celular.
	if controles != null:
		v += controles.mover
	if v.length() > 1.0:
		v = v.normalized()
	direccion = v

	# --- Esprintar: SHIFT en la compu, o el joystick a fondo en el celular ---
	var sprint := Input.is_key_pressed(KEY_SHIFT)
	if controles != null and controles.mover.length() > 0.95:
		sprint = true
	if sprint and rol != Rol.ARQUERO:
		factor_velocidad = 1.35

	var tirar := Input.is_key_pressed(KEY_SPACE)
	var pasar := Input.is_key_pressed(KEY_P) or Input.is_key_pressed(KEY_E)
	if controles != null:
		tirar = tirar or controles.disparar
		pasar = pasar or controles.pasar

	# El arquero: SHIFT es la barrida, para llegar a la pelota.
	if rol == Rol.ARQUERO and sprint and _espera_especial <= 0.0:
		_espera_especial = 0.7
		var lado := v
		if lado.length() < 0.3:
			lado = hacia
		velocity = lado.normalized() * 22.0

	# El arquero ataja con TIRO (un toquecito).
	_quiere_agarrar = tirar

	if en_penal:
		# Tirando un penal: se apunta con el joystick (arriba/abajo) y se dispara.
		direccion = Vector2.ZERO
		if tirar and _espera_pateo <= 0.0:
			var altura := 0.0
			if controles != null:
				altura = clampf(controles.mover.y * 3.2, -3.0, 3.0)
			var objetivo := Vector2(arco_rival, altura)
			hacia = (objetivo - position).normalized()
			rotation = angulo_hacia(hacia)
			patear(24.0, 0.0)
		return

	# El arquero no carga tiros cuando está atajando con las manos al aire.
	if rol == Rol.ARQUERO and not _agarrando:
		potencia = 0.0
		cargando = false
		if pasar:
			pasar_balon()
		return

	# --- Cargar el tiro: entre más rato aprietes TIRO, más duro sale ---
	if tirar:
		cargando = true
		potencia = clampf(potencia + delta * 6.5, 1.0, 10.0)
	else:
		if cargando:
			cargando = false
			var p := potencia if potencia > 0.0 else 1.0
			potencia = 0.0
			disparar_con_potencia(p)
		elif pasar:
			pasar_balon()


## Patea con la fuerza que cargaste (de 1 a 10).
## Ojo: entre más duro, menos preciso: si cargas al máximo el balón se puede ir
## afuera (como cuando le pegas demasiado fuerte y se va arriba del arco).
func disparar_con_potencia(p: float) -> bool:
	var t := clampf((p - 1.0) / 9.0, 0.0, 1.0)
	var fuerza := lerpf(13.0, 32.0, t)
	var desvio := randf_range(-1.0, 1.0) * deg_to_rad(lerpf(1.0, 15.0, t))
	var rumbo := hacia.rotated(desvio)
	rotation = angulo_hacia(rumbo)
	hacia = rumbo
	return patear(fuerza, 0.0)


# ----------------------------------------------------------- si juega solo ---

func _pensar() -> void:
	if balon == null:
		direccion = Vector2.ZERO
		return

	var b: Vector2 = balon.position
	var signo := signf(arco_rival - arco_propio)
	var distancia := position.distance_to(b)

	# Durante un saque del otro equipo: me alejo y no la toco.
	if sin_tocar and rol != Rol.ARQUERO:
		var d: Vector2 = position - b
		if d.length() < 14.0 and d.length() > 0.01:
			direccion = d.normalized() + _separacion()
		else:
			direccion = _separacion()
		return

	if rol == Rol.ARQUERO:
		_pensar_arquero(b, distancia)
		return

	var mio: bool = dueno_balon != null and dueno_balon.equipo == equipo
	var libre := dueno_balon == null

	# 1) Yo tengo el balón.
	if dueno_balon == self:
		# Si un rival me está encima, la paso a un compañero (¡las IA también pasan!).
		var marca = _rival_mas_cercano()
		if marca != null and position.distance_to(marca.position) < 8.0:
			if _pasar_a_un_companero():
				return
		# Si no, sigo para el arco rival.
		var destino := Vector2(arco_rival - signo * 10.0, clampf(b.y * 0.5, -8.0, 8.0))
		direccion = destino - position
		_quizas_patear(signo)
		return

	# 2) El más cercano de mi equipo va a presionar (si el balón está libre o es del rival).
	if soy_mas_cercano and (libre or not mio):
		direccion = b - position
		# Si el que la tiene es un rival, me arrimo con cuidado: si lo atropello
		# me cobran falta. (Por eso los bots ya no se te tiran encima.)
		if not libre and position.distance_to(b) < 8.0:
			factor_velocidad = 0.5
		return

	# 3) Si la tiene mi equipo, acompaño el ataque según mi rol.
	if mio:
		var destino := formacion
		match rol:
			Rol.DEFENSA:
				destino = formacion + Vector2(signo * 18.0, 0.0)
			Rol.MEDIO:
				destino = formacion + Vector2(signo * 35.0, 0.0)
			Rol.DELANTERO:
				# OJO: cada delantero va a SU puesto. Si todos apuntaran al mismo
				# lugar (como antes), se amontonaban todos arriba.
				destino = formacion + Vector2(signo * 40.0, 0.0)
				destino.y = lerpf(destino.y, b.y, 0.25)
		# Se acerca muy poquito al balón para apoyar, sin amontonarse.
		destino = destino.lerp(b, 0.06)
		destino.x = clampf(destino.x, -56.0, 56.0)
		destino.y = clampf(destino.y, -35.0, 35.0)
		direccion = (destino - position) + _separacion() * 0.6
		return

	# 4) La tiene el rival: defiendo según mi rol.
	var objetivo := position
	match rol:
		Rol.DEFENSA:
			# Cada defensa marca al rival que tiene MÁS CERCA. Si todos marcaran
			# al mismo (como antes), los cinco se iban detrás de un solo atacante.
			var marca = _rival_mas_cercano()
			if marca != null:
				var suyo: Vector2 = marca.position
				objetivo = suyo + (Vector2(arco_propio, 0.0) - suyo).normalized() * 3.4
			else:
				objetivo = formacion + Vector2(signo * 4.0, 0.0)
			# Se queda cerca de su propio puesto, sin abandonarlo.
			objetivo = objetivo.lerp(formacion, 0.35)
		Rol.MEDIO:
			# Cada uno se corre hacia su puesto, un poquito hacia el balón.
			objetivo = (formacion + Vector2(-signo * 8.0, 0.0)).lerp(b, 0.18)
		Rol.DELANTERO:
			# Se queda arriba, listo para el contragolpe.
			objetivo = formacion + Vector2(0.0, (b.y - formacion.y) * 0.35)
	direccion = (objetivo - position) + _separacion()
	if direccion.length() < 0.2:
		direccion = Vector2.ZERO


## Empuja suave para que los compañeros no se amontonen: es como si se
## apartaran unos de otros cuando están demasiado juntos.
func _separacion() -> Vector2:
	var empuje := Vector2.ZERO
	for f in todos:
		if f == self or f.equipo != equipo:
			continue
		var d: Vector2 = position - f.position
		var dist := d.length()
		if dist < 0.01 or dist > 13.0:
			continue
		empuje += (d / dist) * (13.0 - dist) * 0.9
	return empuje


## El rival de campo más cercano a mí.
func _rival_mas_cercano():
	var mejor = null
	var mejor_distancia := 1000000.0
	for f in todos:
		if f.equipo == equipo or f.rol == Rol.ARQUERO:
			continue
		var d: float = position.distance_to(f.position)
		if d < mejor_distancia:
			mejor_distancia = d
			mejor = f
	return mejor


## Busca el mejor compañero para pasarle: que esté adelante, que no esté
## demasiado lejos y que no tenga un rival justo en la línea del pase.
func _companero_para_pasar():
	var signo := signf(arco_rival - arco_propio)
	var mejor = null
	var mejor_puntaje := -1000000.0
	for f in todos:
		if f == self or f.equipo != equipo or f.rol == Rol.ARQUERO:
			continue
		var d: Vector2 = f.position - position
		var dist := d.length()
		if dist < 9.0 or dist > 50.0:
			continue
		var adelante := d.x * signo
		if adelante < -5.0:
			continue          # ese compañero está más atrás que yo
		var tapado := 0
		for r in todos:
			if r.equipo == equipo:
				continue
			var en_la_linea := Geometry2D.get_closest_point_to_segment(r.position, position, f.position)
			if en_la_linea.distance_to(r.position) < 4.0:
				tapado += 1
		var puntaje: float = adelante * 1.6 - float(tapado) * 25.0 - dist * 0.25
		if puntaje > mejor_puntaje:
			mejor_puntaje = puntaje
			mejor = f
	return mejor


## Le pega al balón para dárselo a un compañero. Devuelve true si lo hizo.
func _pasar_a_un_companero() -> bool:
	if _espera_pateo > 0.0:
		return false
	var companero = _companero_para_pasar()
	if companero == null:
		return false
	var d: Vector2 = companero.position - position
	if d.length() < 1.0:
		return false
	hacia = d.normalized()
	rotation = angulo_hacia(hacia)
	return patear(clampf(d.length() * 0.85, 11.0, 22.0), 0.0)


## El pase del jugador que manejas: si hay compañero, se la da a él.
func pasar_balon() -> bool:
	if _companero_para_pasar() != null:
		return _pasar_a_un_companero()
	return patear(12.0)


func _pensar_arquero(b: Vector2, _distancia: float) -> void:
	# En un penal se queda clavado en la línea hasta que pateen (es la regla).
	if _agarrando or quieto:
		direccion = Vector2.ZERO
		return
	# Se para SIEMPRE entre el balón y el centro del arco, como los arqueros
	# de verdad: si el balón está lejos se queda en la línea, y si se acerca
	# sale un poco para tapar el ángulo.
	var centro_arco := Vector2(arco_propio, 0.0)
	var al_balon := b - centro_arco
	var lejos := al_balon.length()
	if lejos < 0.1:
		direccion = Vector2.ZERO
		return
	var salida := clampf(18.0 - lejos, 0.0, 7.0)
	var objetivo := centro_arco + (al_balon / lejos) * salida
	objetivo.y = clampf(objetivo.y, -6.5, 6.5)
	direccion = objetivo - position
	if direccion.length() < 0.25:
		direccion = Vector2.ZERO


## Si tengo el balón y estoy cerca del arco rival, le pego.
func _quizas_patear(signo: float) -> void:
	if _espera_pateo > 0.0 or not puede_tocar:
		return
	if hacia.dot(Vector2(signo, 0.0)) < 0.5:
		return                       # no estoy mirando hacia el arco
	var dist_arco := absf(arco_rival - position.x)
	if dist_arco < 18.0:
		patear(20.0, 0.0)
	elif dist_arco < 34.0:
		patear(15.0, 0.0)            # despeje largo


## El rival de campo más peligroso: el que está más cerca de mi arco.
func _rival_peligroso():
	var mejor = null
	var mejor_distancia := 1000000.0
	for f in todos:
		if f.equipo == equipo:
			continue
		if f.rol == Rol.ARQUERO:
			continue
		var d: float = absf(f.position.x - arco_propio)
		if d < mejor_distancia:
			mejor_distancia = d
			mejor = f
	return mejor


## Hacia dónde tiene que girar el nodo para mirar en esa dirección.
func angulo_hacia(destino: Vector2) -> float:
	return atan2(destino.x, -destino.y)


# --------------------------------------------------------------- saques ---

## El saque: no puede caminar. Si es con las manos, el balón va arriba
## de la cabeza; si es con el pie (córner o saque de arco), queda en el piso.
func _sacar(delta: float) -> void:
	direccion = Vector2.ZERO
	if balon != null and saque_con_mano:
		balon.position = position + hacia * (RADIO + Balon.RADIO * 0.2)
		balon.velocidad = Vector2.ZERO
		balon.agarrado = true

	if controlado:
		# Apuntas con el joystick y lanzas con TIRO (fuerte) o PASE (suave).
		var v := Vector2.ZERO
		if controles != null:
			v = controles.mover
		if v.length() > 0.35:
			rotation = angulo_hacia(v)
			hacia = Vector2.UP.rotated(rotation)
		if controles != null and (controles.disparar or controles.pasar):
			if saque_con_mano:
				lanzar(26.0 if controles.disparar else 16.0)
			else:
				sacando = false
				patear(22.0 if controles.disparar else 14.0, 0.0)
		return

	# Un bot saca solo, después de un momentito.
	_tiempo_saque += delta
	if _tiempo_saque < 1.2:
		return
	if saque_con_mano:
		var companero = _companero_para_pasar()
		if companero != null:
			rotation = angulo_hacia(companero.position - position)
			hacia = Vector2.UP.rotated(rotation)
		lanzar(22.0)
	else:
		var companero2 = _companero_para_pasar()
		if companero2 != null:
			rotation = angulo_hacia(companero2.position - position)
			hacia = Vector2.UP.rotated(rotation)
		sacando = false
		patear(20.0, 0.0)


## Lanza el balón con las manos (el saque de banda).
func lanzar(fuerza: float) -> void:
	if balon == null:
		return
	sacando = false
	balon.agarrado = false
	balon.ultimo_toque = self
	balon.position = position + hacia * (RADIO + Balon.RADIO * 0.6)
	balon.velocidad = hacia * fuerza
	_espera_pateo = 0.3


func _draw() -> void:
	# Sombra.
	draw_circle(Vector2(0.10, 0.18), RADIO, Color(0.0, 0.0, 0.0, 0.22))

	# Si me están controlando, un aro amarillo para no perderme.
	if controlado:
		draw_circle(Vector2.ZERO, RADIO + 0.30, Color(1.0, 0.90, 0.10, 0.30))
		draw_arc(Vector2.ZERO, RADIO + 0.28, 0.0, TAU, 40, Color(1.0, 0.90, 0.10), 0.16)

	# Cuerpo (la camiseta).
	draw_circle(Vector2.ZERO, RADIO, color_camiseta)
	draw_arc(Vector2.ZERO, RADIO, 0.0, TAU, 40, Color(0.0, 0.0, 0.0, 0.32), 0.11)

	# Las manitas del arquero: un tercio de su tamaño.
	if rol == Rol.ARQUERO:
		var mat_mano := color_piel
		draw_circle(Vector2(-RADIO * 0.92, -RADIO * 0.50), MANITA, mat_mano)
		draw_circle(Vector2(RADIO * 0.92, -RADIO * 0.50), MANITA, mat_mano)
		draw_arc(Vector2(-RADIO * 0.92, -RADIO * 0.50), MANITA, 0.0, TAU, 20, Color(0.0, 0.0, 0.0, 0.30), 0.07)
		draw_arc(Vector2(RADIO * 0.92, -RADIO * 0.50), MANITA, 0.0, TAU, 20, Color(0.0, 0.0, 0.0, 0.30), 0.07)

	# Pelo (atrás) y cara (adelante): así se ve hacia dónde mira.
	draw_circle(Vector2(0.0, 0.12), RADIO * 0.62, color_pelo)
	draw_circle(Vector2(0.0, -0.10), RADIO * 0.52, color_piel)

	# Si está sacando con las manos, los brazos van arriba sujetando el balón.
	if sacando and saque_con_mano:
		draw_circle(Vector2(-RADIO * 0.60, -RADIO * 1.15), RADIO * 0.22, color_piel)
		draw_circle(Vector2(RADIO * 0.60, -RADIO * 1.15), RADIO * 0.22, color_piel)

	# El número, siempre derecho aunque el jugador gire.
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	var fuente := ThemeDB.fallback_font
	var tam := int(RADIO * 1.00)
	draw_string(fuente, Vector2(-RADIO, float(tam) * 0.35), str(numero),
		HORIZONTAL_ALIGNMENT_CENTER, RADIO * 2.0, tam, color_numero)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
