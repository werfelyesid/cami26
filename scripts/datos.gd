extends Node
## Progreso del jugador: monedas, gemas, cartas, plantilla y carrera.
##
## Se carga solo (autoload "Datos" en project.godot, ver [autoload]) y se
## guarda en user://partida.json, así el progreso no se pierde al cerrar.
##
## El archivo guarda una "version". Si algún día cambia el formato, se sube
## VERSION y se convierte lo viejo en _aplicar(), en vez de perder la partida.

const RUTA := "user://partida.json"
## Copia de seguridad. Se guarda cada vez que se avanza, con el progreso
## ANTERIOR, y solo si ese progreso tenía algo (cartas o plata): así un borrado
## accidental NO pisa la copia buena.
##
## ¿Por qué existe? Porque una prueba automática llamó a borrar_todo() sobre la
## partida de verdad y se perdieron las cartas del jugador. Ahora, si el
## guardado aparece vacío y hay copia con progreso, se recupera solo.
const RUTA_RESPALDO := "user://partida_respaldo.json"
## Se pone en true en las pruebas automáticas: así el progreso de verdad no se
## toca NUNCA (se usa otro archivo).
var modo_prueba := false
const VERSION := 1

## La liga del modo carrera (calendario, tabla y simulación). Se usa con
## preload (y no con class_name) para no tener que regenerar la caché de clases.
const CarreraLiga = preload("res://scripts/carrera_liga.gd")

## Las moneditas: sirven para el mercado, mejorar cartas y los contratos.
var monedas := 0
## Las gemas: sirven para comprar sobres y acelerar cosas.
var gemas := 0
## Las cartas que ganó el jugador. Cada carta es un diccionario:
##   {"nombre": "Vinícius Jr.", "pos": "EI", "equipo": "Real Madrid",
##    "vel": 95, "tir": 84, "fis": 68, "res": 78}
var inventario: Array = []
## La plantilla de Ultimate Team: {"titulares": [...], "banquillo": [...]}.
## Las listas guardan posiciones del inventario (números).
var plantilla: Dictionary = {"titulares": [], "banquillo": []}
## El modo carrera: la liga. Se guarda en el archivo, y es así:
##   {"club": "barcelona",            a quién manejas
##    "temporada": 1,
##    "fecha": 3,                     la fecha que toca jugar (1..21)
##    "calendario": [[[local, visita], ...], ...]   las 21 fechas
##    "resultados": [[local, visita, goles_local, goles_visita], ...],
##    "premio_cobrado": false}        si ya te llevaste el premio del año
var carrera: Dictionary = {}
## Fecha (YYYY-MM-DD) del último sobre diario que se reclamó.
var ultimo_sobre_diario := ""
## El premio del último sobre abierto, para que lo muestre la pantalla que viene
## después. OJO: esto NO se guarda en el archivo, es solo un recado entre escenas.
var ultimo_premio: Dictionary = {}
## El partido de liga que se está jugando AHORA, para que la escena del partido
## sepa contra quién juega. Es también un recado entre escenas, no se guarda.
##   {"rival": "sevilla", "soy_local": true, "fecha": 3}
var partido_de_liga: Dictionary = {}
## El resultado del último partido de liga, para que la pantalla de la carrera
## lo cuente al volver. Recado entre escenas, no se guarda.
##   {"fecha", "rival", "mios", "rivales", "gano", "empato"}
var ultimo_resultado_liga: Dictionary = {}
## Adónde vuelve la pantalla de sobres: "" = al menú, "carrera" = a la carrera.
var volver_a := ""


func _ready() -> void:
	cargar()
	_actualizar_cartas()


