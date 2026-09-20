extends Node3D
## La escena del partido: arma todo, lleva el marcador y el reloj,
## y decide cuándo es gol.
##
## Reglas (bien simples, estilo arcade):
##   - Tú atacas la portería de la derecha (x = +30).
##   - El rival ataca la tuya (x = -30).
##   - Dura 4 minutos. Gana el que meta más goles.

const Escenario = preload("res://scripts/estadio.gd")
const Balon = preload("res://scripts/balon.gd")
const Jugador = preload("res://scripts/jugador.gd")
const Rival = preload("res://scripts/rival.gd")
const Portero = preload("res://scripts/portero.gd")
const Hud = preload("res://scripts/hud.gd")
const Controles = preload("res://scripts/controles_tactiles.gd")

const DURACION := 240.0            # 4 minutos
const MITAD_LARGO := 30.0
const MITAD_ANCHO := 20.0
const ANCHO_PORTERIA := 6.0
const ALTO_PORTERIA := 2.2

const POS_BALON := Vector3(0.0, 0.35, 0.0)
const POS_JUGADOR := Vector3(-6.0, 0.3, 0.0)
const POS_RIVAL := Vector3(6.0, 0.3, 0.0)
const X_ARQUERO := 28.8

var balon = null
var jugador = null
var rival = null
var porteros := []
var futbolistas := []
var camara: Camera3D
var hud = null
var controles = null
var menu_pausa: CanvasLayer

var goles_local := 0
var goles_rival := 0
var tiempo := DURACION
var pausado := false
var congelado := false             # true mientras se celebra un gol
var terminado := false


func _ready() -> void:
	add_child(Escenario.new())
	_crear_balon()
	_crear_equipos()
	_crear_camara()
	_crear_interfaz()
	_saque_de_centro()


# ------------------------------------------------------------------ armado ---

func _crear_balon() -> void:
	balon = Balon.new()
	balon.position = POS_BALON
	add_child(balon)


func _crear_equipos() -> void:
	# --- Tú (camiseta azul) ---
	jugador = Jugador.new()
	jugador.color_camiseta = Color(0.12, 0.32, 0.92)
	jugador.color_pantalon = Color(0.96, 0.96, 0.99)
	jugador.balon = balon
	jugador.position = POS_JUGADOR
	add_child(jugador)
	futbolistas.append(jugador)

	# --- El rival (camiseta roja) ---
	rival = Rival.new()
	rival.color_camiseta = Color(0.88, 0.16, 0.16)
	rival.color_pantalon = Color(0.10, 0.10, 0.12)
	rival.color_piel = Color(0.78, 0.55, 0.38)
	rival.balon = balon
	rival.velocidad_dificultad = Ajustes.velocidad_rival()
	rival.position = POS_RIVAL
	add_child(rival)
	futbolistas.append(rival)

	# --- Los dos arqueros ---
	_crear_arquero(-X_ARQUERO, Vector3(1.0, 0.0, 0.0))
	_crear_arquero(X_ARQUERO, Vector3(-1.0, 0.0, 0.0))


func _crear_arquero(x: float, mira: Vector3) -> void:
	var arquero = Portero.new()
	arquero.color_camiseta = Color(0.95, 0.76, 0.12)
	arquero.color_pantalon = Color(0.16, 0.16, 0.20)
	arquero.balon = balon
	arquero.linea_x = x
	arquero.despeje = mira
	arquero.mirar_fijo = true
	arquero.hacia_fijo = mira
	arquero.puede_regatear = false
	arquero.velocidad = Ajustes.velocidad_arquero()
	arquero.position = Vector3(x, 0.3, 0.0)
	arquero.rotation.y = atan2(-mira.x, -mira.z)
	add_child(arquero)
	porteros.append(arquero)
	futbolistas.append(arquero)


func _crear_camara() -> void:
	camara = Camera3D.new()
	camara.fov = 64.0
	camara.near = 0.15
	camara.far = 400.0
	camara.position = POS_BALON + Vector3(0.0, 15.0, 25.0)
	add_child(camara)
	camara.current = true
	camara.look_at(POS_BALON + Vector3(0.0, 0.7, 0.0), Vector3.UP)


func _crear_interfaz() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.pausa_pedida.connect(_pausar)

	controles = Controles.new()
	hud.add_child(controles)     # va dentro del CanvasLayer, para que se vea encima
	jugador.controles = controles

	_crear_menu_pausa()


