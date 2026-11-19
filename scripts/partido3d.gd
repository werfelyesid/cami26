extends Node3D
## EL PARTIDO 3D: 11 contra 11, con la cámara de la tele siguiendo el balón.
##
## Las reglas, como en el fútbol de verdad:
##   - 11 jugadores por equipo, cada uno con su puesto y su media. El que tiene
##     más media corre más, patea más fuerte y falla menos.
##   - El balón sale del campo y hay SAQUE DE BANDA, CÓRNER o SAQUE DE ARCO,
##     según por dónde salió y quién la tocó último.
##   - Las faltas existen para los dos lados: si te barren y te pegan es falta
##     (y dentro del área, penal). Tú también puedes barrerte con X y hacerle
##     falta al rival.
##   - Al que tiene la pelota NO se la pueden quitar tocándosela: solo con una
##     barrida, y eso es falta.
##
## El reloj muestra los 90 minutos de siempre: 45 al descanso (10 segundos de
## pausa) y 90 al final. Si van empatados, GOL DE ORO.

const Escenario = preload("res://scripts/estadio3d.gd")
const Balon = preload("res://scripts/balon3d.gd")
const Jugador = preload("res://scripts/jugador3d.gd")
const Hud = preload("res://scripts/hud.gd")
const Controles = preload("res://scripts/controles_tactiles.gd")

# --- La cancha (las mismas medidas del estadio) ---
const MITAD_LARGO := 52.5
const MITAD_ANCHO := 34.0
const ANCHO_ARCO := 7.32
const ALTO_ARCO := 2.44
const AREA_PROFUNDIDAD := 16.5
const AREA_MITAD_ANCHO := 20.16
const PUNTO_PENAL := 11.0

# --- La formación: 1 arquero, 4 defensas, 3 medios y 3 delanteros ---
## x va de -1 (arco propio) a +1 (arco rival) y z de -1 a +1 (las bandas).
const FORMACION := [
	{"rol": 0, "x": -0.96, "z": 0.00},
	{"rol": 1, "x": -0.66, "z": -0.62},
	{"rol": 1, "x": -0.74, "z": -0.21},
	{"rol": 1, "x": -0.74, "z": 0.21},
	{"rol": 1, "x": -0.66, "z": 0.62},
	{"rol": 2, "x": -0.36, "z": -0.30},
	{"rol": 2, "x": -0.42, "z": 0.30},
	{"rol": 2, "x": -0.10, "z": 0.00},
	{"rol": 3, "x": 0.30, "z": -0.62},
	{"rol": 3, "x": 0.42, "z": 0.00},
	{"rol": 3, "x": 0.30, "z": 0.62},
]
## El índice del jugador que manejas al empezar (el 9, el delantero centro).
const INDICE_HUMANO := 9

# --- El reloj ---
## Cuánto dura el partido de verdad, en segundos.
const PARTIDO_REAL := 160.0
## Cuántos segundos de reloj pasan por cada segundo de verdad (33,75).
## Así el marcador recorre los 90 minutos en 160 segundos.
const MINUTO := (90.0 * 60.0) / PARTIDO_REAL
## Cuándo se termina cada tiempo, en segundos DE VERDAD.
const FIN_1T := PARTIDO_REAL * 0.5
const FIN_2T := PARTIDO_REAL
const DESCANSO := 8.0

enum Fase { JUEGO, DESCANSO, GOL, PENAL, SAQUE, FINAL }

# --- El partido ---
var balon = null
var equipos := [[], []]
var arqueros := [null, null]
var humano = null
var controlado = null
var camara: Camera3D
var hud = null
var controles = null
var menu_pausa: CanvasLayer

var goles_mios := 0
var goles_rival := 0
var tiempo := 0.0
var fase := Fase.JUEGO
var terminado := false
var congelado := false
var liga: Dictionary = {}

# --- La posesión y el último toque ---
var _dueno = null
var _dueno_equipo := -1
var _ultimo_toque = null
var _ultimo_equipo := 0
## Cuánto tiempo lleva cada rival pegado al que tiene la pelota (para robar).
var _pegado := {}
## Para no cobrar dos faltas seguidas por la misma jugada.
var _espera_falta := 0.0

# --- Los saques ---
var _saque_tipo := ""
var _saque_equipo := 0
var _saque_punto := Vector3.ZERO
var _saque_tomador = null
var _reloj_saque := 0.0

# --- Los penales ---
var _penal_equipo := 0
var _penal_tirador = null
var _penal_arquero = null
var _penal_espera := 0.0
var _penal_tirado := false
var _penal_reloj := 0.0

# --- El reloj del descanso y el gol de oro ---
var _descanso_hecho := false
var _reloj_descanso := 0.0
var _gol_de_oro := false
var _modo_camara := 0

# --- Los colores de las camisetas (uno por equipo, bien distintos) ---
var _colores := []
var _color_arquero := [Color(0.95, 0.78, 0.12), Color(0.10, 0.62, 0.35)]

# --- Las estadísticas del partido (como en FIFA) ---
var stats := {
	0: {"posesion": 0.0, "tiros": 0, "al_arco": 0, "corners": 0, "faltas": 0, "amarillas": 0},
	1: {"posesion": 0.0, "tiros": 0, "al_arco": 0, "corners": 0, "faltas": 0, "amarillas": 0},
}
## Quién metió los goles (nombre -> cuántos).
var _goleadores := {"": 0}
var _ultimo_goleador := ""

# --- El tiempo añadido (el "45+2" y el "90+4" del fútbol de verdad) ---
var _agregado_1t := 0.0
var _agregado_2t := 0.0

# --- El radar ---
var _radar: Control = null
## Cuántas veces la máquina tiró al arco (para probar el ataque).
var tiros := 0


func _ready() -> void:
	# El tiempo añadido: de 1 a 3 minutos en el primero y de 2 a 5 en el segundo.
	# Va en segundos de verdad, así que los minutos se pasan con MINUTO.
	_agregado_1t = randf_range(1.0, 3.0) * 60.0 / MINUTO
	_agregado_2t = randf_range(2.0, 5.0) * 60.0 / MINUTO
	add_child(Escenario.new())
	_colores = _elegir_colores()
	_crear_balon()
	_crear_equipos()
	_crear_camara()
	_crear_interfaz()
	_poner_nombres()
	hud.poner_colores(_colores[0]["camiseta"], _colores[1]["camiseta"])
	# Si es leyenda, el nombre ya se ve dorado arriba: no lo repetimos en blanco.
	humano.mostrar_indicador(true, "" if humano.leyenda else humano.nombre)
	_saque_de_centro()


# ------------------------------------------------------------------ armado ---

