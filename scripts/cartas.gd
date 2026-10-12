class_name Cartas
extends RefCounted
## Las cartas de los jugadores: de qué nivel son y con qué piel se dibujan.
##
## Una carta es un diccionario con los datos del jugador ya listos para pintar:
##   nombre, puesto, dorsal, equipo, color1, color2,
##   vel, tir, fis, res   (las 4 estadísticas, de 1 a 99)
##   ovr                  (el promedio, de 1 a 99)
##   nivel                ("bronce", "plata" u "oro")
##   especial             (true si es de las brillantes y raras)
##
## El nivel lo decide el OVR, como en FIFA: bronce hasta 64, plata de 65 a 74
## y oro de 75 para arriba. El OVR es el promedio de las 4 estadísticas.

const PIELES := {
	"bronce": "res://datos/cartas/carta_bronce.png",
	"plata": "res://datos/cartas/carta_plata.png",
	"oro": "res://datos/cartas/carta_oro.png",
	"especial": "res://datos/cartas/carta_especial.png",
}
const AVATAR := "res://datos/cartas/avatar.png"

const OVR_PLATA := 65
const OVR_ORO := 75
## Cada cuánto sale una carta especial (brillante) al azar: 6 de cada 100.
const PROBABILIDAD_ESPECIAL := 0.06

## Las 4 estadísticas: la clave en la carta y cómo se muestra.
const ESTADISTICAS := [
	["vel", "VEL"],
	["tir", "TIR"],
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
		"fis": int(jugador.get("f", 50)),
		"res": int(jugador.get("r", 50)),
		"ovr": ovr,
		"nivel": nivel(ovr),
		"especial": especial,
	}


## Saca una carta al azar de toda la base de datos de clubes.
## `prob_especial` es la probabilidad de que salga brillante.
static func aleatoria(azar: RandomNumberGenerator, prob_especial := PROBABILIDAD_ESPECIAL) -> Dictionary:
	var clubes := Clubes.cargar_todos()
	if clubes.is_empty():
		return {}

	var club = clubes[azar.randi_range(0, clubes.size() - 1)]
	var plantilla = club.get("plantilla", [])
	if typeof(plantilla) != TYPE_ARRAY or plantilla.is_empty():
		return {}

	var jugador = plantilla[azar.randi_range(0, plantilla.size() - 1)]
	return crear(jugador, club, azar.randf() < prob_especial)


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
