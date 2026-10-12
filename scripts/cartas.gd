class_name Cartas
extends RefCounted
## Las cartas de los jugadores: de qué nivel son y con qué piel se dibujan.
##
## Una carta es un diccionario con los datos del jugador ya listos para pintar:
##   nombre, puesto, dorsal, equipo, color1, color2,
##   vel, tir, pas, reg, fis, res   (las 6 estadísticas, de 1 a 99)
##   ovr                  (el promedio, de 1 a 99)
##   nivel                ("bronce", "plata" u "oro")
##   especial             (true si es de las brillantes y raras)
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

## Las 6 estadísticas: la clave en la carta y cómo se muestra.
const ESTADISTICAS := [
	["vel", "VEL"],
	["tir", "TIR"],
	["pas", "PAS"],
	["reg", "REG"],
	["fis", "FIS"],
	["res", "RES"],
]


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
	return {
		"nombre": str(jugador.get("n", "?")),
		"puesto": str(jugador.get("p", "MC")),
		"dorsal": int(jugador.get("d", 0)),
		"equipo": str(club.get("nombre", "")),
		"equipo_id": str(club.get("id", "")),
		"color1": str(club.get("color_principal", "#ffffff")),
		"color2": str(club.get("color_secundario", "#111111")),
		"vel": int(jugador.get("v", 50)),
		"tir": int(jugador.get("t", 50)),
		"pas": int(jugador.get("pas", 50)),
		"reg": int(jugador.get("reg", 50)),
		"fis": int(jugador.get("f", 50)),
		"res": int(jugador.get("r", 50)),
		"ovr": ovr,
		"nivel": nivel(ovr),
		"especial": especial,
	}


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