## Elige las camisetas de los dos equipos.
##
## Si está puesto "colores al azar" (como en la pantalla de elegir club), se
## inventan dos colores MUY distintos entre sí, así nunca se confunden. Si no,
## se usan los del club, pero si se parecen demasiado se le cambia uno al rival.
func _elegir_colores() -> Array:
	var azar := bool(Datos.partido_de_liga.get("colores_azar", true))
	var club_local := Clubes.buscar(str(Datos.partido_de_liga.get("club_local", "")))
	var club_rival := Clubes.buscar(str(Datos.partido_de_liga.get("rival", "")))

	var uno: Color
	var otro: Color
	if azar or club_local.is_empty() or club_rival.is_empty():
		uno = _color_al_azar()
		otro = _color_al_azar(uno.h)
	else:
		uno = Cartas.color_de(str(club_local.get("color_principal", "#2050d0")))
		otro = Cartas.color_de(str(club_rival.get("color_principal", "#d02020")))

	# Si aun así quedaron parecidos (dos blancos, por ejemplo), se cambia uno.
	if _se_parecen(uno, otro):
		otro = _color_al_azar(uno.h)
	if _se_parecen(uno, otro):
		otro = Color.from_hsv(fposmod(uno.h + 0.5, 1.0), 0.85, 0.75)

	# Los arqueros van de otro color, como manda la regla.
	_color_arquero = [
		_color_al_azar(uno.h if not _se_parecen(uno, Color(0.95, 0.78, 0.12)) else otro.h),
		_color_al_azar(otro.h),
	]

	return [
		{"camiseta": uno, "pantalon": _contraste(uno), "medias": uno},
		{"camiseta": otro, "pantalon": _contraste(otro), "medias": otro},
	]


## Un color fuerte al azar. Nunca verde (se perdería en el pasto) y nunca
## parecido a `evitar` (el color del otro equipo).
func _color_al_azar(evitar := -1.0) -> Color:
	for intento in 80:
		var h := randf()
		if h > 0.23 and h < 0.44:
			continue
		if evitar >= 0.0 and _distancia_tono(h, evitar) < 0.30:
			continue
		return Color.from_hsv(h, randf_range(0.70, 0.98), randf_range(0.62, 1.0))
	return Color(0.15, 0.35, 0.92)


## Qué tan lejos están dos tonos de color (0 = iguales, 0,5 = opuestos).
func _distancia_tono(a: float, b: float) -> float:
	return absf(fposmod(a - b + 0.5, 1.0) - 0.5)


## ¿Dos colores se confunden a la distancia?
func _se_parecen(a: Color, b: Color) -> bool:
	var los_dos_claros := a.get_luminance() > 0.78 and b.get_luminance() > 0.78
	var mismo_tono := _distancia_tono(a.h, b.h) < 0.14 \
		and absf(a.s - b.s) < 0.35 and absf(a.v - b.v) < 0.45
	return los_dos_claros or mismo_tono


## La pantaloneta: oscura si la camiseta es clara, y clara si es oscura.
func _contraste(c: Color) -> Color:
	return Color(0.10, 0.10, 0.13) if c.get_luminance() > 0.5 else Color(0.95, 0.95, 0.98)


func _crear_balon() -> void:
	balon = Balon.new()
	balon.position = Vector3(0.0, 0.5, 0.0)
	add_child(balon)


func _crear_equipos() -> void:
	_crear_equipo(0)
	_crear_equipo(1)
	humano = equipos[0][INDICE_HUMANO]
	controlado = humano


## Arma uno de los dos equipos: 11 jugadores en su formación.
func _crear_equipo(equipo_id: int) -> void:
	var datos := _once_de(equipo_id)
	var lista: Array = []

	for i in FORMACION.size():
		var puesto: Dictionary = FORMACION[i]
		var quien: Dictionary = datos[i]

		# En TU equipo juegan las tres leyendas: Neymar, Cristiano y Messi.
		if equipo_id == 0:
			var leyenda: Dictionary = _leyenda(i)
			if not leyenda.is_empty():
				quien = leyenda

		var j = Jugador.new()
		j.equipo = equipo_id
		j.rol = int(puesto["rol"])
		j.numero = int(quien.get("dorsal", i + 1))
		j.nombre = str(quien.get("nombre", "Jugador"))
		# La camiseta sale de la paleta del equipo (colores bien distintos).
		var paleta: Dictionary = _colores[equipo_id]
		j.color_camiseta = paleta["camiseta"]
		j.color_pantalon = paleta["pantalon"]
		j.color_medias = paleta["medias"]
		j.color_piel = quien.get("piel", Color(0.80, 0.60, 0.44))
		j.color_pelo = quien.get("pelo", Color(0.10, 0.08, 0.06))
		# El número se ve bien sobre camiseta clara y sobre oscura.
		j.numero_color = Color(0.10, 0.10, 0.12) if j.color_camiseta.get_luminance() > 0.55 \
			else Color(0.98, 0.98, 0.98)
		if j.rol == Jugador.Rol.ARQUERO:
			# El arquero va con otro color, para no confundirse con los suyos.
			j.color_camiseta = _color_arquero[equipo_id]
			j.color_medias = _color_arquero[equipo_id]
			j.color_pantalon = _contraste(_color_arquero[equipo_id])

		# Dónde juega.
		var base := Vector3(float(puesto["x"]) * MITAD_LARGO, 0.0, float(puesto["z"]) * MITAD_ANCHO)
		if equipo_id == 1:
			base.x = -base.x
		j.formacion = base
		j.arco_propio = -MITAD_LARGO if equipo_id == 0 else MITAD_LARGO
		j.arco_rival = MITAD_LARGO if equipo_id == 0 else -MITAD_LARGO
		j.balon = balon
		j.es_humano = (equipo_id == 0 and i == INDICE_HUMANO)

		add_child(j)
		j.global_position = base
		# La dificultad elegida sube o baja la media del rival (como en FIFA).
		var media: int = int(quien.get("media", 70))
		if equipo_id == 1:
			media += [-7, 0, 7][clampi(Ajustes.dificultad, 0, 2)]
		j.poner_media(media)
		var es_leyenda := bool(quien.get("leyenda", false))
		var nombre_leyenda := str(quien.get("nombre", ""))
		j.poner_leyenda(es_leyenda, nombre_leyenda)
		if j.rol == Jugador.Rol.ARQUERO:
			# El arquero se mueve más lento que un jugador de campo: si no, ataja
			# todo. Con media 90 llega a 4,8 m/s, como uno de verdad.
			j._vel_base *= 0.55
		j.falta_cometida.connect(_falta)
		j.remate.connect(_contar_remate)

		lista.append(j)
		if j.rol == Jugador.Rol.ARQUERO:
			arqueros[equipo_id] = j

	equipos[equipo_id] = lista


## Los once de un equipo, ya ordenados como los pide la formación: primero el
## arquero, después 4 defensas, 3 medios y 3 delanteros. Los mejores juegan.
## Las tres leyendas de tu equipo, con 130 de media. Van en los tres puestos
## de ataque: 8 = izquierda (Neymar), 9 = centro (Cristiano) y 10 = derecha
## (Messi). El 9 es el que manejas al empezar.
func _leyenda(i: int) -> Dictionary:
	match i:
		8:
			return {
				"nombre": "NEYMAR", "dorsal": 11, "media": 130, "leyenda": true,
				"piel": Color(0.80, 0.58, 0.42), "pelo": Color(0.12, 0.08, 0.05),
			}
		9:
			return {
				"nombre": "CRISTIANO", "dorsal": 7, "media": 130, "leyenda": true,
				"piel": Color(0.87, 0.67, 0.50), "pelo": Color(0.15, 0.10, 0.07),
			}
		10:
			return {
				"nombre": "MESSI", "dorsal": 10, "media": 130, "leyenda": true,
				"piel": Color(0.84, 0.63, 0.47), "pelo": Color(0.22, 0.14, 0.07),
			}
	return {}


