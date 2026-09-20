extends Node3D
## El estadio: césped, líneas, porterías con red, tablas y gradas con gente.
##
## Todo se construye por código, así no hay que dibujar nada en el editor.
## Si quieres mover algo, cambia los números de aquí arriba.

const LARGO := 60.0              # de -30 a +30, sobre el eje X
const ANCHO := 40.0              # de -20 a +20, sobre el eje Z
const MITAD_LARGO := LARGO * 0.5
const MITAD_ANCHO := ANCHO * 0.5
const ANCHO_PORTERIA := 6.0      # el ancho del arco (más grande que el real, para divertirse)
const ALTO_PORTERIA := 2.2
const LARGO_RED := 2.4           # cuánto se hunde la red por detrás
const ALTO_TABLA := 1.0
const ALTO_LINEA := 0.05         # las líneas van un poquito arriba del césped

const VERDE_CLARO := Color(0.25, 0.57, 0.25)
const VERDE_OSCURO := Color(0.21, 0.48, 0.21)
const VERDE_FUERA := Color(0.15, 0.36, 0.17)
const BLANCO := Color(0.94, 0.96, 0.96)


func _ready() -> void:
	_crear_ambiente()
	_crear_cesped()
	_crear_lineas()
	_crear_porterias()
	_crear_tablas()


# ---------------------------------------------------------------- ambiente ---

func _crear_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.66, 0.92)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.76, 0.81, 0.88)
	env.ambient_light_energy = 1.0
	var mundo := WorldEnvironment.new()
	mundo.environment = env
	add_child(mundo)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	sol.light_energy = 1.15
	sol.light_color = Color(1.0, 0.97, 0.9)
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 70.0
	add_child(sol)


# ----------------------------------------------------------------- césped ---

func _crear_cesped() -> void:
	# Un cuadrado verde grande alrededor de la cancha.
	_caja_visual("Cesped base", Vector3(92.0, 0.4, 66.0), Vector3(0.0, -0.2, 0.0), _material(VERDE_FUERA, 0.95))

	# Franjas claras y oscuras, como las canchas de verdad.
	var franjas := 10
	var ancho_franja := LARGO / float(franjas)
	for i in franjas:
		var color := VERDE_CLARO if i % 2 == 0 else VERDE_OSCURO
		var x := -MITAD_LARGO + ancho_franja * (float(i) + 0.5)
		_caja_visual("Franja", Vector3(ancho_franja, 0.04, ANCHO), Vector3(x, 0.0, 0.0), _material(color, 0.95))


# ----------------------------------------------------------------- líneas ---

func _crear_lineas() -> void:
	var g := 0.14

	# Borde de la cancha.
	_linea(Vector3(-MITAD_LARGO, 0.0, -MITAD_ANCHO), Vector3(MITAD_LARGO, 0.0, -MITAD_ANCHO), g)
	_linea(Vector3(-MITAD_LARGO, 0.0, MITAD_ANCHO), Vector3(MITAD_LARGO, 0.0, MITAD_ANCHO), g)
	_linea(Vector3(-MITAD_LARGO, 0.0, -MITAD_ANCHO), Vector3(-MITAD_LARGO, 0.0, MITAD_ANCHO), g)
	_linea(Vector3(MITAD_LARGO, 0.0, -MITAD_ANCHO), Vector3(MITAD_LARGO, 0.0, MITAD_ANCHO), g)

	# Línea del medio.
	_linea(Vector3(0.0, 0.0, -MITAD_ANCHO), Vector3(0.0, 0.0, MITAD_ANCHO), g)

	# Círculo central, hecho con 40 pedacitos de recta.
	var radio := 9.15
	var pasos := 40
	for i in pasos:
		var a1 := TAU * float(i) / float(pasos)
		var a2 := TAU * float(i + 1) / float(pasos)
		_linea(Vector3(cos(a1) * radio, 0.0, sin(a1) * radio), Vector3(cos(a2) * radio, 0.0, sin(a2) * radio), g)

	# Punto del centro.
	var punto := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.25
	disco.bottom_radius = 0.25
	disco.height = 0.03
	disco.radial_segments = 20
	punto.mesh = disco
	punto.position = Vector3(0.0, ALTO_LINEA, 0.0)
	punto.material_override = _material(BLANCO, 0.8)
	add_child(punto)

	# Áreas de cada portería.
	for s in [-1.0, 1.0]:
		# Área grande: 12 m de fondo, 24 m de ancho.
		var x_area: float = s * (MITAD_LARGO - 12.0)
		_linea(Vector3(x_area, 0.0, -12.0), Vector3(x_area, 0.0, 12.0), g)
		_linea(Vector3(s * MITAD_LARGO, 0.0, -12.0), Vector3(x_area, 0.0, -12.0), g)
		_linea(Vector3(s * MITAD_LARGO, 0.0, 12.0), Vector3(x_area, 0.0, 12.0), g)
		# Área chica: 5,5 m de fondo, 14 m de ancho.
		var x_chica: float = s * (MITAD_LARGO - 5.5)
		_linea(Vector3(x_chica, 0.0, -7.0), Vector3(x_chica, 0.0, 7.0), g)
		_linea(Vector3(s * MITAD_LARGO, 0.0, -7.0), Vector3(x_chica, 0.0, -7.0), g)
		_linea(Vector3(s * MITAD_LARGO, 0.0, 7.0), Vector3(x_chica, 0.0, 7.0), g)


