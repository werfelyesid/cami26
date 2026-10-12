extends Control
## MI PLANTILLA (el "Ultimate Team"): aquí armas tu equipo con las cartas que
## ganas en los sobres.
##
##   - A la izquierda está la lista de tus cartas (con un filtro por puesto) y
##     abajo el banquillo.
##   - A la derecha, la cancha con 11 huecos según la formación.
##   - Se arma ARRASTRANDO una carta de la lista a un hueco. También se puede
##     TOCAR una carta y después el hueco (o al revés), por si el arrastre se
##     pone difícil con el dedo.
##   - La única regla: el hueco del arco es solo para arqueros. El resto de las
##     cartas van donde quieras (así lo pidió Camilo: "sencillo").
##
## La plantilla se guarda sola en el progreso (Datos.plantilla), con la posición
## de cada carta en el inventario.

const RUTA_MENU := "res://scenes/main_menu.tscn"
const CanchaMini = preload("res://scripts/cancha_mini.gd")

const TITULARES := 11
const BANQUILLO := 7
const TAM_HUECO := Vector2(91.0, 125.0)
const TAM_BANCO := Vector2(88.0, 106.0)

## Dónde va cada hueco en la cancha, por formación. Las x e y son proporciones
## de la cancha (0,0 = esquina de arriba a la izquierda). El arco es el hueco 0
## y va abajo, porque tú atacas hacia arriba.
const FORMACIONES := {
	"4-3-3": [
		{"e": "ARQ", "x": 0.50, "y": 0.88},
		{"e": "DEF", "x": 0.13, "y": 0.64}, {"e": "DEF", "x": 0.38, "y": 0.68},
		{"e": "DEF", "x": 0.62, "y": 0.68}, {"e": "DEF", "x": 0.87, "y": 0.64},
		{"e": "MED", "x": 0.24, "y": 0.42}, {"e": "MED", "x": 0.50, "y": 0.38},
		{"e": "MED", "x": 0.76, "y": 0.42},
		{"e": "DEL", "x": 0.16, "y": 0.16}, {"e": "DEL", "x": 0.50, "y": 0.12},
		{"e": "DEL", "x": 0.84, "y": 0.16},
	],
	"4-4-2": [
		{"e": "ARQ", "x": 0.50, "y": 0.88},
		{"e": "DEF", "x": 0.13, "y": 0.64}, {"e": "DEF", "x": 0.38, "y": 0.68},
		{"e": "DEF", "x": 0.62, "y": 0.68}, {"e": "DEF", "x": 0.87, "y": 0.64},
		{"e": "MED", "x": 0.13, "y": 0.40}, {"e": "MED", "x": 0.38, "y": 0.38},
		{"e": "MED", "x": 0.62, "y": 0.38}, {"e": "MED", "x": 0.87, "y": 0.40},
		{"e": "DEL", "x": 0.36, "y": 0.14}, {"e": "DEL", "x": 0.64, "y": 0.14},
	],
	"3-5-2": [
		{"e": "ARQ", "x": 0.50, "y": 0.88},
		{"e": "DEF", "x": 0.25, "y": 0.66}, {"e": "DEF", "x": 0.50, "y": 0.70},
		{"e": "DEF", "x": 0.75, "y": 0.66},
		{"e": "MED", "x": 0.10, "y": 0.42}, {"e": "MED", "x": 0.33, "y": 0.38},
		{"e": "MED", "x": 0.50, "y": 0.50}, {"e": "MED", "x": 0.67, "y": 0.38},
		{"e": "MED", "x": 0.90, "y": 0.42},
		{"e": "DEL", "x": 0.36, "y": 0.14}, {"e": "DEL", "x": 0.64, "y": 0.14},
	],
}

var titulares: Array = []      # índices del inventario (-1 = hueco libre)
var banquillo: Array = []
var formacion := "4-3-3"
var filtro := "TODOS"

var _lista: VBoxContainer
var _desliz: ScrollContainer
var _cancha: Control
var _huecos: Array = []
var _bancos: Array = []
var _ovr: Label
var _aviso: Label
var _boton_formacion: Button
var _boton_filtro: Button

