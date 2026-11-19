class_name Clubes
extends RefCounted
## Lee los clubes y sus plantillas desde datos/clubes.json.
##
## Cómo está escrito el archivo (para poder editarlo a mano):
##   - La plantilla va EN ORDEN: los 11 primeros son los TITULARES y el resto
##     el banquillo. Así no hace falta un campo "titular" en cada jugador.
##   - Cada jugador usa claves cortas, para que el archivo no quede enorme:
##       n = nombre        p = puesto        d = dorsal
##   - Las estadísticas dependen del puesto (ver ESTADISTICAS más abajo):
##       Jugadores de campo:  v velocidad · t tiro · f físico · r resistencia
##                            pas pase · reg regate
##       Arqueros (POR):      ref reflejos · man manos · ach achique
##                            aer juego aéreo · pie juego con los pies · saq saque
##     Son 6 en los dos casos, todas de 1 a 99.
##   - El OVR NO se guarda: se calcula solo, pesando las estadísticas que
##     importan en cada puesto (ver PESOS_OVR más abajo).
##
## Para probar que los datos están bien, hay una comprobación:
##   Clubes.validar()  ->  devuelve la lista de problemas (vacía = todo bien)

const RUTA := "res://datos/clubes.json"
const JUGADORES_TITULARES := 11

## El tope de una estadística. El FIFA usa 99, pero aquí las cartas del equipo
## pueden llegar más arriba (119 es el tope), porque Camilo las quiere así.
const MAX_ESTADISTICA := 130

## Los puestos que se usan y a qué rol del partido corresponde cada uno.
## Los números son los mismos del enum Rol de futbolista.gd:
## 0 = arquero · 1 = defensa · 2 = medio · 3 = delantero
const ROLES := {
	"POR": 0,
	"LD": 1, "DFC": 1, "LI": 1,
	"MCD": 2, "MC": 2, "MCO": 2, "MD": 2, "MI": 2,
	"ED": 3, "SD": 3, "DC": 3, "EI": 3,
}


## Lista de clubes ya leída del archivo, para no leer y analizar el JSON cada
## vez que se pide una carta (eso hacía lentísimo sacar cartas).
static var _cache: Array = []


## Devuelve la lista de clubes del archivo (vacía si algo salió mal).
## OJO: se lee una sola vez y se guarda. Si se edita clubes.json hay que
## reiniciar el juego para que se note el cambio.
static func cargar_todos() -> Array:
	if not _cache.is_empty():
		return _cache

	if not FileAccess.file_exists(RUTA):
		push_error("No existe el archivo de clubes: %s" % RUTA)
		return []
	var archivo := FileAccess.open(RUTA, FileAccess.READ)
	if archivo == null:
		push_error("No se pudo abrir %s" % RUTA)
		return []
	var texto := archivo.get_as_text()
	archivo.close()

	var leido = JSON.parse_string(texto)
	if typeof(leido) != TYPE_DICTIONARY:
		push_error("%s no es un JSON válido." % RUTA)
		return []
	var lista = leido.get("clubes", [])
	if typeof(lista) != TYPE_ARRAY:
		push_error("%s no tiene una lista de clubes." % RUTA)
		return []
	_cache = lista
	return _cache


## Busca un club por su id (por ejemplo "real_madrid"). {} si no está.
static func buscar(id: String) -> Dictionary:
	for club in cargar_todos():
		if str(club.get("id", "")) == id:
			return club
	return {}


## El rol del partido (0-3) que le toca a un puesto.
static func rol_de(puesto: String) -> int:
	return int(ROLES.get(puesto, 2))


## El promedio de una carta (el OVR) se calcula POR PUESTO, como en el FIFA: a
## cada puesto se le pesan las estadísticas que de verdad le importan.
##
## Ojo: si se promediaran las 6 estadísticas parejo, los arqueros saldrían
## siempre bronce (Courtois quedaría en 53) porque no regatean ni tiran.
##
## Las claves son las del archivo (ver ESTADISTICAS). Cada fila suma 1.
##
## El arquero promedia parejo sus 4 estadísticas de arquero (reflejos, manos,
## achique y juego aéreo, 25% cada una). El "juego con los pies" y el "saque"
## no entran en el promedio: son de adorno, para saber si sabe jugar con el pie.
const PESOS_OVR := {
	"POR": {"ref": 0.25, "man": 0.25, "ach": 0.25, "aer": 0.25},
	"DEF": {"f": 0.30, "r": 0.20, "v": 0.20, "pas": 0.15, "reg": 0.10, "t": 0.05},
	"MED": {"pas": 0.30, "reg": 0.20, "r": 0.20, "v": 0.15, "f": 0.10, "t": 0.05},
	"DEL": {"t": 0.35, "v": 0.25, "reg": 0.25, "f": 0.08, "r": 0.07},
}

