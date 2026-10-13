class_name Cartas
extends RefCounted
## Las cartas de los jugadores: de qué nivel son y con qué piel se dibujan.
##
## Una carta es un diccionario con los datos del jugador ya listos para pintar:
##   nombre, puesto, dorsal, equipo, color1, color2,
##   sus 6 estadísticas (de 1 a 99, ver Cartas.estadisticas)
##   ovr                  (el promedio, de 1 a 99)
##   nivel                ("bronce", "plata" u "oro")
##   especial             (true si es de las brillantes y raras)
##
## Las estadísticas NO son las mismas para todos: los jugadores de campo usan
## vel, tir, pas, reg, fis y res, y los arqueros usan ref, man, ach, aer, pie
## y saq (ver Clubes.ESTADISTICAS).
##
## El nivel lo decide el OVR, como en FIFA: bronce hasta 74, plata de 75 a 82
## y oro de 83 para arriba. El OVR se calcula con las estadísticas que importan
## en el puesto (ver Clubes.ovr).

const PIELES := {
	"bronce": "res://datos/cartas/carta_bronce.png",
	"plata": "res://datos/cartas/carta_plata.png",
	"oro": "res://datos/cartas/carta_oro.png",
	"especial": "res://datos/cartas/carta_especial.png",
}
const AVATAR := "res://datos/cartas/avatar.png"

const OVR_PLATA := 75
const OVR_ORO := 83
## Cada cuánto sale una carta especial (brillante) al azar: 6 de cada 100.
const PROBABILIDAD_ESPECIAL := 0.06
## Con qué OVR mínimo puede ser especial: la especial es una carta de oro con la
## piel brillante, así que no tendría sentido que saliera peor que una de plata.
const OVR_MINIMO_ESPECIAL := 83

## Cómo se muestra cada estadística en la carta. Las de arquero (ref, man, ach,
## aer, pie, saq) solo las usan los porteros.
const ETIQUETAS := {
	"vel": "VEL", "tir": "TIR", "pas": "PAS", "reg": "REG", "fis": "FIS", "res": "RES",
	"ref": "REF", "man": "MAN", "ach": "ACH", "aer": "AER", "pie": "PIE", "saq": "SAQ",
}

## Cómo se llama cada estadística DENTRO de una carta. En el archivo de clubes
## algunas usan una sola letra (v, t, f, r) para que el archivo no quede enorme,
## pero en la carta se llaman completo. OJO: si esto se desajusta, las cartas
## muestran 0 (ya nos pasó).
const CLAVES := {
	"v": "vel", "t": "tir", "f": "fis", "r": "res", "pas": "pas", "reg": "reg",
	"ref": "ref", "man": "man", "ach": "ach", "aer": "aer", "pie": "pie", "saq": "saq",
}


## Las 6 estadísticas de una carta ya listas para dibujar: [[clave, etiqueta], ...].
## Las claves son las de la CARTA (vel, tir...), que es lo que hay que buscar en
## el diccionario de la carta. Dependen del puesto.
static func estadisticas(puesto: String) -> Array:
	var lista: Array = []
	for clave in Clubes.estadisticas(puesto):
		var en_carta := str(CLAVES.get(clave, clave))
		lista.append([en_carta, str(ETIQUETAS.get(en_carta, en_carta.to_upper()))])
	return lista


## Los colores de cada nivel de carta: arriba, abajo y el borde. Son los mismos
## que usa la herramienta herramientas/generar_cartas.py.
const COLORES_PIEL := {
	"bronce": [Color8(150, 104, 62), Color8(86, 52, 22), Color8(216, 168, 114)],
	"plata": [Color8(198, 205, 213), Color8(117, 125, 134), Color8(240, 245, 250)],
	"oro": [Color8(248, 208, 84), Color8(172, 118, 20), Color8(255, 238, 168)],
	"especial": [Color8(84, 48, 176), Color8(16, 8, 48), Color8(255, 208, 92)],
}


## Dibuja la piel de una carta POR CÓDIGO: un degradado del color del nivel y su
## borde. Se usa como red de seguridad, porque las imágenes PNG de las pieles se
## pueden quedar en blanco (les pasó: las cartas salían blancas) y una carta
## blanca no se entiende. Cualquier nodo que sepa dibujar puede usarla.
static func dibujar_piel(quien: CanvasItem, tam: Vector2, nivel: String, especial: bool) -> void:
	var clave := "especial" if especial else nivel
	var colores: Array = COLORES_PIEL.get(clave, COLORES_PIEL["bronce"])
	var arriba: Color = colores[0]
	var abajo: Color = colores[1]
	var borde: Color = colores[2]

	# El degradado, con franjas finitas (así se hace un degradado con rectángulos).
	var franjas := 10
	var alto := tam.y / float(franjas)
	for i in franjas:
		var t := float(i) / float(franjas - 1)
		quien.draw_rect(Rect2(0.0, alto * float(i), tam.x, alto + 1.0), arriba.lerp(abajo, t))

	# El borde y una línea clara por dentro, para que se vea con volumen.
	var grosor := maxf(2.0, tam.y * 0.022)
	quien.draw_rect(Rect2(0.0, 0.0, tam.x, tam.y), borde, false, grosor)
	var dentro := grosor + maxf(1.0, tam.y * 0.018)
	if tam.x > dentro * 2.0 and tam.y > dentro * 2.0:
		quien.draw_rect(Rect2(dentro, dentro, tam.x - dentro * 2.0, tam.y - dentro * 2.0),
			Color(1, 1, 1, 0.22), false, maxf(1.0, tam.y * 0.008))
	if clave == "especial":
		quien.draw_rect(Rect2(dentro, dentro, tam.x - dentro * 2.0, tam.y - dentro * 2.0),
			Color(1, 0.85, 0.35, 0.30), false, maxf(1.0, tam.y * 0.012))