# Para el "tocar y tocar": qué hay seleccionado ahora mismo.
var _sel_zona := ""
var _sel_pos := -1
var _sel_indice := -1


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	titulares.resize(TITULARES)
	banquillo.resize(BANQUILLO)
	for i in TITULARES:
		titulares[i] = -1
	for i in BANQUILLO:
		banquillo[i] = -1
	_cargar()
	_construir()
	# El tamaño de la cancha no se sabe hasta que el motor acomoda todo, así que
	# hay que esperar un cuadro para poner cada hueco en su sitio.
	await get_tree().process_frame
	_acomodar()
	_refrescar()
	resized.connect(_acomodar)


# ------------------------------------------------------------------ armado ---

func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.07, 0.09, 0.13)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	# --- Arriba: título, promedio del equipo, formación y salir ---
	var cabecera := HBoxContainer.new()
	cabecera.set_anchors_preset(Control.PRESET_TOP_WIDE)
	cabecera.offset_left = 14.0
	cabecera.offset_right = -14.0
	cabecera.offset_top = 8.0
	cabecera.offset_bottom = 56.0
	cabecera.add_theme_constant_override("separation", 14)
	add_child(cabecera)

	var titulo := Label.new()
	titulo.text = "MI PLANTILLA"
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulo)

	_ovr = Label.new()
	_ovr.add_theme_font_size_override("font_size", 24)
	_ovr.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	cabecera.add_child(_ovr)

	_boton_formacion = Button.new()
	_boton_formacion.add_theme_font_size_override("font_size", 20)
	_boton_formacion.custom_minimum_size = Vector2(140.0, 44.0)
	_boton_formacion.pressed.connect(_cambiar_formacion)
	cabecera.add_child(_boton_formacion)

	var volver := Button.new()
	volver.text = "VOLVER"
	volver.add_theme_font_size_override("font_size", 20)
	volver.custom_minimum_size = Vector2(120.0, 44.0)
	volver.pressed.connect(func(): get_tree().change_scene_to_file(RUTA_MENU))
	cabecera.add_child(volver)

	# --- Izquierda: la lista de cartas ---
	var izquierda := VBoxContainer.new()
	izquierda.set_anchors_preset(Control.PRESET_TOP_LEFT)
	izquierda.offset_left = 14.0
	izquierda.offset_top = 64.0
	izquierda.offset_right = 14.0 + 340.0
	izquierda.offset_bottom = 598.0
	izquierda.add_theme_constant_override("separation", 6)
	add_child(izquierda)

	var fila_titulo := HBoxContainer.new()
	fila_titulo.add_theme_constant_override("separation", 8)
	izquierda.add_child(fila_titulo)

	var lbl_lista := Label.new()
	lbl_lista.text = "TUS CARTAS"
	lbl_lista.add_theme_font_size_override("font_size", 20)
	lbl_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_titulo.add_child(lbl_lista)

	_boton_filtro = Button.new()
	_boton_filtro.add_theme_font_size_override("font_size", 16)
	_boton_filtro.custom_minimum_size = Vector2(130.0, 36.0)
	_boton_filtro.pressed.connect(_cambiar_filtro)
	fila_titulo.add_child(_boton_filtro)

	_desliz = ScrollContainer.new()
	_desliz.custom_minimum_size = Vector2(340.0, 380.0)
	_desliz.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desliz.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	izquierda.add_child(_desliz)

	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 5)
	_desliz.add_child(_lista)

	# --- Derecha: la cancha con los 11 huecos ---
	var derecha := Control.new()
	derecha.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	derecha.offset_left = -14.0 - 900.0
	derecha.offset_right = -14.0
	derecha.offset_top = 64.0
	derecha.offset_bottom = 598.0
	derecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(derecha)

	_cancha = CanchaMini.new()
	_cancha.set_anchors_preset(Control.PRESET_FULL_RECT)
	derecha.add_child(_cancha)

	_huecos = _crear_huecos(derecha, TITULARES, "titular", TAM_HUECO)

	# --- Abajo del todo: el banquillo (7 huecos en una fila) ---
	var abajo := HBoxContainer.new()
	abajo.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	abajo.offset_left = 14.0
	abajo.offset_right = -14.0
	abajo.offset_top = -122.0
	abajo.offset_bottom = -54.0
	abajo.alignment = BoxContainer.ALIGNMENT_CENTER
	abajo.add_theme_constant_override("separation", 8)
	add_child(abajo)

	var fila_banco := HBoxContainer.new()
	fila_banco.add_theme_constant_override("separation", 8)
	abajo.add_child(fila_banco)
	_bancos = _crear_huecos(fila_banco, BANQUILLO, "banquillo", TAM_BANCO)

	var lbl_banco := Label.new()
	lbl_banco.text = "BANQUILLO"
	lbl_banco.add_theme_font_size_override("font_size", 18)
	lbl_banco.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	lbl_banco.offset_left = -150.0
	lbl_banco.offset_right = -14.0
	lbl_banco.offset_top = -50.0
	lbl_banco.offset_bottom = -26.0
	lbl_banco.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(lbl_banco)

	# --- Abajo: los avisos ---
	_aviso = Label.new()
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 18)
	_aviso.add_theme_color_override("font_color", Color(1, 0.75, 0.35))
	_aviso.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_aviso.offset_left = 380.0
	_aviso.offset_right = -180.0
	_aviso.offset_top = -48.0
	_aviso.offset_bottom = -20.0
	add_child(_aviso)