## Vuelve a armar las cartas viejas desde el archivo de clubes.
##
## ¿Por qué? Al principio las cartas tenían solo 4 estadísticas (velocidad, tiro,
## físico y resistencia) y el promedio se calculaba distinto. Las cartas que ya
## estaban guardadas no tienen pase ni regate, así que mostrarían PAS 0 y REG 0.
## Aquí se buscan en datos/clubes.json y se rehacen al día, sin perder nada más
## (los sobres, las monedas y el resto del progreso quedan igual).
##
## Esto también arregla las cartas de ARQUERO viejas: antes usaban las mismas
## estadísticas que los jugadores de campo y ahora tienen las suyas.
func _actualizar_cartas() -> void:
	var cambiadas := false
	for i in inventario.size():
		var carta: Dictionary = inventario[i]
		if typeof(carta) != TYPE_DICTIONARY:
			continue
		var faltan := _faltan_estadisticas(carta)
		if faltan.is_empty():
			continue
		var al_dia := _carta_al_dia(carta)
		if not al_dia.is_empty():
			inventario[i] = al_dia
		else:
			# Si el jugador ya no está en el archivo, al menos que no muestre ceros.
			for clave in faltan:
				carta[clave] = 50
		cambiadas = true
	if cambiadas:
		guardar()


## Las estadísticas que le faltan a una carta para estar al día.
## OJO: se preguntan con las claves de la CARTA (vel, tir...), no con las del
## archivo de clubes (v, t...), porque si no todas las cartas parecerían
## incompletas y se rearmarían a cada rato.
func _faltan_estadisticas(carta: Dictionary) -> Array:
	var faltan: Array = []
	for par in Cartas.estadisticas(str(carta.get("puesto", ""))):
		if not carta.has(par[0]):
			faltan.append(par[0])
	return faltan


## Busca al jugador de una carta en el archivo de clubes y la rehace al día.
func _carta_al_dia(carta: Dictionary) -> Dictionary:
	var nombre := str(carta.get("nombre", ""))
	var equipo := str(carta.get("equipo", ""))
	for club in Clubes.cargar_todos():
		if str(club.get("nombre", "")) != equipo:
			continue
		for jugador in club.get("plantilla", []):
			if str(jugador.get("n", "")) == nombre:
				return Cartas.crear(jugador, club, bool(carta.get("especial", false)))
	return {}


## Lee el guardado (si existe) y deja el progreso en memoria.
## El archivo que se usa AHORA (en las pruebas, uno aparte).
func ruta_guardado() -> String:
	return "user://prueba.json" if modo_prueba else RUTA


## El archivo de la copia de seguridad que toca ahora.
func ruta_respaldo() -> String:
	return "user://prueba_respaldo.json" if modo_prueba else RUTA_RESPALDO


func cargar() -> void:
	var ruta := ruta_guardado()
	if FileAccess.file_exists(ruta):
		var archivo := FileAccess.open(ruta, FileAccess.READ)
		if archivo == null:
			push_warning("No se pudo leer el guardado: %s" % ruta)
		else:
			var texto := archivo.get_as_text()
			archivo.close()
			var leido = JSON.parse_string(texto)
			if typeof(leido) == TYPE_DICTIONARY:
				_aplicar(leido)
			else:
				push_warning("El guardado está dañado; se prueba con la copia de seguridad.")
	_recuperar_si_hace_falta()
	# Las leyendas tienen que estar siempre en la plantilla, aunque el guardado
	# sea viejo (si no, no aparecen en MI PLANTILLA ni en el partido).
	agregar_leyendas()


