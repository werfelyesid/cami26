extends Control
## La pantalla de los SOBRES.
##
## Se llega de dos maneras:
##   - Desde el menú: para comprar un sobre o reclamar el diario.
##   - Al ganar un partido: el premio ya viene puesto en Datos.ultimo_premio,
##     así que se muestra el sobre abierto de una vez.
##
## Para probarla sin jugar (y para hacer capturas):
##   godot --path . res://scenes/sobres.tscn
##   godot --path . res://scenes/sobres.tscn -- --captura /tmp/sobres.png
##   godot --path . res://scenes/sobres.tscn -- --simular-premio --captura /tmp/premio.png

const Tarjeta = preload("res://scripts/tarjeta.gd")
const RUTA_MENU := "res://scenes/main_menu.tscn"

const TAMANO_TIENDA := Vector2(150.0, 197.0)
const TAMANO_PREMIO := Vector2(236.0, 324.0)

var azar := RandomNumberGenerator.new()

var _tienda: VBoxContainer
var _premio: VBoxContainer
var _monedero: Label
var _aviso: Label
var _boton_gemas: Button
var _boton_monedas: Button
var _boton_diario: Button

# Solo para las pruebas desde la terminal.
var _ruta_captura := ""
var _simular_premio := false
var _cuenta_atras := 15
var _capturando := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	azar.randomize()
	_leer_argumentos()
	_construir()

	if _simular_premio:
		Datos.ultimo_premio = Sobres.premio(azar, true)

	if Datos.ultimo_premio.is_empty():
		_refrescar()
	else:
		_mostrar_premio()


func _leer_argumentos() -> void:
	var argumentos := OS.get_cmdline_user_args()
	for i in argumentos.size():
		if argumentos[i] == "--captura" and i + 1 < argumentos.size():
			_ruta_captura = argumentos[i + 1]
		elif argumentos[i] == "--simular-premio":
			_simular_premio = true


# ------------------------------------------------------------- la pantalla ---

func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.07, 0.09, 0.13)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	_tienda = VBoxContainer.new()
	_tienda.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tienda.alignment = BoxContainer.ALIGNMENT_CENTER
	_tienda.add_theme_constant_override("separation", 10)
	add_child(_tienda)

	_titulo(_tienda, "SOBRES", 38)

	_monedero = Label.new()
	_monedero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_monedero.add_theme_font_size_override("font_size", 22)
	_monedero.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	_tienda.add_child(_monedero)

	var sobre := TextureRect.new()
	sobre.texture = load("res://datos/cartas/sobre.png")
	sobre.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sobre.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sobre.custom_minimum_size = TAMANO_TIENDA
	sobre.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tienda.add_child(sobre)

	_aviso = Label.new()
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 18)
	_aviso.add_theme_color_override("font_color", Color(1, 0.7, 0.7))
	_tienda.add_child(_aviso)

	_boton_gemas = _boton(_tienda, "SOBRE CON GEMAS  ·  %s" % Texto.miles(Sobres.COSTO_GEMAS), 20)
	_boton_gemas.pressed.connect(_comprar.bind(true))

	_boton_monedas = _boton(_tienda, "SOBRE CON MONEDITAS  ·  %s" % Texto.miles(Sobres.COSTO_MONEDAS), 20)
	_boton_monedas.pressed.connect(_comprar.bind(false))

	_boton_diario = _boton(_tienda, "SOBRE DIARIO", 20)
	_boton_diario.pressed.connect(_diario)

	var probabilidades := Label.new()
	probabilidades.text = "Probabilidades:  %s" % Sobres.texto_probabilidades()
	probabilidades.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	probabilidades.add_theme_font_size_override("font_size", 15)
	probabilidades.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	_tienda.add_child(probabilidades)

	var volver := _boton(_tienda, "VOLVER AL MENÚ", 20)
	volver.pressed.connect(func(): get_tree().change_scene_to_file(RUTA_MENU))

	_premio = VBoxContainer.new()
	_premio.set_anchors_preset(Control.PRESET_FULL_RECT)
	_premio.alignment = BoxContainer.ALIGNMENT_CENTER
	_premio.add_theme_constant_override("separation", 12)
	_premio.visible = false
	add_child(_premio)


## Deja los botones y el monedero como están ahora mismo.
func _refrescar() -> void:
	_monedero.text = "GEMAS  %s        MONEDITAS  %s" % [Texto.miles(Datos.gemas), Texto.miles(Datos.monedas)]
	_boton_gemas.disabled = Datos.gemas < Sobres.COSTO_GEMAS
	_boton_monedas.disabled = Datos.monedas < Sobres.COSTO_MONEDAS

	var diario_listo := Datos.sobre_diario_disponible()
	_boton_diario.disabled = not diario_listo
	_boton_diario.text = "SOBRE DIARIO  ·  GRATIS" if diario_listo else "SOBRE DIARIO  ·  YA LO ABRISTE HOY"
	_aviso.text = ""


