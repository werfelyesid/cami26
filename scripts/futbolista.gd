extends CharacterBody3D
## Base de todos los jugadores: tu jugador, el rival y los arqueros.
##
## Aquí está lo importante:
##   - _logica()   -> la decisión de hacia dónde moverse (cada uno la cambia)
##   - _mover()    -> la física del movimiento y hacia dónde mira
##   - _tocar_balon() -> el "regate": el que tiene el balón lo va empujando
##   - patear()    -> el tiro y el pase
##
## Las medidas del cuerpo son de mentira (cápsula de 1,70 m) para que se
## vea parecido a una persona, no para ser realista.

var velocidad := 7.0
var aceleracion := 45.0

var color_camiseta := Color(0.15, 0.35, 0.9)
var color_pantalon := Color(0.95, 0.95, 0.95)
var color_piel := Color(0.85, 0.64, 0.47)
var color_pelo := Color(0.14, 0.10, 0.08)

## Hacia dónde quiere caminar, en cada eje (-1 a 1). La pone _logica().
var direccion := Vector3.ZERO
## Hacia dónde está mirando de verdad (se calcula con el movimiento).
var hacia := Vector3.FORWARD
## El balón del partido (lo pone la escena del partido).
var balon = null
## El partido lo pone en true solo para el jugador que está más cerca del balón.
var puede_tocar := false
## Si es false, este jugador nunca empuja el balón (lo usan los arqueros).
var puede_regatear := true
## Si es true, el jugador mira siempre hacia "hacia_fijo" (lo usan los arqueros).
var mirar_fijo := false
var hacia_fijo := Vector3.ZERO

## Cuenta atrás para que no se pueda patear mil veces por segundo.
var _espera_pateo := 0.0


func _ready() -> void:
	# --- choque (una cápsula que llega hasta el suelo) ---
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.33
	capsula.height = 1.7
	var choque := CollisionShape3D.new()
	choque.shape = capsula
	choque.position = Vector3(0.0, 0.85, 0.0)
	add_child(choque)

	# --- piernas ---
	for lado in [-1.0, 1.0]:
		_pieza(Vector3(0.14, 0.62, 0.16), Vector3(0.11 * lado, 0.31, 0.0), color_pantalon)
	# --- pies ---
	for lado in [-1.0, 1.0]:
		_pieza(Vector3(0.16, 0.09, 0.26), Vector3(0.11 * lado, 0.05, -0.05), Color(0.12, 0.12, 0.14))
	# --- camiseta ---
	_pieza(Vector3(0.46, 0.62, 0.28), Vector3(0.0, 1.02, 0.0), color_camiseta)
	# --- brazos ---
	for lado in [-1.0, 1.0]:
		_pieza(Vector3(0.11, 0.52, 0.13), Vector3(0.29 * lado, 1.06, 0.0), color_piel)
	# --- cabeza ---
	var cabeza := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.19
	esfera.height = 0.38
	esfera.radial_segments = 16
	esfera.rings = 8
	cabeza.mesh = esfera
	cabeza.position = Vector3(0.0, 1.50, 0.0)
	cabeza.material_override = _material(color_piel, 0.7)
	add_child(cabeza)
	# --- pelo ---
	var pelo := MeshInstance3D.new()
	var esfera_pelo := SphereMesh.new()
	esfera_pelo.radius = 0.196
	esfera_pelo.height = 0.39
	esfera_pelo.radial_segments = 16
	esfera_pelo.rings = 8
	pelo.mesh = esfera_pelo
	pelo.position = Vector3(0.0, 1.545, 0.015)
	pelo.material_override = _material(color_pelo, 0.9)
	add_child(pelo)


func _physics_process(delta: float) -> void:
	_espera_pateo = maxf(0.0, _espera_pateo - delta)
	_logica(delta)
	_mover(delta)
	_tocar_balon(delta)


## Cada jugador decide aquí hacia dónde quiere moverse.
## La clase base no hace nada; el jugador, el rival y el arquero la cambian.
func _logica(_delta: float) -> void:
	pass


func _mover(delta: float) -> void:
	# Gravedad (así el jugador no sale volando ni se hunde).
	var g := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= g * delta

	# Acelerar hacia la dirección que pidió _logica().
	var objetivo := direccion.normalized() * velocidad
	velocity.x = move_toward(velocity.x, objetivo.x, aceleracion * delta)
	velocity.z = move_toward(velocity.z, objetivo.z, aceleracion * delta)
	move_and_slide()

	# Hacia dónde mira.
	if mirar_fijo:
		if hacia_fijo.length() > 0.001:
			hacia = hacia_fijo.normalized()
			rotation.y = atan2(-hacia.x, -hacia.z)
	else:
		var plano := Vector3(velocity.x, 0.0, velocity.z)
		if plano.length() > 0.5:
			rotation.y = lerp_angle(rotation.y, atan2(-plano.x, -plano.z), minf(1.0, 14.0 * delta))
		hacia = -global_transform.basis.z
		hacia.y = 0.0
		if hacia.length() > 0.001:
			hacia = hacia.normalized()


## El regate: si este jugador es el más cercano al balón y va de frente,
## le va empujando la pelota por delante. Así no hay que hacer malabares.
func _tocar_balon(_delta: float) -> void:
	if balon == null or not puede_tocar or not puede_regatear:
		return
	var d: Vector3 = balon.global_position - global_position
	d.y = 0.0
	var distancia := d.length()
	if distancia > 1.7 or distancia < 0.01:
		return
	if hacia.dot(d / distancia) < 0.35:
		return
	var v: Vector3 = balon.linear_velocity
	var objetivo := hacia * maxf(velocidad * 0.95, 4.0)
	v.x = lerpf(v.x, objetivo.x, 0.35)
	v.z = lerpf(v.z, objetivo.z, 0.35)
	balon.linear_velocity = v


## Patea el balón. Devuelve true si lo alcanzó a tocar.
##   fuerza  -> qué tan fuerte sale (más grande = más rápido)
##   arriba  -> cuánto se levanta del piso
##   giro_minimo -> qué tan de frente tiene que estar el balón (0 = da igual)
func patear(fuerza: float, arriba: float, giro_minimo := 0.1) -> bool:
	if balon == null or _espera_pateo > 0.0:
		return false
	var d: Vector3 = balon.global_position - global_position
	d.y = 0.0
	var distancia := d.length()
	if distancia > 2.3 or distancia < 0.01:
		return false
	if hacia.dot(d / distancia) < giro_minimo:
		return false
	_espera_pateo = 0.4
	balon.apply_central_impulse((hacia * fuerza + Vector3.UP * arriba) * balon.mass)
	return true


func _pieza(tam: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	malla.material_override = _material(color, 0.85)
	add_child(malla)
	return malla


func _material(color: Color, rugosidad: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rugosidad
	return m
