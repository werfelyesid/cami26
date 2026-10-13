#!/usr/bin/env python3
"""Calcula las estadísticas "pase" y "regate" de los jugadores de campo, y las
6 estadísticas propias de los ARQUEROS, en datos/clubes.json.

OJO: todas las estadísticas son INVENTADAS. No salen de ninguna base de datos de
verdad: se calculan con las reglas de abajo, que son estables (el mismo jugador
da siempre el mismo número) y tienen sentido con el puesto.

=== Jugadores de campo: pase y regate ===

    pase  = base_pase(puesto)  + ajuste por técnica (tiro) y por velocidad
    regate = base_regate(puesto) + ajuste por velocidad y por tiro

Las bases (antes de ajustes):
    DEF (defensa)   pase 66   regate 60
    MED (medio)     pase 82   regate 76
    DEL (delantero) pase 74   regate 86

Ajustes (sobre la base):
    pase   += (tiro - 70) * 0.18  +  (velocidad - 75) * 0.08
    regate += (velocidad - 75) * 0.22  +  (tiro - 70) * 0.10

=== Arqueros: sus 6 estadísticas son otras ===

A un arquero no le sirven el regate ni el tiro, así que en vez de las de campo
usa estas seis: ref reflejos · man manos · ach achique · aer juego aéreo ·
pie juego con los pies · saq saque.

Se calculan de las estadísticas viejas del arquero (v, t, f, r, pas, reg):

    ref = 0.50*f + 0.30*r + 0.20*v      man = 0.55*f + 0.35*r + 0.10*v
    ach = 0.45*f + 0.35*r + 0.20*v      aer = 0.50*f + 0.40*r + 0.10*v
    pie = 0.70*pas + 0.30*f             saq = 0.60*pas + 0.40*f

El arquero que ya las tenga se deja quieto, y al que se le calculen se le borran
las 6 viejas (para que no queden dos juegos de estadísticas en la misma ficha).
El OVR del arquero es el promedio de ref, man, ach y aer (ver PESOS_OVR en
scripts/clubes.gd), y con esta regla ningún arquero cambia de nivel.

=== Para todos: un toque por jugador ===

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

# El tope de una estadística (el mismo de scripts/clubes.gd: MAX_ESTADISTICA).
TOPE = 119

BASES = {
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

# Las 6 estadísticas de cada grupo, según scripts/clubes.gd (ESTADISTICAS).
CLAVES = {
    "POR": ["ref", "man", "ach", "aer", "pie", "saq"],
    "DEF": ["v", "t", "pas", "reg", "f", "r"],
    "MED": ["v", "t", "pas", "reg", "f", "r"],
    "DEL": ["v", "t", "pas", "reg", "f", "r"],
}

# Las 6 viejas que usaban también los arqueros (solo para migrarlos).
CLAVES_VIEJAS = ["v", "t", "f", "r", "pas", "reg"]

# Los cortes de nivel, iguales que en scripts/cartas.gd (OVR_PLATA, OVR_ORO):
# bronce hasta 74, plata de 75 a 82 y oro de 83 para arriba.
CORTE_PLATA = 75
CORTE_ORO = 83


def toque(nombre: str) -> int:
    """Un numerito estable por jugador, de -3 a +3, para que no queden iguales."""
    return (sum(ord(c) for c in nombre) % 7) - 3


def limite(valor: float) -> int:
    return max(1, min(TOPE, int(round(valor))))


def calcular(jugador: dict) -> tuple:
    """Devuelve (pase, regate) para un jugador de campo."""
    puesto = jugador.get("p", "MC")
    grupo = GRUPO.get(puesto, "MED")
    base_pase, base_regate = BASES[grupo]
    velocidad = jugador.get("v", 70)
    tiro = jugador.get("t", 70)
    t = toque(str(jugador.get("n", "")))

    pase = base_pase + (tiro - 70) * 0.18 + (velocidad - 75) * 0.08 + t
    regate = base_regate + (velocidad - 75) * 0.22 + (tiro - 70) * 0.10 + t
    return limite(pase), limite(regate)


def calcular_arquero(jugador: dict) -> dict:
    """Las 6 estadísticas propias de un arquero, de sus 6 viejas."""
    f = jugador.get("f", 70)
    r = jugador.get("r", 70)
    v = jugador.get("v", 70)
    pas = jugador.get("pas", 70)
    return {
        "ref": limite(0.50 * f + 0.30 * r + 0.20 * v),
        "man": limite(0.55 * f + 0.35 * r + 0.10 * v),
        "ach": limite(0.45 * f + 0.35 * r + 0.20 * v),
        "aer": limite(0.50 * f + 0.40 * r + 0.10 * v),
        "pie": limite(0.70 * pas + 0.30 * f),
        "saq": limite(0.60 * pas + 0.40 * f),
    }


def main() -> None:
    solo_revisar = "--revisar" in sys.argv
    with open(RUTA, encoding="utf-8") as f:
        datos = json.load(f)

    campos = {"DEF": [], "MED": [], "DEL": []}
    arqueros = []
    migrados = 0
    problemas = []

    for club in datos["clubes"]:
        for jugador in club["plantilla"]:
            grupo = GRUPO.get(jugador.get("p", "MC"), "MED")
            nombre = "%s / %s" % (club.get("nombre", "?"), jugador.get("n", "?"))
            if grupo == "POR":
                # El arquero que ya tiene SUS estadísticas se deja quieto.
                if not all(k in jugador for k in CLAVES["POR"]):
                    if not all(k in jugador for k in CLAVES_VIEJAS):
                        problemas.append("%s: es arquero y le faltan estadísticas." % nombre)
                        continue
                    # Migración: era de los viejos, se le calculan las suyas.
                    jugador.update(calcular_arquero(jugador))
                    for k in CLAVES_VIEJAS:
                        jugador.pop(k, None)
                    migrados += 1
                arqueros.append([jugador[k] for k in CLAVES["POR"]])
            else:
                pase, regate = calcular(jugador)
                jugador["pas"] = pase
                jugador["reg"] = regate
                campos[grupo].append((pase, regate))

    def rango(valores: list) -> str:
        ordenados = sorted(valores)
        return "%3d - %3d - %3d" % (ordenados[0], ordenados[len(ordenados) // 2], ordenados[-1])

    print("jugadores de campo:", sum(len(v) for v in campos.values()), "| arqueros:", len(arqueros),
          "| arqueros migrados:", migrados)
    print("%-5s %4s  %-13s %-13s" % ("grupo", "n", "pase (min-med-max)", "regate (min-med-max)"))
    for grupo in ["DEF", "MED", "DEL"]:
        lista = campos.get(grupo, [])
        if not lista:
            continue
        print("%-5s %4d  %s  %s" % (grupo, len(lista),
              rango([x[0] for x in lista]), rango([x[1] for x in lista])))
    if arqueros:
        print("\n%-5s %4s  %s" % ("grupo", "n", "  ".join("%-13s" % k for k in CLAVES["POR"])))
        print("%-5s %4d  %s" % ("POR", len(arqueros),
              "  ".join("%-13s" % rango([a[i] for a in arqueros]) for i in range(len(CLAVES["POR"])))))

    if problemas:
        print("\nPROBLEMAS (%d):" % len(problemas))
        for p in problemas:
            print("   -", p)

    # ¿Cómo quedan los niveles de carta? Se calcula el OVR igual que el juego:
    # pesando las estadísticas que importan en cada puesto. Los pesos son una
    # copia de PESOS_OVR de scripts/clubes.gd: si se cambian allí, cambiarlos aquí.
    pesos = {
        "POR": {"ref": 0.25, "man": 0.25, "ach": 0.25, "aer": 0.25},
        "DEF": {"f": 0.30, "r": 0.20, "v": 0.20, "pas": 0.15, "reg": 0.10, "t": 0.05},
        "MED": {"pas": 0.30, "reg": 0.20, "r": 0.20, "v": 0.15, "f": 0.10, "t": 0.05},
        "DEL": {"t": 0.35, "v": 0.25, "reg": 0.25, "f": 0.08, "r": 0.07},
    }
    cuantos = {"bronce": 0, "plata": 0, "oro": 0}
    for club in datos["clubes"]:
        for jugador in club["plantilla"]:
            grupo = GRUPO.get(jugador.get("p", "MC"), "MED")
            ovr = round(sum(jugador.get(k, 50) * w for k, w in pesos[grupo].items()))
            if ovr >= CORTE_ORO:
                cuantos["oro"] += 1
            elif ovr >= CORTE_PLATA:
                cuantos["plata"] += 1
            else:
                cuantos["bronce"] += 1
    total = sum(cuantos.values())
    print()
    print("niveles (bronce < %d, plata %d-%d, oro %d+):" % (
        CORTE_PLATA, CORTE_PLATA, CORTE_ORO - 1, CORTE_ORO))
    print("  bronce %3d (%.0f%%)   plata %3d (%.0f%%)   oro %3d (%.0f%%)" % (
        cuantos["bronce"], 100 * cuantos["bronce"] / total,
        cuantos["plata"], 100 * cuantos["plata"] / total,
        cuantos["oro"], 100 * cuantos["oro"] / total))

    if solo_revisar:
        print("(solo revisión: no se escribió nada)")
        return

    with open(RUTA, "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print("escrito:", RUTA)


if __name__ == "__main__":
    main()