## A qué grupo pertenece cada puesto (los mismos grupos que usa la herramienta
## herramientas/agregar_estadisticas.py para inventar el pase y el regate).
const GRUPO_PUESTO := {
	"POR": "POR",
	"LD": "DEF", "DFC": "DEF", "LI": "DEF",
	"MCD": "MED", "MC": "MED", "MCO": "MED", "MD": "MED", "MI": "MED",
	"ED": "DEL", "SD": "DEL", "DC": "DEL", "EI": "DEL",
}


## El grupo de un puesto: POR, DEF, MED o DEL.
static func grupo_de(puesto: String) -> String:
	return str(GRUPO_PUESTO.get(puesto, "MED"))


## Las 6 estadísticas que guarda cada jugador, según su grupo.
## OJO: los arqueros son los únicos que usan estadísticas distintas. A un
## arquero no le sirve el regate ni el tiro, así que tiene las suyas.
##
## El ORDEN de esta lista es el orden en que se muestran en la carta, así que
## no se debe cambiar a la loca (los jugadores de campo van VEL, TIR, PAS, REG,
## FIS, RES, como siempre).
const ESTADISTICAS := {
	"POR": ["ref", "man", "ach", "aer", "pie", "saq"],
	"DEF": ["v", "t", "pas", "reg", "f", "r"],
	"MED": ["v", "t", "pas", "reg", "f", "r"],
	"DEL": ["v", "t", "pas", "reg", "f", "r"],
}


## Las 6 estadísticas que le tocan a un puesto.
static func estadisticas(puesto: String) -> Array:
	return ESTADISTICAS[grupo_de(puesto)]


## El OVR (el promedio de la carta), de 1 a 99, pesando las estadísticas que
## importan en el puesto del jugador.
static func ovr(jugador: Dictionary) -> int:
	var pesos: Dictionary = PESOS_OVR[grupo_de(str(jugador.get("p", "MC")))]
	var total := 0.0
	for clave in pesos:
		total += float(jugador.get(clave, 50)) * float(pesos[clave])
	return int(roundf(total))


## Los titulares de un club (los 11 primeros de la plantilla).
static func titulares(club: Dictionary) -> Array:
	var plantilla = club.get("plantilla", [])
	if typeof(plantilla) != TYPE_ARRAY:
		return []
	return plantilla.slice(0, mini(JUGADORES_TITULARES, plantilla.size()))


## El banquillo de un club (los que van después de los 11).
static func banquillo(club: Dictionary) -> Array:
	var plantilla = club.get("plantilla", [])
	if typeof(plantilla) != TYPE_ARRAY:
		return []
	if plantilla.size() <= JUGADORES_TITULARES:
		return []
	return plantilla.slice(JUGADORES_TITULARES)


## Revisa el archivo entero y devuelve la lista de problemas encontrados.
## Sirve para darse cuenta de un error de dedo sin abrir el juego.
static func validar() -> Array:
	var problemas: Array = []
	var clubes := cargar_todos()
	if clubes.is_empty():
		problemas.append("No se cargó ningún club.")
		return problemas

	for club in clubes:
		var nombre := str(club.get("nombre", "?"))
		if str(club.get("id", "")) == "":
			problemas.append("%s: le falta el id." % nombre)

		var plantilla = club.get("plantilla", [])
		if typeof(plantilla) != TYPE_ARRAY:
			problemas.append("%s: la plantilla no es una lista." % nombre)
			continue
		if plantilla.size() < JUGADORES_TITULARES:
			problemas.append("%s: solo tiene %d jugadores (mínimo %d)." % [nombre, plantilla.size(), JUGADORES_TITULARES])
			continue

		var porteros := 0
		var dorsales := {}
		var nombres := {}
		for jugador in plantilla:
			var de := str(jugador.get("n", "?"))
			var puesto := str(jugador.get("p", ""))
			var dorsal := int(jugador.get("d", 0))

			if not ROLES.has(puesto):
				problemas.append("%s / %s: el puesto «%s» no existe." % [nombre, de, puesto])
			if puesto == "POR":
				porteros += 1
			if dorsales.has(dorsal):
				problemas.append("%s: el dorsal %d está repetido (%s y %s)." % [nombre, dorsal, dorsales[dorsal], de])
			dorsales[dorsal] = de
			if nombres.has(de):
				problemas.append("%s: «%s» está dos veces." % [nombre, de])
			nombres[de] = true

			for clave in estadisticas(puesto):
				var valor := int(jugador.get(clave, -1))
				if valor < 1 or valor > MAX_ESTADISTICA:
					problemas.append("%s / %s: %s está fuera de 1-%d (%d)." % [nombre, de, clave, MAX_ESTADISTICA, valor])

		if porteros == 0:
			problemas.append("%s: no tiene ningún arquero." % nombre)

	return problemas
