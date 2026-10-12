extends Node2D
## La escena del partido.
##
## 16 jugadores por equipo, cada uno con su rol y su número:
##   1 = arquero
##   2, 3, 4, 5, 6 = defensas
##   7, 8, 10, 11, 15, 16 = medios
##   9, 12, 13, 14 = delanteros
##
## Tú manejas un jugador de tu equipo y puedes cambiar a otro con el botón
## CAMBIAR (o con la tecla Q). Los otros juegan solos, según su rol.
##
## El partido, como en el fútbol de verdad:
##   - 90 minutos de reloj. Ojo: 1 segundo de verdad = 1 minuto de juego,
##     así que el partido dura 90 segundos.
##   - Al minuto 45 hay descanso y el reloj se para 10 segundos.
##   - Si van empatados al 90, hay tiempo extra hasta el 120.
##   - Y si siguen empatados... ¡8 rondas de penales!

const Escenario = preload("res://scripts/cancha.gd")
const Balon = preload("res://scripts/balon.gd")
const Jugador = preload("res://scripts/futbolista.gd")
const Hud = preload("res://scripts/hud.gd")
const Controles = preload("res://scripts/controles_tactiles.gd")
const Marcas = preload("res://scripts/marcas_penal.gd")
const InterfazPenal = preload("res://scripts/interfaz_penal.gd")

# Los roles: los mismos números que el enum de futbolista.gd.
const ARQUERO := 0
const DEFENSA := 1
const MEDIO := 2
const DELANTERO := 3

enum Fase { JUEGO, DESCANSO, EXTRA, PENALES, FINAL }
## APUNTA = todavía no pateó (se está apuntando o eligiendo a dónde tirarse).
enum EstadoPenal { APUNTA, EN_VUELO, RESULTADO }

# --- El reloj ---
## Cuánto dura el partido DE VERDAD, en segundos. El marcador muestra los 90
## minutos de siempre: así el reloj de la pantalla hace el recorrido completo
## (minuto 45 al descanso, 90 al final) pero el partido no dura hora y media.
const PARTIDO_REAL := 160.0
## Segundos de juego que tiene un minuto del marcador.
const MINUTO := (90.0 * 60.0) / PARTIDO_REAL
const FIN_1T := 45.0 * MINUTO
const FIN_2T := 90.0 * MINUTO
const FIN_EXTRA := 120.0 * MINUTO
const SEGUNDOS_DESCANSO := 10.0
const RONDAS_PENALES := 8

# --- Los penales ---
## Las tres zonas del arco. -1 arriba, 0 al centro, +1 abajo.
const ZONAS_PENAL := [-1, 0, 1]
## A qué fracción de la mitad del arco queda cada zona. Ojo al cambiarla:
##   - Si es muy grande, los tiros se van al palo.
##   - Si es muy chica, el arquero tapa dos zonas de una sola tirida.
const ZONA_FRACCION := 0.55
## El arco se agranda en los penales (10 m -> 18 m). Con el arco de siempre las
## tres zonas quedan tan juntas que el arquero taparía dos de una sola tirida.
## (Ojo: el balón mide 2 m y el arquero llega a 2,87 m, por eso hace falta un
## arco bien ancho para que cada zona sea solo suya.)
const ARCO_PENAL := 18.0
## Cuánto tiene el jugador para decidir a dónde se tira su arquero.
const SEGUNDOS_DECISION := 4.0
## Cuánto tarda el rival en patear después de que el arquero ya se tiró.
const ESPERA_TRAS_TIRIDA := 0.6
## Si el balón no pasó nada en este tiempo, el penal se da por fallado.
const SEGUNDOS_VUELO := 3.0

# --- La cancha (igual que en cancha.gd) ---
const MITAD_LARGO := 60.0
const MITAD_ANCHO := 38.0
const MITAD_PORTERIA := 5.0           # mitad del arco de 10 m
const PUNTO_PENAL := 11.0
const AREA_PROFUNDIDAD := 16.5
const AREA_MITAD_ANCHO := 20.0

const ZOOM_ALTO := 36.0               # cuántos metros se ven de alto
## Qué tan cerca tienen que estar dos jugadores para que sea choque.
const CHOQUE := 2.7
const VELOCIDAD_MIA := 8.2
const VELOCIDAD_COMPANERO := 7.2

## Los 16 puestos de tu equipo. Tu equipo ataca hacia la derecha (+x).
## Es la formación que pidió Camilo: 1 arquero, 5 defensas, 6 medios
## (mediocentro, medio centro izquierdo y derecho, extremos y volantes)
## y 4 de ataque (extremo izquierdo, extremo derecho y 2 delanteros).
const FORMACION := [
	{"rol": ARQUERO, "num": 1, "pos": Vector2(-58.0, 0.0)},
	{"rol": DEFENSA, "num": 2, "pos": Vector2(-42.0, -26.0)},
	{"rol": DEFENSA, "num": 3, "pos": Vector2(-42.0, 26.0)},
	{"rol": DEFENSA, "num": 4, "pos": Vector2(-47.0, -9.0)},
	{"rol": DEFENSA, "num": 5, "pos": Vector2(-47.0, 9.0)},
	{"rol": DEFENSA, "num": 6, "pos": Vector2(-52.0, 0.0)},
	{"rol": MEDIO, "num": 8, "pos": Vector2(-26.0, 0.0)},
	{"rol": MEDIO, "num": 15, "pos": Vector2(-16.0, -18.0)},
	{"rol": MEDIO, "num": 16, "pos": Vector2(-16.0, 18.0)},
	{"rol": MEDIO, "num": 12, "pos": Vector2(-30.0, -26.0)},
	{"rol": MEDIO, "num": 14, "pos": Vector2(-30.0, 26.0)},
	{"rol": MEDIO, "num": 10, "pos": Vector2(-4.0, 0.0)},
	{"rol": DELANTERO, "num": 11, "pos": Vector2(20.0, -30.0)},
	{"rol": DELANTERO, "num": 7, "pos": Vector2(20.0, 30.0)},
	{"rol": DELANTERO, "num": 9, "pos": Vector2(26.0, -8.0)},
	{"rol": DELANTERO, "num": 13, "pos": Vector2(26.0, 8.0)},
]

