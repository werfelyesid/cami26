extends Control
## EL MODO CARRERA: la liga.
##
## Pantalla:
##   - Si todavía no hay liga: te deja ELEGIR TU CLUB (los 21, con las Leyendas
##     incluidas) y arranca la temporada.
##   - Si ya hay liga: a la izquierda la TABLA DE POSICIONES y a la derecha tu
##     próximo partido, con JUGAR (lo juegas tú) y SIMULAR (lo juega la compu).
##
## Al final de las fechas te dice quién salió campeón, en qué puesto quedaste y
## el premio que te ganaste (una sola vez).
##
## OJO: las cuentas de la liga NO están aquí, están en scripts/carrera_liga.gd
## (el calendario, la tabla y la simulación) y en Datos (el guardado).

const RUTA_MENU := "res://scenes/main_menu.tscn"
const RUTA_PARTIDO := "res://scenes/partido.tscn"
const CarreraLiga = preload("res://scripts/carrera_liga.gd")

## Lo que mide cada columna de la tabla.
const COLUMNAS := [
	["POS", 46.0], ["EQUIPO", 208.0], ["PJ", 42.0], ["G", 42.0], ["E", 42.0],
	["P", 42.0], ["GF", 46.0], ["GC", 46.0], ["DIF", 56.0], ["PTS", 58.0],
]

var _aviso: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.13, 0.10)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_cabecera()
	if Datos.carrera_activa():
		_temporada()
	else:
		_elegir_club()


# ------------------------------------------------------------------ arriba ---

func _cabecera() -> void:
	var caja := HBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_TOP_WIDE)
	caja.offset_left = 14.0
	caja.offset_right = -14.0
	caja.offset_top = 8.0
	caja.offset_bottom = 58.0
	caja.add_theme_constant_override("separation", 14)
	add_child(caja)

	var titulo := Label.new()
	titulo.text = "CARRERA"
	titulo.add_theme_font_size_override("font_size", 30)
	caja.add_child(titulo)

	if Datos.carrera_activa():
		var club := Datos.carrera_club()
		var info := Label.new()
		info.text = "%s   ·   TEMPORADA %d   ·   FECHA %d DE %d" % [
			str(club.get("nombre", "?")), int(Datos.carrera.get("temporada", 1)),
			mini(Datos.carrera_fecha(), Datos.carrera_fechas()), Datos.carrera_fechas()]
		info.add_theme_font_size_override("font_size", 22)
		info.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caja.add_child(info)
	else:
		var vacio := Label.new()
		vacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caja.add_child(vacio)

	var volver := Button.new()
	volver.text = "VOLVER"
	volver.add_theme_font_size_override("font_size", 20)
	volver.custom_minimum_size = Vector2(130.0, 46.0)
	volver.pressed.connect(func(): get_tree().change_scene_to_file(RUTA_MENU))
	caja.add_child(volver)


# ------------------------------------------------------- elegir el club ---

func _elegir_club() -> void:
	var titulo := Label.new()
	titulo.text = "ELIGE TU CLUB PARA LA LIGA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	titulo.offset_top = 68.0
	titulo.offset_bottom = 108.0
	add_child(titulo)

	var explicacion := Label.new()
	explicacion.text = "Juegas una liga de todos contra todos, una sola vuelta. " \
		+ "Los partidos que no juegas los simula la compu. Al final hay premio según el puesto."
	explicacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explicacion.add_theme_font_size_override("font_size", 18)
	explicacion.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	explicacion.set_anchors_preset(Control.PRESET_TOP_WIDE)
	explicacion.offset_left = 220.0
	explicacion.offset_right = -220.0
	explicacion.offset_top = 110.0
	explicacion.offset_bottom = 150.0
	add_child(explicacion)

	var desliz := ScrollContainer.new()
	desliz.set_anchors_preset(Control.PRESET_FULL_RECT)
	desliz.offset_left = 60.0
	desliz.offset_right = -60.0
	desliz.offset_top = 158.0
	desliz.offset_bottom = -24.0
	add_child(desliz)

	var rejilla := GridContainer.new()
	rejilla.columns = 3
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rejilla.add_theme_constant_override("h_separation", 12)
	rejilla.add_theme_constant_override("v_separation", 10)
	desliz.add_child(rejilla)

	for club in Clubes.cargar_todos():
		var id := str(club.get("id", ""))
		var boton := Button.new()
		boton.text = "%s  (%s)" % [str(club.get("nombre", "?")), str(club.get("corto", ""))]
		boton.add_theme_font_size_override("font_size", 20)
		boton.custom_minimum_size = Vector2(368.0, 52.0)
		boton.pressed.connect(func(): _empezar_con(id))
		rejilla.add_child(boton)


func _empezar_con(club_id: String) -> void:
	Datos.carrera_empezar(club_id)
	get_tree().reload_current_scene()


# --------------------------------------------------------- la temporada ---

func _temporada() -> void:
	_tabla()
	_panel_partido()


