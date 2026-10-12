extends Control
## El menú principal: JUGAR, elegir dificultad, CÓMO JUGAR, SOBRES y SALIR.

const RUTA_PARTIDO := "res://scenes/partido.tscn"
const RUTA_SOBRES := "res://scenes/sobres.tscn"
const RUTA_PLANTILLA := "res://scenes/plantilla.tscn"

var boton_dificultad: Button
var panel_ayuda: PanelContainer
var desliz: ScrollContainer

## Para deslizar el texto de la ayuda con el dedo.
var _arrastre_dedo := -1
var _arrastre_y := 0.0


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
	titulo.add_theme_font_size_override("font_size", 104)
	titulo.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	titulo.add_theme_constant_override("outline_size", 12)
	titulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	titulo.offset_top = 24.0
	titulo.offset_bottom = 148.0
	add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "FÚTBOL 3D PARA EL CELULAR"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 26)
	subtitulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitulo.offset_top = 148.0
	subtitulo.offset_bottom = 192.0
	add_child(subtitulo)


func _crear_botones() -> void:
	var caja := VBoxContainer.new()
	# Arranca debajo del subtítulo (offset fijo desde arriba) y se estira solo
	# hacia abajo, según lo que midan los botones.
	caja.set_anchors_preset(Control.PRESET_CENTER_TOP)
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.offset_top = 198.0
	caja.offset_bottom = 198.0
	caja.add_theme_constant_override("separation", 12)
	add_child(caja)

	var jugar := _boton("JUGAR", 38, Vector2(360.0, 74.0))
	jugar.pressed.connect(_jugar)
	caja.add_child(jugar)

	boton_dificultad = _boton("", 22, Vector2(360.0, 52.0))
	boton_dificultad.pressed.connect(_cambiar_dificultad)
	caja.add_child(boton_dificultad)

	var ayuda := _boton("CÓMO JUGAR", 22, Vector2(360.0, 52.0))
	ayuda.pressed.connect(_mostrar_ayuda)
	caja.add_child(ayuda)

	var sobres := _boton("SOBRES", 22, Vector2(360.0, 52.0))
	sobres.pressed.connect(_ver_sobres)
	caja.add_child(sobres)

	var plantilla := _boton("MI PLANTILLA", 22, Vector2(360.0, 52.0))
	plantilla.pressed.connect(_ver_plantilla)
	caja.add_child(plantilla)

	if not OS.has_feature("mobile"):
		var salir := _boton("SALIR", 22, Vector2(360.0, 52.0))
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

	# Lo que el jugador lleva ganado.
	var monedero := Label.new()
	monedero.text = "GEMAS  %s        MONEDITAS  %s" % [
		Texto.miles(Datos.gemas), Texto.miles(Datos.monedas)]
	monedero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monedero.add_theme_font_size_override("font_size", 20)
	monedero.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	monedero.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	monedero.offset_top = -104.0
	monedero.offset_bottom = -64.0
	add_child(monedero)

	_actualizar_texto_dificultad()


