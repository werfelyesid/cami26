extends Node
## Ajustes globales del juego (se cargan solos, ver [autoload] en project.godot).
##
## Aquí se guarda la dificultad que elige el jugador en el menú.
## El menú la cambia y el partido la lee.

## 0 = fácil, 1 = normal, 2 = difícil.
var dificultad := 1

const NOMBRES := ["FÁCIL", "NORMAL", "DIFÍCIL"]
const VELOCIDAD_RIVAL := [5.2, 6.4, 7.6]
const VELOCIDAD_ARQUERO := [4.6, 5.4, 6.4]

# --- Números de las camisetas ---
# Van en el mismo orden que la formación de partido.gd. Las leyendas van en los
# tres puestos de ataque: Neymar 11, Messi 10 y Cristiano 7.
const NUMEROS_POR_DEFECTO := [1, 2, 3, 4, 5, 6, 8, 15, 16, 12, 14, 17, 11, 10, 7, 13]
## Si cambian los números de por defecto, se sube esta versión y se reinician
## los que ya estaban guardados (si no, quedarían los viejos para siempre).
const VERSION_NUMEROS := 2
const RUTA_NUMEROS := "user://numeros.cfg"

## Los 16 números de tu equipo y los 16 del rival.
var numeros_mios: Array = []
var numeros_rival: Array = []


func _ready() -> void:
	cargar_numeros()


## Lee los números guardados (si no hay nada, usa los de por defecto).
func cargar_numeros() -> void:
	numeros_mios = NUMEROS_POR_DEFECTO.duplicate()
	numeros_rival = NUMEROS_POR_DEFECTO.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_NUMEROS) != OK:
		return
	# ¿Los números guardados son de una versión vieja? Entonces se usan los
	# nuevos (si no, las leyendas quedarían con números de antes).
	if int(cfg.get_value("numeros", "version", 1)) < VERSION_NUMEROS:
		return
	var mios = cfg.get_value("numeros", "mios", numeros_mios)
	var rival = cfg.get_value("numeros", "rival", numeros_rival)
	if mios is Array and mios.size() == NUMEROS_POR_DEFECTO.size():
		numeros_mios = mios
	if rival is Array and rival.size() == NUMEROS_POR_DEFECTO.size():
		numeros_rival = rival


## Guarda los números para que sigan ahí la próxima vez.
func guardar_numeros() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("numeros", "version", VERSION_NUMEROS)
	cfg.set_value("numeros", "mios", numeros_mios)
	cfg.set_value("numeros", "rival", numeros_rival)
	cfg.save(RUTA_NUMEROS)


## Devuelve la dificultad actual como texto: "FÁCIL", "NORMAL" o "DIFÍCIL".
func nombre_dificultad() -> String:
	return NOMBRES[dificultad]


## Qué tan rápido corre el rival, según la dificultad elegida.
func velocidad_rival() -> float:
	return VELOCIDAD_RIVAL[dificultad]


## Qué tan rápido se mueven los arqueros, según la dificultad elegida.
func velocidad_arquero() -> float:
	return VELOCIDAD_ARQUERO[dificultad]


## Pasa a la siguiente dificultad, dando la vuelta (fácil -> normal -> difícil -> fácil).
func siguiente_dificultad() -> void:
	dificultad = (dificultad + 1) % NOMBRES.size()
