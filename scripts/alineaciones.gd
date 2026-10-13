class_name Alineaciones
extends Control
## Lo que se ve ANTES de que empiece el partido: las alineaciones.
##
## Arriba el título, y abajo dos columnas: a la izquierda TUS jugadores (los de
## tu plantilla de cartas) y a la derecha los del rival (la plantilla de verdad
## del club, si el partido es de la carrera).
##
## Cualquier toque en la pantalla arranca el partido.

## El título arriba y las dos columnas (tú y el rival).
const RUTA_PARTIDO := "res://scenes/partido.tscn"

## Lo que se muestra. Lo llena quien abre esta pantalla.
var mio_titulo := "TÚ"
var mio_subtitulo := ""
var mio_jugadores: Array = []
var rival_titulo := "RIVAL"
var rival_subtitulo := ""
var rival_jugadores: Array = []
## De dónde salió esta pantalla, para volver si se cancela.
var volver_a := "res://scenes/main_menu.tscn"

var _espera := 0.0
var _listo := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_construir()
	# Un ratito de cortesía antes de aceptar toques: así no se salta la pantalla
	# sin querer con el mismo toque que venía del menú.
	await get_tree().create_timer(0.6).timeout
	_listo = true


func _input(evento: InputEvent) -> void:
	if not _listo:
		return
	var toco := false
	if evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed:
		toco = true
	elif evento is InputEventScreenTouch and (evento as InputEventScreenTouch).pressed:
		toco = true
	if toco:
		_arrancar()


func _arrancar() -> void:
	get_tree().change_scene_to_file(RUTA_PARTIDO)


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.09, 0.10)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var titulo := Label.new()
	titulo.text = "ALINEACIONES"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.add_theme_color_override("font_color", Color(1, 1, 1))
	titulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	titulo.offset_top = 10.0
	titulo.offset_bottom = 56.0
	add_child(titulo)

	# Las dos columnas, una al lado de la otra.
	var fila := HBoxContainer.new()
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.offset_left = 24.0
	fila.offset_right = -24.0
	fila.offset_top = 62.0
	fila.offset_bottom = -62.0
	fila.add_theme_constant_override("separation", 40)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(fila)

	_columna(fila, mio_titulo, mio_subtitulo, mio_jugadores, Color(0.35, 0.75, 1.0), false)
	_columna(fila, rival_titulo, rival_subtitulo, rival_jugadores, Color(1.0, 0.45, 0.4), true)

	var pie := Label.new()
	pie.text = "Toca la pantalla para empezar"
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pie.add_theme_font_size_override("font_size", 20)
	pie.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	pie.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	pie.offset_top = -50.0
	pie.offset_bottom = -16.0
	add_child(pie)


## Una de las dos columnas: el nombre del equipo y sus 11 jugadores.
func _columna(padre: Control, titulo: String, subtitulo: String, jugadores: Array,
		color: Color, muy_ancha: bool) -> void:
	var caja := VBoxContainer.new()
	caja.custom_minimum_size = Vector2(560.0, 0.0)
	caja.add_theme_constant_override("separation", 1)
	padre.add_child(caja)

	var lbl := Label.new()
	lbl.text = titulo
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", color)
	caja.add_child(lbl)

	if subtitulo != "":
		var sub := Label.new()
		sub.text = subtitulo
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_font_size_override("font_size", 17)
		sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		caja.add_child(sub)

	_fila(caja, "PTO", "JUGADOR", "CLUB", "OVR", Color(1, 1, 1, 0.45), 14)

	for j in jugadores:
		_fila(caja, _puesto_texto(j.get("puesto", "")), str(j.get("nombre", "?")),
			str(j.get("equipo", "")), "%d" % int(j.get("ovr", 0)),
			Color(0.95, 0.97, 0.95), 17)


## El puesto, como texto. OJO: en una carta el puesto viene como texto ("POR",
## "DC") y el rol del equipo de siempre viene como número (0 = arquero). Aquí se
## acepta cualquiera de los dos (si no, salía "0" en todos).
func _puesto_texto(valor) -> String:
	if typeof(valor) == TYPE_STRING and str(valor) != "":
		return str(valor)
	match int(valor):
		0:
			return "ARQ"
		1:
			return "DEF"
		2:
			return "MED"
		_:
			return "DEL"