func _once_de(equipo_id: int) -> Array:
	var crudos := _mi_plantilla() if equipo_id == 0 else _plantilla_del_rival()

	# Se separan por puesto y se ordenan de mejor a peor.
	var por_rol := {0: [], 1: [], 2: [], 3: []}
	for c in crudos:
		var r := Clubes.rol_de(str(c.get("puesto", "MC")))
		por_rol[r].append(c)
	for r in por_rol:
		por_rol[r].sort_custom(func(a, b): return int(a.get("media", 0)) > int(b.get("media", 0)))

	var once: Array = []
	for puesto in FORMACION:
		var r := int(puesto["rol"])
		var elegido: Dictionary = {}
		if not por_rol[r].is_empty():
			elegido = por_rol[r].pop_front()
		else:
			# Si a ese equipo le faltan jugadores de ese puesto, se usa cualquiera.
			for otro in [3, 2, 1, 0]:
				if not por_rol[otro].is_empty():
					elegido = por_rol[otro].pop_front()
					break
		if elegido.is_empty():
			elegido = _jugador_de_relleno(r)
		once.append(elegido)

	return once


## Tu equipo.
##
## Si elegiste un club en la pantalla de antes del partido, juegas con SU once
## (sus jugadores y sus medias). Si no elegiste ninguno, juegas con las cartas
## que tienes puestas en MI PLANTILLA.
func _mi_plantilla() -> Array:
	var id := str(Datos.partido_de_liga.get("club_local", ""))
	if id != "":
		var club := Clubes.buscar(id)
		if not club.is_empty():
			return _plantilla_de_club(club)

	var lista: Array = []
	for indice in Datos.plantilla.get("titulares", []):
		var i := int(indice)
		if i < 0 or i >= Datos.inventario.size():
			continue
		var carta: Dictionary = Datos.inventario[i]
		lista.append({
			"nombre": str(carta.get("nombre", "Jugador")),
			"puesto": str(carta.get("puesto", "MC")),
			"dorsal": int(carta.get("dorsal", lista.size() + 1)),
			"media": int(carta.get("ovr", 70)),
		})

	if lista.size() < 11:
		# Faltan cartas: se completa con jugadores de casa.
		lista.clear()
		var azar := RandomNumberGenerator.new()
		azar.seed = 20261024
		var puestos := ["POR", "LI", "DFC", "DFC", "LD", "MC", "MC", "MCO", "EI", "DC", "ED"]
		for i in 11:
			lista.append({
				"nombre": "Casa %d" % (i + 1),
				"puesto": puestos[i],
				"dorsal": i + 1,
				"media": azar.randi_range(62, 74),
			})
	return lista


## El rival: el club que elegiste (o uno cualquiera si no elegiste).
func _plantilla_del_rival() -> Array:
	var club := {}
	if not Datos.partido_de_liga.is_empty():
		club = Clubes.buscar(str(Datos.partido_de_liga.get("rival", "")))
	if club.is_empty():
		var todos := Clubes.cargar_todos()
		if not todos.is_empty():
			club = todos[randi() % todos.size()]
	if club.is_empty():
		return []
	return _plantilla_de_club(club)


## Los once de un club, con su nombre, su puesto, su dorsal y su media.
func _plantilla_de_club(club: Dictionary) -> Array:
	var lista: Array = []
	for jugador in Clubes.titulares(club):
		lista.append({
			"nombre": str(jugador.get("n", "Jugador")),
			"puesto": str(jugador.get("p", "MC")),
			"dorsal": int(jugador.get("d", 1)),
			"media": Clubes.ovr(jugador),
		})
	return lista


func _jugador_de_relleno(rol: int) -> Dictionary:
	return {
		"nombre": "Jugador",
		"puesto": "MC",
		"dorsal": 12,
		"media": 68,
		"camiseta": Color(0.10, 0.30, 0.85),
		"pantalon": Color(0.96, 0.96, 0.99),
	}


func _crear_camara() -> void:
	camara = Camera3D.new()
	camara.fov = 42.0
	camara.near = 0.2
	camara.far = 400.0
	camara.position = Vector3(0.0, 12.0, 20.0)
	add_child(camara)
	camara.current = true
	camara.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	humano.camara = camara


func _crear_interfaz() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.pausa_pedida.connect(_pausar)

	controles = Controles.new()
	hud.add_child(controles)
	humano.controles = controles

	# El radar de la esquina (como el de FIFA).
	_radar = preload("res://scripts/minimapa.gd").new()
	_radar.partido = self
	_radar.position = Vector2(16.0, 104.0)
	hud.add_child(_radar)

	_crear_menu_pausa()


func _crear_menu_pausa() -> void:
	menu_pausa = CanvasLayer.new()
	menu_pausa.layer = 5
	menu_pausa.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(menu_pausa)

	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.03, 0.05, 0.72)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_pausa.add_child(fondo)

	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_CENTER)
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BOTH
	caja.add_theme_constant_override("separation", 14)
	menu_pausa.add_child(caja)

	var titulo := Label.new()
	titulo.text = "PAUSA"
	titulo.add_theme_font_size_override("font_size", 54)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)

	var seguir := Button.new()
	seguir.text = "SEGUIR JUGANDO"
	seguir.custom_minimum_size = Vector2(320.0, 66.0)
	seguir.add_theme_font_size_override("font_size", 24)
	seguir.pressed.connect(_seguir)
	caja.add_child(seguir)

	var menu := Button.new()
	menu.text = "SALIR AL MENÚ"
	menu.custom_minimum_size = Vector2(320.0, 66.0)
	menu.add_theme_font_size_override("font_size", 24)
	menu.pressed.connect(_salir_al_menu)
	caja.add_child(menu)

	menu_pausa.visible = false


func _poner_nombres() -> void:
	liga = Datos.partido_de_liga.duplicate()
	if liga.is_empty():
		return
	var mio := Clubes.buscar(str(Datos.carrera.get("club", "")))
	var suyo := Clubes.buscar(str(liga.get("rival", "")))
	var mi_corto := str(mio.get("corto", "TÚ"))
	var su_corto := str(suyo.get("corto", "RIVAL"))
	if bool(liga.get("soy_local", true)):
		hud.poner_nombres(mi_corto, su_corto)
	else:
		hud.poner_nombres(su_corto, mi_corto)


# ------------------------------------------------------------ saque de centro ---

func _saque_de_centro() -> void:
	_quitar_balon()
	fase = Fase.JUEGO
	_modo_camara = 0
	balon.reiniciar(Vector3(0.0, 0.4, 0.0))

	for equipo_id in [0, 1]:
		for j in equipos[equipo_id]:
			j.velocity = Vector3.ZERO
			j.tiene_destino = false
			j.correr = false
			j.mirar_a = Vector3.ZERO
			j.modo_penal = false
			var base: Vector3 = j.formacion
			# En el saque de centro todos están en su puesto, un poquito atrás.
			j.global_position = Vector3(base.x * 0.92, 0.0, base.z)

	# El que saca arranca con el balón.
	if humano != null and not humano.es_humano:
		humano = equipos[0][INDICE_HUMANO]
	var sacador = equipos[0][INDICE_HUMANO]
	sacador.global_position = Vector3(-1.2, 0.0, 0.0)
	_dar_balon(sacador)


# ---------------------------------------------------------------- cada cuadro ---