## La tabla de posiciones (a la izquierda).
func _tabla() -> void:
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_TOP_LEFT)
	caja.offset_left = 14.0
	caja.offset_top = 70.0
	caja.offset_right = 754.0
	caja.offset_bottom = 706.0
	caja.add_theme_constant_override("separation", 4)
	add_child(caja)

	var titulo := Label.new()
	titulo.text = "TABLA DE POSICIONES"
	titulo.add_theme_font_size_override("font_size", 22)
	caja.add_child(titulo)

	# El encabezado y las 21 filas van en la MISMA rejilla: así las columnas
	# quedan alineadas solas.
	var rejilla := GridContainer.new()
	rejilla.columns = COLUMNAS.size()
	rejilla.add_theme_constant_override("h_separation", 2)
	rejilla.add_theme_constant_override("v_separation", 2)
	caja.add_child(rejilla)

	for columna in COLUMNAS:
		rejilla.add_child(_celda(str(columna[0]), float(columna[1]), 17,
			Color(1, 0.92, 0.6), HORIZONTAL_ALIGNMENT_CENTER))

	var mio := str(Datos.carrera.get("club", ""))
	for fila in Datos.carrera_tabla():
		var es_mio := str(fila["id"]) == mio
		var club := Clubes.buscar(str(fila["id"]))
		var color := Color(1, 1, 1)
		if es_mio:
			color = Color(0.55, 1.0, 0.62)
		var datos := [
			str(fila["puesto"]), "%s %s" % [str(club.get("corto", "")), str(club.get("nombre", ""))],
			str(fila["pj"]), str(fila["g"]), str(fila["e"]), str(fila["p"]),
			str(fila["gf"]), str(fila["gc"]), str(fila["dif"]), str(fila["pts"]),
		]
		for i in datos.size():
			var ancho: float = float(COLUMNAS[i][1])
			var alineacion := HORIZONTAL_ALIGNMENT_LEFT if i == 1 else HORIZONTAL_ALIGNMENT_CENTER
			rejilla.add_child(_celda(datos[i], ancho, 17, color, alineacion))


func _celda(texto: String, ancho: float, tam: int, color: Color, alineacion: int) -> Label:
	var lbl := Label.new()
	lbl.text = texto
	lbl.custom_minimum_size = Vector2(ancho, 24.0)
	lbl.horizontal_alignment = alineacion
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	lbl.clip_text = true
	return lbl


## Tu próximo partido y los botones (a la derecha).
func _panel_partido() -> void:
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	caja.offset_left = -14.0 - 470.0
	caja.offset_right = -14.0
	caja.offset_top = 70.0
	caja.offset_bottom = 706.0
	caja.add_theme_constant_override("separation", 12)
	add_child(caja)

	var club := Datos.carrera_club()

	_etiqueta(caja, "TU EQUIPO", 18, Color(1, 1, 1, 0.65))
	# El color del club, pero aclarado: hay clubes con colores muy oscuros que no
	# se leerían sobre el fondo.
	var color_club := Cartas.color_de(str(club.get("color_principal", "#ffffff"))).lerp(Color.WHITE, 0.35)
	_etiqueta(caja, str(club.get("nombre", "?")), 30, color_club)

	_aviso = _etiqueta(caja, "", 19, Color(1, 0.85, 0.4))
	if not Datos.ultimo_resultado_liga.is_empty():
		_aviso.text = _texto_del_ultimo_resultado()
		Datos.ultimo_resultado_liga = {}

	if Datos.carrera_terminada():
		_final_de_temporada(caja)
		return

	if Datos.carrera_descansa():
		_etiqueta(caja, "FECHA %d DE %d" % [Datos.carrera_fecha(), Datos.carrera_fechas()], 20,
			Color(1, 0.92, 0.6))
		_etiqueta(caja, "ESTA FECHA DESCANSAS", 26, Color(1, 1, 1))
		_etiqueta(caja, "Son 21 clubes, así que a cada uno le toca descansar una fecha.", 17,
			Color(1, 1, 1, 0.7))
		var pasar := Button.new()
		pasar.text = "PASAR LA FECHA"
		pasar.add_theme_font_size_override("font_size", 24)
		pasar.custom_minimum_size = Vector2(440.0, 64.0)
		pasar.pressed.connect(_simular)
		caja.add_child(pasar)
		_etiqueta(caja, "Vas %dº de %d." % [Datos.carrera_puesto(), Datos.carrera_ids().size()], 20,
			Color(1, 0.92, 0.6))
		return

	var mio := Datos.carrera_mi_partido()
	var rival := Clubes.buscar(str(mio[1])) if Datos.carrera_soy_local() else Clubes.buscar(str(mio[0]))
	_etiqueta(caja, "FECHA %d DE %d" % [Datos.carrera_fecha(), Datos.carrera_fechas()], 20,
		Color(1, 0.92, 0.6))
	var donde := "EN CASA" if Datos.carrera_soy_local() else "DE VISITA"
	_etiqueta(caja, "vs %s" % str(rival.get("nombre", "?")), 26, Color(1, 1, 1))
	_etiqueta(caja, donde, 18, Color(1, 1, 1, 0.7))

	var jugar := Button.new()
	jugar.text = "JUGAR EL PARTIDO"
	jugar.add_theme_font_size_override("font_size", 28)
	jugar.custom_minimum_size = Vector2(440.0, 76.0)
	jugar.pressed.connect(_jugar)
	caja.add_child(jugar)

	var simular := Button.new()
	simular.text = "SIMULAR LA FECHA"
	simular.add_theme_font_size_override("font_size", 20)
	simular.custom_minimum_size = Vector2(440.0, 52.0)
	simular.pressed.connect(_simular)
	caja.add_child(simular)

	_etiqueta(caja, "En la liga el empate vale: si empatas no hay tiempo extra.", 16,
		Color(1, 1, 1, 0.6))
	_etiqueta(caja, "Vas %dº de %d." % [Datos.carrera_puesto(), Datos.carrera_ids().size()], 20,
		Color(1, 0.92, 0.6))