## Una fila con las 4 columnas bien alineadas (cada una con su ancho).
func _fila(padre: Control, puesto: String, nombre: String, equipo: String, ovr: String,
		color: Color, tam: int) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	padre.add_child(fila)
	var anchos := [46.0, 250.0, 190.0, 56.0]
	var textos := [puesto, nombre, equipo, ovr]
	if nombre.length() > 26:
		textos[1] = nombre.substr(0, 26)
	if equipo.length() > 20:
		textos[2] = equipo.substr(0, 20)
	for i in 4:
		var lbl := Label.new()
		lbl.text = str(textos[i])
		lbl.custom_minimum_size = Vector2(anchos[i], 0.0)
		lbl.add_theme_font_size_override("font_size", tam)
		lbl.add_theme_color_override("font_color", color)
		lbl.clip_text = true
		fila.add_child(lbl)


## Arma la pantalla de alineaciones y la abre.
##
## Si tienes plantilla armada, se muestran TUS 11 cartas; si no, salen los
## jugadores del equipo normal (para que la pantalla nunca salga vacía).
## El rival es la plantilla del club cuando el partido es de la carrera.
static func mostrar(arbol: SceneTree, volver := "res://scenes/main_menu.tscn") -> void:
	var pantalla := Alineaciones.new()

	var lista: Array = []
	var guardada: Dictionary = Datos.plantilla
	var puestos = guardada.get("titulares", [])
	if typeof(puestos) == TYPE_ARRAY:
		for indice in puestos:
			var i := int(indice)
			if i >= 0 and i < Datos.inventario.size():
				lista.append(Datos.inventario[i])

	if lista.is_empty():
		pantalla.mio_titulo = "TÚ"
		pantalla.mio_subtitulo = "equipo de siempre (todavía no armaste tu plantilla)"
		pantalla.mio_jugadores = _equipo_normal()
	else:
		pantalla.mio_titulo = "TÚ  ·  MI PLANTILLA"
		pantalla.mio_subtitulo = "OVR del equipo: %d" % _promedio(lista)
		pantalla.mio_jugadores = lista

	# El rival: si el partido es de la carrera, la plantilla de ese club.
	var liga: Dictionary = Datos.partido_de_liga
	if not liga.is_empty():
		var rival := Clubes.buscar(str(liga.get("rival", "")))
		pantalla.rival_titulo = str(rival.get("nombre", "RIVAL"))
		var tactica = rival.get("tactica", {})
		pantalla.rival_subtitulo = "%s  ·  %s" % [
			str(tactica.get("formacion", "")), str(rival.get("liga", ""))]
		pantalla.rival_jugadores = _cartas_del_club(rival)
	else:
		pantalla.rival_titulo = "RIVAL"
		pantalla.rival_subtitulo = "equipo de siempre"
		pantalla.rival_jugadores = _equipo_normal()

	pantalla.volver_a = volver
	# OJO: en el primer cuadro el árbol todavía se está armando, así que hay que
	# dejar el add_child para el final del cuadro (si no, falla con
	# "Parent node is busy setting up children").
	arbol.root.add_child.call_deferred(pantalla)


## Los 11 titulares del equipo de siempre (el que arma el partido).
static func _equipo_normal() -> Array:
	var salida: Array = []
	var partido = load("res://scripts/partido.gd")
	for datos in partido.FORMACION:
		salida.append({
			"nombre": "Jugador %d" % int(datos.get("num", 0)),
			"puesto": int(datos.get("rol", 2)),
			"numero": int(datos.get("num", 0)),
			"equipo": "CAMI26",
			"ovr": 0,
		})
	return salida


## Las 11 cartas de los titulares de un club del archivo.
static func _cartas_del_club(club: Dictionary) -> Array:
	var salida: Array = []
	for j in Clubes.titulares(club):
		salida.append(Cartas.crear(j, club, false))
	return salida


static func _promedio(lista: Array) -> int:
	var suma := 0
	for c in lista:
		suma += int(c.get("ovr", 0))
	return int(round(float(suma) / float(maxi(1, lista.size()))))