var balon = null
var futbolistas := []                 # los 32 jugadores
var arqueros := []
var camara: Camera2D
var hud = null
var controles = null
var menu_pausa: CanvasLayer
var controlado = null                 # el jugador que manejas ahora
var dueno_balon = null                # quién tiene el balón

var goles_local := 0
var goles_rival := 0
var tiempo := 0.0                     # segundos de juego (5400 = minuto 90)
var fase := Fase.JUEGO
var descanso_hecho := false
var cuenta_descanso := 0.0
var pausado := false
var congelado := false                # mientras se celebra un gol
var terminado := false
var _espera_cambio := 0.0
var _proteccion_id := 0                # para saber si ya pasó el ratito de protección
var _en_saque := false                 # hay un saque en curso (el balón está "fuera de juego")
var _espera_falta := 0.0               # para no cobrar mil faltas seguidas

# --- Penales ---
var penales_mios := 0
var penales_rival := 0
var ronda_penal := 0
var turno_mio := true
var penal_estado := EstadoPenal.APUNTA
var penal_tiempo := 0.0
## El pateador y el arquero del penal que se está cobrando.
var penal_tirador = null
var penal_arquero = null
## A qué zona del arco se está apuntando (-1, 0, +1).
var penal_zona_tiro := 0
## A qué zona se tiró el arquero.
var penal_zona_arquero := 0
## Ya se decidió a dónde se tira el arquero (el jugador o el azar).
var penal_decidido := false
## Lo que le queda al jugador para elegir (4 segundos).
var penal_decision := SEGUNDOS_DECISION
## Lo que le queda al rival para patear después de la tirida del arquero.
var penal_espera := 0.0
## Por qué terminó el penal: "gol", "atajada" o "afuera".
var penal_motivo := ""

var escenario = null
var marcas = null
var interfaz_penal = null


func _ready() -> void:
	escenario = Escenario.new()
	add_child(escenario)
	_crear_balon()
	_crear_equipos()
	_crear_camara()
	_crear_interfaz()
	_saque_de_centro()


# ----------------------------------------------------------------- armado ---

func _crear_balon() -> void:
	balon = Balon.new()
	balon.position = Vector2.ZERO
	add_child(balon)


func _crear_equipos() -> void:
	_crear_equipo(0)
	_crear_equipo(1)
	# Empezamos manejando al delantero número 9.
	controlado = _buscar(0, DELANTERO)
	if controlado != null:
		controlado.controlado = true


func _crear_equipo(equipo: int) -> void:
	for datos in FORMACION:
		var f = Jugador.new()
		f.equipo = equipo
		f.rol = datos["rol"]
		f.numero = datos["num"]
		var puesto: Vector2 = datos["pos"]
		if equipo == 1:
			puesto = Vector2(-puesto.x, puesto.y)      # el rival juega al revés
		f.formacion = puesto

		if equipo == 0:
			# Tu equipo: azul.
			f.arco_propio = -MITAD_LARGO
			f.arco_rival = MITAD_LARGO
			f.color_camiseta = Color(0.12, 0.32, 0.92)
			f.color_numero = Color(1, 1, 1)
			f.velocidad = VELOCIDAD_COMPANERO if f.rol != ARQUERO else Ajustes.velocidad_arquero()
			if f.rol == ARQUERO:
				f.color_camiseta = Color(0.95, 0.76, 0.12)
		else:
			# El rival: rojo.
			f.arco_propio = MITAD_LARGO
			f.arco_rival = -MITAD_LARGO
			f.color_camiseta = Color(0.86, 0.16, 0.16)
			f.color_numero = Color(1, 1, 1)
			f.velocidad = Ajustes.velocidad_rival() if f.rol != ARQUERO else Ajustes.velocidad_arquero()
			if f.rol == ARQUERO:
				f.color_camiseta = Color(0.20, 0.72, 0.35)

		f.area_propia = _area_de(equipo)
		f.balon = balon
		f.todos = futbolistas
		f.position = puesto
		add_child(f)
		futbolistas.append(f)
		if f.rol == ARQUERO:
			arqueros.append(f)


func _area_de(equipo: int) -> Rect2:
	var prof := AREA_PROFUNDIDAD
	if equipo == 0:
		return Rect2(-MITAD_LARGO, -AREA_MITAD_ANCHO, prof, AREA_MITAD_ANCHO * 2.0)
	return Rect2(MITAD_LARGO - prof, -AREA_MITAD_ANCHO, prof, AREA_MITAD_ANCHO * 2.0)