func _crear_menu_pausa() -> void:
	menu_pausa = CanvasLayer.new()
	menu_pausa.layer = 5
	# "WHEN_PAUSED" es la clave: este menú tiene que funcionar justo cuando
	# el juego está congelado.
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
	tiempo = maxf(0.0, tiempo - delta)
	_seguir_balon(delta)
	hud.actualizar(goles_local, goles_rival, tiempo)
	if tiempo <= 0.0:
		_finalizar()


func _physics_process(_delta: float) -> void:
	if pausado or terminado or congelado:
		return
	_marcar_dueno_del_balon()
	_revisar_gol()
	_revisar_balon_fuera()


## El que esté más cerca del balón es el único que lo puede ir empujando.
## Así no se pelean dos jugadores por la misma pelota.
func _marcar_dueno_del_balon() -> void:
	if balon == null:
		return
	var mejor = null
	var mejor_distancia := 1000000.0
	for f in futbolistas:
		if not f.puede_regatear:
			continue
		var d: float = f.global_position.distance_to(balon.global_position)
		if d < mejor_distancia:
			mejor_distancia = d
			mejor = f
	for f in futbolistas:
		f.puede_tocar = (f == mejor)


func _revisar_gol() -> void:
	if balon == null:
		return
	var p: Vector3 = balon.global_position
	var dentro_del_arco := absf(p.z) < ANCHO_PORTERIA * 0.5 and p.y < ALTO_PORTERIA
	if p.x > MITAD_LARGO and dentro_del_arco:
		_anotar(true)
	elif p.x < -MITAD_LARGO and dentro_del_arco:
		_anotar(false)


## Si el balón se va muy lejos (por encima de las tablas), vuelve al centro.
func _revisar_balon_fuera() -> void:
	if balon == null:
		return
	var p: Vector3 = balon.global_position
	if absf(p.x) > MITAD_LARGO + 6.0 or absf(p.z) > MITAD_ANCHO + 5.0 or p.y < -3.0:
		balon.reiniciar(POS_BALON)


func _seguir_balon(delta: float) -> void:
	if camara == null or balon == null:
		return
	var foco: Vector3 = balon.global_position
	foco.x = clampf(foco.x, -13.0, 13.0)
	foco.z = clampf(foco.z, -9.0, 9.0)
	foco.y = 0.6

	var destino := foco + Vector3(0.0, 15.0, 25.0)
	camara.global_position = camara.global_position.lerp(destino, minf(1.0, delta * 2.4))

	var mira := foco + Vector3(0.0, 0.4, 0.0)
	if camara.global_position.distance_to(mira) > 1.0:
		camara.look_at(mira, Vector3.UP)


# ---------------------------------------------------------------- jugadas ---

func _anotar(es_tuyo: bool) -> void:
	if congelado or terminado:
		return
	congelado = true

	if es_tuyo:
		goles_local += 1
		hud.mostrar_mensaje("¡GOOOL!", 2.2)
	else:
		goles_rival += 1
		hud.mostrar_mensaje("GOL DEL RIVAL", 2.2)

	hud.actualizar(goles_local, goles_rival, tiempo)
	_parar_todos()

	await get_tree().create_timer(2.2).timeout
	if terminado:
		return
	_saque_de_centro()
	congelado = false


func _saque_de_centro() -> void:
	balon.reiniciar(POS_BALON)

	jugador.global_position = POS_JUGADOR
	jugador.velocity = Vector3.ZERO
	jugador.direccion = Vector3.ZERO

	rival.global_position = POS_RIVAL
	rival.velocity = Vector3.ZERO
	rival.direccion = Vector3.ZERO

	var i := 0
	for arquero in porteros:
		var x := X_ARQUERO if i == 0 else -X_ARQUERO
		arquero.global_position = Vector3(x, 0.3, 0.0)
		arquero.velocity = Vector3.ZERO
		arquero.direccion = Vector3.ZERO
		i += 1

	hud.actualizar(goles_local, goles_rival, tiempo)


func _parar_todos() -> void:
	for f in futbolistas:
		f.direccion = Vector3.ZERO
		f.velocity = Vector3.ZERO
	if balon != null:
		balon.linear_velocity = Vector3.ZERO
		balon.angular_velocity = Vector3.ZERO


func _finalizar() -> void:
	terminado = true
	_parar_todos()

	var texto := "EMPATE  %d - %d" % [goles_local, goles_rival]
	if goles_local > goles_rival:
		texto = "¡GANASTE  %d - %d!" % [goles_local, goles_rival]
	elif goles_rival > goles_local:
		texto = "PERDISTE  %d - %d" % [goles_local, goles_rival]
	hud.mostrar_mensaje(texto, 3.8)
	hud.actualizar(goles_local, goles_rival, 0.0)

	await get_tree().create_timer(4.0).timeout
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