## Crea los huecos (sin colocarlos: de eso se encarga _acomodar).
func _crear_huecos(padre: Control, cuantos: int, zona: String, tam: Vector2) -> Array:
	var lista: Array = []
	for i in cuantos:
		var h := MiniCarta.new()
		h.zona = zona
		h.posicion = i
		h.pantalla = self
		h.custom_minimum_size = tam
		h.size = tam
		padre.add_child(h)
		lista.append(h)
	return lista


# --------------------------------------------------------------- la lista ---

## Redibuja la lista de cartas según el filtro. Las mejores van primero.
func _refrescar_lista() -> void:
	for hijo in _lista.get_children():
		hijo.queue_free()

	var indices: Array = []
	for i in Datos.inventario.size():
		var carta: Dictionary = Datos.inventario[i]
		if filtro != "TODOS" and not _entra_en_filtro(str(carta.get("puesto", "")), filtro):
			continue
		indices.append(i)
	indices.sort_custom(func(a, b): return int(Datos.inventario[a].get("ovr", 0)) > int(Datos.inventario[b].get("ovr", 0)))

	if indices.is_empty():
		var lbl := Label.new()
		lbl.text = "No tienes cartas de este puesto.\nGana partidos para conseguir sobres."
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(320.0, 60.0)
		lbl.add_theme_font_size_override("font_size", 16)
		_lista.add_child(lbl)
		return

	for i in indices:
		var fila := MiniCarta.new()
		fila.zona = "lista"
		fila.posicion = int(i)
		fila.pantalla = self
		fila.con_estadisticas = true
		fila.custom_minimum_size = Vector2(320.0, 74.0)
		fila.size = Vector2(320.0, 74.0)
		_lista.add_child(fila)
		fila.poner(Datos.inventario[i], int(i))
		# Las que ya están en el equipo se ven con un toque verde, para saberlo.
		if _en_la_plantilla(int(i)):
			fila.modulate = Color(0.62, 1.0, 0.68)


## ¿Esa carta ya está puesta en el equipo (de titulares o de banquillo)?
func _en_la_plantilla(indice: int) -> bool:
	return titulares.has(indice) or banquillo.has(indice)


## ¿Un puesto entra en el filtro?
func _entra_en_filtro(puesto: String, cual: String) -> bool:
	if cual == "POR":
		return puesto == "POR"
	if cual == "DEF":
		return Clubes.grupo_de(puesto) == "DEF"
	if cual == "MED":
		return Clubes.grupo_de(puesto) == "MED"
	if cual == "DEL":
		return Clubes.grupo_de(puesto) == "DEL"
	return true


func _cambiar_filtro() -> void:
	var orden := ["TODOS", "POR", "DEF", "MED", "DEL"]
	filtro = orden[(orden.find(filtro) + 1) % orden.size()]
	_boton_filtro.text = "FILTRO: %s" % filtro
	_refrescar_lista()


func _cambiar_formacion() -> void:
	var nombres := FORMACIONES.keys()
	formacion = str(nombres[(nombres.find(formacion) + 1) % nombres.size()])
	_acomodar()
	_guardar()


# ------------------------------------------------------------- los huecos ---