## La textura de la piel de una carta, PERO solo si sirve. Si no existe o salió
## en blanco (la imagen se puede dañar al regenerarla), devuelve null para que
## quien dibuje use `dibujar_piel()` en su lugar.
static func textura_piel(carta: Dictionary) -> Texture2D:
	return textura_buena(piel(carta))


## Una imagen cualquiera (una piel, el avatar), PERO solo si sirve: si no existe
## o si quedó en blanco devuelve null. Todas las imágenes de las cartas se miran
## con esto, para que ninguna pueda salir como un cuadro blanco.
static func textura_buena(ruta: String) -> Texture2D:
	var tex: Texture2D = load(ruta)
	if tex == null:
		return null
	var imagen := tex.get_image()
	if imagen == null or imagen.get_width() < 8:
		return null
	# El centro sirve de termómetro: si la imagen quedó en blanco, el centro
	# también está blanco (las pieles de las cartas y el avatar son oscuros ahí).
	var píxel := imagen.get_pixel(imagen.get_width() / 2, imagen.get_height() / 2)
	if píxel.r > 0.94 and píxel.g > 0.94 and píxel.b > 0.94:
		return null                      # salió en blanco
	return tex


## El nivel que le toca a un OVR.
static func nivel(ovr: int) -> String:
	if ovr >= OVR_ORO:
		return "oro"
	if ovr >= OVR_PLATA:
		return "plata"
	return "bronce"


## La imagen (piel) que le toca a una carta.
static func piel(carta: Dictionary) -> String:
	if bool(carta.get("especial", false)):
		return PIELES["especial"]
	return str(PIELES.get(str(carta.get("nivel", "bronce")), PIELES["bronce"]))


## Arma una carta a partir de un jugador y su club.
static func crear(jugador: Dictionary, club: Dictionary, especial := false) -> Dictionary:
	var ovr := Clubes.ovr(jugador)
	var carta := {
		"nombre": str(jugador.get("n", "?")),
		"puesto": str(jugador.get("p", "MC")),
		"dorsal": int(jugador.get("d", 0)),
		"equipo": str(club.get("nombre", "")),
		"equipo_id": str(club.get("id", "")),
		"color1": str(club.get("color_principal", "#ffffff")),
		"color2": str(club.get("color_secundario", "#111111")),
		"ovr": ovr,
		"nivel": nivel(ovr),
		"especial": especial,
	}
	# Las 6 estadísticas que le tocan a su puesto (el arquero tiene las suyas).
	for par in estadisticas(str(jugador.get("p", "MC"))):
		var clave: String = par[0]
		carta[clave] = int(jugador.get(clave, 50))
	return carta


## Las cartas ya armadas y separadas por nivel, para no estar recorriendo toda la
## base de datos cada vez que se saca una carta (eso lo hacía lentísimo).
static var _pools: Dictionary = {}


## Todas las cartas de un nivel, ya listas para usar.
## `nivel` puede ser "bronce", "plata", "oro", "especial" o "todos".
## La especial es una carta de oro (OVR de 75 para arriba) con la piel brillante.
static func pool(nivel := "todos") -> Array:
	if _pools.has(nivel):
		return _pools[nivel]

	var lista: Array = []
	for club in Clubes.cargar_todos():
		var plantilla = club.get("plantilla", [])
		if typeof(plantilla) != TYPE_ARRAY:
			continue
		for jugador in plantilla:
			var carta := crear(jugador, club, nivel == "especial")
			if nivel == "todos":
				lista.append(carta)
			elif nivel == "especial":
				if bool(carta["especial"]) and int(carta["ovr"]) >= OVR_MINIMO_ESPECIAL:
					lista.append(carta)
			elif str(carta["nivel"]) == nivel:
				lista.append(carta)

	_pools[nivel] = lista
	return lista


## Saca una carta al azar de toda la base de datos de clubes.
## `prob_especial` es la probabilidad de que salga brillante.
##
## OJO: se devuelve una COPIA de la carta. Si no, la carta guardada en el
## inventario sería el mismo diccionario que el del pool, y cualquier cambio se
## vería en los dos lados.
static func aleatoria(azar: RandomNumberGenerator, prob_especial := PROBABILIDAD_ESPECIAL) -> Dictionary:
	var lista := pool("especial") if azar.randf() < prob_especial else pool("todos")
	if lista.is_empty():
		return {}
	return (lista[azar.randi_range(0, lista.size() - 1)] as Dictionary).duplicate(true)


## Convierte un color del archivo de clubes ("#00954c") en un Color de Godot.
static func color_de(texto: String, por_defecto := Color.WHITE) -> Color:
	var limpio := texto.strip_edges()
	if limpio.begins_with("#") and (limpio.length() == 7 or limpio.length() == 9):
		return Color.html(limpio)
	return por_defecto


## El texto de la carta, para los mensajes ("Mbappé 87 — Real Madrid").
static func descripcion(carta: Dictionary) -> String:
	if carta.is_empty():
		return "(carta vacía)"
	return "%s %d — %s" % [str(carta.get("nombre", "?")), int(carta.get("ovr", 0)), str(carta.get("equipo", ""))]
