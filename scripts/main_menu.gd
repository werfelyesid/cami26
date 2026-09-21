extends Control
## El menú principal: JUGAR, elegir dificultad, CÓMO JUGAR y SALIR.

const RUTA_PARTIDO := "res://scenes/partido.tscn"

var boton_dificultad: Button
var panel_ayuda: PanelContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.20, 0.12)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	_crear_titulo()
	_crear_botones()
	_crear_ayuda()


func _crear_titulo() -> void:
	var titulo := Label.new()
	titulo.text = "CAMI26"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 120)
	titulo.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	titulo.add_theme_constant_override("outline_size", 12)
	titulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	titulo.offset_top = 40.0
	titulo.offset_bottom = 190.0
	add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "FÚTBOL 3D PARA EL CELULAR"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 28)
	subtitulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitulo.offset_top = 170.0
	subtitulo.offset_bottom = 220.0
	add_child(subtitulo)


func _crear_botones() -> void:
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_CENTER)
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BOTH
	caja.add_theme_constant_override("separation", 20)
	add_child(caja)

	var jugar := _boton("JUGAR", 44, Vector2(360.0, 96.0))
	jugar.pressed.connect(_jugar)
	caja.add_child(jugar)

	boton_dificultad = _boton("", 26, Vector2(360.0, 66.0))
	boton_dificultad.pressed.connect(_cambiar_dificultad)
	caja.add_child(boton_dificultad)

	var ayuda := _boton("CÓMO JUGAR", 26, Vector2(360.0, 66.0))
	ayuda.pressed.connect(_mostrar_ayuda)
	caja.add_child(ayuda)

	if not OS.has_feature("mobile"):
		var salir := _boton("SALIR", 26, Vector2(360.0, 66.0))
		salir.pressed.connect(_salir)
		caja.add_child(salir)

	var version := Label.new()
	version.text = "v0.1 — hecho por Camilo y su papá"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 18)
	version.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	version.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	version.offset_top = -60.0
	version.offset_bottom = -20.0
	add_child(version)

	_actualizar_texto_dificultad()


func _crear_ayuda() -> void:
	panel_ayuda = PanelContainer.new()
	panel_ayuda.set_anchors_preset(Control.PRESET_CENTER)
	panel_ayuda.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_ayuda.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel_ayuda.custom_minimum_size = Vector2(1000.0, 640.0)
	add_child(panel_ayuda)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 18)
	panel_ayuda.add_child(caja)

	var texto := Label.new()
	texto.text = """CÓMO JUGAR

• Mueve a tu jugador con el joystick de la izquierda.
  En la compu también sirven W, A, S, D o las flechas.
• TIRO (rojo): dispara al arco.  En la compu: la barra espaciadora.
• PASE (azul): toca suave.  En la compu: Shift.
• CAMBIAR (amarillo): pasas a manejar otro jugador de tu equipo
  (el que esté más cerca del balón).  En la compu: Q.
  Al que manejas se le ve un aro amarillo.

• Son 16 jugadores por equipo, cada uno con su puesto y su número:
  1 arquero · 2,3,4,5,6 defensas · 7,8,10,11,15,16 medios · 9,12,13,14 delanteros.
  Los defensas marcan a los atacantes rivales y tapan los tiros,
  los medios presionan y los delanteros van a hacer los goles.
  Si no los manejas, juegan solos.

• El arquero tiene manitas (un tercio de su tamaño) para tapar el arco,
  atrapa el balón con las manos y lo despeja. No sale del área.

• El partido son 90 minutos = 90 segundos de verdad:
  al minuto 45 hay descanso y el reloj se para 10 segundos.
  Si van empatados al 90 hay tiempo extra hasta el 120,
  y si siguen empatados... ¡8 rondas de penales!

¡Gana el que meta más goles!"""
	texto.add_theme_font_size_override("font_size", 21)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(940.0, 540.0)
	caja.add_child(texto)

	var volver := _boton("VOLVER", 26, Vector2(240.0, 60.0))
	volver.pressed.connect(_ocultar_ayuda)
	caja.add_child(volver)

	panel_ayuda.visible = false


# ------------------------------------------------------------------ botones ---

func _jugar() -> void:
	get_tree().change_scene_to_file(RUTA_PARTIDO)


func _cambiar_dificultad() -> void:
	Ajustes.siguiente_dificultad()
	_actualizar_texto_dificultad()


func _actualizar_texto_dificultad() -> void:
	boton_dificultad.text = "DIFICULTAD:  %s" % Ajustes.nombre_dificultad()


func _mostrar_ayuda() -> void:
	panel_ayuda.visible = true


func _ocultar_ayuda() -> void:
	panel_ayuda.visible = false


func _salir() -> void:
	get_tree().quit()


func _boton(texto: String, tam_fuente: int, tam: Vector2) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = tam
	boton.add_theme_font_size_override("font_size", tam_fuente)
	return boton