func _process(delta: float) -> void:
	if terminado:
		return

	_seguir_camara(delta)
	_actualizar_hud()

	if _espera_falta > 0.0:
		_espera_falta -= delta

	if congelado:
		return

	match fase:
		Fase.JUEGO:
			tiempo += delta
			if _dueno_equipo >= 0:
				stats[_dueno_equipo]["posesion"] += delta
			_pensar_todos(delta)
			_revisar_agarres(delta)
			if not _descanso_hecho and tiempo >= FIN_1T + _agregado_1t:
				_empezar_descanso()
			elif tiempo >= FIN_2T + _agregado_2t:
				if goles_mios == goles_rival:
					if not _gol_de_oro:
						_gol_de_oro = true
						hud.mostrar_mensaje("GOL DE ORO", 2.4)
				else:
					_finalizar()
		Fase.DESCANSO:
			_reloj_descanso -= delta
			if _reloj_descanso <= 0.0:
				fase = Fase.JUEGO
				hud.ocultar_estadisticas()
				hud.mostrar_mensaje("¡SEGUNDO TIEMPO!", 1.8)
		Fase.SAQUE:
			_reloj_saque -= delta
			if _reloj_saque <= 0.0:
				_ejecutar_saque()
		Fase.PENAL:
			_procesar_penal(delta)


func _physics_process(_delta: float) -> void:
	if controles != null and controles.cambiar:
		controles.cambiar = false
		_cambiar_jugador()

	if congelado or terminado:
		return

	_decidir_dueno()

	# Perro guardián: si un saque o un penal se quedó colgado, se destraba.
	if fase == Fase.SAQUE and _reloj_saque < -2.0:
		_ejecutar_saque()
	elif fase == Fase.PENAL and _penal_reloj < -6.0:
		_terminar_penal("")

	if fase == Fase.JUEGO:
		_revisar_balon()
	elif fase == Fase.PENAL:
		_revisar_penal_balon()


# ------------------------------------------------------------------ la cámara ---

## La cámara sigue al BALÓN: siempre queda en el centro de la pantalla, y se
## mueve suavecito (si saltara de golpe marearía).
func _seguir_camara(delta: float) -> void:
	if _modo_camara == 1:
		_seguir_camara_penal(delta)
		return

	var foco: Vector3 = balon.global_position
	# Un poquito hacia donde va el balón, para ver lo que viene.
	var adelanto := Vector3(balon.linear_velocity.x, 0.0, balon.linear_velocity.z) * 0.14
	foco += adelanto.limit_length(5.0)

	# La cámara va detrás del balón, pero SIN meterse en las tribunas (que
	# empiezan a 40 m del medio): si se metía, se veía todo negro.
	var cam_z := clampf(foco.z + 20.0, -37.0, 37.0)
	var cam_x := clampf(foco.x, -46.0, 46.0)
	var destino_cam := Vector3(cam_x, 12.0, cam_z)
	camara.global_position = camara.global_position.lerp(destino_cam, minf(1.0, delta * 3.2))
	camara.look_at(Vector3(foco.x, 1.2, foco.z), Vector3.UP)


## En el penal la cámara se pone detrás del pateador.
func _seguir_camara_penal(delta: float) -> void:
	var signo := 1.0 if _penal_equipo == 0 else -1.0
	var punto := Vector3(signo * (MITAD_LARGO - PUNTO_PENAL), 0.0, 0.0)
	var destino := Vector3(punto.x - signo * 7.5, 3.2, 0.4)
	camara.global_position = camara.global_position.lerp(destino, minf(1.0, delta * 3.4))
	camara.look_at(Vector3(signo * MITAD_LARGO, 1.1, 0.0), Vector3.UP)


func _actualizar_hud() -> void:
	var texto := "PRIMER TIEMPO"
	if _gol_de_oro:
		texto = "GOL DE ORO"
	elif _descanso_hecho:
		texto = "SEGUNDO TIEMPO"
	if fase == Fase.DESCANSO:
		texto = "DESCANSO"
	elif fase == Fase.FINAL:
		texto = "FINAL"
	elif fase == Fase.PENAL:
		texto = "PENAL"
	elif fase == Fase.SAQUE:
		texto = "SAQUE"

	var segundos := tiempo * MINUTO
	hud.actualizar(goles_mios, goles_rival, segundos, texto, "")

	# El reloj del fútbol de verdad: "45+2" y "90+4".
	var minutos := segundos / 60.0
	if minutos > 90.0:
		hud.reloj.text = "90+%d" % int(ceil(minutos - 90.0))
	elif minutos > 45.0 and (fase == Fase.DESCANSO or not _descanso_hecho):
		hud.reloj.text = "45+%d" % int(ceil(minutos - 45.0))

	if controlado != null:
		hud.potencia(controlado.potencia if controlado.es_humano else 0.0)
		hud.energia(controlado.energia if controlado.es_humano else -1.0)


# ------------------------------------------------------- la cabeza de la máquina ---

## Decide a dónde va cada uno de los 20 jugadores que no manejas.
func _pensar_todos(delta: float) -> void:
	var bpos: Vector3 = balon.global_position

	for equipo_id in [0, 1]:
		var lista: Array = equipos[equipo_id]
		var ataca := 1.0 if equipo_id == 0 else -1.0
		var tiene_balon: bool = (_dueno_equipo == equipo_id)
		var mas_cercano = _mas_cercano(lista, bpos, true)

		for j in lista:
			if j.es_humano:
				j.mirar_a = Vector3.ZERO
				continue
			if j.barriendo() or j.en_el_piso() or j.agarrando():
				j.tiene_destino = false
				continue

			# --- el arquero ---
			if j.rol == Jugador.Rol.ARQUERO:
				_pensar_arquero(j)
				continue

			# --- el que tiene la pelota ---
			if j == _dueno:
				_pensar_con_balon(j, delta)
				continue

			j.correr = false
			j.mirar_a = Vector3.ZERO

			# --- al que se le fue la pelota, la va a buscar ---
			if _dueno == null and j == mas_cercano:
				j.tiene_destino = true
				j.destino = Vector3(bpos.x, 0.0, bpos.z)
				j.correr = true
				continue

			# --- el rival tiene la pelota ---
			if _dueno != null and _dueno_equipo != equipo_id:
				var al_que_marcar = _dueno
				if j == mas_cercano:
					# Lo persigue, pero se queda del lado de su arco: no lo
					# atropella (eso sería falta).
					var hacia_su_arco: Vector3 = Vector3(j.arco_propio, 0.0, 0.0) - al_que_marcar.global_position
					hacia_su_arco.y = 0.0
					if hacia_su_arco.length() > 0.1:
						hacia_su_arco = hacia_su_arco.normalized()
					j.tiene_destino = true
					j.destino = al_que_marcar.global_position + hacia_su_arco * 1.35
					j.correr = true
					j.mirar_a = al_que_marcar.global_position

					# Y de vez en cuando se tira una barrida (si le pega, es falta).
					var cerca: float = j.global_position.distance_to(al_que_marcar.global_position)
					if cerca < 2.0 and j.puede_barrerse() and randf() < delta * 0.05:
						j.mirar_a = al_que_marcar.global_position
						j.empezar_barrida(al_que_marcar.global_position - j.global_position)
					continue

			# --- los demás: a su puesto, corriendo según el balón ---
			var objetivo := _puesto_ahora(j, bpos, ataca, tiene_balon)
			j.tiene_destino = true
			j.destino = objetivo
			# Los delanteros y los medios acompañan la jugada.
			j.correr = j.rol == Jugador.Rol.DELANTERO and tiene_balon


