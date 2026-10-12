#!/usr/bin/env python3
"""Agrega las estadísticas "pase" y "regate" a datos/clubes.json.

OJO: estas dos estadísticas son INVENTADAS (las otras cuatro también lo son).
No salen de ninguna base de datos de verdad: se calculan con la regla de abajo,
que es estable (el mismo jugador da siempre el mismo número) y tiene sentido
con el puesto:

    pase  = base_pase(puesto)  + ajuste por técnica (tiro) y por velocidad
    regate = base_regate(puesto) + ajuste por velocidad y por tiro

Las bases (antes de ajustes):
    POR (arquero)   pase 58   regate 34     (el arquero no regatea)
    DEF (defensa)   pase 66   regate 60
    MED (medio)     pase 82   regate 76
    DEL (delantero) pase 74   regate 86

Ajustes (sobre la base):
    pase   += (tiro - 70) * 0.18  +  (velocidad - 75) * 0.08
    regate += (velocidad - 75) * 0.22  +  (tiro - 70) * 0.10

Y un "toque" chiquito por jugador (de -3 a +3) que sale de sumar las letras de
su nombre, para que no queden todos iguales.

Uso:
    python3 herramientas/agregar_estadisticas.py
    python3 herramientas/agregar_estadisticas.py --revisar   (solo informa)
"""

import json
import os
import sys

RUTA = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "datos", "clubes.json")

BASES = {
    "POR": (58, 34),
    "DEF": (66, 60),
    "MED": (82, 76),
    "DEL": (74, 86),
}

# A qué grupo va cada puesto del archivo.
GRUPO = {
    "POR": "POR",
    "LD": "DEF", "DFC": "DEF", "LI": "DEF",
    "MCD": "MED", "MC": "MED", "MCO": "MED", "MD": "MED", "MI": "MED",
    "ED": "DEL", "SD": "DEL", "DC": "DEL", "EI": "DEL",
}

# Los cortes de nivel, iguales que en scripts/cartas.gd (OVR_PLATA, OVR_ORO).
CORTE_PLATA = 73
CORTE_ORO = 81


def toque(nombre: str) -> int:
    """Un numerito estable por jugador, de -3 a +3, para que no queden iguales."""
    return (sum(ord(c) for c in nombre) % 7) - 3


def limite(valor: float) -> int:
    return max(1, min(99, int(round(valor))))


def calcular(jugador: dict) -> tuple:
    """Devuelve (pase, regate) para un jugador."""
    puesto = jugador.get("p", "MC")
    grupo = GRUPO.get(puesto, "MED")
    base_pase, base_regate = BASES[grupo]
    velocidad = jugador.get("v", 70)
    tiro = jugador.get("t", 70)
    t = toque(str(jugador.get("n", "")))

    pase = base_pase + (tiro - 70) * 0.18 + (velocidad - 75) * 0.08 + t
    regate = base_regate + (velocidad - 75) * 0.22 + (tiro - 70) * 0.10 + t
    return limite(pase), limite(regate)


def main() -> None:
    solo_revisar = "--revisar" in sys.argv
    with open(RUTA, encoding="utf-8") as f:
        datos = json.load(f)

    grupos = {}
    for club in datos["clubes"]:
        for jugador in club["plantilla"]:
            pase, regate = calcular(jugador)
            jugador["pas"] = pase
            jugador["reg"] = regate
            grupo = GRUPO.get(jugador.get("p", "MC"), "MED")
            grupos.setdefault(grupo, []).append((pase, regate))

    print("jugadores con pase y regate:", sum(len(v) for v in grupos.values()))
    print("%-5s %4s  %-13s %-13s" % ("grupo", "n", "pase (min-med-max)", "regate (min-med-max)"))
    for grupo in ["POR", "DEF", "MED", "DEL"]:
        lista = grupos.get(grupo, [])
        if not lista:
            continue
        pa = sorted(x[0] for x in lista)
        re = sorted(x[1] for x in lista)
        mit = len(lista) // 2
        print("%-5s %4d  %3d - %3d - %3d  %3d - %3d - %3d" % (
            grupo, len(lista), pa[0], pa[mit], pa[-1], re[0], re[mit], re[-1]))

    # ¿Cómo quedan los niveles de carta con el OVR de 6 estadísticas?
    # (Los cortes están abajo, en CORTE_PLATA y CORTE_ORO, y son los mismos que
    #  los de scripts/cartas.gd: si se cambian allí, cambiarlos aquí también.)
    bronce = plata = oro = 0
    for club in datos["clubes"]:
        for jugador in club["plantilla"]:
            ovr = round((jugador["v"] + jugador["t"] + jugador["f"] + jugador["r"]
                         + jugador["pas"] + jugador["reg"]) / 6.0)
            if ovr >= CORTE_ORO:
                oro += 1
            elif ovr >= CORTE_PLATA:
                plata += 1
            else:
                bronce += 1
    total = bronce + plata + oro
    print()
    print("niveles (bronce < %d, plata %d-%d, oro %d+):" % (
        CORTE_PLATA, CORTE_PLATA, CORTE_ORO - 1, CORTE_ORO))
    print("  bronce %3d (%.0f%%)   plata %3d (%.0f%%)   oro %3d (%.0f%%)" % (
        bronce, 100 * bronce / total, plata, 100 * plata / total, oro, 100 * oro / total))

    if solo_revisar:
        print("(solo revisión: no se escribió nada)")
        return

    with open(RUTA, "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print("escrito:", RUTA)


if __name__ == "__main__":
    main()
