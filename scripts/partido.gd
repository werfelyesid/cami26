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

# Los roles: los mismos números que el enum de futbolista.gd.
const ARQUERO := 0
const DEFENSA := 1
const MEDIO := 2
const DELANTERO := 3

enum Fase { JUEGO, DESCANSO, EXTRA, PENALES, FINAL }
enum EstadoPenal { ESPERA, EN_VUELO, RESULTADO }

# --- El reloj ---
const MINUTO := 60.0                  # segundos de juego que tiene un minuto
const FIN_1T := 45.0 * MINUTO
const FIN_2T := 90.0 * MINUTO
const FIN_EXTRA := 120.0 * MINUTO
const SEGUNDOS_DESCANSO := 10.0
const RONDAS_PENALES := 8

# --- La cancha (igual que en cancha.gd) ---
const MITAD_LARGO := 60.0
const MITAD_ANCHO := 38.0
const MITAD_PORTERIA := 5.0           # mitad del arco de 10 m
const PUNTO_PENAL := 11.0
const AREA_PROFUNDIDAD := 16.5
const AREA_MITAD_ANCHO := 20.0

const ZOOM_ALTO := 36.0               # cuántos metros se ven de alto
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

# --- Penales ---
var penales_mios := 0
var penales_rival := 0
var ronda_penal := 0
var turno_mio := true
var penal_estado := EstadoPenal.ESPERA
var penal_tiempo := 0.0


func _ready() -> void:
	add_child(Escenario.new())
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


func _physics_process(_delta: float) -> void:
	if pausado or terminado or congelado:
		return
	if fase == Fase.PENALES:
		_revisar_gol()
		return
	_marcar_dueno_del_balon()
	_revisar_gol()


## Decide quién tiene el balón y quién es el más cercano de cada equipo.
## El dueño es el más cercano, pero el que ya lo tiene conserva una ventaja
## (si no, se lo quitarían todo el tiempo).
func _marcar_dueno_del_balon() -> void:
	if balon == null:
		return

	var mejor = null
	var mejor_distancia := 1000000.0
	var mas_cercano := [null, null]
	var distancia_equipo := [1000000.0, 1000000.0]

	for f in futbolistas:
		if not f.visible:
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
			d -= 0.40                     # tu jugador tiene una ayudita
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


func _revisar_gol() -> void:
	if balon == null or congelado:
		return
	var p: Vector2 = balon.position
	if absf(p.y) >= MITAD_PORTERIA:
		return
	if p.x > MITAD_LARGO:
		_gol(true)
	elif p.x < -MITAD_LARGO:
		_gol(false)


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
	var mejor = null
	var mejor_distancia := 1000000.0
	for f in futbolistas:
		if f.equipo != 0 or f.rol == ARQUERO or f == controlado:
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
	_parar_todos()

	await get_tree().create_timer(2.2).timeout
	if terminado:
		return
	_saque_de_centro()
	congelado = false


func _saque_de_centro() -> void:
	balon.reiniciar(Vector2.ZERO)
	dueno_balon = null
	for f in futbolistas:
		f.quieto = false
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
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ---------------------------------------------------------------- penales ---

func _empezar_penales() -> void:
	fase = Fase.PENALES
	penales_mios = 0
	penales_rival = 0
	ronda_penal = 0
	turno_mio = true
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
	penal_estado = EstadoPenal.ESPERA
	penal_tiempo = 0.0

	var equipo_tirador := 0 if turno_mio else 1
	var tirador = _buscar(equipo_tirador, DELANTERO)
	var arquero = _arquero_de(1 - equipo_tirador)
	var signo := 1.0 if turno_mio else -1.0
	var punto := Vector2(signo * (MITAD_LARGO - PUNTO_PENAL), 0.0)

	balon.reiniciar(punto)

	for f in futbolistas:
		f.quieto = false
		f.en_penal = false
		if f == tirador or f == arquero:
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

	if arquero != null:
		arquero.velocidad = 9.5
		arquero.position = Vector2(signo * (MITAD_LARGO - 1.6), 0.0)
		# La regla del penal: el arquero se queda clavado en la línea
		# hasta que el otro patee. Recién ahí se puede mover.
		arquero.quieto = true

	if tirador != null:
		tirador.en_penal = turno_mio
		tirador.controlado = turno_mio
		tirador.position = punto - Vector2(signo * 3.0, 0.0)
		tirador.rotation = tirador.angulo_hacia(Vector2(signo, 0.0))
		tirador.velocity = Vector2.ZERO

	if turno_mio:
		if controlado != null and controlado != tirador:
			controlado.controlado = false
		controlado = tirador


func _actualizar_penales(delta: float) -> void:
	penal_tiempo += delta
	match penal_estado:
		EstadoPenal.ESPERA:
			if turno_mio:
				if balon.velocidad.length() > 8.0:
					_soltar_arquero()
					penal_estado = EstadoPenal.EN_VUELO
					penal_tiempo = 0.0
			elif penal_tiempo > 1.8:
				_soltar_arquero()
				_tirar_penal_rival()
				penal_estado = EstadoPenal.EN_VUELO
				penal_tiempo = 0.0
		EstadoPenal.EN_VUELO:
			if penal_tiempo > 3.0:
				_terminar_penal(false)


## Ya pateó: ahora sí el arquero puede moverse para atajar.
func _soltar_arquero() -> void:
	var arquero = _arquero_de(1 if turno_mio else 0)
	if arquero != null:
		arquero.quieto = false


func _tirar_penal_rival() -> void:
	var tirador = _buscar(1, DELANTERO)
	if tirador == null:
		return
	var altura := randf_range(-3.4, 3.4)
	var objetivo := Vector2(-MITAD_LARGO, altura)
	tirador.hacia = (objetivo - tirador.position).normalized()
	tirador.rotation = tirador.angulo_hacia(tirador.hacia)
	tirador.patear(24.0, 0.0)


func _terminar_penal(fue_gol: bool) -> void:
	if penal_estado == EstadoPenal.RESULTADO or terminado:
		return
	penal_estado = EstadoPenal.RESULTADO

	if fue_gol:
		if turno_mio:
			penales_mios += 1
			hud.mostrar_mensaje("¡GOOOL!", 1.5)
		else:
			penales_rival += 1
			hud.mostrar_mensaje("GOL DEL RIVAL", 1.5)
	else:
		hud.mostrar_mensaje("¡ATAJÓ EL ARQUERO!", 1.5)

	balon.velocidad = Vector2.ZERO
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
	var texto := "PENALES: GANASTE  %d - %d" % [penales_mios, penales_rival]
	if penales_rival > penales_mios:
		texto = "PENALES: PERDISTE  %d - %d" % [penales_mios, penales_rival]
	hud.mostrar_mensaje(texto, 4.0)

	await get_tree().create_timer(4.5).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


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