## Dónde tiene que estar un jugador sin la pelota: en su puesto, corrido hacia
## donde está el balón (como se mueve un equipo de verdad).
func _puesto_ahora(j, bpos: Vector3, ataca: float, tiene_balon: bool) -> Vector3:
	var base: Vector3 = j.formacion
	var corrimiento := clampf(bpos.x * 0.45, -22.0, 22.0)
	var x := base.x + corrimiento
	var z := base.z + (bpos.z - base.z) * 0.28

	if tiene_balon:
		# Con la pelota, los de arriba se abren para recibir.
		x += ataca * (6.0 if j.rol == Jugador.Rol.DELANTERO else 3.0)
	else:
		# Sin la pelota, todos vuelven un poco.
		x -= ataca * (5.0 if j.rol == Jugador.Rol.DELANTERO else 3.0)

	x = clampf(x, -MITAD_LARGO + 2.0, MITAD_LARGO - 2.0)
	z = clampf(z, -MITAD_ANCHO + 2.0, MITAD_ANCHO - 2.0)
	return Vector3(x, 0.0, z)


## El que tiene la pelota: la lleva hacia el arco y, si está cerca, dispara.
func _pensar_con_balon(j, delta: float) -> void:
	var gol := Vector3(j.arco_rival, 0.0, 0.0)
	var distancia := absf(gol.x - j.global_position.x)
	j.correr = true
	j.tiene_destino = true
	j.mirar_a = gol

	# ¿Cuánto lo están apretando?
	var apuro := 99.0
	for rival in equipos[1 - j.equipo]:
		var d: float = rival.global_position.distance_to(j.global_position)
		if d < apuro:
			apuro = d

	# Tira al arco si está cerca y tiene ángulo (los de más media apuntan mejor).
	if distancia < 32.0 and j.alcance_del_balon(2.0) and randf() < delta * 4.2:
		var zona: float = randf_range(-2.4, 2.4) * (2.0 - float(j.media) / 119.0)
		if j.patear_a(Vector3(j.arco_rival, 0.9, zona), 27.0, 1.6):
			tiros += 1
			stats[j.equipo]["tiros"] += 1
			if absf(zona) < ANCHO_ARCO * 0.5:
				stats[j.equipo]["al_arco"] += 1
		return

	# Si lo aprietan mucho, la pasa a un compañero.
	if apuro < 2.3 and randf() < delta * 3.0:
		var companero = _companero_libre(j)
		if companero != null:
			j.patear_a(companero.global_position, 15.0, 1.2)
			return

	# Si no, sigue para adelante, esquivando al rival más cercano.
	var esquivar := 0.0
	for rival in equipos[1 - j.equipo]:
		var d2: Vector3 = rival.global_position - j.global_position
		d2.y = 0.0
		if d2.length() < 3.2:
			esquivar -= signf(d2.z) * 4.0
	var destino := Vector3(gol.x, 0.0, clampf(j.global_position.z + esquivar, -MITAD_ANCHO + 2.0, MITAD_ANCHO - 2.0))
	j.destino = destino


## El arquero: se mueve de palo a palo siguiendo el balón y despeja si le llega.
func _pensar_arquero(j) -> void:
	j.correr = false
	j.tiene_destino = true
	var base: Vector3 = j.formacion
	var bpos: Vector3 = balon.global_position

	# Sigue al balón, pero se queda cerca del centro: si se abriera del todo,
	# taparía cualquier tiro (un arquero de verdad no es tan rápido).
	var objetivo_z := clampf(bpos.z * 0.30, -ANCHO_ARCO * 0.34, ANCHO_ARCO * 0.34)
	var adelante := 0.6
	if absf(bpos.x - j.arco_propio) < 20.0:
		adelante = 1.4
	var objetivo_x: float = j.arco_propio + signf(-j.arco_propio) * adelante
	j.destino = Vector3(objetivo_x, 0.0, objetivo_z)
	j.mirar_a = bpos

	# Si el balón le llega y va suelto, lo agarra o lo despeja.
	if _dueno == null or _dueno == j:
		var d: Vector3 = balon.global_position - j.global_position
		d.y = 0.0
		if d.length() < 1.35 and not j.agarrando():
			if balon.linear_velocity.length() < 16.0:
				j.agarrar_balon()
				_ultimo_toque = j
				_ultimo_equipo = j.equipo
			else:
				var afuera := Vector3(-signf(j.arco_propio), 0.0, randf_range(-0.4, 0.4))
				j.patear_a(j.global_position + afuera * 25.0, 22.0, 4.0)


## Un compañero al que se le puede pasar (el más adelantado y sin marca).
func _companero_libre(j):
	var mejor = null
	var mejor_nota := -999.0
	for c in equipos[j.equipo]:
		if c == j or c.rol == Jugador.Rol.ARQUERO:
			continue
		var adelanto: float = (c.global_position.x - j.global_position.x) * signf(j.arco_rival)
		var distancia: float = c.global_position.distance_to(j.global_position)
		if distancia < 3.0 or distancia > 34.0:
			continue
		var marca := 0.0
		for rival in equipos[1 - j.equipo]:
			if rival.global_position.distance_to(c.global_position) < 2.5:
				marca += 1.0
		var nota := adelanto * 0.5 - marca * 6.0 - distancia * 0.1
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = c
	return mejor


# ------------------------------------------------------------------ posesión ---

## Quién tiene el balón. El que lo tiene se lo lleva pegado a los pies, y al
## dueño humano NO se lo pueden quitar tocándoselo (solo con una barrida).
func _decidir_dueno() -> void:
	if balon == null:
		return

	# ¿El que lo tenía se alejó o lo soltó?
	if _dueno != null:
		var sigue: bool = _dueno.dueno == _dueno
		if sigue:
			var d: Vector3 = balon.global_position - _dueno.global_position
			d.y = 0.0
			if d.length() > 2.2:
				_dueno.soltar_balon()
				sigue = false
		if not sigue:
			_dueno = null
			_dueno_equipo = -1

	# Red de seguridad: si el balón quedó congelado y sin dueño (por un saque que
	# no llegó a ejecutarse, por ejemplo), se descongela para que se pueda jugar.
	if _dueno == null and balon.freeze and not _alguien_agarrando():
		balon.freeze = false

	# ¿Alguien lo agarró?
	if _dueno == null and balon.se_puede_recoger() and balon.linear_velocity.length() < 9.0:
		var mejor = null
		var mejor_d := 1.0
		for equipo_id in [0, 1]:
			for j in equipos[equipo_id]:
				if j.agarrando() or j.barriendo() or j.en_el_piso():
					continue
				var d2: Vector3 = balon.global_position - j.global_position
				d2.y = 0.0
				if d2.length() < mejor_d:
					mejor_d = d2.length()
					mejor = j
		if mejor != null:
			_dar_balon(mejor)

	# ¿Se lo roban al que lo tiene? (solo si el dueño NO eres tú)
	if _dueno != null and not _dueno.es_humano:
		for rival in equipos[1 - _dueno_equipo]:
			if rival.agarrando() or rival.barriendo() or rival.en_el_piso():
				continue
			var d3: Vector3 = rival.global_position - _dueno.global_position
			d3.y = 0.0
			if d3.length() < 1.0:
				var gana := randf() < 0.045 * (1.0 + float(rival.media - _dueno.media) / 60.0)
				if gana:
					_dar_balon(rival)
					break

	# Se lo contamos a todos.
	for equipo_id in [0, 1]:
		for j in equipos[equipo_id]:
			j.dueno = _dueno if _dueno == j else null
			j.poseedor = _dueno


