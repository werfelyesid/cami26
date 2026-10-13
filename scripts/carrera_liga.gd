extends RefCounted
## EL MODO CARRERA: una liga de todos contra todos, en una sola vuelta.
##
## Con los 20 clubes de LaLiga (más las Leyendas, que también juegan) son
## 21 clubes: cada fecha juegas TÚ y los demás partidos se simulan. Son 21
## fechas (una sola vuelta, 10 partidos por fecha) y al final hay premio según
## el puesto en que quedaste.
##
## OJO: aquí NO se guarda nada (de eso se encarga Datos) y aquí NO se dibuja
## nada (de eso se encarga la pantalla carrera.gd). Aquí solo está la cuenta:
## el calendario, la tabla, la simulación y los premios. Así se puede probar
## una temporada completa sin abrir el juego.
##
## (No tiene class_name a propósito: los scripts nuevos con class_name necesitan
##  regenerar la caché de clases de Godot, y así se evita ese paso. Se usa con
##  preload, como CanchaMini o Tarjeta.)

## Cuántos puntos da ganar y cuántos empatar (como en el fútbol de verdad).
const PUNTOS_GANADO := 3
const PUNTOS_EMPATE := 1

# --- Para simular los partidos que no juegas tú ---
## Los goles que mete un equipo "normal" en un partido.
const GOLES_PROMEDIO := 1.3
## Cuántos puntos de fuerza hay que sacarle al rival para meter un gol más.
const FUERZA_POR_GOL := 9.0
## Cuánta fuerza de más se tiene jugando en casa.
const VENTAJA_LOCAL := 2.5
## Para que no salgan goleadas absurdas.
const MAX_GOLES := 7

## El premio al terminar la temporada, según en qué puesto quedes.
## Cada fila: [hasta qué puesto, monedas, gemas, cartas].
## El primero gana las 3 cartas, el segundo 2 y del 5º al 10º 1.
const PREMIOS := [
	[1, 20000, 500, 3],
	[4, 10000, 250, 2],
	[10, 5000, 100, 1],
	[99, 2000, 0, 0],
]


## El calendario de una vuelta, con el método de la rueda: uno queda fijo y los
## demás van girando. Devuelve una lista de fechas, y cada fecha es una lista de
## partidos [local, visita].
static func calendario(ids: Array) -> Array:
	var lista: Array = []
	for id in ids:
		lista.append(str(id))
	if lista.size() < 2:
		return []
	if lista.size() % 2 == 1:
		lista.append("")                      # con un número raro, uno descansa
	var cuantos: int = lista.size()
	var fechas: Array = []
	for r in cuantos - 1:
		var fecha: Array = []
		for i in cuantos / 2:
			var a := str(lista[i])
			var b := str(lista[cuantos - 1 - i])
			if a == "" or b == "":
				continue
			# Se alterna la localía para que no sea siempre el mismo el local.
			if (r + i) % 2 == 0:
				fecha.append([a, b])
			else:
				fecha.append([b, a])
		fechas.append(fecha)
		var ultimo = lista.pop_back()
		lista.insert(1, ultimo)
	return fechas


## La tabla de posiciones, sumando los resultados.
## `resultados` es una lista de [local, visita, goles_local, goles_visita].
## Devuelve la lista YA ORDENADA: primero el que más puntos tiene, y si empatan
## la diferencia de gol, y si siguen empatados los goles a favor.
## Cada fila: {"id", "pj", "g", "e", "p", "gf", "gc", "dif", "pts"}.
static func tabla(ids: Array, resultados: Array) -> Array:
	var cuentas := {}
	for id in ids:
		var clave := str(id)
		cuentas[clave] = {"id": clave, "pj": 0, "g": 0, "e": 0, "p": 0,
			"gf": 0, "gc": 0, "dif": 0, "pts": 0}
	for partido in resultados:
		_apuntar(cuentas, str(partido[0]), int(partido[2]), int(partido[3]))
		_apuntar(cuentas, str(partido[1]), int(partido[3]), int(partido[2]))
	var lista: Array = cuentas.values()
	lista.sort_custom(_mas_arriba)
	return lista