# -------------------------------------------------------------- los sobres ---

## Compra un sobre. `con_gemas` dice con qué se paga.
## OJO: el sobre comprado trae SOLO el jugador, sin gemas ni moneditas.
func _comprar(con_gemas: bool) -> void:
	if con_gemas:
		if Datos.gemas < Sobres.COSTO_GEMAS:
			return
		Datos.agregar_gemas(-Sobres.COSTO_GEMAS)
	else:
		if Datos.monedas < Sobres.COSTO_MONEDAS:
			return
		Datos.agregar_monedas(-Sobres.COSTO_MONEDAS)
	_entregar(Sobres.premio(azar, false))


## El sobre diario: es completo (jugador + plata) y solo uno por día.
func _diario() -> void:
	if not Datos.sobre_diario_disponible():
		return
	Datos.reclamar_sobre_diario()
	_entregar(Sobres.premio(azar, true))


func _entregar(premio: Dictionary) -> void:
	var carta: Dictionary = premio.get("carta", {})
	if carta.is_empty():
		_aviso.text = "¡Uy! No se pudo armar la carta. Inténtalo otra vez."
		return
	Datos.entregar_premio(carta, int(premio.get("monedas", 0)), int(premio.get("gemas", 0)))
	Datos.ultimo_premio = premio
	_mostrar_premio()


# --------------------------------------------------------- el sobre abierto ---

func _mostrar_premio() -> void:
	for hijo in _premio.get_children():
		hijo.queue_free()

	var premio := Datos.ultimo_premio
	var carta: Dictionary = premio.get("carta", {})
	if carta.is_empty():
		_volver_a_la_tienda()
		return

	_tienda.visible = false
	_premio.visible = true

	_titulo(_premio, "¡SOBRE ABIERTO!", 32)

	var tarjeta := Tarjeta.new()
	_premio.add_child(tarjeta)
	tarjeta.configurar(carta, TAMANO_PREMIO)
	tarjeta.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tarjeta.custom_minimum_size = TAMANO_PREMIO

	_linea(_premio, "%s  ·  OVR %d" % [str(carta.get("nombre", "")), int(carta.get("ovr", 0))], 22,
		Color(1, 1, 1))
	_linea(_premio, str(carta.get("equipo", "")), 17, Color(1, 1, 1, 0.75))

	var monedas := int(premio.get("monedas", 0))
	var gemas := int(premio.get("gemas", 0))
	if monedas > 0 or gemas > 0:
		_linea(_premio, "+%s gemas      +%s moneditas" % [Texto.miles(gemas), Texto.miles(monedas)], 20,
			Color(1, 0.92, 0.6))
	else:
		_linea(_premio, "Sobre comprado: solo viene el jugador", 16, Color(1, 1, 1, 0.6))

	_linea(_premio, "Ya tienes %s cartas" % Texto.miles(Datos.inventario.size()), 17, Color(1, 1, 1, 0.7))

	var aceptar := _boton(_premio, "ACEPTAR", 22)
	aceptar.pressed.connect(_volver_a_la_tienda)


func _volver_a_la_tienda() -> void:
	Datos.ultimo_premio = {}
	for hijo in _premio.get_children():
		hijo.queue_free()
	_premio.visible = false
	_tienda.visible = true
	_refrescar()


# ---------------------------------------------------------------- ayuditas ---

func _titulo(donde: VBoxContainer, texto: String, tam: int) -> void:
	var lbl := Label.new()
	lbl.text = texto
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	donde.add_child(lbl)


func _linea(donde: VBoxContainer, texto: String, tam: int, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = texto
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	donde.add_child(lbl)


func _boton(donde: VBoxContainer, texto: String, tam: int) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.add_theme_font_size_override("font_size", tam)
	boton.custom_minimum_size = Vector2(400.0, 52.0)
	boton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	donde.add_child(boton)
	return boton


func _process(_delta: float) -> void:
	if _ruta_captura == "" or _capturando:
		return
	_cuenta_atras -= 1
	if _cuenta_atras > 0:
		return
	_capturando = true
	await RenderingServer.frame_post_draw
	var imagen := get_viewport().get_texture().get_image()
	imagen.save_png(_ruta_captura)
	print("captura guardada en ", _ruta_captura)
	get_tree().quit()