## Busca un jugador por equipo y rol.
func _buscar(equipo: int, rol: int):
	for f in futbolistas:
		if f.equipo == equipo and f.rol == rol:
			return f
	return null


func _arquero_de(equipo: int):
	for f in arqueros:
		if f.equipo == equipo:
			return f
	return null


func _crear_camara() -> void:
	camara = Camera2D.new()
	camara.position_smoothing_enabled = true
	camara.position_smoothing_speed = 5.0
	camara.limit_left = -int(MITAD_LARGO)
	camara.limit_right = int(MITAD_LARGO)
	camara.limit_top = -int(MITAD_ANCHO)
	camara.limit_bottom = int(MITAD_ANCHO)
	camara.enabled = true
	add_child(camara)
	_ajustar_camara()
	get_viewport().size_changed.connect(_ajustar_camara)


## Que se vean siempre unos 30 m de alto, sin importar el tamaño de la pantalla.
func _ajustar_camara() -> void:
	if camara == null:
		return
	var alto := float(get_viewport_rect().size.y)
	var z := alto / ZOOM_ALTO
	camara.zoom = Vector2(z, z)


func _crear_interfaz() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.pausa_pedida.connect(_pausar)

	controles = Controles.new()
	hud.add_child(controles)
	_poner_controles()

	# Las marcas de las zonas del arco y los botones del arquero (penales).
	marcas = Marcas.new()
	add_child(marcas)

	interfaz_penal = InterfazPenal.new()
	add_child(interfaz_penal)
	interfaz_penal.zona_elegida.connect(_al_elegir_zona)

	_crear_menu_pausa()


## Los controles táctiles se le pasan al jugador que estás manejando.
func _poner_controles() -> void:
	for f in futbolistas:
		f.controles = controles
	if controlado != null:
		controlado.controles = controles


func _crear_menu_pausa() -> void:
	menu_pausa = CanvasLayer.new()
	menu_pausa.layer = 5
	menu_pausa.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(menu_pausa)

	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.65)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_pausa.add_child(fondo)

	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_CENTER)
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BOTH
	caja.add_theme_constant_override("separation", 20)
	menu_pausa.add_child(caja)

	var titulo := Label.new()
	titulo.text = "PAUSA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 56)
	caja.add_child(titulo)

	var seguir := Button.new()
	seguir.text = "SEGUIR JUGANDO"
	seguir.custom_minimum_size = Vector2(300.0, 68.0)
	seguir.add_theme_font_size_override("font_size", 26)
	seguir.pressed.connect(_reanudar)
	caja.add_child(seguir)

	var salir := Button.new()
	salir.text = "SALIR AL MENÚ"
	salir.custom_minimum_size = Vector2(300.0, 68.0)
	salir.add_theme_font_size_override("font_size", 26)
	salir.pressed.connect(_salir_al_menu)
	caja.add_child(salir)

	menu_pausa.visible = false


# ------------------------------------------------------------- cada cuadro ---

func _process(delta: float) -> void:
	if pausado or terminado:
		return

	# Cambiar de jugador.
	_espera_cambio = maxf(0.0, _espera_cambio - delta)
	_espera_falta = maxf(0.0, _espera_falta - delta)
	if controles != null and controles.cambiar:
		controles.cambiar = false
		_cambiar_jugador()
	if (Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_TAB)) and _espera_cambio <= 0.0:
		_espera_cambio = 0.4
		_cambiar_jugador()

	match fase:
		Fase.JUEGO:
			tiempo += MINUTO * delta
			if tiempo >= FIN_2T:
				_terminar_tiempo_normal()
			elif tiempo >= FIN_1T and not descanso_hecho:
				_a_descanso()
		Fase.DESCANSO:
			cuenta_descanso -= delta
			if cuenta_descanso <= 0.0:
				_empezar_segundo_tiempo()
		Fase.EXTRA:
			tiempo += MINUTO * delta
			if tiempo >= FIN_EXTRA:
				_terminar_tiempo_extra()
		Fase.PENALES:
			_actualizar_penales(delta)

	_seguir_el_balon()
	hud.actualizar(goles_local, goles_rival, tiempo, _texto_fase(), _texto_extra())
	if controlado != null:
		hud.potencia(controlado.potencia)


func _physics_process(_delta: float) -> void:
	if pausado or terminado or congelado:
		return
	if fase == Fase.PENALES:
		_revisar_gol()
		return
	_marcar_dueno_del_balon()
	_revisar_falta()
	_revisar_gol()
	_revisar_fuera()


## Decide quién tiene el balón y quién es el más cercano de cada equipo.
## El dueño es el más cercano, pero el que ya lo tiene conserva una ventaja
## (si no, se lo quitarían todo el tiempo).
func _marcar_dueno_del_balon() -> void:
	if balon == null:
		return

	# Mientras hay un saque, el balón no es de nadie: nadie lo puede robar.
	if _en_saque:
		dueno_balon = null
		for f in futbolistas:
			f.puede_tocar = false
			f.dueno_balon = null
		return

	var mejor = null
	var mejor_distancia := 1000000.0
	var mas_cercano := [null, null]
	var distancia_equipo := [1000000.0, 1000000.0]

	for f in futbolistas:
		if not f.visible or f.sin_tocar:
			continue
		var d: float = f.position.distance_to(balon.position)
		# El más cercano de cada equipo (ese va a presionar).
		if f.rol != ARQUERO and d < distancia_equipo[f.equipo]:
			distancia_equipo[f.equipo] = d
			mas_cercano[f.equipo] = f
		if f.rol == ARQUERO:
			continue                      # los arqueros no regatean
		if f == dueno_balon:
			d -= 0.45                     # el que la tiene, la conserva
		if f == controlado:
			d -= 0.60                     # tu jugador tiene una buena ayudita
		if d < mejor_distancia:
			mejor_distancia = d
			mejor = f

	if mejor_distancia > 3.6:
		mejor = null
	dueno_balon = mejor

	for f in futbolistas:
		f.dueno_balon = dueno_balon
		f.puede_tocar = (f == dueno_balon)
		f.soy_mas_cercano = (f == mas_cercano[f.equipo])


