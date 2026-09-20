extends RigidBody3D
## El balón del partido: una esfera que rueda y rebota.
##
## Se construye todo por código (forma, malla y material) para que no haya
## que dibujar nada en el editor.

## Radio del balón en metros (un balón de verdad mide 0,11 m de radio,
## pero aquí lo hacemos un poco más grande para que se vea bien).
const RADIO := 0.22


func _ready() -> void:
	mass = 0.45
	gravity_scale = 1.1
	continuous_cd = true      # evita que el balón atraviese las porterías
	linear_damp = 0.12
	angular_damp = 0.6
	can_sleep = false         # el balón nunca se "duerme"

	# --- choque ---
	var forma := SphereShape3D.new()
	forma.radius = RADIO
	var choque := CollisionShape3D.new()
	choque.shape = forma
	add_child(choque)

	# --- cómo rebota ---
	var fisica := PhysicsMaterial.new()
	fisica.bounce = 0.55
	fisica.friction = 0.7
	physics_material_override = fisica

	# --- se ve ---
	var malla := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = RADIO
	esfera.height = RADIO * 2.0
	esfera.radial_segments = 20
	esfera.rings = 12
	malla.mesh = esfera
	malla.material_override = _material(Color(0.96, 0.96, 0.94), 0.35)
	add_child(malla)

	# Los "parches" negros del balón (seis manchas repartidas).
	var mat_parche := _material(Color(0.09, 0.10, 0.12), 0.4)
	var puntos := [
		Vector3(0, 1, 0), Vector3(0, -1, 0),
		Vector3(1, 0, 0), Vector3(-1, 0, 0),
		Vector3(0, 0, 1), Vector3(0, 0, -1),
	]
	for p in puntos:
		var parche := MeshInstance3D.new()
		var bolita := SphereMesh.new()
		bolita.radius = 0.075
		bolita.height = 0.15
		bolita.radial_segments = 12
		bolita.rings = 6
		parche.mesh = bolita
		parche.material_override = mat_parche
		parche.position = p * (RADIO - 0.02)
		add_child(parche)


## Devuelve el balón a un lugar, quietecito (se usa en el saque de centro).
func reiniciar(posicion: Vector3) -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = posicion


func _material(color: Color, rugosidad: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rugosidad
	return m
