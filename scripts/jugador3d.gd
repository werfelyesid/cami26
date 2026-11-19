extends CharacterBody3D
## UN JUGADOR 3D, de cualquiera de los dos equipos.
##
## Aquí está el muñeco (camiseta, pantaloneta, medias, botines y número), el
## movimiento, la animación de correr, la barrida, el tiro y el buceo del
## arquero. Las decisiones (a dónde va cada uno) las toma partido3d.gd.
##
## La MEDIA manda: un jugador de media 90 corre más, patea más fuerte y falla
## menos que uno de media 60. Con poner_media() se le dan sus números.
##
## El modelo se arma con cajas y esferas (no hay modelos para descargar). Las
## medidas son las de una persona de 1,78 m, así el tamaño es el de verdad al
## lado del arco y del balón.

const ALTO := 1.78
## El ancho del arco (el arquero se mueve de palo a palo).
const ANCHO_ARCO := 7.32

# --- El sprint y el cansancio (como en FIFA) ---
## Cuánto se multiplica la velocidad cuando esprintas.
const FACTOR_SPRINT := 1.9
## Cuántos segundos dura la energía llena (5 segundos de sprint seguido).
const SEGUNDOS_SPRINT := 5.0
## Cuánta energía se recupera por segundo cuando NO esprintas.
const RECARGA_ENERGIA := 0.26
## Hasta que no se recupere esto, no se puede volver a esprintar.
const ENERGIA_MINIMA := 0.20
## Con el balón en los pies se va MUY lento (la mitad de la velocidad).
const FACTOR_CON_BALON := 0.52

## Los puestos.
enum Rol { ARQUERO, DEFENSA, MEDIO, DELANTERO }

# --- Quién es ---
var numero := 9
var nombre := "Jugador"
var equipo := 0
var rol := Rol.MEDIO
## El promedio del jugador (1 a 130). Manda en la velocidad y la precisión.
var media := 70
## Si es una leyenda (Cristiano, Messi, Neymar): aro dorado y etiqueta.
var leyenda := false
var es_humano := false

# --- Colores del uniforme ---
var color_camiseta := Color(0.10, 0.30, 0.85)
var color_pantalon := Color(0.95, 0.95, 0.98)
var color_medias := Color(0.10, 0.30, 0.85)
var color_piel := Color(0.85, 0.64, 0.47)
var color_pelo := Color(0.12, 0.09, 0.07)
var color_botines := Color(0.09, 0.09, 0.10)
var numero_color := Color(0.97, 0.97, 0.97)

# --- Lo que le dice el partido ---
var balon = null
var controles = null
var camara: Camera3D = null
## Dónde tiene que ir (lo calcula el partido).
var destino := Vector3.ZERO
var tiene_destino := false
## Si sale corriendo a todo (sprint).
var correr := false
## A quién mirar. Si es cero, mira hacia donde camina.
var mirar_a := Vector3.ZERO
## Su puesto en la formación (se lo pone el partido).
var formacion := Vector3.ZERO
var arco_propio := -52.5
var arco_rival := 52.5
## En los penales no se mueve solo: lo maneja el partido.
var modo_penal := false

# --- La posesión ---
## Soy yo el que tiene el balón (lo pone el partido).
var dueno = null
## Quién lo tiene en el partido, sea quien sea.
var poseedor = null

# --- Cómo juega (sale de la media) ---
var velocidad := 7.2
var potencia := 0.0             # 1 a 10, mientras carga el tiro
var cargando := false

# --- La energía (para el sprint) ---
## De 0 a 1. Con 1 se puede esprintar 5 segundos seguidos.
var energia := 1.0
## true mientras se está esprintando de verdad (para la barra del HUD).
var esprintando := false
var _energia_agotada := false

# --- El indicador (el aro y el nombre, solo para el que manejas) ---
var _anillo: MeshInstance3D
var _etiqueta: Label3D
var _anillo_leyenda: MeshInstance3D
var _etiqueta_leyenda: Label3D