## La mitad del arco que hay AHORA. En los penales el arco se agranda, así que
## no se puede usar una constante: hay que preguntarle a la cancha.
func _mitad_porteria() -> float:
	if escenario != null:
		return escenario.mitad_porteria()
	return MITAD_PORTERIA


## La altura (y) a la que queda cada zona del arco.
func _y_de_zona(zona: int) -> float:
	return float(zona) * _mitad_porteria() * ZONA_FRACCION


## Qué zona está eligiendo el jugador con el joystick (arriba/centro/abajo).
func _zona_del_joystick() -> int:
	var v := Vector2.ZERO
	if controles != null:
		v = controles.mover
	# También con el teclado, para probar en la compu.
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1.0
	if v.y < -0.35:
		return -1
	if v.y > 0.35:
		return 1
	return 0


## Una zona al azar (la usa el arquero cuando no sabe para dónde va el tiro).
func _zona_al_azar() -> int:
	return ZONAS_PENAL[randi() % ZONAS_PENAL.size()]


func _revisar_gol() -> void:
	if balon == null or congelado or _en_saque:
		return
	var p: Vector2 = balon.position
	if absf(p.y) >= _mitad_porteria():
		return
	if p.x > MITAD_LARGO:
		_gol(true)
	elif p.x < -MITAD_LARGO:
		_gol(false)


## Si el balón se va afuera, saca el equipo contrario al que lo tocó de última,
## como en el fútbol de verdad: saque de banda, tiro de esquina o saque de arco.
func _revisar_fuera() -> void:
	if balon == null or congelado or _en_saque:
		return
	var p: Vector2 = balon.position
	if absf(p.x) > MITAD_LARGO:
		_sacar_de_fondo(p)
		return
	if absf(p.y) > MITAD_ANCHO:
		_sacar_de_banda(p)


## De quién era el equipo que tocó el balón por última vez.
func _equipo_del_ultimo_toque() -> int:
	if balon.ultimo_toque != null:
		return balon.ultimo_toque.equipo
	return 0


func _sacar_de_banda(p: Vector2) -> void:
	var equipo := 1 - _equipo_del_ultimo_toque()
	var punto := Vector2(clampf(p.x, -MITAD_LARGO + 3.0, MITAD_LARGO - 3.0), signf(p.y) * (MITAD_ANCHO - 0.8))
	_hacer_saque(punto, equipo, "¡SAQUE DE BANDA!  Apunta y lanza con TIRO", false, true)


func _sacar_de_fondo(p: Vector2) -> void:
	var lado := signf(p.x)
	var equipo_del_arco := 0 if lado < 0.0 else 1
	if _equipo_del_ultimo_toque() == equipo_del_arco:
		# La tocó el que defiende ese arco: es TIRO DE ESQUINA para el otro.
		var punto := Vector2(lado * (MITAD_LARGO - 0.8), signf(p.y) * (MITAD_ANCHO - 0.8))
		_hacer_saque(punto, 1 - equipo_del_arco, "¡TIRO DE ESQUINA!", false, false)
	else:
		# La tiró afuera el que estaba atacando: SAQUE DE ARCO para el que defiende.
		_hacer_saque(Vector2(lado * (MITAD_LARGO - 7.0), 0.0), equipo_del_arco, "SAQUE DE ARCO", true, false)


## Acomoda el saque. Ojo: NO se congela a nadie. El que saca se queda quieto
## (sacando = true) y los del otro equipo se alejan y no pueden tocar el balón,
## porque hasta que se haga el saque la pelota está "fuera de juego".
func _hacer_saque(punto: Vector2, equipo: int, texto: String, permitir_arquero: bool, con_las_manos: bool) -> void:
	_en_saque = true
	_proteccion_id += 1
	var mi_proteccion := _proteccion_id

	balon.reiniciar(punto)
	balon.ultimo_toque = null
	_parar_todos()
	hud.mostrar_mensaje(texto, 2.2)

	# Los del otro equipo se alejan y no pueden tocarla mientras sacas.
	for f in futbolistas:
		f.sin_tocar = (f.equipo != equipo)
		f.sacando = false

	# El saque de banda y el córner de TU equipo los haces tú.
	# El saque de arco lo hace el arquero, como en el fútbol de verdad.
	var sacador = null
	if equipo == 0 and not permitir_arquero and controlado != null:
		sacador = controlado
	else:
		sacador = _mas_cercano_a(punto, equipo, permitir_arquero)

	if sacador != null:
		var adentro := Vector2(-signf(punto.x) * 2.0, 0.0)
		if absf(punto.y) > MITAD_ANCHO - 1.5:
			adentro = Vector2(0.0, -signf(punto.y) * 3.0)
		elif absf(punto.x) > MITAD_LARGO - 1.5:
			adentro = Vector2(-signf(punto.x) * 3.0, 0.0)
		# El saque de banda se hace bien desde la línea, con los pies afuera.
		sacador.position = punto if con_las_manos else punto + adentro
		sacador.velocity = Vector2.ZERO
		sacador.direccion = Vector2.ZERO
		sacador.rotation = sacador.angulo_hacia(adentro)
		sacador.sacando = true
		sacador.saque_con_mano = con_las_manos
		sacador._tiempo_saque = 0.0

	# Espera a que se haga el saque (si se queda dormido, lo hace solo a los 8 s).
	var espera := 0.0
	while espera < 8.0:
		await get_tree().create_timer(0.25).timeout
		if terminado or mi_proteccion != _proteccion_id:
			return
		if sacador == null or not sacador.sacando:
			break
		espera += 0.25

	if sacador != null and sacador.sacando:
		sacador.sacando = false
		if sacador.saque_con_mano:
			sacador.lanzar(20.0)
		else:
			sacador.patear(18.0, 0.0)

	_en_saque = false
	_quitar_proteccion()


