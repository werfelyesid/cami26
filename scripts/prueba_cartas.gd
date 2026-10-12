extends Control
## Pantalla de PRUEBA de las cartas (fase 1).
##
## Muestra los 4 niveles (bronce, plata, oro y especial) y unas cuantas cartas
## al azar, con un botón para sacar otra tanda. Sirve para revisar cómo quedan
## las cartas sin tener que jugar un partido.
##
## Para hacer una captura sin quedarse mirando la pantalla:
##   godot --path . res://scenes/prueba_cartas.tscn -- --captura /tmp/cartas.png

const Tarjeta = preload("res://scripts/tarjeta.gd")

const TAMANO := Vector2(172.0, 237.0)

var azar := RandomNumberGenerator.new()
var rejilla: GridContainer
var _ruta_captura := ""
var _cuenta_atras := 15
var _capturando := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	azar.randomize()
	_leer_argumentos()
	_construir()
	_tanda()


func _leer_argumentos() -> void:
	var argumentos := OS.get_cmdline_user_args()
	for i in argumentos.size():
		if argumentos[i] == "--captura" and i + 1 < argumentos.size():
			_ruta_captura = argumentos[i + 1]


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.07, 0.09, 0.13)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	# Todo va dentro de una columna centrada: así nada se pisa, sin importar
	# el tamaño de la pantalla.
	var columna := VBoxContainer.new()
	columna.set_anchors_preset(Control.PRESET_FULL_RECT)
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 12)
	add_child(columna)

	var titulo := Label.new()
	titulo.text = "CARTAS — PRUEBA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color(1, 1, 1))
	columna.add_child(titulo)

	rejilla = GridContainer.new()
	rejilla.columns = 4
	rejilla.add_theme_constant_override("h_separation", 16)
	rejilla.add_theme_constant_override("v_separation", 14)
	rejilla.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	columna.add_child(rejilla)

	var boton := Button.new()
	boton.text = "OTRA TANDA"
	boton.add_theme_font_size_override("font_size", 22)
	boton.custom_minimum_size = Vector2(280.0, 54.0)
	boton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	boton.pressed.connect(_tanda)
	columna.add_child(boton)

	var volver := Button.new()
	volver.text = "VOLVER AL MENÚ"
	volver.add_theme_font_size_override("font_size", 20)
	volver.custom_minimum_size = Vector2(280.0, 46.0)
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	columna.add_child(volver)


## Saca una tanda nueva: primero una de cada nivel, y después 4 al azar.
func _tanda() -> void:
	for hijo in rejilla.get_children():
		hijo.queue_free()
	for nivel in ["bronce", "plata", "oro", "especial"]:
		_agregar(_carta_de_nivel(nivel))
	for i in 4:
		_agregar(Cartas.aleatoria(azar))


func _agregar(carta: Dictionary) -> void:
	if carta.is_empty():
		return
	var tarjeta := Tarjeta.new()
	rejilla.add_child(tarjeta)
	tarjeta.configurar(carta, TAMANO)


## Busca una carta de un nivel concreto (para que la prueba muestre las 4).
func _carta_de_nivel(nivel: String) -> Dictionary:
	if nivel == "especial":
		for i in 500:
			var carta := Cartas.aleatoria(azar, 1.0)
			if int(carta.get("ovr", 0)) >= Cartas.OVR_ORO:
				return carta
		return Cartas.aleatoria(azar, 1.0)
	for i in 500:
		var otra := Cartas.aleatoria(azar, 0.0)
		if str(otra.get("nivel", "")) == nivel:
			return otra
	return Cartas.aleatoria(azar)


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