## Mete a las tres leyendas (Neymar, Cristiano y Messi) en el inventario y en
## los titulares. Se puede llamar muchas veces: si ya están, no las repite.
func agregar_leyendas() -> void:
	var leyendas := [
		{
			"nombre": "NEYMAR", "puesto": "EI", "dorsal": 11,
			"equipo": "Leyendas", "equipo_id": "leyendas",
			"color1": "#1f7a3a", "color2": "#f2d21b",
			"ovr": 130, "nivel": "oro", "especial": true, "leyenda": true,
			"vel": 130, "tir": 130, "pas": 130, "reg": 130, "fis": 130, "res": 130,
		},
		{
			"nombre": "CRISTIANO", "puesto": "DC", "dorsal": 7,
			"equipo": "Leyendas", "equipo_id": "leyendas",
			"color1": "#1b2a6b", "color2": "#f2c200",
			"ovr": 130, "nivel": "oro", "especial": true, "leyenda": true,
			"vel": 130, "tir": 130, "pas": 130, "reg": 130, "fis": 130, "res": 130,
		},
		{
			"nombre": "MESSI", "puesto": "ED", "dorsal": 10,
			"equipo": "Leyendas", "equipo_id": "leyendas",
			"color1": "#7a1f2b", "color2": "#f2c200",
			"ovr": 130, "nivel": "oro", "especial": true, "leyenda": true,
			"vel": 130, "tir": 130, "pas": 130, "reg": 130, "fis": 130, "res": 130,
		},
	]

	var cambio := false

	# 1) Que estén en el inventario (sin repetirlas).
	for carta in leyendas:
		var existe := false
		for c in inventario:
			if str(c.get("nombre", "")) == str(carta["nombre"]) and bool(c.get("leyenda", false)):
				existe = true
				break
		if not existe:
			inventario.append(carta)
			cambio = true

	# 2) Que estén entre los titulares (si la plantilla está llena, se saca a
	#    alguien que no sea leyenda).
	var titulares: Array = plantilla.get("titulares", [])
	if not (titulares is Array):
		titulares = []
	for i in inventario.size():
		if not bool(inventario[i].get("leyenda", false)):
			continue
		if titulares.has(i):
			continue
		if titulares.size() >= 11:
			for j in range(titulares.size() - 1, -1, -1):
				var indice: int = int(titulares[j])
				if indice < 0 or indice >= inventario.size():
					titulares.remove_at(j)
					break
				if not bool(inventario[indice].get("leyenda", false)):
					titulares.remove_at(j)
					break
		titulares.append(i)
		cambio = true
	plantilla["titulares"] = titulares

	if cambio:
		guardar()


## Si la partida quedó vacía pero hay una copia con progreso, la recupera sola.
## Así un borrado accidental no se lleva las cartas de nadie.
func _recuperar_si_hace_falta() -> void:
	if not inventario.is_empty() or monedas > 0 or gemas > 0:
		return
	var ruta := ruta_respaldo()
	if not FileAccess.file_exists(ruta):
		return
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return
	var leido = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if typeof(leido) != TYPE_DICTIONARY:
		return
	var cartas = leido.get("inventario", [])
	var tiene_algo: bool = (typeof(cartas) == TYPE_ARRAY and not cartas.is_empty()) \
		or int(leido.get("monedas", 0)) > 0 or int(leido.get("gemas", 0)) > 0
	if not tiene_algo:
		return
	push_warning("La partida estaba vacía: se recuperó la copia de seguridad.")
	_aplicar(leido)
	guardar()


## Hace la copia de seguridad del archivo actual (el de ANTES de guardar).
## Solo si el progreso de ahora vale la pena: un progreso vacío no pisa la copia.
func _respaldar() -> void:
	if inventario.is_empty() and monedas <= 0 and gemas <= 0:
		return
	var ruta := ruta_guardado()
	if not FileAccess.file_exists(ruta):
		return
	DirAccess.copy_absolute(ruta, ruta_respaldo())


## Escribe el progreso en el disco. Devuelve true si se pudo guardar.
func guardar() -> bool:
	_respaldar()
	var archivo := FileAccess.open(ruta_guardado(), FileAccess.WRITE)
	if archivo == null:
		push_warning("No se pudo guardar: %s" % ruta_guardado())
		return false
	var datos := {
		"version": VERSION,
		"monedas": monedas,
		"gemas": gemas,
		"inventario": inventario,
		"plantilla": plantilla,
		"carrera": carrera,
		"ultimo_sobre_diario": ultimo_sobre_diario,
	}
	archivo.store_string(JSON.stringify(datos, "  "))
	archivo.close()
	return true