func _dar_balon(j) -> void:
	if _dueno != null and _dueno != j:
		_dueno.soltar_balon()
	_dueno = j
	_dueno_equipo = j.equipo
	_ultimo_toque = j
	_ultimo_equipo = j.equipo
	balon.freeze = false
	balon.linear_velocity = Vector3.ZERO
	balon.angular_velocity = Vector3.ZERO
	balon.global_position = j.global_position + Vector3(0.0, 0.13, 0.0)
	j.dueno = j


## Cuenta un remate: un tiro y, si iba entre los tres palos, un tiro al arco.
func _contar_remate(quien, rumbo: Vector3, _potencia: float) -> void:
	if quien == null or not is_instance_valid(quien):
		return
	# Solo cuentan los tiros que van hacia el arco de enfrente.
	if rumbo.x * signf(quien.arco_rival) <= 0.25:
		return
	stats[quien.equipo]["tiros"] += 1

	# ¿Va entre los palos? Se mira dónde cruza la línea del arco.
	var distancia_x: float = quien.arco_rival - balon.global_position.x
	if absf(rumbo.x) < 0.05:
		return
	var t: float = distancia_x / rumbo.x
	var z: float = balon.global_position.z + rumbo.z * t
	if absf(z) < ANCHO_ARCO * 0.5:
		stats[quien.equipo]["al_arco"] += 1


func _quitar_balon() -> void:
	for equipo_id in [0, 1]:
		for j in equipos[equipo_id]:
			if j.dueno == j:
				j.soltar_balon()
			j.dueno = null
			j.poseedor = null
	_dueno = null
	_dueno_equipo = -1


## ¿Algún arquero tiene el balón en las manos ahora?
func _alguien_agarrando() -> bool:
	for a in arqueros:
		if a != null and a.agarrando():
			return true
	return false


func _mas_cercano(lista: Array, punto: Vector3, sin_arquero := false):
	var mejor = null
	var mejor_d := 1e9
	for j in lista:
		if sin_arquero and j.rol == Jugador.Rol.ARQUERO:
			continue
		var d: float = j.global_position.distance_to(punto)
		if d < mejor_d:
			mejor_d = d
			mejor = j
	return mejor


## Los arqueros que atrapan el balón lo tienen 1,5 s y después lo ponen en juego.
func _revisar_agarres(delta: float) -> void:
	for equipo_id in [0, 1]:
		var a = arqueros[equipo_id]
		if a == null or not a.agarrando():
			continue
		if a.revisar_agarre(delta):
			var objetivo := Vector3(a.global_position.x + signf(-a.arco_propio) * 26.0,
				0.0, randf_range(-14.0, 14.0))
			a.soltar_agarre()
			a.patear_a(objetivo, 24.0, 4.0)


# ------------------------------------------------------- fuera de la cancha ---

## Mira si el balón se fue afuera. Depende de por dónde salió y de quién la
## tocó último: saque de banda, córner o saque de arco.
func _revisar_balon() -> void:
	if balon == null or _modo_camara != 0:
		return

	var b: Vector3 = balon.global_position
	var portador = _dueno
	if portador != null:
		b = portador.global_position

	# ¿Gol?
	if absf(b.x) > MITAD_LARGO + 0.12 and absf(b.z) < ANCHO_ARCO * 0.5 and b.y < ALTO_ARCO:
		_gol(b.x > 0.0)
		return

	# Red de seguridad: si el balón terminó muy lejos del campo (detrás del
	# arco, por ejemplo), se vuelve a poner en juego.
	if absf(b.x) > MITAD_LARGO + 8.0 or absf(b.z) > MITAD_ANCHO + 8.0:
		var en_banda := absf(b.z) > MITAD_ANCHO + 8.0
		if en_banda:
			_saque("banda", 1 - _ultimo_equipo,
				Vector3(clampf(b.x, -MITAD_LARGO + 1.5, MITAD_LARGO - 1.5), 0.35,
					signf(b.z) * (MITAD_ANCHO - 0.3)))
		else:
			_saque("arco", 1 - (0 if b.x > 0.0 else 1),
				Vector3(signf(b.x) * (MITAD_LARGO - 5.5), 0.35, 0.0))
		return

	var fuera_z := absf(b.z) > MITAD_ANCHO + 0.12
	var fuera_x := absf(b.x) > MITAD_LARGO + 0.12
	if not fuera_z and not fuera_x:
		return

	# --- por la banda: saque de banda para el otro equipo ---
	if fuera_z:
		var punto := Vector3(
			clampf(b.x, -MITAD_LARGO + 1.5, MITAD_LARGO - 1.5),
			0.35,
			signf(b.z) * (MITAD_ANCHO - 0.3))
		_saque("banda", 1 - _ultimo_equipo, punto)
		return

	# --- por la línea de fondo: córner o saque de arco ---
	var signo := signf(b.x)
	# El equipo que ataca ese arco es el 0 si el arco está en +x.
	var atacante := 0 if signo > 0.0 else 1
	if _ultimo_equipo == atacante:
		# La tocó el que atacaba: saque de arco para el que defiende.
		var punto := Vector3(signo * (MITAD_LARGO - 5.5), 0.35, randf_range(-6.0, 6.0))
		_saque("arco", 1 - atacante, punto)
	else:
		# La tocó el que defendía: córner para el que ataca.
		var punto := Vector3(signo * (MITAD_LARGO - 0.4), 0.35,
			signf(b.z) * (MITAD_ANCHO - 0.4))
		_saque("corner", atacante, punto)


## Prepara un saque: se para el juego un momento, se acomoda el balón y el
## jugador más cercano del equipo que saca lo pone en juego.
func _saque(tipo: String, equipo_id: int, punto: Vector3) -> void:
	if fase != Fase.JUEGO:
		return
	fase = Fase.SAQUE
	_saque_tipo = tipo
	_saque_equipo = equipo_id
	if tipo == "corner":
		stats[equipo_id]["corners"] += 1
	_saque_punto = punto
	_reloj_saque = 1.0

	_quitar_balon()
	balon.freeze = true
	balon.global_position = punto
	balon.linear_velocity = Vector3.ZERO

	_saque_tomador = _mas_cercano(equipos[equipo_id], punto)

	var mensajes := {
		"banda": "SAQUE DE BANDA",
		"arco": "SAQUE DE ARCO",
		"corner": "¡CÓRNER!",
		"falta": "FALTA",
	}
	hud.mostrar_mensaje(str(mensajes.get(tipo, "SAQUE")), 1.4)


