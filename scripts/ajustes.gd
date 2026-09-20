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