func _quitar_proteccion() -> void:
	for f in futbolistas:
		f.sin_tocar = false


## El jugador de un equipo que está más cerca de un punto.
func _mas_cercano_a(punto: Vector2, equipo: int, permitir_arquero: bool):
	var mejor = null
	var mejor_distancia := 1000000.0
	for f in futbolistas:
		if f.equipo != equipo:
			continue
		if f.rol == ARQUERO and not permitir_arquero:
			continue
		var d: float = f.position.distance_to(punto)
		if d < mejor_distancia:
			mejor_distancia = d
			mejor = f
	return mejor


func _congelar_jugadores(congelar: bool) -> void:
	for f in futbolistas:
		f.set_physics_process(not congelar)


# ---------------------------------------------------------------- faltas ---

## Si un rival se te atraviesa encima (o tú encima de él) es FALTA.
## Si la falta es dentro del área, es PENAL.
func _revisar_falta() -> void:
	if balon == null or _en_saque or congelado:
		return

	# Al arquero que tiene el balón en las manos NO se le puede quitar:
	# el que se le arrime se lleva amarilla.
	for a in arqueros:
		if not a._agarrando:
			continue
		for f in futbolistas:
			if f.equipo == a.equipo or f.rol == ARQUERO:
				continue
			if f.position.distance_to(a.position) < CHOQUE:
				_espera_falta = 3.0
				hud.mostrar_mensaje("¡AMARILLA!  Al arquero no se le quita el balón", 2.4)
				f.velocity = (f.position - a.position).normalized() * 10.0
				return

	if dueno_balon == null:
		return
	if _espera_falta > 0.0:
		return

	var victima = dueno_balon
	if victima.rol == ARQUERO:
		return

	for f in futbolistas:
		if f.equipo == victima.equipo or f.rol == ARQUERO:
			continue
		var d: Vector2 = victima.position - f.position
		var dist := d.length()
		if dist > CHOQUE or dist < 0.01:
			continue
		var hacia_victima := d / dist
		# Qué tan fuerte lo está atropellando cada uno.
		var empuje_rival: float = f.velocity.dot(hacia_victima)
		var empuje_mio: float = victima.velocity.dot(-hacia_victima)
		if empuje_rival > 4.5 and empuje_rival > empuje_mio + 1.0:
			_cobrar_falta(f, victima)
			return
		if empuje_mio > 4.5 and empuje_mio > empuje_rival + 1.0:
			_cobrar_falta(victima, f)
			return


func _cobrar_falta(infractor, victima) -> void:
	_espera_falta = 3.0
	var equipo_favorecido: int = victima.equipo
	var punto: Vector2 = victima.position

	# ¿La falta fue dentro del área del que la hizo? Entonces es PENAL.
	var es_penal: bool = _area_de(infractor.equipo).has_point(punto)
	if es_penal:
		var signo := 1.0 if infractor.equipo == 0 else -1.0
		punto = Vector2(signo * (MITAD_LARGO - PUNTO_PENAL), 0.0)

	var texto := "¡FALTA A TU FAVOR!" if equipo_favorecido == 0 else "FALTA EN CONTRA"
	if es_penal:
		texto = "¡PENAL PARA TI!" if equipo_favorecido == 0 else "PENAL PARA EL RIVAL"

	_hacer_saque(punto, equipo_favorecido, texto, false, false)


func _seguir_el_balon() -> void:
	if camara == null or balon == null:
		return
	var foco: Vector2 = balon.position
	if controlado != null and fase != Fase.PENALES:
		foco = (foco + controlado.position) * 0.5
	camara.position = foco


# ------------------------------------------------------ cambiar de jugador ---

func _cambiar_jugador() -> void:
	if fase == Fase.PENALES:
		return
	# Si el balón está en tu área, también puedes pasar a manejar al arquero.
	var con_arquero: bool = _area_de(0).has_point(balon.position)
	var mejor = null
	var mejor_distancia := 1000000.0
	for f in futbolistas:
		if f.equipo != 0 or f == controlado:
			continue
		if f.rol == ARQUERO and not con_arquero:
			continue
		var d: float = f.position.distance_to(balon.position)
		if d < mejor_distancia:
			mejor_distancia = d
			mejor = f
	if mejor == null:
		return
	if controlado != null:
		controlado.controlado = false
		controlado.velocidad = VELOCIDAD_COMPANERO
	controlado = mejor
	controlado.controlado = true
	controlado.controles = controles
	controlado.velocidad = VELOCIDAD_MIA