func _ejecutar_saque() -> void:
	fase = Fase.JUEGO
	var t = _saque_tomador
	if t == null:
		return

	# Hacia dónde entra el balón a la cancha.
	var adentro := Vector3.ZERO
	match _saque_tipo:
		"banda":
			adentro = Vector3(0.0, 0.0, -signf(_saque_punto.z))
		"arco":
			adentro = Vector3(-signf(_saque_punto.x), 0.0, 0.0)
		"corner":
			adentro = Vector3(-signf(_saque_punto.x), 0.0, -signf(_saque_punto.z))
		_:
			adentro = Vector3(signf(t.arco_rival), 0.0, 0.0)

	t.global_position = _saque_punto + adentro * 1.1
	t.velocity = Vector3.ZERO
	t.tiene_destino = false
	t.rotation.y = atan2(-adentro.x, -adentro.z)

	balon.freeze = false
	balon.global_position = _saque_punto
	balon.linear_velocity = Vector3.ZERO
	_dar_balon(t)

	if t.es_humano:
		return       # si sacas tú, sacas tú

	t._espera_pateo = 0.0
	match _saque_tipo:
		"corner":
			# Centro al área.
			var centro := Vector3(signf(_saque_punto.x) * (MITAD_LARGO - 10.0), 0.9, randf_range(-3.0, 3.0))
			t.patear_a(centro, 19.0, 4.2)
		"arco":
			var objetivo := Vector3(t.global_position.x + signf(-t.arco_propio) * 28.0, 0.0, randf_range(-16.0, 16.0))
			t.patear_a(objetivo, 24.0, 4.0)
		"banda", "falta":
			var companero = _companero_libre(t)
			if companero == null:
				companero = _mas_cercano(equipos[_saque_equipo], t.global_position + adentro * 14.0)
			if companero != null and companero != t:
				t.patear_a(companero.global_position, 14.0, 1.2)


# ------------------------------------------------------------------ faltas ---

## Alguien le hizo falta a otro. Si fue dentro del área es PENAL; si no, tiro
## libre desde el lugar de la falta.
func _falta(faltoso, victima) -> void:
	if fase != Fase.JUEGO or congelado or terminado:
		return
	if victima == null or faltoso == null:
		return
	if _espera_falta > 0.0:
		return
	_espera_falta = 2.5

	# Las cuentas y la tarjeta (como el árbitro de FIFA).
	stats[faltoso.equipo]["faltas"] += 1
	var hay_amarilla := randf() < 0.45
	if hay_amarilla:
		stats[faltoso.equipo]["amarillas"] += 1

	var punto: Vector3 = victima.global_position
	# Es penal si la falta fue dentro del área del arco que el que recibió la
	# falta estaba atacando (el arco que defiende el que hizo la falta).
	var arco_atacado: float = victima.arco_rival
	var en_area := absf(punto.x - arco_atacado) < AREA_PROFUNDIDAD and absf(punto.z) < AREA_MITAD_ANCHO

	if en_area:
		_preparar_penal(victima.equipo)
	else:
		_saque("falta", victima.equipo, Vector3(punto.x, 0.35, punto.z))
		hud.mostrar_mensaje("AMARILLA" if hay_amarilla else "FALTA", 1.3)


# ------------------------------------------------------------------ penales ---

## Prepara un penal a favor del equipo que recibió la falta.
func _preparar_penal(equipo_id: int) -> void:
	fase = Fase.PENAL
	_modo_camara = 1
	_penal_equipo = equipo_id
	_penal_tirado = false
	_penal_reloj = 6.0
	_penal_espera = 1.6 if equipo_id == 1 else 0.0

	var signo := 1.0 if equipo_id == 0 else -1.0
	var punto := Vector3(signo * (MITAD_LARGO - PUNTO_PENAL), 0.4, 0.0)

	# El que patea: el mejor del equipo.
	_penal_tirador = _mejor_del_equipo(equipo_id, Jugador.Rol.DELANTERO)
	_penal_arquero = arqueros[1 - equipo_id]

	_quitar_balon()
	balon.freeze = false
	balon.reiniciar(punto)

	_penal_tirador.global_position = punto - Vector3(signo * 1.5, 0.0, 0.0)
	_penal_tirador.velocity = Vector3.ZERO
	_penal_tirador.mirar_a = Vector3(signo * MITAD_LARGO, 0.0, 0.0)
	_penal_tirador.modo_penal = true

	_penal_arquero.global_position = Vector3(signo * (MITAD_LARGO - 0.6), 0.0, 0.0)
	_penal_arquero.velocity = Vector3.ZERO
	_penal_arquero.modo_penal = true

	# Los demás se apartan (cada uno en un lugarcito, para que no se apilen).
	var apartado := 0
	for otro_id in [0, 1]:
		for j in equipos[otro_id]:
			if j == _penal_tirador or j == _penal_arquero:
				continue
			j.modo_penal = true
			j.tiene_destino = false
			j.global_position = Vector3(-signo * (18.0 + float(apartado % 5) * 2.4), 0.0,
				-24.0 + float(apartado / 5) * 4.0)
			j.velocity = Vector3.ZERO
			apartado += 1

	# Si el penal es mío, lo pateo yo.
	if equipo_id == 0 and _penal_tirador != controlado:
		_poner_control(_penal_tirador)

	hud.mostrar_mensaje("PENAL", 1.6)


func _mejor_del_equipo(equipo_id: int, rol: int):
	var mejor = null
	for j in equipos[equipo_id]:
		if j.rol != rol:
			continue
		if mejor == null or j.media > mejor.media:
			mejor = j
	if mejor == null:
		mejor = _mas_cercano(equipos[equipo_id], Vector3.ZERO, true)
	return mejor


## Se juega el penal.
func _procesar_penal(delta: float) -> void:
	_penal_reloj -= delta

	if _penal_equipo == 1 and not _penal_tirado:
		# El rival patea solo: espera un momento y dispara a una zona.
		_penal_espera -= delta
		if _penal_espera <= 0.0:
			var zona: float = [-ANCHO_ARCO * 0.34, 0.0, ANCHO_ARCO * 0.34][randi() % 3]
			_penal_tirador.mirar_a = Vector3(-MITAD_LARGO, 0.0, zona)
			if _penal_tirador.patear_a(Vector3(-MITAD_LARGO, 0.9, zona), 24.0, 1.5):
				stats[1]["tiros"] += 1
				if absf(zona) < ANCHO_ARCO * 0.5:
					stats[1]["al_arco"] += 1
			_penal_tirado = true
			# El arquero adivina: cuanto mejor es, más chances de tirarse bien.
			var acierta := randf() < clampf(0.18 + float(_penal_arquero.media) / 119.0 * 0.5, 0.15, 0.72)
			var su_zona: float = zona
			if not acierta:
				su_zona = -zona if zona != 0.0 else ANCHO_ARCO * 0.34
			_penal_arquero.bucear(su_zona)
		return

	# Cuando el balón sale disparado, el arquero rival se tira.
	if not _penal_tirado and _penal_equipo == 0 and balon.linear_velocity.length() > 8.0:
		_penal_tirado = true
		var zonas := [-ANCHO_ARCO * 0.34, 0.0, ANCHO_ARCO * 0.34]
		_penal_arquero.bucear(zonas[randi() % zonas.size()])

	if _penal_tirado:
		if _penal_arquero.agarrando():
			_terminar_penal("¡ATAJÓ EL ARQUERO!")
			return
		var b: Vector3 = balon.global_position
		var se_fue := absf(b.z) > ANCHO_ARCO * 1.3
		var la_saco: bool = balon.linear_velocity.x * (1.0 if _penal_equipo == 0 else -1.0) < -2.0
		if se_fue or la_saco or _penal_reloj < 2.0:
			_terminar_penal("AFUERA")

	if _penal_reloj <= 0.0:
		_terminar_penal("")