## Coloca los huecos de los titulares donde dice la formación.
func _acomodar() -> void:
	var puestos: Array = FORMACIONES.get(formacion, FORMACIONES["4-3-3"])
	for i in _huecos.size():
		var h: MiniCarta = _huecos[i]
		var p: Dictionary = puestos[i] if i < puestos.size() else {"x": 0.5, "y": 0.5, "e": "?"}
		h.etiqueta = str(p.get("e", ""))
		h.position = Vector2(
			_cancha.size.x * float(p["x"]) - TAM_HUECO.x * 0.5,
			_cancha.size.y * float(p["y"]) - TAM_HUECO.y * 0.5)
	_boton_formacion.text = "FORMACIÓN %s" % formacion


## Pinta las cartas que hay en la plantilla.
func _refrescar() -> void:
	for i in _huecos.size():
		var h: MiniCarta = _huecos[i]
		var indice: int = int(titulares[i])
		if indice >= 0 and indice < Datos.inventario.size():
			h.poner(Datos.inventario[indice], indice)
		else:
			h.vaciar()
	for i in _bancos.size():
		var h2: MiniCarta = _bancos[i]
		var indice2: int = int(banquillo[i])
		if indice2 >= 0 and indice2 < Datos.inventario.size():
			h2.poner(Datos.inventario[indice2], indice2)
		else:
			h2.vaciar()

	var puestos: Array = []
	for indice in titulares:
		if int(indice) >= 0 and int(indice) < Datos.inventario.size():
			puestos.append(int(Datos.inventario[int(indice)].get("ovr", 0)))
	var texto := "EQUIPO  —"
	if not puestos.is_empty():
		var suma := 0
		for p in puestos:
			suma += int(p)
		texto = "EQUIPO %d  (%d de 11)" % [int(round(float(suma) / float(puestos.size()))), puestos.size()]
	_ovr.text = texto
	_refrescar_lista()
	_limpiar_seleccion()


# --------------------------------------------------------- mover cartas ---

## ¿Se puede soltar lo que se arrastra sobre este hueco?
func puede_soltar(datos: Variant, destino: MiniCarta) -> bool:
	if typeof(datos) != TYPE_DICTIONARY or not datos.has("indice"):
		return false
	var indice: int = int(datos["indice"])
	if indice < 0 or indice >= Datos.inventario.size():
		return false
	var carta: Dictionary = Datos.inventario[indice]
	var puesto := str(carta.get("puesto", ""))

	if destino.zona == "lista":
		# Soltar sobre la lista = devolver la carta (solo si venía de un hueco).
		return str(datos.get("zona", "lista")) != "lista"
	if destino.zona == "titular" and destino.posicion == 0:
		return puesto == "POR"          # el arco es solo para arqueros
	if destino.zona == "titular":
		return puesto != "POR"          # los arqueros no juegan de campo
	return true                          # el banquillo acepta cualquiera


## Mueve la carta a donde la soltaron (y devuelve la que estaba ahí).
func soltar(datos: Variant, destino: MiniCarta) -> void:
	var indice: int = int(datos["indice"])
	var zona_origen := str(datos.get("zona", "lista"))
	var pos_origen := int(datos.get("pos", -1))

	# Si la carta se suelta donde ya estaba, no hay nada que hacer.
	# (Sin esto, se duplicaba: quedaba en el hueco viejo y en el nuevo.)
	if zona_origen == destino.zona and pos_origen == destino.posicion:
		_limpiar_seleccion()
		return

	var ocupaba := _indice_en(destino.zona, destino.posicion)

	# Se saca la carta de donde estaba.
	if zona_origen != "lista":
		_asignar(zona_origen, pos_origen, -1)
	else:
		_quitar_de_todos(indice)

	if destino.zona != "lista":
		_asignar(destino.zona, destino.posicion, indice)

	# Si en el destino había otra carta y la que arrastramos venía de un hueco,
	# las cambiamos de lugar. (Si venía de la lista, esa carta se queda libre.)
	if ocupaba != -1 and zona_origen != "lista":
		_asignar(zona_origen, pos_origen, ocupaba)

	_guardar()
	_refrescar()


func _asignar(zona: String, pos: int, indice: int) -> void:
	if zona == "titular" and pos >= 0 and pos < titulares.size():
		titulares[pos] = indice
	elif zona == "banquillo" and pos >= 0 and pos < banquillo.size():
		banquillo[pos] = indice