## Cuando ya se jugaron todas las fechas: el campeón, tu puesto y el premio.
func _final_de_temporada(caja: VBoxContainer) -> void:
	var tabla := Datos.carrera_tabla()
	_etiqueta(caja, "¡TEMPORADA TERMINADA!", 26, Color(1, 0.92, 0.6))
	if not tabla.is_empty():
		var campeon := Clubes.buscar(str(tabla[0]["id"]))
		_etiqueta(caja, "CAMPEÓN: %s" % str(campeon.get("nombre", "?")), 24, Color(1, 1, 1))
	var puesto := Datos.carrera_puesto()
	_etiqueta(caja, "TÚ QUEDASTE %dº" % puesto, 24, Color(0.55, 1.0, 0.62))

	var premio := Datos.carrera_premio()
	if premio.is_empty():
		_etiqueta(caja, "Premio ya cobrado.", 18, Color(1, 1, 1, 0.7))
		return
	_etiqueta(caja, "PREMIO: %s" % CarreraLiga.texto_premio(puesto), 18, Color(1, 0.85, 0.4))

	var cobrar := Button.new()
	cobrar.text = "COBRAR EL PREMIO"
	cobrar.add_theme_font_size_override("font_size", 24)
	cobrar.custom_minimum_size = Vector2(440.0, 64.0)
	cobrar.pressed.connect(_cobrar)
	caja.add_child(cobrar)

	var nueva := Button.new()
	nueva.text = "JUGAR OTRA TEMPORADA"
	nueva.add_theme_font_size_override("font_size", 20)
	nueva.custom_minimum_size = Vector2(440.0, 52.0)
	nueva.pressed.connect(_nueva_temporada)
	caja.add_child(nueva)

	var cambiar := Button.new()
	cambiar.text = "CAMBIAR DE CLUB"
	cambiar.add_theme_font_size_override("font_size", 18)
	cambiar.custom_minimum_size = Vector2(440.0, 46.0)
	cambiar.pressed.connect(_borrar_carrera)
	caja.add_child(cambiar)


func _etiqueta(donde: VBoxContainer, texto: String, tam: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = texto
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	donde.add_child(lbl)
	return lbl


func _texto_del_ultimo_resultado() -> String:
	var r := Datos.ultimo_resultado_liga
	var rival := Clubes.buscar(str(r.get("rival", "")))
	var quien := "GANASTE" if bool(r.get("gano", false)) else ("EMPATASTE" if bool(r.get("empato", false)) else "PERDISTE")
	return "FECHA %d: %s %d - %d vs %s" % [int(r.get("fecha", 0)), quien,
		int(r.get("mios", 0)), int(r.get("rivales", 0)), str(rival.get("nombre", "?"))]


# ------------------------------------------------------------------ botones ---

## Arranca el partido de verdad. La escena del partido lo lee de Datos.
func _jugar() -> void:
	var mio := Datos.carrera_mi_partido()
	if mio.is_empty():
		return
	Datos.partido_de_liga = {
		"rival": str(mio[1]) if Datos.carrera_soy_local() else str(mio[0]),
		"soy_local": Datos.carrera_soy_local(),
		"fecha": Datos.carrera_fecha(),
	}
	get_tree().change_scene_to_file(RUTA_PARTIDO)


## Deja que la compu juegue tu partido y toda la fecha.
func _simular() -> void:
	Datos.carrera_simular_fecha()
	get_tree().reload_current_scene()


func _cobrar() -> void:
	Datos.carrera_cobrar_premio()
	get_tree().reload_current_scene()


func _nueva_temporada() -> void:
	Datos.carrera_nueva_temporada()
	get_tree().reload_current_scene()


func _borrar_carrera() -> void:
	Datos.carrera_borrar()
	get_tree().reload_current_scene()