# -------------------------------------------------------------- porterías ---

func _crear_porterias() -> void:
	var mat_palo := _material(Color(0.97, 0.98, 0.99), 0.35)
	var radio_palo := 0.09
	var medio_arco := ANCHO_PORTERIA * 0.5

	for s in [-1.0, 1.0]:
		var x: float = s * MITAD_LARGO
		# Los dos postes.
		for z in [-medio_arco, medio_arco]:
			_palo(Vector3(x, 0.0, z), radio_palo, ALTO_PORTERIA, mat_palo, false)
		# El travesaño.
		_palo(Vector3(x, ALTO_PORTERIA, 0.0), radio_palo, ANCHO_PORTERIA, mat_palo, true)

		# La red: fondo, costados y techo (con choque, para que el balón no salga).
		var mat_red := _material(Color(1.0, 1.0, 1.0, 0.32), 0.9)
		mat_red.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_red.cull_mode = BaseMaterial3D.CULL_DISABLED
		var x_red: float = x + s * LARGO_RED
		_caja_solida("Red", Vector3(0.06, ALTO_PORTERIA, ANCHO_PORTERIA), Vector3(x_red, ALTO_PORTERIA * 0.5, 0.0), mat_red)
		for z in [-medio_arco, medio_arco]:
			_caja_solida("Red", Vector3(LARGO_RED, ALTO_PORTERIA, 0.06), Vector3(x + s * LARGO_RED * 0.5, ALTO_PORTERIA * 0.5, z), mat_red)
		_caja_solida("Red", Vector3(LARGO_RED, 0.06, ANCHO_PORTERIA), Vector3(x + s * LARGO_RED * 0.5, ALTO_PORTERIA, 0.0), mat_red)


func _palo(pos: Vector3, radio: float, largo: float, mat: Material, horizontal: bool) -> void:
	var cuerpo := StaticBody3D.new()
	if horizontal:
		cuerpo.position = pos
	else:
		cuerpo.position = Vector3(pos.x, largo * 0.5, pos.z)
	add_child(cuerpo)

	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = largo
	cilindro.radial_segments = 12
	malla.mesh = cilindro
	malla.material_override = mat
	if horizontal:
		malla.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	cuerpo.add_child(malla)

	var forma := CylinderShape3D.new()
	forma.radius = radio
	forma.height = largo
	var choque := CollisionShape3D.new()
	choque.shape = forma
	if horizontal:
		choque.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	cuerpo.add_child(choque)


# ----------------------------------------------------------------- tablas ---