func _indice_en(zona: String, pos: int) -> int:
	if zona == "titular" and pos >= 0 and pos < titulares.size():
		return int(titulares[pos])
	if zona == "banquillo" and pos >= 0 and pos < banquillo.size():
		return int(banquillo[pos])
	return -1


## Saca una carta de todos los huecos (una carta no puede estar dos veces).
func _quitar_de_todos(indice: int) -> void:
	for i in titulares.size():
		if int(titulares[i]) == indice:
			titulares[i] = -1
	for i in banquillo.size():
		if int(banquillo[i]) == indice:
			banquillo[i] = -1


# ------------------------------------------------------ tocar y tocar ---

## Un toque simple en una carta. Sirve de plan B si el arrastre se pone difícil:
## se toca la carta y después el hueco (o al revés).
func tocar(w: MiniCarta) -> void:
	# Una fila de la lista sin carta no es nada.
	if w.zona == "lista" and w.indice < 0:
		return

	if _sel_indice == -1:
		# Un hueco vacío no se puede "agarrar": no hay nada que llevar.
		if w.indice < 0:
			return
		_sel_zona = w.zona
		_sel_pos = w.posicion
		_sel_indice = w.indice
		w.modulate = Color(1.35, 1.35, 1.0)
		_avisar("Ahora toca el hueco donde quieres ponerlo (o vuelve a tocarlo para soltarlo)")
		return

	# Ya había algo tocado: si tocaste una carta de la lista y tenías un hueco
	# elegido, la carta entra en ese hueco. Si no, se intenta el cambio normal.
	if w.zona == "lista" and _sel_zona != "lista":
		var el_hueco := _widget(_sel_zona, _sel_pos)
		var datos := {"indice": w.indice, "zona": "lista", "pos": 0}
		if el_hueco != null and puede_soltar(datos, el_hueco):
			soltar(datos, el_hueco)
			return
		_avisar("Esa carta no puede ir ahí")
		_limpiar_seleccion()
		return

	var datos2 := {"indice": _sel_indice, "zona": _sel_zona, "pos": _sel_pos}
	if puede_soltar(datos2, w):
		soltar(datos2, w)
		return

	if w.zona == "titular" and w.posicion == 0:
		_avisar("En el arco solo puede jugar un arquero")
	elif _sel_zona == "titular" and _sel_pos == 0:
		_avisar("Los arqueros no juegan de campo")
	_limpiar_seleccion()


func _widget(zona: String, pos: int) -> MiniCarta:
	if zona == "titular" and pos >= 0 and pos < _huecos.size():
		return _huecos[pos]
	if zona == "banquillo" and pos >= 0 and pos < _bancos.size():
		return _bancos[pos]
	return null


func _limpiar_seleccion() -> void:
	_sel_zona = ""
	_sel_pos = -1
	_sel_indice = -1
	for w in _huecos:
		w.modulate = Color(1, 1, 1)
	for w in _bancos:
		w.modulate = Color(1, 1, 1)
	for w in _lista.get_children():
		if w is MiniCarta:
			w.modulate = Color(1, 1, 1)


func _avisar(texto: String) -> void:
	_aviso.text = texto


# ------------------------------------------------------------- guardar ---

## Lee la plantilla guardada y la deja lista (arreglando lo que esté raro).
func _cargar() -> void:
	var guardada: Dictionary = Datos.plantilla
	var t = guardada.get("titulares", [])
	var b = guardada.get("banquillo", [])
	if typeof(t) == TYPE_ARRAY:
		for i in mini(TITULARES, t.size()):
			titulares[i] = int(t[i])
	if typeof(b) == TYPE_ARRAY:
		for i in mini(BANQUILLO, b.size()):
			banquillo[i] = int(b[i])
	if guardada.has("formacion") and FORMACIONES.has(str(guardada["formacion"])):
		formacion = str(guardada["formacion"])
	_sanear()


## Revisa que las cartas de la plantilla existan y que no estén repetidas.
func _sanear() -> void:
	var vistos := {}
	for lista in [titulares, banquillo]:
		for i in lista.size():
			var indice: int = int(lista[i])
			if indice < 0:
				continue
			if indice >= Datos.inventario.size() or vistos.has(indice):
				lista[i] = -1
			else:
				vistos[indice] = true


func _guardar() -> void:
	Datos.plantilla = {
		"titulares": titulares,
		"banquillo": banquillo,
		"formacion": formacion,
	}
	Datos.guardar()