## Copia al juego lo que viene del archivo, con valores por defecto si falta algo.
func _aplicar(leido: Dictionary) -> void:
	var version_leida := int(leido.get("version", 0))
	if version_leida > VERSION:
		push_warning("El guardado es de una versión más nueva (%d); no se carga." % version_leida)
		return

	monedas = int(leido.get("monedas", 0))
	gemas = int(leido.get("gemas", 0))

	# OJO: lo que viene del JSON llega sin tipo (Variant), así que aquí no se
	# puede usar := y hay que decir el tipo a mano (nos pasó varias veces).
	var inv = leido.get("inventario", [])
	inventario = inv if typeof(inv) == TYPE_ARRAY else []

	var plan = leido.get("plantilla", {})
	if typeof(plan) == TYPE_DICTIONARY:
		plantilla = plan
	else:
		plantilla = {"titulares": [], "banquillo": []}

	var car = leido.get("carrera", {})
	carrera = car if typeof(car) == TYPE_DICTIONARY else {}

	ultimo_sobre_diario = str(leido.get("ultimo_sobre_diario", ""))
	# Hasta aquí llegó la versión 1. Cuando haya más, se migra en este punto.


# ------------------------------------------------------------- monedero ---

## Suma (o resta) moneditas. Nunca queda en negativo.
func agregar_monedas(cantidad: int) -> void:
	monedas = maxi(0, monedas + cantidad)
	guardar()


## Suma (o resta) gemas. Nunca queda en negativo.
func agregar_gemas(cantidad: int) -> void:
	gemas = maxi(0, gemas + cantidad)
	guardar()


## Guarda una carta en el inventario y devuelve su posición en la lista.
func agregar_carta(carta: Dictionary) -> int:
	inventario.append(carta)
	guardar()
	return inventario.size() - 1


## Entrega de una sola vez todo lo que trae un sobre: la carta y la plata.
## Se guarda una sola vez, en vez de tres (más rápido y más seguro).
func entregar_premio(carta: Dictionary, monedas_premio: int, gemas_premio: int) -> void:
	if not carta.is_empty():
		inventario.append(carta)
	monedas = maxi(0, monedas + monedas_premio)
	gemas = maxi(0, gemas + gemas_premio)
	guardar()


## Borra todo el progreso.
##
## OJO: solo borra si se pide A PROPÓSITO (`forzar = true`) o si estamos en modo
## prueba. Antes borraba siempre, y una prueba automática se llevó por delante la
## partida de verdad del jugador (se perdieron sus cartas). Nunca más.
func borrar_todo(forzar := false) -> void:
	if not forzar and not modo_prueba:
		push_error("borrar_todo() se negó: hay que pedirlo a propósito con forzar = true")
		return
	monedas = 0
	gemas = 0
	inventario = []
	plantilla = {"titulares": [], "banquillo": []}
	carrera = {}
	ultimo_sobre_diario = ""
	guardar()
	# Un borrado a propósito se lleva también la copia de seguridad: si no, al
	# volver a cargar reaparecería lo que se quería borrar.
	var respaldo := ruta_respaldo()
	if FileAccess.file_exists(respaldo):
		DirAccess.remove_absolute(respaldo)


# --------------------------------------------------------- sobre diario ---

## La fecha de hoy (YYYY-MM-DD), para saber si el sobre diario ya se reclamó.
func hoy() -> String:
	return Time.get_date_string_from_system()


## ¿Todavía no se ha reclamado el sobre diario de hoy?
func sobre_diario_disponible() -> bool:
	return ultimo_sobre_diario != hoy()


## Marca el sobre diario de hoy como reclamado.
func reclamar_sobre_diario() -> void:
	ultimo_sobre_diario = hoy()
	guardar()


# --------------------------------------------------------------- carrera ---

## Los clubes que juegan la liga (todos, en el orden del archivo).
## Los clubes que juegan la liga del modo carrera.
##
## OJO: NO son todos los clubes del archivo. En el archivo hay también clubes de
## otras ligas (Premier, Serie A, Bundesliga, Ligue 1) para que los sobres tengan
## mucha más variedad de jugadores. Si la carrera los metiera a todos, la liga
## tendría 36 clubes y 35 fechas en vez de 21.
func carrera_ids() -> Array:
	var ids: Array = []
	for club in Clubes.cargar_todos():
		var liga := str(club.get("liga", ""))
		if liga == "LaLiga" or liga == "Especial":
			ids.append(str(club.get("id", "")))
	return ids