## Cuál va más arriba en la tabla.
static func _mas_arriba(a: Dictionary, b: Dictionary) -> bool:
	if int(a["pts"]) != int(b["pts"]):
		return int(a["pts"]) > int(b["pts"])
	if int(a["dif"]) != int(b["dif"]):
		return int(a["dif"]) > int(b["dif"])
	if int(a["gf"]) != int(b["gf"]):
		return int(a["gf"]) > int(b["gf"])
	return str(a["id"]) < str(b["id"])


static func _apuntar(cuentas: Dictionary, id: String, a_favor: int, en_contra: int) -> void:
	if not cuentas.has(id):
		return
	var c: Dictionary = cuentas[id]
	c["pj"] = int(c["pj"]) + 1
	c["gf"] = int(c["gf"]) + a_favor
	c["gc"] = int(c["gc"]) + en_contra
	c["dif"] = int(c["gf"]) - int(c["gc"])
	if a_favor > en_contra:
		c["g"] = int(c["g"]) + 1
		c["pts"] = int(c["pts"]) + PUNTOS_GANADO
	elif a_favor == en_contra:
		c["e"] = int(c["e"]) + 1
		c["pts"] = int(c["pts"]) + PUNTOS_EMPATE
	else:
		c["p"] = int(c["p"]) + 1


## La fuerza de cada club (de 0 a 99): el promedio de sus 11 titulares.
## Sirve para simular los partidos que no juegas.
static func fuerzas() -> Dictionary:
	var fuerza := {}
	for club in Clubes.cargar_todos():
		var suma := 0.0
		var cuantos := 0
		for jugador in Clubes.titulares(club):
			suma += float(Clubes.ovr(jugador))
			cuantos += 1
		fuerza[str(club.get("id", ""))] = suma / maxf(1.0, float(cuantos))
	return fuerza


## Simula UN partido y devuelve [goles del local, goles de la visita].
## Sale de la diferencia de fuerza: al mejor le toca meter más goles.
static func simular(azar: RandomNumberGenerator, local: String, visita: String, fuerza: Dictionary) -> Array:
	var del_local := float(fuerza.get(local, 70.0)) + VENTAJA_LOCAL
	var de_la_visita := float(fuerza.get(visita, 70.0))
	var diferencia := (del_local - de_la_visita) / FUERZA_POR_GOL
	var media_local := maxf(0.2, GOLES_PROMEDIO + diferencia * 0.5)
	var media_visita := maxf(0.2, GOLES_PROMEDIO - diferencia * 0.5)
	return [_goles(azar, media_local), _goles(azar, media_visita)]


## Los goles de un equipo en un partido simulado, alrededor de su media.
static func _goles(azar: RandomNumberGenerator, media: float) -> int:
	return clampi(int(roundf(azar.randfn(media, 1.0))), 0, MAX_GOLES)


## El premio que le toca a un puesto (1 = campeón).
## Devuelve {"puesto", "monedas", "gemas", "cartas"}.
static func premio(puesto: int) -> Dictionary:
	for fila in PREMIOS:
		if puesto <= int(fila[0]):
			return {"puesto": puesto, "monedas": int(fila[1]), "gemas": int(fila[2]),
				"cartas": int(fila[3])}
	return {"puesto": puesto, "monedas": 0, "gemas": 0, "cartas": 0}


## Cuántas cartas te dan por quedar en ese puesto (para los mensajes).
static func texto_premio(puesto: int) -> String:
	var p := premio(puesto)
	var texto := "%s moneditas" % Texto.miles(int(p["monedas"]))
	if int(p["gemas"]) > 0:
		texto += "  ·  %s gemas" % Texto.miles(int(p["gemas"]))
	if int(p["cartas"]) > 0:
		texto += "  ·  %d carta%s" % [int(p["cartas"]), "s" if int(p["cartas"]) > 1 else ""]
	return texto