## Se terminó el penal: se vuelve a jugar desde el centro.
func _terminar_penal(mensaje: String) -> void:
	if fase != Fase.PENAL:
		return
	if mensaje != "":
		hud.mostrar_mensaje(mensaje, 1.6)
	for equipo_id in [0, 1]:
		for j in equipos[equipo_id]:
			j.modo_penal = false
			if j.agarrando():
				j.soltar_agarre()
	_modo_camara = 0
	_saque_de_centro()


## El balón dentro del área en un penal: si entra, es gol.
func _revisar_penal_balon() -> void:
	var b: Vector3 = balon.global_position
	if absf(b.x) > MITAD_LARGO + 0.12 and absf(b.z) < ANCHO_ARCO * 0.5 and b.y < ALTO_ARCO:
		var de_local := b.x > 0.0
		_gol(de_local)


# -------------------------------------------------------------------- goles ---

## ¿Es gol? `es_mio` = true si entró en el arco del rival (el de +x).
func _gol(es_mio: bool) -> void:
	if fase == Fase.FINAL or fase == Fase.GOL:
		return

	if es_mio:
		goles_mios += 1
	else:
		goles_rival += 1

	# ¿Quién la metió? El último que la tocó.
	var goleador := ""
	if _ultimo_toque != null and is_instance_valid(_ultimo_toque):
		goleador = _ultimo_toque.nombre
	if goleador != "":
		_goleadores[goleador] = int(_goleadores.get(goleador, 0)) + 1
		_ultimo_goleador = goleador

	_actualizar_hud()
	var cartel := "¡GOOOL!" if es_mio else "GOL DEL RIVAL"
	if goleador != "":
		cartel = "%s\n%s" % [cartel, goleador]
	hud.mostrar_mensaje(cartel, 2.4)

	var era_gol_de_oro := _gol_de_oro
	fase = Fase.GOL
	_modo_camara = 0
	_congelar(true)
	balon.freeze = true
	for equipo_id in [0, 1]:
		for j in equipos[equipo_id]:
			j.modo_penal = false
			if j.agarrando():
				j.soltar_agarre()

	await get_tree().create_timer(2.6).timeout

	if terminado:
		return
	balon.freeze = false
	if era_gol_de_oro:
		_gol_de_oro = false
		_congelar(false)
		_finalizar()
		return
	_saque_de_centro()
	_congelar(false)


func _congelar(si: bool) -> void:
	congelado = si
	for equipo_id in [0, 1]:
		for j in equipos[equipo_id]:
			j.set_physics_process(not si)
			if si:
				j.velocity = Vector3.ZERO


# ------------------------------------------------------------------- finales ---

func _empezar_descanso() -> void:
	fase = Fase.DESCANSO
	_descanso_hecho = true
	_reloj_descanso = DESCANSO
	hud.mostrar_mensaje("DESCANSO", 1.4)
	hud.mostrar_estadisticas("ESTADÍSTICAS", _filas_stats())


## Las filas del cartel de estadísticas (como el de FIFA).
func _filas_stats() -> Array:
	var p0 := float(stats[0]["posesion"])
	var p1 := float(stats[1]["posesion"])
	var total := maxf(p0 + p1, 0.001)
	var pos0 := int(roundf(p0 / total * 100.0))
	return [
		["%d%%" % pos0, "POSESIÓN", "%d%%" % (100 - pos0)],
		["%d" % int(stats[0]["tiros"]), "TIROS", "%d" % int(stats[1]["tiros"])],
		["%d" % int(stats[0]["al_arco"]), "TIROS AL ARCO", "%d" % int(stats[1]["al_arco"])],
		["%d" % int(stats[0]["corners"]), "CÓRNERS", "%d" % int(stats[1]["corners"])],
		["%d" % int(stats[0]["faltas"]), "FALTAS", "%d" % int(stats[1]["faltas"])],
		["%d" % int(stats[0]["amarillas"]), "AMARILLAS", "%d" % int(stats[1]["amarillas"])],
	]


func _finalizar() -> void:
	if terminado:
		return
	terminado = true
	fase = Fase.FINAL
	_congelar(true)
	balon.freeze = true

	var texto := "EMPATE  %d - %d" % [goles_mios, goles_rival]
	if goles_mios > goles_rival:
		texto = "¡GANASTE  %d - %d!" % [goles_mios, goles_rival]
	elif goles_rival > goles_mios:
		texto = "PERDISTE  %d - %d" % [goles_mios, goles_rival]
	hud.mostrar_mensaje(texto, 3.0)
	_actualizar_hud()

	var pie := ""
	if _ultimo_goleador != "":
		pie = "Goleador: %s" % _ultimo_goleador
	hud.mostrar_estadisticas("FINAL", _filas_stats(), pie)

	await get_tree().create_timer(7.0).timeout
	_ir_al_final(goles_mios > goles_rival)


func _ir_al_final(gano: bool) -> void:
	if not liga.is_empty():
		_cerrar_partido_de_liga(gano)
		return
	if gano:
		_entregar_sobre_ganado()
		get_tree().change_scene_to_file("res://scenes/sobres.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _cerrar_partido_de_liga(gano: bool) -> void:
	var soy_local := bool(liga.get("soy_local", true))
	var de_local := goles_mios if soy_local else goles_rival
	var de_visita := goles_rival if soy_local else goles_mios
	Datos.carrera_cerrar_mi_partido(de_local, de_visita)
	if gano:
		_entregar_sobre_ganado()
		Datos.volver_a = "carrera"
		get_tree().change_scene_to_file("res://scenes/sobres.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/carrera.tscn")


func _entregar_sobre_ganado() -> void:
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	var premio := Sobres.premio(azar, true)
	Datos.entregar_premio(premio["carta"], int(premio["monedas"]), int(premio["gemas"]))
	Datos.ultimo_premio = premio


# --------------------------------------------------------------------- pausa ---

func _pausar() -> void:
	get_tree().paused = true
	menu_pausa.visible = true


func _seguir() -> void:
	menu_pausa.visible = false
	get_tree().paused = false


func _salir_al_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey):
		return
	var tecla := evento as InputEventKey
	if not tecla.pressed or tecla.echo:
		return
	if tecla.keycode == KEY_ESCAPE:
		if get_tree().paused:
			_seguir()
		else:
			_pausar()
	elif tecla.keycode == KEY_Q:
		_cambiar_jugador()


## CAMBIAR: pasas a manejar al compañero más cercano al balón.
func _cambiar_jugador() -> void:
	if congelado or terminado:
		return
	if controlado == null:
		return
	var nuevo = _mas_cercano(equipos[0], balon.global_position)
	if nuevo == null or nuevo == controlado:
		return
	_poner_control(nuevo)
	hud.mostrar_mensaje("JUEGAS CON EL %d" % nuevo.numero, 1.1)


## Le pasa el control a otro jugador de tu equipo.
func _poner_control(nuevo) -> void:
	if nuevo == null or nuevo == controlado:
		return
	if controlado != null:
		var viejo = controlado
		viejo.es_humano = false
		viejo.controles = null
		viejo.camara = null
		viejo.correr = false
		viejo.tiene_destino = false
		viejo.potencia = 0.0
		viejo.cargando = false
		viejo.mostrar_indicador(false)
	nuevo.es_humano = true
	nuevo.controles = controles
	nuevo.camara = camara
	nuevo.tiene_destino = false
	nuevo.correr = false
	nuevo.mostrar_indicador(true, "" if nuevo.leyenda else nuevo.nombre)
	controlado = nuevo