## Empieza una liga nueva con el club que elijas.
func carrera_empezar(club_id: String, temporada := 1) -> void:
	carrera = {
		"club": club_id,
		"temporada": temporada,
		"fecha": 1,
		"calendario": CarreraLiga.calendario(carrera_ids()),
		"resultados": [],
		"premio_cobrado": false,
	}
	partido_de_liga = {}
	ultimo_resultado_liga = {}
	guardar()


## ¿Hay una liga empezada?
func carrera_activa() -> bool:
	return carrera.has("club") and not carrera_calendario().is_empty()


func carrera_calendario() -> Array:
	var cal = carrera.get("calendario", [])
	return cal if typeof(cal) == TYPE_ARRAY else []


## El club que manejas (la ficha del archivo de clubes).
func carrera_club() -> Dictionary:
	return Clubes.buscar(str(carrera.get("club", "")))


## La fecha que toca jugar (1, 2, ...). Si ya se jugó todo, es más grande que
## el calendario: así se sabe que la temporada terminó.
func carrera_fecha() -> int:
	return int(carrera.get("fecha", 1))


## Cuántas fechas tiene la temporada.
func carrera_fechas() -> int:
	return carrera_calendario().size()


## ¿Ya se jugó la temporada entera?
func carrera_terminada() -> bool:
	return carrera_activa() and carrera_fecha() > carrera_fechas()


## El partido que te toca en la fecha actual: [local, visita]. [] si ya terminó.
func carrera_mi_partido() -> Array:
	var cal := carrera_calendario()
	var f := carrera_fecha()
	if f < 1 or f > cal.size():
		return []
	var mio := str(carrera.get("club", ""))
	for par in cal[f - 1]:
		if str(par[0]) == mio or str(par[1]) == mio:
			return [str(par[0]), str(par[1])]
	return []


## ¿Juegas en casa la fecha que toca?
func carrera_soy_local() -> bool:
	var mio := carrera_mi_partido()
	return not mio.is_empty() and str(mio[0]) == str(carrera.get("club", ""))


## Guarda mi resultado, simula los otros partidos de la fecha y pasa a la
## siguiente. OJO: los goles van SIEMPRE conmigo primero, sin importar de quién
## era la casa.
func carrera_jugar_fecha(goles_mios: int, goles_rival: int) -> void:
	var mio := carrera_mi_partido()
	if mio.is_empty():
		return
	var resultados: Array = carrera.get("resultados", [])
	if carrera_soy_local():
		resultados.append([str(mio[0]), str(mio[1]), goles_mios, goles_rival])
	else:
		resultados.append([str(mio[0]), str(mio[1]), goles_rival, goles_mios])
	_simular_el_resto(mio, resultados)
	carrera["resultados"] = resultados
	carrera["fecha"] = carrera_fecha() + 1
	guardar()


## ¿Esta fecha te toca DESCANSAR? Con un número raro de clubes (21) siempre hay
## uno que no juega, y puede ser el tuyo.
func carrera_descansa() -> bool:
	return carrera_activa() and not carrera_terminada() and carrera_mi_partido().is_empty()


## Simula los partidos de la fecha en la que NO juegas tú.
func _simular_el_resto(mi_partido: Array, resultados: Array) -> void:
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	var fuerza := CarreraLiga.fuerzas()
	for par in carrera_calendario()[carrera_fecha() - 1]:
		if mi_partido.size() == 2 and str(par[0]) == str(mi_partido[0]) \
				and str(par[1]) == str(mi_partido[1]):
			continue
		var goles := CarreraLiga.simular(azar, str(par[0]), str(par[1]), fuerza)
		resultados.append([str(par[0]), str(par[1]), int(goles[0]), int(goles[1])])


## Pasa la fecha en la que descansas: simula los diez partidos de los demás.
func carrera_simular_descanso() -> void:
	if not carrera_descansa():
		return
	var resultados: Array = carrera.get("resultados", [])
	_simular_el_resto([], resultados)
	carrera["resultados"] = resultados
	carrera["fecha"] = carrera_fecha() + 1
	guardar()