# ---------------------------------------------------------------- jugadas ---

func _gol(es_tuyo: bool) -> void:
	if fase == Fase.PENALES:
		if (es_tuyo and turno_mio) or (not es_tuyo and not turno_mio):
			_terminar_penal(true)
		return

	if congelado or terminado:
		return
	congelado = true

	if es_tuyo:
		goles_local += 1
		hud.mostrar_mensaje("¡GOOOL!", 2.2)
	else:
		goles_rival += 1
		hud.mostrar_mensaje("GOL DEL RIVAL", 2.2)

	hud.actualizar(goles_local, goles_rival, tiempo, _texto_fase(), _texto_extra())
	_congelar_jugadores(true)
	_parar_todos()

	await get_tree().create_timer(2.2).timeout
	if terminado:
		return
	_saque_de_centro()
	congelado = false


func _saque_de_centro() -> void:
	_en_saque = false
	balon.reiniciar(Vector2.ZERO)
	balon.ultimo_toque = null
	dueno_balon = null
	for f in futbolistas:
		f.quieto = false
		f.sin_tocar = false
		f.sacando = false
		f.en_penal = false
		f.visible = true
		f.set_physics_process(true)
		f.position = f.formacion
		f.velocity = Vector2.ZERO
		f.direccion = Vector2.ZERO
		f.controlado = false
		f.puede_tocar = false
	if controlado != null:
		controlado.controlado = true
		controlado.velocidad = VELOCIDAD_MIA
	# Un toque pendiente no puede tirar por su cuenta.
	controles.disparo_toque = false
	controles.pase_toque = false


func _parar_todos() -> void:
	for f in futbolistas:
		f.direccion = Vector2.ZERO
		f.velocity = Vector2.ZERO
	if balon != null:
		balon.velocidad = Vector2.ZERO


# ------------------------------------------------------------------ reloj ---

func _texto_fase() -> String:
	match fase:
		Fase.JUEGO:
			return "SEGUNDO TIEMPO" if descanso_hecho else "PRIMER TIEMPO"
		Fase.DESCANSO:
			return "DESCANSO"
		Fase.EXTRA:
			return "TIEMPO EXTRA"
		Fase.PENALES:
			return "PENALES"
		_:
			return "FINAL"


func _texto_extra() -> String:
	if fase == Fase.DESCANSO:
		return "vuelve en %d s" % int(ceilf(cuenta_descanso))
	if fase == Fase.PENALES:
		return "ronda %d de %d  ·  %d - %d" % [ronda_penal + 1, RONDAS_PENALES, penales_mios, penales_rival]
	return "pulsa CAMBIAR (o Q) para elegir otro jugador"


func _a_descanso() -> void:
	fase = Fase.DESCANSO
	descanso_hecho = true
	tiempo = FIN_1T
	cuenta_descanso = SEGUNDOS_DESCANSO
	_parar_todos()
	hud.mostrar_mensaje("DESCANSO", SEGUNDOS_DESCANSO)


func _empezar_segundo_tiempo() -> void:
	fase = Fase.JUEGO
	_saque_de_centro()
	hud.mostrar_mensaje("¡SEGUNDO TIEMPO!", 2.0)


func _terminar_tiempo_normal() -> void:
	tiempo = FIN_2T
	_parar_todos()
	if goles_local == goles_rival:
		fase = Fase.EXTRA
		hud.mostrar_mensaje("¡NOS VAMOS A TIEMPO EXTRA!", 3.0)
		await get_tree().create_timer(3.0).timeout
		if terminado:
			return
		_saque_de_centro()
	else:
		_finalizar()


func _terminar_tiempo_extra() -> void:
	tiempo = FIN_EXTRA
	_parar_todos()
	if goles_local == goles_rival:
		await _empezar_penales()
	else:
		_finalizar()


func _finalizar() -> void:
	terminado = true
	_parar_todos()
	var texto := "EMPATE  %d - %d" % [goles_local, goles_rival]
	if goles_local > goles_rival:
		texto = "¡GANASTE  %d - %d!" % [goles_local, goles_rival]
	elif goles_rival > goles_local:
		texto = "PERDISTE  %d - %d" % [goles_local, goles_rival]
	hud.mostrar_mensaje(texto, 3.8)
	hud.actualizar(goles_local, goles_rival, tiempo, "FINAL", "")

	await get_tree().create_timer(4.0).timeout
	_ir_al_final(goles_local > goles_rival)