# --- Relojes y estado ---
var hacia := Vector3.FORWARD
var _vel_base := 7.2
var _espera_pateo := 0.0
var _era_disparo := false
var _era_pase := false
var _era_barrida := false
var _barrida_t := 0.0
var _barrida_cd := 0.0
var _barrida_dir := Vector3.ZERO
var _en_el_piso := 0.0
var _buceando := 0.0
var _buceo_dir := 0.0
var _agarrando := false
var _tiempo_agarre := 0.0
var _anim_golpe := 0.0
var _fase := 0.0

## Aviso al partido: este jugador le hizo falta a otro.
signal falta_cometida(faltoso, victima)
## Aviso al partido: este jugador remató al arco (para las estadísticas).
signal remate(quien, rumbo, potencia)

# --- El modelo (se arma en _ready) ---
var cuerpo: Node3D
var _pierna_izq: Node3D
var _pierna_der: Node3D
var _brazo_izq: Node3D
var _brazo_der: Node3D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4

	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.30
	capsula.height = ALTO
	var choque := CollisionShape3D.new()
	choque.shape = capsula
	choque.position = Vector3(0.0, ALTO * 0.5, 0.0)
	add_child(choque)

	# Los que maneja la cámara (tú y los arqueros) llevan el muñeco completo.
	_armar_modelo(es_humano or rol == Rol.ARQUERO)
	_armar_indicador()


## Con esto se le dan sus números al jugador.
## La media va de 1 a 119 (las cartas de Camilo llegan a 119).
func poner_media(valor: int) -> void:
	media = clampi(valor, 1, 130)
	# Un jugador de media 60 corre 7,3 m/s; uno de 130, 9,2 m/s.
	_vel_base = 5.64 + float(media) * 0.0275
	velocidad = _vel_base


## Qué tan bien le pega al balón: 0 = nunca falla, 1 = se le va afuera.
func error_de_tiro() -> float:
	return clampf(1.55 - float(media) * 0.012, 0.15, 1.4)


## Qué tan fuerte patea, comparado con un jugador normal (media 70).
func fuerza_de_tiro() -> float:
	return clampf(0.82 + float(media) / 119.0 * 0.46, 0.7, 1.35)


# ---------------------------------------------------------------- modelo ---