## Simula la fecha completa, TU partido incluido (es el botón SIMULAR).
## Devuelve [goles del local, goles de la visita], o [] si esta fecha descansas.
func carrera_simular_fecha() -> Array:
	if carrera_descansa():
		carrera_simular_descanso()
		return []
	var mio := carrera_mi_partido()
	if mio.is_empty():
		return []
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	var goles := CarreraLiga.simular(azar, str(mio[0]), str(mio[1]), CarreraLiga.fuerzas())
	var del_local := int(goles[0])
	var de_la_visita := int(goles[1])
	if carrera_soy_local():
		carrera_jugar_fecha(del_local, de_la_visita)
	else:
		carrera_jugar_fecha(de_la_visita, del_local)
	ultimo_resultado_liga = {
		"fecha": carrera_fecha() - 1,
		"rival": str(mio[1]) if carrera_soy_local() else str(mio[0]),
		"mios": del_local if carrera_soy_local() else de_la_visita,
		"rivales": de_la_visita if carrera_soy_local() else del_local,
		"gano": (del_local > de_la_visita) if carrera_soy_local() else (de_la_visita > del_local),
		"empato": del_local == de_la_visita,
	}
	return [del_local, de_la_visita]


## Cierra el partido de liga que se acaba de jugar (lo llama la escena del
## partido) y deja el resultado en `ultimo_resultado_liga`.
func carrera_cerrar_mi_partido(goles_mios: int, goles_rival: int) -> void:
	var mio := carrera_mi_partido()
	if mio.is_empty():
		return
	var era_local := carrera_soy_local()
	carrera_jugar_fecha(goles_mios, goles_rival)
	ultimo_resultado_liga = {
		"fecha": carrera_fecha() - 1,
		"rival": str(mio[1]) if era_local else str(mio[0]),
		"mios": goles_mios,
		"rivales": goles_rival,
		"gano": goles_mios > goles_rival,
		"empato": goles_mios == goles_rival,
	}
	partido_de_liga = {}


## La tabla de posiciones ordenada, con el puesto ya puesto en cada fila.
func carrera_tabla() -> Array:
	var lista := CarreraLiga.tabla(carrera_ids(), carrera.get("resultados", []))
	for i in lista.size():
		lista[i]["puesto"] = i + 1
	return lista


## Tu puesto en la tabla (1 = primero, 0 = todavía no hay liga).
func carrera_puesto() -> int:
	var mio := str(carrera.get("club", ""))
	for fila in carrera_tabla():
		if str(fila["id"]) == mio:
			return int(fila["puesto"])
	return 0


## El premio de la temporada, si ya terminó y todavía no lo cobraste.
func carrera_premio() -> Dictionary:
	if not carrera_terminada() or bool(carrera.get("premio_cobrado", false)):
		return {}
	return CarreraLiga.premio(carrera_puesto())


## Te entrega el premio de la temporada (una sola vez) y lo devuelve para que la
## pantalla lo muestre. Trae las cartas ganadas en "cartas".
func carrera_cobrar_premio() -> Dictionary:
	var premio := carrera_premio()
	if premio.is_empty():
		return {}
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	var cartas: Array = []
	for i in int(premio["cartas"]):
		var carta := Cartas.aleatoria(azar)
		if not carta.is_empty():
			cartas.append(carta)
	monedas = maxi(0, monedas + int(premio["monedas"]))
	gemas = maxi(0, gemas + int(premio["gemas"]))
	for carta in cartas:
		inventario.append(carta)
	carrera["premio_cobrado"] = true
	guardar()
	premio["cartas_ganadas"] = cartas
	return premio


## Empieza otra temporada con el mismo club (calendario nuevo y resultados en
## blanco). La temporada anterior ya no se puede consultar.
func carrera_nueva_temporada() -> void:
	if not carrera_activa():
		return
	carrera_empezar(str(carrera.get("club", "")), int(carrera.get("temporada", 1)) + 1)


## Borra la carrera, para elegir otro club.
func carrera_borrar() -> void:
	carrera = {}
	partido_de_liga = {}
	ultimo_resultado_liga = {}
	guardar()
