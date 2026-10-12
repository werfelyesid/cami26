class_name Sobres
extends RefCounted
## Los sobres: cuánto cuestan, qué traen y qué probabilidad tiene cada nivel.
##
## Las reglas (decididas con Camilo):
##   - Ganar un partido da un sobre COMPLETO: 1 jugador + 200 gemas + 1.000 moneditas.
##   - El sobre diario también es completo, pero solo uno por día.
##   - Los sobres COMPRADOS traen SOLO el jugador, sin gemas ni moneditas.
##     OJO: si el sobre comprado trajera las 200 gemas saldría gratis (pagas 200 y
##     te devuelven 200), y con eso se podrían sacar cartas infinitas sin jugar.
##
## Este archivo solo sabe de sobres: no toca el guardado (eso lo hace la pantalla).
## Así se puede probar la suerte de los sobres sin abrir el juego.

## La probabilidad de cada nivel. Suman 1.0 (55 + 34 + 10 + 1 = 100%).
const NIVELES := [
	["bronce", 0.55],
	["plata", 0.34],
	["oro", 0.10],
	["especial", 0.01],
]

const COSTO_GEMAS := 200
const COSTO_MONEDAS := 5000
const MONEDAS_DEL_SOBRE := 1000
const GEMAS_DEL_SOBRE := 200

## Con qué OVR mínimo sale una carta especial: es una carta de oro con la piel
## brillante, así que no tendría sentido que saliera peor que una de plata.
## (El valor está en Cartas.OVR_MINIMO_ESPECIAL.)


## El nivel que le toca al sobre, echando el dado con las probabilidades de arriba.
static func nivel_al_azar(azar: RandomNumberGenerator) -> String:
	var dado := azar.randf()
	var acumulado := 0.0
	for par in NIVELES:
		acumulado += float(par[1])
		if dado < acumulado:
			return str(par[0])
	return "bronce"


## Saca la carta que va dentro de un sobre: se elige el nivel con las
## probabilidades de arriba y después un jugador cualquiera de ese nivel.
static func carta(azar: RandomNumberGenerator) -> Dictionary:
	var nivel := nivel_al_azar(azar)
	var lista := Cartas.pool(nivel)
	if lista.is_empty():
		return Cartas.aleatoria(azar)
	# Copia, para que el inventario no comparta el diccionario con el pool.
	return (lista[azar.randi_range(0, lista.size() - 1)] as Dictionary).duplicate(true)


## El contenido de un sobre: la carta y, si es completo, la plata.
static func premio(azar: RandomNumberGenerator, completo: bool) -> Dictionary:
	var resultado := {"carta": carta(azar), "monedas": 0, "gemas": 0}
	if completo:
		resultado["monedas"] = MONEDAS_DEL_SOBRE
		resultado["gemas"] = GEMAS_DEL_SOBRE
	return resultado


## Las probabilidades escritas, para mostrarlas en pantalla:
## "bronce 55% · plata 34% · oro 10% · especial 1%"
static func texto_probabilidades() -> String:
	var partes := ""
	for par in NIVELES:
		var trozo: String = "%s %d%%" % [str(par[0]), int(round(float(par[1]) * 100.0))]
		partes = trozo if partes == "" else "%s · %s" % [partes, trozo]
	return partes
