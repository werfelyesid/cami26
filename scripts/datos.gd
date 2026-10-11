extends Node
## Progreso del jugador: monedas, gemas, cartas, plantilla y carrera.
##
## Se carga solo (autoload "Datos" en project.godot, ver [autoload]) y se
## guarda en user://partida.json, así el progreso no se pierde al cerrar.
##
## El archivo guarda una "version". Si algún día cambia el formato, se sube
## VERSION y se convierte lo viejo en _aplicar(), en vez de perder la partida.

const RUTA := "user://partida.json"
const VERSION := 1

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
## El modo carrera: club elegido, temporada, tabla y resultados.
var carrera: Dictionary = {}
## Fecha (YYYY-MM-DD) del último sobre diario que se reclamó.
var ultimo_sobre_diario := ""


func _ready() -> void:
	cargar()


## Lee el guardado (si existe) y deja el progreso en memoria.
func cargar() -> void:
	if not FileAccess.file_exists(RUTA):
		return
	var archivo := FileAccess.open(RUTA, FileAccess.READ)
	if archivo == null:
		push_warning("No se pudo leer el guardado: %s" % RUTA)
		return
	var texto := archivo.get_as_text()
	archivo.close()
	var leido = JSON.parse_string(texto)
	if typeof(leido) != TYPE_DICTIONARY:
		push_warning("El guardado está dañado; se empieza de cero.")
		return
	_aplicar(leido)


## Escribe el progreso en el disco. Devuelve true si se pudo guardar.
func guardar() -> bool:
	var archivo := FileAccess.open(RUTA, FileAccess.WRITE)
	if archivo == null:
		push_warning("No se pudo guardar: %s" % RUTA)
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


## Borra todo el progreso (útil mientras se prueba).
func borrar_todo() -> void:
	monedas = 0
	gemas = 0
	inventario = []
	plantilla = {"titulares": [], "banquillo": []}
	carrera = {}
	ultimo_sobre_diario = ""
	guardar()


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