## Arma el muñeco. Con `detalle` en false se ahorra la mitad de las piezas
## (manos, hombros, cuello): con 22 jugadores en la cancha eso se nota.
func _armar_modelo(detalle: bool) -> void:
	cuerpo = Node3D.new()
	add_child(cuerpo)

	# --- piernas (el pivote está en la cadera) ---
	_pierna_izq = _pivote(Vector3(0.105, 0.92, 0.0))
	_pierna_der = _pivote(Vector3(-0.105, 0.92, 0.0))
	for pierna in [_pierna_izq, _pierna_der]:
		_caja(pierna, Vector3(0.17, 0.42, 0.19), Vector3(0.0, -0.20, 0.0), color_pantalon, 0.85)
		_caja(pierna, Vector3(0.145, 0.42, 0.16), Vector3(0.0, -0.60, 0.0), color_medias, 0.85)
		_caja(pierna, Vector3(0.15, 0.11, 0.30), Vector3(0.0, -0.845, -0.055), color_botines, 0.45)

	# --- pantaloneta y torso ---
	_caja(cuerpo, Vector3(0.40, 0.24, 0.27), Vector3(0.0, 0.99, 0.0), color_pantalon, 0.85)
	_caja(cuerpo, Vector3(0.44, 0.54, 0.26), Vector3(0.0, 1.30, 0.0), color_camiseta, 0.8)
	if detalle:
		for lado in [-1.0, 1.0]:
			var hombro := MeshInstance3D.new()
			var esfera := SphereMesh.new()
			esfera.radius = 0.115
			esfera.height = 0.23
			esfera.radial_segments = 10
			esfera.rings = 5
			hombro.mesh = esfera
			hombro.position = Vector3(0.20 * lado, 1.53, 0.0)
			hombro.material_override = _material(color_camiseta, 0.8)
			cuerpo.add_child(hombro)

	# --- brazos ---
	_brazo_izq = _pivote(Vector3(0.26, 1.50, 0.0))
	_brazo_der = _pivote(Vector3(-0.26, 1.50, 0.0))
	for brazo in [_brazo_izq, _brazo_der]:
		_caja(brazo, Vector3(0.135, 0.17, 0.155), Vector3(0.0, -0.075, 0.0), color_camiseta, 0.8)
		_caja(brazo, Vector3(0.105, 0.40, 0.115), Vector3(0.0, -0.33, 0.0), color_piel, 0.6)
		if detalle:
			var mano := MeshInstance3D.new()
			var esfera := SphereMesh.new()
			esfera.radius = 0.062
			esfera.height = 0.124
			esfera.radial_segments = 8
			esfera.rings = 4
			mano.mesh = esfera
			mano.position = Vector3(0.0, -0.555, 0.0)
			mano.material_override = _material(color_piel, 0.6)
			brazo.add_child(mano)

	# --- cuello y cabeza ---
	if detalle:
		_caja(cuerpo, Vector3(0.13, 0.09, 0.13), Vector3(0.0, 1.60, 0.0), color_piel, 0.6)
	var cabeza := MeshInstance3D.new()
	var craneo := SphereMesh.new()
	craneo.radius = 0.115
	craneo.height = 0.26
	craneo.radial_segments = 14
	craneo.rings = 8
	cabeza.mesh = craneo
	cabeza.position = Vector3(0.0, 1.70, 0.0)
	cabeza.scale = Vector3(0.95, 1.12, 1.0)
	cabeza.material_override = _material(color_piel, 0.62)
	cuerpo.add_child(cabeza)

	# --- pelo ---
	var pelo := MeshInstance3D.new()
	var casco := SphereMesh.new()
	casco.radius = 0.12
	casco.height = 0.24
	casco.is_hemisphere = true
	casco.radial_segments = 12
	casco.rings = 6
	pelo.mesh = casco
	pelo.position = Vector3(0.0, 1.755, 0.005)
	pelo.scale = Vector3(0.98, 0.95, 1.02)
	pelo.material_override = _material(color_pelo, 0.75)
	cuerpo.add_child(pelo)

	# --- el número, en la espalda ---
	var dorsal := Label3D.new()
	dorsal.text = str(numero)
	dorsal.font_size = 64
	dorsal.pixel_size = 0.0035
	dorsal.modulate = numero_color
	dorsal.outline_size = 0
	dorsal.position = Vector3(0.0, 1.30, 0.14)
	cuerpo.add_child(dorsal)