## Termina el partido y lleva a donde toca.
## Si ganaste, primero te sale el sobre: 1 jugador + 200 gemas + 1.000 moneditas.
func _ir_al_final(gano: bool) -> void:
	if gano:
		_entregar_sobre_ganado()
		get_tree().change_scene_to_file("res://scenes/sobres.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


## Arma y guarda el sobre que se gana por ganar el partido.
func _entregar_sobre_ganado() -> void:
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	var premio := Sobres.premio(azar, true)
	Datos.entregar_premio(premio["carta"], int(premio["monedas"]), int(premio["gemas"]))
	# La pantalla de sobres lo lee de aquí y lo muestra abierto.
	Datos.ultimo_premio = premio


# ---------------------------------------------------------------- penales ---

func _empezar_penales() -> void:
	fase = Fase.PENALES
	penales_mios = 0
	penales_rival = 0
	ronda_penal = 0
	turno_mio = true
	# El arco se agranda: así las tres zonas quedan separadas y el arquero solo
	# puede tapar la suya (con el arco chiquito taparía dos de una sola tirida).
	escenario.poner_arco(ARCO_PENAL)
	marcas.mitad = _mitad_porteria()
	hud.mostrar_mensaje("¡PENALES!", 2.5)
	# Que la cámara pueda llegar hasta el arco.
	camara.limit_left = -int(MITAD_LARGO) - 30
	camara.limit_right = int(MITAD_LARGO) + 30
	camara.limit_top = -int(MITAD_ANCHO) - 30
	camara.limit_bottom = int(MITAD_ANCHO) + 30
	await get_tree().create_timer(2.5).timeout
	if terminado:
		return
	_preparar_penal()


func _preparar_penal() -> void:
	penal_estado = EstadoPenal.APUNTA
	penal_tiempo = 0.0
	penal_decidido = false
	penal_decision = SEGUNDOS_DECISION
	penal_espera = ESPERA_TRAS_TIRIDA
	penal_zona_tiro = 0
	penal_zona_arquero = 0
	penal_motivo = ""

	var equipo_tirador := 0 if turno_mio else 1
	penal_tirador = _buscar(equipo_tirador, DELANTERO)
	penal_arquero = _arquero_de(1 - equipo_tirador)
	var signo := 1.0 if turno_mio else -1.0
	var punto := Vector2(signo * (MITAD_LARGO - PUNTO_PENAL), 0.0)

	balon.reiniciar(punto)

	for f in futbolistas:
		f.reiniciar_para_penal()
		if f == penal_tirador or f == penal_arquero:
			f.visible = true
			f.set_physics_process(true)
			f.puede_tocar = false
			f.direccion = Vector2.ZERO
			f.velocity = Vector2.ZERO
		else:
			f.visible = false
			f.set_physics_process(false)
			f.controlado = false
			f.position = Vector2(0.0, 300.0)

	if penal_arquero != null:
		penal_arquero.velocidad = 9.5
		penal_arquero.aceleracion = 45.0
		penal_arquero.penal_mitad_arco = _mitad_porteria()
		penal_arquero.position = Vector2(signo * (MITAD_LARGO - 1.6), 0.0)
		# La regla del penal: el arquero se queda clavado en la línea hasta que
		# el otro patee. Recién ahí se tira.
		penal_arquero.quieto = true

	if penal_tirador != null:
		penal_tirador.en_penal = turno_mio
		penal_tirador.controlado = turno_mio
		# El balón queda EN LOS PIES del pateador: se para justo detrás del
		# punto de penal, pegadito al balón.
		penal_tirador.position = punto - Vector2(signo * 1.3, 0.0)
		penal_tirador.rotation = penal_tirador.angulo_hacia(Vector2(signo, 0.0))
		penal_tirador.velocity = Vector2.ZERO
		penal_tirador.penal_objetivo = Vector2(signo * MITAD_LARGO, 0.0)
		# El pateador NO se mueve: si lo dejábamos jugar solo, se iba caminando
		# y el rival nunca llegaba a patear.
		penal_tirador.quieto = true

	if turno_mio:
		if controlado != null and controlado != penal_tirador:
			controlado.controlado = false
		controlado = penal_tirador
	else:
		# Cuando tira el rival, el que decide es el jugador: manda a su arquero
		# con los botones (con el joystick apunta al arco, no al arquero).
		if controlado != null:
			controlado.controlado = false
		controlado = null

	marcas.activo = true
	marcas.lado = signo
	marcas.mitad = _mitad_porteria()
	marcas.zona = 0
	marcas.mostrar_zona_arquero = false
	marcas.zona_arquero = 0
	# Un toque que haya quedado "pendiente" (por ejemplo, cuando no manejabas a
	# nadie) no puede disparar el penal solo: se limpia al empezar.
	controles.disparo_toque = false
	controles.pase_toque = false
	interfaz_penal.mostrar(turno_mio)


func _actualizar_penales(delta: float) -> void:
	penal_tiempo += delta

	if penal_estado == EstadoPenal.APUNTA:
		if turno_mio:
			# Apuntar con el joystick: la zona elegida se ve marcada en el arco.
			penal_zona_tiro = _zona_del_joystick()
			marcas.zona = penal_zona_tiro
			if penal_tirador != null:
				penal_tirador.penal_objetivo = Vector2(penal_tirador.arco_rival,
					_y_de_zona(penal_zona_tiro))
		elif not penal_decidido:
			# Tienes 4 segundos para decir a dónde se tira tu arquero.
			penal_decision -= delta
			var elegida := _zona_del_joystick()
			penal_zona_arquero = elegida
			marcas.zona = elegida
			interfaz_penal.poner_zona(elegida)
			interfaz_penal.poner_cuenta(penal_decision)
			if penal_decision <= 0.0:
				# Se acabó el tiempo: el arquero se tira al azar.
				_elegir_arquero(_zona_al_azar(), "¡sin tiempo!  se tiró al azar")
		else:
			# Ya se tiró el arquero: el rival patea en un ratito.
			penal_espera -= delta
			if penal_espera <= 0.0:
				_tirar_penal_rival()
				penal_estado = EstadoPenal.EN_VUELO
				penal_tiempo = 0.0

		# Cuando el balón sale disparado, empieza el vuelo.
		if penal_estado == EstadoPenal.APUNTA and balon.velocidad.length() > 8.0:
			_arrancar_vuelo()

	elif penal_estado == EstadoPenal.EN_VUELO:
		# Si el arquero la tocó, atajó.
		if penal_arquero != null and penal_arquero.penal_toco_balon:
			balon.velocidad = Vector2.ZERO
			_terminar_penal(false, "atajada")
		elif penal_tiempo > SEGUNDOS_VUELO:
			var fuera := absf(balon.position.y) > _mitad_porteria()
			_terminar_penal(false, "afuera" if fuera else "atajada")


## Ya salió el tiro.
func _arrancar_vuelo() -> void:
	penal_estado = EstadoPenal.EN_VUELO
	penal_tiempo = 0.0
	if turno_mio:
		# El arquero del rival elige su zona AL AZAR justo cuando sale el tiro:
		# así no puede saber para dónde va el balón.
		_elegir_arquero(_zona_al_azar(), "")
	elif not penal_decidido:
		_elegir_arquero(_zona_al_azar(), "")


## Manda al arquero a tirarse a una zona y avisa en pantalla.
func _elegir_arquero(zona: int, aviso: String) -> void:
	penal_decidido = true
	penal_zona_arquero = zona
	marcas.zona_arquero = zona
	marcas.mostrar_zona_arquero = true
	if penal_arquero != null:
		penal_arquero.penal_mitad_arco = _mitad_porteria()
		penal_arquero.tirarse(zona, _y_de_zona(zona))
	interfaz_penal.cerrar_decision(aviso if aviso != ""
		else "¡se tiró hacia %s!" % _nombre_zona(zona))


## El jugador apretó uno de los tres botones del arquero.
func _al_elegir_zona(zona: int) -> void:
	if fase != Fase.PENALES or turno_mio or penal_decidido:
		return
	if penal_estado != EstadoPenal.APUNTA:
		return
	_elegir_arquero(zona, "¡te tiraste hacia %s!" % _nombre_zona(zona))


func _nombre_zona(zona: int) -> String:
	match zona:
		-1:
			return "arriba"
		1:
			return "abajo"
		_:
			return "el centro"


## El rival tira su penal: apunta a una zona al azar y le pega al balón.
func _tirar_penal_rival() -> void:
	if penal_tirador == null:
		return
	var zona := _zona_al_azar()
	var objetivo := Vector2(penal_tirador.arco_rival,
		_y_de_zona(zona) + randf_range(-0.9, 0.9))
	penal_zona_tiro = zona
	penal_tirador.hacia = (objetivo - penal_tirador.position).normalized()
	penal_tirador.rotation = penal_tirador.angulo_hacia(penal_tirador.hacia)
	penal_tirador.patear(24.0, 0.0)


## Termina el penal. `motivo` dice por qué no fue gol: "atajada" o "afuera".
func _terminar_penal(fue_gol: bool, motivo := "atajada") -> void:
	if penal_estado == EstadoPenal.RESULTADO or terminado:
		return
	penal_estado = EstadoPenal.RESULTADO

	if fue_gol:
		penal_motivo = "gol"
		if turno_mio:
			penales_mios += 1
			hud.mostrar_mensaje("¡GOOOL!", 1.5)
		else:
			penales_rival += 1
			hud.mostrar_mensaje("GOL DEL RIVAL", 1.5)
	else:
		penal_motivo = motivo
		hud.mostrar_mensaje("¡ATAJÓ EL ARQUERO!" if motivo == "atajada" else "¡SE FUE AFUERA!", 1.5)

	balon.velocidad = Vector2.ZERO
	interfaz_penal.ocultar()
	marcas.activo = false
	hud.actualizar(goles_local, goles_rival, tiempo, _texto_fase(), _texto_extra())

	await get_tree().create_timer(1.7).timeout
	if terminado:
		return
	_siguiente_penal()


func _siguiente_penal() -> void:
	if turno_mio:
		turno_mio = false
		_preparar_penal()
		return
	# Terminó la ronda: los dos equipos ya tiraron.
	turno_mio = true
	ronda_penal += 1
	if ronda_penal >= RONDAS_PENALES and penales_mios != penales_rival:
		_fin_penales()
		return
	_preparar_penal()


func _fin_penales() -> void:
	terminado = true
	interfaz_penal.ocultar()
	marcas.activo = false
	var texto := "PENALES: GANASTE  %d - %d" % [penales_mios, penales_rival]
	if penales_rival > penales_mios:
		texto = "PENALES: PERDISTE  %d - %d" % [penales_mios, penales_rival]
	hud.mostrar_mensaje(texto, 4.0)

	await get_tree().create_timer(4.5).timeout
	_ir_al_final(penales_mios > penales_rival)


# ------------------------------------------------------------------ pausa ---

func _pausar() -> void:
	if terminado or pausado:
		return
	pausado = true
	menu_pausa.visible = true
	get_tree().paused = true


func _reanudar() -> void:
	pausado = false
	menu_pausa.visible = false
	get_tree().paused = false


func _salir_al_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