func _crear_tablas() -> void:
	var mat := _material(Color(0.86, 0.88, 0.93), 0.6)
	var grosor := 0.16
	var x_borde := MITAD_LARGO + 0.16
	var z_borde := MITAD_ANCHO + 0.16

	# Detrás de las porterías, dejando libre la boca del arco.
	for s in [-1.0, 1.0]:
		var hueco := ANCHO_PORTERIA * 0.5 + 0.1
		var largo := MITAD_ANCHO - hueco
		var cz := hueco + largo * 0.5
		_caja_solida("Tabla", Vector3(grosor, ALTO_TABLA, largo), Vector3(s * x_borde, ALTO_TABLA * 0.5, cz), mat)
		_caja_solida("Tabla", Vector3(grosor, ALTO_TABLA, largo), Vector3(s * x_borde, ALTO_TABLA * 0.5, -cz), mat)

	# A los costados.
	_caja_solida("Tabla", Vector3(LARGO + 0.4, ALTO_TABLA, grosor), Vector3(0.0, ALTO_TABLA * 0.5, z_borde), mat)
	_caja_solida("Tabla", Vector3(LARGO + 0.4, ALTO_TABLA, grosor), Vector3(0.0, ALTO_TABLA * 0.5, -z_borde), mat)


# ---------------------------------------------------------------- gradas ---

func _crear_gradas() -> void:
	var mat_hormigon := _material(Color(0.56, 0.57, 0.61), 0.95)
	var largo_grada := LARGO + 18.0

	# Tres escalones a cada lado.
	for s in [-1.0, 1.0]:
		for i in 3:
			var alto := 1.2 + float(i) * 1.4
			var z: float = s * (MITAD_ANCHO + 3.0 + float(i) * 2.0)
			_caja_solida("Grada", Vector3(largo_grada, alto, 2.0), Vector3(0.0, alto * 0.5, z), mat_hormigon)

	# La gente (muchos cubitos de colores, todos de un solo golpe para que no pese).
	var caja_gente := BoxMesh.new()
	caja_gente.size = Vector3(0.36, 0.54, 0.36)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = caja_gente
	multi.instance_count = 420

	var azar := RandomNumberGenerator.new()
	azar.seed = 20260920
	for i in multi.instance_count:
		var s := -1.0 if azar.randi() % 2 == 0 else 1.0
		var nivel := azar.randi_range(0, 2)
		var x := azar.randf_range(-largo_grada * 0.5, largo_grada * 0.5)
		var z := s * (MITAD_ANCHO + 3.0 + float(nivel) * 2.0) + azar.randf_range(-0.6, 0.6)
		var y := 1.2 + float(nivel) * 1.4 + 0.27
		multi.set_instance_transform(i, Transform3D(Basis(), Vector3(x, y, z)))
		multi.set_instance_color(i, _color_gente(azar))

	var gente := MultiMeshInstance3D.new()
	gente.multimesh = multi
	var mat_gente := StandardMaterial3D.new()
	mat_gente.vertex_color_use_as_albedo = true
	mat_gente.roughness = 1.0
	gente.material_override = mat_gente
	add_child(gente)


func _color_gente(azar: RandomNumberGenerator) -> Color:
	var opciones := [
		Color(0.20, 0.42, 0.85), Color(0.95, 0.95, 0.95), Color(0.95, 0.80, 0.15),
		Color(0.85, 0.20, 0.20), Color(0.20, 0.65, 0.35), Color(0.55, 0.30, 0.75),
		Color(0.15, 0.15, 0.20),
	]
	return opciones[azar.randi_range(0, opciones.size() - 1)]


# ---------------------------------------------------------------- ayudas ---

func _linea(a: Vector3, b: Vector3, grosor := 0.14) -> void:
	var d := b - a
	var largo := d.length()
	if largo <= 0.001:
		return
	var nodo := Node3D.new()
	nodo.position = Vector3((a.x + b.x) * 0.5, ALTO_LINEA, (a.z + b.z) * 0.5)
	add_child(nodo)
	nodo.look_at(nodo.global_position + d, Vector3.UP)

	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(grosor, 0.03, largo)
	malla.mesh = caja
	malla.material_override = _material(BLANCO, 0.8)
	nodo.add_child(malla)


func _caja_visual(nombre: String, tam: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.material_override = mat
	malla.position = pos
	add_child(malla)
	return malla


func _caja_solida(nombre: String, tam: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre
	cuerpo.position = pos
	add_child(cuerpo)

	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.material_override = mat
	cuerpo.add_child(malla)

	var forma := BoxShape3D.new()
	forma.size = tam
	var choque := CollisionShape3D.new()
	choque.shape = forma
	cuerpo.add_child(choque)
	return cuerpo


func _material(color: Color, rugosidad: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rugosidad
	return m