func _crear_ayuda() -> void:
	panel_ayuda = PanelContainer.new()
	panel_ayuda.set_anchors_preset(Control.PRESET_CENTER)
	panel_ayuda.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_ayuda.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel_ayuda.custom_minimum_size = Vector2(1000.0, 640.0)
	# Un fondo casi opaco: si no, el texto de la ayuda se mezcla con el del menú
	# y al deslizar no se entiende nada.
	var fondo_panel := StyleBoxFlat.new()
	fondo_panel.bg_color = Color(0.05, 0.13, 0.09, 1.0)
	fondo_panel.set_corner_radius_all(22)
	fondo_panel.set_content_margin_all(26.0)
	panel_ayuda.add_theme_stylebox_override("panel", fondo_panel)
	add_child(panel_ayuda)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	panel_ayuda.add_child(caja)

	# --- Arriba: el título y la X para cerrar ---
	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 20)
	caja.add_child(cabecera)

	var titulo := Label.new()
	titulo.text = "CÓMO JUGAR"
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulo)

	var cerrar := Button.new()
	cerrar.text = "X"
	cerrar.custom_minimum_size = Vector2(60.0, 60.0)
	cerrar.add_theme_font_size_override("font_size", 30)
	cerrar.tooltip_text = "Cerrar"
	cerrar.pressed.connect(_ocultar_ayuda)
	cabecera.add_child(cerrar)

	# --- El texto, con scroll (que se pueda deslizar) ---
	desliz = ScrollContainer.new()
	desliz.custom_minimum_size = Vector2(940.0, 470.0)
	desliz.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Solo se desliza de arriba a abajo.
	desliz.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caja.add_child(desliz)

	var texto := Label.new()
	texto.text = """CÓMO JUGAR

• Mueve a tu jugador con el joystick de la izquierda.
  En la compu: W A S D o las flechas.
• TIRO (rojo): un toque y el balón sale ya. Si lo MANTIENES APRETADO se carga
  la fuerza (sale la barra de abajo, de 1 a 10) y el tiro sale más duro...
  ¡pero menos preciso: se te puede ir afuera! En la compu: la barra espaciadora.
• PASE (azul): pase a un compañero.  En la compu: la tecla P.
• CORRER MÁS RÁPIDO (esprint): Shift en la compu, o empujar el joystick
  hasta el fondo en el celular. (Los compañeros con el balón corren más lento.)
• CAMBIAR (amarillo): pasas a manejar otro jugador de tu equipo
  (el más cercano al balón). En la compu: la tecla Q.
  Si el balón está en tu área, también puedes pasar a manejar al ARQUERO.

• SI MANEJAS AL ARQUERO: TIRO es atajar (con las manos) y Shift es la
  barrida para llegar a la pelota. Si tiene el balón, mantenlo apretado
  para cargar el despeje y suéltalo para reventarla.

• Son 16 jugadores por equipo, cada uno con su puesto y su número:
  1 arquero · 2,3,4,5,6 defensas · 7,8,10,11,15,16 medios · 9,12,13,14 delanteros.
  Los defensas marcan y tapan los tiros, los medios presionan y los delanteros
  van a hacer los goles. Si no los manejas, juegan solos.

• MI PLANTILLA: con las cartas que te salen en los sobres armas tu equipo.
  Arrastra una carta de la lista hasta un hueco de la cancha (o tócala y
  después toca el hueco). En el arco SOLO puede ir un arquero; los demás van
  donde quieras. Arriba se ve el promedio de tu equipo (el OVR).

• LOS PENALES: el arco se hace más grande y se parte en TRES ZONAS:
  arriba, el centro y abajo.
  - Si tiras tú: mueve el joystick (arriba/abajo) para elegir la zona; la que
    elijas se ve encendida en el arco. Después, TIRO: un toque o mantener
    apretado. El arquero rival se tira a una zona al azar, así que no puede
    adivinar: si se tira a tu zona te ataja y si no... ¡gol!
  - Si tira el rival: eliges TÚ a dónde se tira tu arquero con los tres botones
    (ARRIBA, CENTRO y ABAJO). Si no eliges en 4 segundos, se tira al azar.

• Al arquero que tiene el balón en las manos NO se le puede quitar:
  el que se le arrime se lleva AMARILLA. Y si te atropellan, es FALTA:
  si es dentro del área... ¡PENAL!

• El marcador muestra los 90 minutos de un partido de verdad, pero el partido
  dura 160 segundos de verdad: al minuto 45 hay descanso y el reloj se para
  10 segundos. Si van empatados al 90 hay tiempo extra hasta el 120,
  y si siguen empatados... ¡8 rondas de penales!

¡Gana el que meta más goles!"""
	texto.add_theme_font_size_override("font_size", 19)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(900.0, 0.0)
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desliz.add_child(texto)

	var volver := _boton("VOLVER", 26, Vector2(240.0, 56.0))
	volver.pressed.connect(_ocultar_ayuda)
	caja.add_child(volver)

	panel_ayuda.visible = false


## Deslizar el texto de CÓMO JUGAR con el dedo.
##
## OJO: el ScrollContainer solo entiende la ruedita del mouse y la barra de
## deslizar. En el celular hay que moverle el scroll a mano con el dedo.
func _input(evento: InputEvent) -> void:
	if panel_ayuda == null or not panel_ayuda.visible or desliz == null:
		return
	if evento is InputEventScreenTouch:
		var t := evento as InputEventScreenTouch
		if t.pressed and desliz.get_global_rect().has_point(t.position):
			_arrastre_dedo = t.index
			_arrastre_y = t.position.y
		elif not t.pressed and t.index == _arrastre_dedo:
			_arrastre_dedo = -1
	elif evento is InputEventScreenDrag:
		var d := evento as InputEventScreenDrag
		if d.index == _arrastre_dedo:
			desliz.scroll_vertical -= int(d.position.y - _arrastre_y)
			_arrastre_y = d.position.y


# ------------------------------------------------------------------ botones ---

func _jugar() -> void:
	get_tree().change_scene_to_file(RUTA_PARTIDO)


func _ver_sobres() -> void:
	get_tree().change_scene_to_file(RUTA_SOBRES)


func _ver_plantilla() -> void:
	get_tree().change_scene_to_file(RUTA_PLANTILLA)


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