## El aro de color en el piso y el nombre flotando: lo que en FIFA te dice
## cuál de los once estás manejando.
func _armar_indicador() -> void:
	_anillo = MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.44
	toro.outer_radius = 0.56
	toro.rings = 12
	toro.ring_segments = 20
	_anillo.mesh = toro
	_anillo.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_anillo.position = Vector3(0.0, 0.04, 0.0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color_camiseta.lightened(0.45)
	material.emission_enabled = true
	material.emission = color_camiseta.lightened(0.35)
	material.emission_energy_multiplier = 1.6
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.92
	_anillo.material_override = material
	_anillo.visible = false
	# Va colgado del jugador (no del cuerpo), así no se inclina al correr.
	add_child(_anillo)

	_etiqueta = Label3D.new()
	_etiqueta.font_size = 64
	_etiqueta.pixel_size = 0.0042
	_etiqueta.position = Vector3(0.0, 2.16, 0.0)
	_etiqueta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_etiqueta.no_depth_test = true
	_etiqueta.outline_size = 12
	_etiqueta.modulate = Color(1, 1, 1)
	_etiqueta.outline_modulate = Color(0, 0, 0, 0.85)
	_etiqueta.visible = false
	add_child(_etiqueta)

	# --- El aro dorado y la etiqueta de LEYENDA ---
	_anillo_leyenda = MeshInstance3D.new()
	var toro_dorado := TorusMesh.new()
	toro_dorado.inner_radius = 0.60
	toro_dorado.outer_radius = 0.76
	toro_dorado.rings = 12
	toro_dorado.ring_segments = 22
	_anillo_leyenda.mesh = toro_dorado
	_anillo_leyenda.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_anillo_leyenda.position = Vector3(0.0, 0.05, 0.0)
	var mat_dorado := StandardMaterial3D.new()
	mat_dorado.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_dorado.albedo_color = Color(1.0, 0.84, 0.20, 0.95)
	mat_dorado.emission_enabled = true
	mat_dorado.emission = Color(1.0, 0.72, 0.10)
	mat_dorado.emission_energy_multiplier = 2.2
	mat_dorado.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_anillo_leyenda.material_override = mat_dorado
	_anillo_leyenda.visible = false
	add_child(_anillo_leyenda)

	_etiqueta_leyenda = Label3D.new()
	_etiqueta_leyenda.font_size = 96
	_etiqueta_leyenda.pixel_size = 0.0042
	_etiqueta_leyenda.position = Vector3(0.0, 2.58, 0.0)
	_etiqueta_leyenda.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_etiqueta_leyenda.no_depth_test = true
	_etiqueta_leyenda.outline_size = 12
	_etiqueta_leyenda.modulate = Color(1.0, 0.84, 0.20)
	_etiqueta_leyenda.outline_modulate = Color(0.25, 0.14, 0.0, 0.95)
	_etiqueta_leyenda.text = ""
	_etiqueta_leyenda.visible = false
	add_child(_etiqueta_leyenda)


## Lo marca como LEYENDA: aro dorado y su nombre arriba en dorado.
func poner_leyenda(si: bool, texto := "") -> void:
	leyenda = si
	if _anillo_leyenda != null:
		_anillo_leyenda.visible = si
	if _etiqueta_leyenda != null:
		_etiqueta_leyenda.visible = si
		_etiqueta_leyenda.text = texto if texto != "" else "LEYENDA"


## Prende (o apaga) el aro y el nombre de encima.
func mostrar_indicador(si: bool, texto := "") -> void:
	if _anillo != null:
		_anillo.visible = si
	if _etiqueta != null:
		_etiqueta.visible = si
		if texto != "":
			_etiqueta.text = texto


func _pivote(pos: Vector3) -> Node3D:
	var nodo := Node3D.new()
	nodo.position = pos
	cuerpo.add_child(nodo)
	return nodo


func _caja(padre: Node3D, tam: Vector3, pos: Vector3, color: Color, rugosidad: float) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	malla.material_override = _material(color, rugosidad)
	padre.add_child(malla)
	return malla


func _material(color: Color, rugosidad: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rugosidad
	m.metallic = 0.0
	return m


# ------------------------------------------------------------- cada cuadro ---

func _physics_process(delta: float) -> void:
	_espera_pateo = maxf(0.0, _espera_pateo - delta)
	_barrida_cd = maxf(0.0, _barrida_cd - delta)
	_en_el_piso = maxf(0.0, _en_el_piso - delta)

	if es_humano:
		_leer_controles(delta)

	_mover(delta)
	_actualizar_energia(delta)
	_anima(delta)
	_mantener_balon(delta)


## La energía del sprint: se gasta mientras esprintas y se recarga cuando no.
func _actualizar_energia(delta: float) -> void:
	if esprintando:
		energia = maxf(0.0, energia - delta / SEGUNDOS_SPRINT)
		if energia <= 0.0:
			_energia_agotada = true
			esprintando = false
	else:
		energia = minf(1.0, energia + delta * RECARGA_ENERGIA)
		if _energia_agotada and energia >= ENERGIA_MINIMA:
			_energia_agotada = false


## El humano camina con el joystick (o el teclado). El tiro, el pase y la
## barrida se disparan con botones.
func _leer_controles(delta: float) -> void:
	var v := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1.0

	var joystick := Vector2.ZERO
	if controles != null:
		joystick = controles.mover
		v += joystick
	if v.length() > 1.0:
		v = v.normalized()

	correr = Input.is_key_pressed(KEY_SHIFT) or joystick.length() > 0.92

	var rumbo := _de_la_camara(v)
	tiene_destino = rumbo.length() > 0.05
	destino = global_position + rumbo * 3.0

	# --- el tiro: se carga mientras se tiene apretado ---
	var disparando := Input.is_key_pressed(KEY_SPACE)
	var pasando := Input.is_key_pressed(KEY_P)
	var barriendo := Input.is_key_pressed(KEY_X)
	if controles != null:
		disparando = disparando or controles.disparar
		pasando = pasando or controles.pasar
		barriendo = barriendo or controles.barrida

	if disparando:
		cargando = true
		potencia = minf(10.0, potencia + delta * 9.0)
	if _era_disparo and not disparando:
		_tirar()
		cargando = false
		potencia = 0.0

	if pasando and not _era_pase:
		_pasar()

	if barriendo and not _era_barrida:
		empezar_barrida(hacia)

	_era_disparo = disparando
	_era_pase = pasando
	_era_barrida = barriendo


## Convierte lo que pide el joystick (pantalla) a una dirección en el mundo,
## tomando como referencia la cámara.
func _de_la_camara(v: Vector2) -> Vector3:
	if camara == null:
		return Vector3(v.x, 0.0, v.y)
	var base := camara.global_transform.basis
	var adelante := Vector3(-base.z.x, 0.0, -base.z.z).normalized()
	var derecha := Vector3(base.x.x, 0.0, base.x.z).normalized()
	if v.length() < 0.05:
		return Vector3.ZERO
	return (derecha * v.x + adelante * -v.y).normalized()


# ------------------------------------------------------------- movimiento ---

func _mover(delta: float) -> void:
	var gravedad := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= gravedad * delta

	# En el piso (después de errar una barrida): no se mueve de acá.
	if _en_el_piso > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 26.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 26.0 * delta)
		move_and_slide()
		return

	# El arquero tirándose en un penal: sale disparado a su zona.
	if _buceando > 0.0:
		_buceando -= delta
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		velocity.z = _buceo_dir * 11.0
		move_and_slide()
		return

	# La barrida: el que se tira va derecho y rapidísimo.
	if _barrida_t > 0.0:
		_barrida_t -= delta
		velocity.x = _barrida_dir.x * 14.0
		velocity.z = _barrida_dir.z * 14.0
		move_and_slide()
		_revisar_barrida()
		return

	var rumbo := Vector3.ZERO
	if tiene_destino and not modo_penal:
		rumbo = destino - global_position
		rumbo.y = 0.0
		if rumbo.length() > 0.4:
			rumbo = rumbo.normalized()
		else:
			rumbo = Vector3.ZERO

	# Sprint: solo si queda energía y no está agotado.
	esprintando = correr and not _energia_agotada and energia > 0.0 and rumbo.length() > 0.1
	velocidad = _vel_base * (FACTOR_SPRINT if esprintando else 1.0)
	# Con el balón en los pies va MUY lento: es el precio de tenerla.
	if dueno == self and not _agarrando:
		velocidad *= FACTOR_CON_BALON

	var objetivo := rumbo * velocidad
	var aceleracion := 34.0 if rumbo.length() > 0.1 else 26.0
	velocity.x = move_toward(velocity.x, objetivo.x, aceleracion * delta)
	velocity.z = move_toward(velocity.z, objetivo.z, aceleracion * delta)
	move_and_slide()

	# Hacia dónde mira.
	var plano := Vector3(velocity.x, 0.0, velocity.z)
	if mirar_a != Vector3.ZERO:
		var a := mirar_a - global_position
		a.y = 0.0
		if a.length() > 0.2:
			rotation.y = lerp_angle(rotation.y, atan2(-a.x, -a.z), minf(1.0, 8.0 * delta))
	elif plano.length() > 0.5:
		var rumbo_mirar := atan2(-plano.x, -plano.z)
		rotation.y = lerp_angle(rotation.y, rumbo_mirar, minf(1.0, 12.0 * delta))

	hacia = -global_transform.basis.z
	hacia.y = 0.0
	if hacia.length() > 0.001:
		hacia = hacia.normalized()


# ------------------------------------------------------------------ barrida ---

## Se tira una barrida hacia donde mira. Es la ÚNICA forma de quitarle el balón
## a alguien, y si le pega al rival es FALTA (y dentro del área, penal).
func empezar_barrida(dir: Vector3) -> void:
	if _barrida_t > 0.0 or _barrida_cd > 0.0 or _en_el_piso > 0.0:
		return
	if _buceando > 0.0:
		return
	var rumbo := Vector3(dir.x, 0.0, dir.z)
	if rumbo.length() < 0.1:
		rumbo = hacia
	_barrida_dir = rumbo.normalized()
	_barrida_t = 0.42
	_barrida_cd = 1.4
	_anim_golpe = 1.0


## Mientras dura la barrida, ¿le pegó a alguien del otro equipo?
func _revisar_barrida() -> void:
	if poseedor == null or poseedor == self:
		return
	if poseedor.equipo == equipo:
		return
	var d: Vector3 = poseedor.global_position - global_position
	d.y = 0.0
	if d.length() < 1.15:
		_barrida_t = 0.0
		_en_el_piso = 1.0
		falta_cometida.emit(self, poseedor)


func en_el_piso() -> bool:
	return _en_el_piso > 0.0


func barriendo() -> bool:
	return _barrida_t > 0.0


func puede_barrerse() -> bool:
	return _barrida_t <= 0.0 and _barrida_cd <= 0.0 and _en_el_piso <= 0.0 and _buceando <= 0.0


## El arquero se tira a un lado del arco (lo usa el partido en los penales).
func bucear(z_objetivo: float) -> void:
	_buceando = 0.8
	var dz := z_objetivo - global_position.z
	_buceo_dir = signf(dz) if absf(dz) > 0.15 else 0.0


# ------------------------------------------------------------------ el balón ---

## El que tiene el balón se lo lleva pegado a los pies.
func _mantener_balon(_delta: float) -> void:
	if balon == null:
		return

	# El arquero que atrapa se lo queda en las manos un ratito.
	if _agarrando:
		balon.freeze = true
		balon.global_position = global_position + Vector3(0.0, 1.25, 0.0) + hacia * 0.25
		return

	if dueno != self:
		return

	var adelante := hacia * 0.55
	balon.freeze = true
	balon.linear_velocity = Vector3.ZERO
	balon.angular_velocity = Vector3.ZERO
	balon.llevar(true)
	balon.global_position = global_position + Vector3(0.0, 0.13, 0.0) + adelante


## Suelta el balón (para patear, pasar o cuando lo pierde).
func soltar_balon() -> void:
	dueno = null
	if balon != null and not _agarrando:
		balon.llevar(false)
		balon.freeze = false


## Atrapa el balón con las manos (el arquero). Se lo queda un ratito.
func agarrar_balon() -> void:
	_agarrando = true
	_tiempo_agarre = 0.0
	dueno = null
	balon.freeze = true
	balon.llevar(true)
	balon.linear_velocity = Vector3.ZERO


func agarrando() -> bool:
	return _agarrando


## ¿Ya se le acabó el tiempo de tener el balón en las manos?
func revisar_agarre(delta: float) -> bool:
	if not _agarrando:
		return false
	_tiempo_agarre += delta
	return _tiempo_agarre > 1.5


func soltar_agarre() -> void:
	_agarrando = false
	if balon != null:
		balon.llevar(false)
		balon.freeze = false


# ------------------------------------------------------------- tiro y pase ---

## ¿Tiene el balón a tiro?
func alcance_del_balon(radio := 2.0) -> bool:
	if balon == null:
		return false
	var d: Vector3 = balon.global_position - global_position
	d.y = 0.0
	return d.length() <= radio


## Patea el balón hacia donde mira. La potencia que se cargó (1 a 10) decide
## la fuerza y la altura. Cuanta más potencia, más se puede ir afuera.
func _tirar() -> void:
	if balon == null or _espera_pateo > 0.0:
		return
	if not alcance_del_balon(2.0):
		return

	_espera_pateo = 0.45
	_anim_golpe = 1.0

	var fuerza := lerpf(11.0, 30.0, clampf((potencia - 1.0) / 9.0, 0.0, 1.0)) * fuerza_de_tiro()
	var altura := lerpf(1.2, 4.4, clampf((potencia - 1.0) / 9.0, 0.0, 1.0))
	var error := Vector3(0.0, 0.0, randf_range(-1.0, 1.0)) * (0.6 + potencia * 0.28) * error_de_tiro()

	var rumbo := hacia
	if rumbo.length() < 0.1:
		rumbo = Vector3(signf(arco_rival), 0.0, 0.0)
	soltar_balon()
	balon.patear((rumbo * fuerza + error + Vector3.UP * altura) * balon.mass)
	# Se avisa con la dirección REAL (con el error incluido), para que las
	# estadísticas de "tiros al arco" no mientan.
	remate.emit(self, (rumbo * fuerza + error).normalized(), potencia)


## El pase: un toque suave y bajo, para acomodar el balón o dárselo a un
## compañero.
func _pasar() -> void:
	if balon == null or _espera_pateo > 0.0:
		return
	if not alcance_del_balon(2.0):
		return
	_espera_pateo = 0.35
	_anim_golpe = 0.7
	soltar_balon()
	balon.patear((hacia * 13.0 + Vector3.UP * 1.0) * balon.mass)


## Un pase a un punto (lo usan los saques y la máquina).
## Devuelve true si alcanzó el balón.
func patear_a(punto: Vector3, fuerza: float, altura: float) -> bool:
	if balon == null or _espera_pateo > 0.0:
		return false
	if not alcance_del_balon(2.2):
		return false
	_espera_pateo = 0.35
	_anim_golpe = 0.8
	var rumbo: Vector3 = punto - balon.global_position
	rumbo.y = 0.0
	if rumbo.length() < 0.2:
		return false
	rumbo = rumbo.normalized()
	soltar_balon()
	balon.patear((rumbo * fuerza * fuerza_de_tiro() + Vector3.UP * altura) * balon.mass)
	return true


# ---------------------------------------------------------------- animación ---

## El muñeco corre: las piernas y los brazos van y vienen, y el cuerpo sube y
## baja un poquito. Cuando patea, la pierna sale para adelante.
func _anima(delta: float) -> void:
	var rapidez := Vector3(velocity.x, 0.0, velocity.z).length()
	var r := clampf(rapidez / maxf(_vel_base, 0.1), 0.0, 1.4)
	_fase += delta * (5.0 + rapidez * 1.7)

	var vaiven := sin(_fase)
	_anim_golpe = maxf(0.0, _anim_golpe - delta * 3.2)

	if _pierna_izq != null:
		_pierna_izq.rotation.x = vaiven * 0.85 * r - _anim_golpe * 1.35
		_pierna_der.rotation.x = -vaiven * 0.85 * r + _anim_golpe * 0.35
	if _brazo_izq != null:
		_brazo_izq.rotation.x = -vaiven * 0.65 * r - _anim_golpe * 0.5
		_brazo_der.rotation.x = vaiven * 0.65 * r - _anim_golpe * 0.5

	if cuerpo == null:
		return
	cuerpo.position.y = absf(vaiven) * 0.035 * r
	cuerpo.rotation.x = -0.10 * r

	# En la barrida se tira al piso; si la erra, queda en el piso.
	if _barrida_t > 0.0 or _en_el_piso > 0.0:
		cuerpo.rotation.x = -1.15
	# El arquero se estira de costado para tapar.
	if _buceando > 0.0:
		cuerpo.rotation.z = -_buceo_dir * 1.35
		cuerpo.position.y = 0.25
	else:
		cuerpo.rotation.z = 0.0
