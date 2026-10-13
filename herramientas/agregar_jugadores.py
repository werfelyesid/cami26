#!/usr/bin/env python3
"""Agrega MUCHOS más jugadores a datos/clubes.json.

Se agregan dos cosas:
  1. Más jugadores a los clubes de LaLiga que ya estaban (los suplentes de verdad).
  2. Clubes grandes de otras ligas (Premier, Serie A, Bundesliga y Ligue 1), con
     su plantilla, para que los sobres den mucha más variedad.

De cada jugador solo hay que escribir: nombre, puesto, dorsal y su NIVEL (1 a 5),
que es qué tan bueno es:

    5 = estrella mundial (Mbappé, Haaland)     2 = suplente
    4 = internacional (titular de un grande)   1 = jovencito / tercer arquero
    3 = buen titular

Las 4 estadísticas de campo se calculan del nivel y del puesto con una regla
fija (velocidad, tiro, físico y resistencia), más un toque por jugador para que
no queden todos iguales. El pase y el regate los calcula después la otra
herramienta (agregar_estadisticas.py), y ahí mismo salen las de los arqueros.

OJO: las estadísticas son INVENTADAS con esta regla; no salen de ninguna base de
datos real.

Uso:
    python3 herramientas/agregar_jugadores.py --revisar   (solo informa)
    python3 herramientas/agregar_jugadores.py
"""

import json
import os
import sys

RUTA = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "datos", "clubes.json")
TOPE = 119

# --- Los clubes nuevos: 16 clubes grandes de Europa -------------------------
# Cada jugador: [nombre, puesto, dorsal, nivel]
NUEVOS_CLUBES = [
    {
        "id": "man_city", "nombre": "Manchester City", "corto": "MCI",
        "liga": "Premier League", "pais": "Inglaterra",
        "color_principal": "#6cabdd", "color_secundario": "#1c2c5b",
        "tactica": {"formacion": "4-3-3", "estilo": "posesion"},
        "jugadores": [
            ["Ederson", "POR", 31, 4], ["Walker", "LD", 2, 4], ["Dias", "DFC", 3, 5],
            ["Aké", "DFC", 6, 3], ["Gvardiol", "LI", 24, 4], ["Rodri", "MCD", 16, 5],
            ["Bernardo Silva", "MC", 20, 4], ["De Bruyne", "MCO", 17, 5],
            ["Foden", "ED", 47, 5], ["Haaland", "DC", 9, 5], ["Doku", "EI", 11, 4],
            ["Ortega", "POR", 18, 3], ["Stones", "DFC", 5, 4], ["Kovačić", "MC", 8, 4],
            ["Grealish", "EI", 10, 4], ["Savinho", "ED", 26, 3],
        ],
    },
    {
        "id": "liverpool", "nombre": "Liverpool", "corto": "LIV",
        "liga": "Premier League", "pais": "Inglaterra",
        "color_principal": "#c8102e", "color_secundario": "#f6eb61",
        "tactica": {"formacion": "4-3-3", "estilo": "presion_alta"},
        "jugadores": [
            ["Alisson", "POR", 1, 5], ["Alexander-Arnold", "LD", 66, 4], ["Konaté", "DFC", 5, 4],
            ["Van Dijk", "DFC", 4, 5], ["Robertson", "LI", 26, 4], ["Gravenberch", "MCD", 38, 4],
            ["Mac Allister", "MC", 10, 4], ["Szoboszlai", "MCO", 8, 4], ["Salah", "ED", 11, 5],
            ["Núñez", "DC", 9, 4], ["Díaz", "EI", 7, 4], ["Kelleher", "POR", 62, 2],
            ["Gomez", "DFC", 2, 3], ["Jones", "MC", 17, 3], ["Gakpo", "EI", 18, 4],
            ["Jota", "DC", 20, 4],
        ],
    },
    {
        "id": "arsenal", "nombre": "Arsenal", "corto": "ARS",
        "liga": "Premier League", "pais": "Inglaterra",
        "color_principal": "#ef0107", "color_secundario": "#ffffff",
        "tactica": {"formacion": "4-3-3", "estilo": "posesion"},
        "jugadores": [
            ["Raya", "POR", 22, 4], ["White", "LD", 4, 4], ["Saliba", "DFC", 2, 5],
            ["Gabriel", "DFC", 6, 4], ["Calafiori", "LI", 33, 4], ["Rice", "MCD", 41, 5],
            ["Ødegaard", "MCO", 8, 5], ["Merino", "MC", 23, 3], ["Saka", "ED", 7, 5],
            ["Havertz", "DC", 29, 4], ["Martinelli", "EI", 11, 4], ["Ramsdale", "POR", 1, 3],
            ["Timber", "DFC", 12, 4], ["Partey", "MCD", 5, 3], ["Trossard", "EI", 19, 4],
            ["Jesus", "DC", 9, 3],
        ],
    },
    {
        "id": "chelsea", "nombre": "Chelsea", "corto": "CHE",
        "liga": "Premier League", "pais": "Inglaterra",
        "color_principal": "#034694", "color_secundario": "#ffffff",
        "tactica": {"formacion": "4-2-3-1", "estilo": "posesion"},
        "jugadores": [
            ["Sánchez", "POR", 1, 3], ["James", "LD", 24, 4], ["Fofana", "DFC", 29, 3],
            ["Colwill", "DFC", 6, 4], ["Cucurella", "LI", 3, 3], ["Caicedo", "MCD", 25, 5],
            ["Fernández", "MC", 8, 4], ["Palmer", "MCO", 20, 5], ["Madueke", "ED", 11, 3],
            ["Jackson", "DC", 15, 3], ["Neto", "EI", 7, 4], ["Jörgensen", "POR", 12, 2],
            ["Chalobah", "DFC", 23, 3], ["Lavia", "MCD", 45, 3], ["Nkunku", "EI", 18, 4],
            ["Guiu", "DC", 38, 2],
        ],
    },
    {
        "id": "man_united", "nombre": "Manchester United", "corto": "MUN",
        "liga": "Premier League", "pais": "Inglaterra",
        "color_principal": "#da020e", "color_secundario": "#000000",
        "tactica": {"formacion": "4-2-3-1", "estilo": "contraataque"},
        "jugadores": [
            ["Onana", "POR", 24, 3], ["Dalot", "LD", 20, 3], ["Martínez", "DFC", 6, 4],
            ["De Ligt", "DFC", 4, 4], ["Shaw", "LI", 23, 3], ["Casemiro", "MCD", 18, 3],
            ["Mainoo", "MC", 37, 4], ["Fernandes", "MCO", 8, 5], ["Garnacho", "ED", 17, 4],
            ["Højlund", "DC", 9, 3], ["Rashford", "EI", 10, 4], ["Bayindir", "POR", 1, 2],
            ["Maguire", "DFC", 5, 3], ["Eriksen", "MC", 14, 3], ["Mount", "MCO", 7, 3],
            ["Zirkzee", "DC", 11, 3],
        ],
    },
    {
        "id": "tottenham", "nombre": "Tottenham", "corto": "TOT",
        "liga": "Premier League", "pais": "Inglaterra",
        "color_principal": "#ffffff", "color_secundario": "#132257",
        "tactica": {"formacion": "4-3-3", "estilo": "presion_alta"},
        "jugadores": [
            ["Vicario", "POR", 1, 4], ["Porro", "LD", 23, 4], ["Romero", "DFC", 17, 4],
            ["Van de Ven", "DFC", 37, 4], ["Udogie", "LI", 13, 4], ["Bissouma", "MCD", 8, 3],
            ["Bentancur", "MC", 30, 3], ["Maddison", "MCO", 10, 4], ["Johnson", "ED", 22, 4],
            ["Son", "DC", 7, 5], ["Werner", "EI", 16, 3], ["Forster", "POR", 20, 2],
            ["Davies", "DFC", 33, 3], ["Sarr", "MC", 29, 3], ["Kulusevski", "EI", 21, 4],
            ["Solanke", "DC", 19, 4],
        ],
    },
    {
        "id": "inter", "nombre": "Inter de Milán", "corto": "INT",
        "liga": "Serie A", "pais": "Italia",
        "color_principal": "#0068a8", "color_secundario": "#000000",
        "tactica": {"formacion": "3-5-2", "estilo": "contraataque"},
        "jugadores": [
            ["Sommer", "POR", 1, 4], ["Pavard", "DFC", 28, 4], ["Acerbi", "DFC", 15, 3],
            ["Bastoni", "DFC", 95, 5], ["Dumfries", "MD", 2, 4], ["Barella", "MC", 23, 5],
            ["Çalhanoğlu", "MCD", 20, 5], ["Mkhitaryan", "MC", 22, 4], ["Dimarco", "MI", 32, 4],
            ["Lautaro", "DC", 10, 5], ["Thuram", "DC", 9, 4], ["Martínez", "POR", 13, 3],
            ["De Vrij", "DFC", 6, 4], ["Frattesi", "MC", 16, 4], ["Taremi", "DC", 99, 3],
            ["Arnautović", "DC", 8, 2],
        ],
    },
    {
        "id": "milan", "nombre": "AC Milan", "corto": "MIL",
        "liga": "Serie A", "pais": "Italia",
        "color_principal": "#fb090b", "color_secundario": "#000000",
        "tactica": {"formacion": "4-2-3-1", "estilo": "contraataque"},
        "jugadores": [
            ["Maignan", "POR", 16, 4], ["Calabria", "LD", 2, 3], ["Tomori", "DFC", 23, 4],
            ["Gabbia", "DFC", 46, 3], ["Theo Hernández", "LI", 19, 5], ["Fofana", "MCD", 29, 4],
            ["Reijnders", "MC", 14, 4], ["Pulisic", "MCO", 11, 4], ["Chukwueze", "ED", 21, 3],
            ["Morata", "DC", 7, 3], ["Leão", "EI", 10, 5], ["Sportiello", "POR", 57, 2],
            ["Pavlović", "DFC", 31, 4], ["Bennacer", "MC", 4, 3], ["Abraham", "DC", 90, 3],
            ["Saelemaekers", "ED", 56, 3],
        ],
    },
    {
        "id": "juventus", "nombre": "Juventus", "corto": "JUV",
        "liga": "Serie A", "pais": "Italia",
        "color_principal": "#ffffff", "color_secundario": "#000000",
        "tactica": {"formacion": "4-2-3-1", "estilo": "contraataque"},
        "jugadores": [
            ["Di Gregorio", "POR", 29, 4], ["Danilo", "LD", 6, 3], ["Bremer", "DFC", 3, 4],
            ["Gatti", "DFC", 4, 3], ["Cambiaso", "LI", 27, 4], ["Locatelli", "MCD", 5, 4],
            ["Thuram", "MC", 19, 4], ["Koopmeiners", "MCO", 8, 4], ["González", "ED", 11, 4],
            ["Vlahović", "DC", 9, 4], ["Yıldız", "EI", 10, 4], ["Perin", "POR", 36, 3],
            ["Kalulu", "DFC", 15, 3], ["Fagioli", "MC", 21, 3], ["Conceição", "ED", 7, 4],
            ["Milik", "DC", 14, 2],
        ],
    },
    {
        "id": "napoli", "nombre": "Napoli", "corto": "NAP",
        "liga": "Serie A", "pais": "Italia",
        "color_principal": "#12a0d7", "color_secundario": "#ffffff",
        "tactica": {"formacion": "4-3-3", "estilo": "contraataque"},
        "jugadores": [
            ["Meret", "POR", 1, 4], ["Di Lorenzo", "LD", 22, 4], ["Rrahmani", "DFC", 13, 4],
            ["Buongiorno", "DFC", 4, 4], ["Olivera", "LI", 17, 3], ["Lobotka", "MCD", 68, 4],
            ["Anguissa", "MC", 99, 4], ["McTominay", "MC", 8, 4], ["Politano", "ED", 21, 4],
            ["Lukaku", "DC", 11, 4], ["Kvaratskhelia", "EI", 77, 5], ["Caprile", "POR", 25, 2],
            ["Juan Jesus", "DFC", 5, 3], ["Gilmour", "MC", 6, 3], ["Neres", "ED", 7, 4],
            ["Simeone", "DC", 18, 3],
        ],
    },
    {
        "id": "bayern", "nombre": "Bayern Múnich", "corto": "FCB",
        "liga": "Bundesliga", "pais": "Alemania",
        "color_principal": "#dc052d", "color_secundario": "#0066b2",
        "tactica": {"formacion": "4-2-3-1", "estilo": "presion_alta"},
        "jugadores": [
            ["Neuer", "POR", 1, 5], ["Kimmich", "LD", 6, 5], ["Kim", "DFC", 3, 4],
            ["Upamecano", "DFC", 2, 4], ["Davies", "LI", 19, 5], ["Palhinha", "MCD", 46, 4],
            ["Goretzka", "MC", 8, 4], ["Musiala", "MCO", 42, 5], ["Olise", "ED", 17, 4],
            ["Kane", "DC", 9, 5], ["Sané", "EI", 10, 4], ["Ulreich", "POR", 26, 2],
            ["Dier", "DFC", 15, 3], ["Laimer", "MC", 27, 3], ["Coman", "EI", 11, 4],
            ["Tel", "DC", 7, 3],
        ],
    },
    {
        "id": "dortmund", "nombre": "Borussia Dortmund", "corto": "BVB",
        "liga": "Bundesliga", "pais": "Alemania",
        "color_principal": "#fde100", "color_secundario": "#000000",
        "tactica": {"formacion": "4-2-3-1", "estilo": "presion_alta"},
        "jugadores": [
            ["Kobel", "POR", 1, 4], ["Ryerson", "LD", 26, 3], ["Schlotterbeck", "DFC", 4, 4],
            ["Hummels", "DFC", 15, 3], ["Bensebaïni", "LI", 5, 4], ["Emre Can", "MCD", 23, 3],
            ["Sabitzer", "MC", 20, 4], ["Brandt", "MCO", 19, 4], ["Adeyemi", "ED", 27, 4],
            ["Guirassy", "DC", 9, 4], ["Gittens", "EI", 43, 4], ["Meyer", "POR", 33, 2],
            ["Süle", "DFC", 25, 3], ["Nmecha", "MC", 8, 3], ["Malen", "ED", 21, 3],
            ["Beier", "DC", 14, 3],
        ],
    },
    {
        "id": "leverkusen", "nombre": "Bayer Leverkusen", "corto": "B04",
        "liga": "Bundesliga", "pais": "Alemania",
        "color_principal": "#e32221", "color_secundario": "#000000",
        "tactica": {"formacion": "3-4-2-1", "estilo": "posesion"},
        "jugadores": [
            ["Hrádecký", "POR", 1, 4], ["Tah", "DFC", 4, 4], ["Tapsoba", "DFC", 12, 4],
            ["Hincapié", "DFC", 3, 4], ["Frimpong", "MD", 30, 4], ["Xhaka", "MCD", 34, 4],
            ["Palacios", "MC", 25, 4], ["Grimaldo", "MI", 20, 5], ["Wirtz", "MCO", 10, 5],
            ["Schick", "DC", 14, 4], ["Boniface", "DC", 22, 4], ["Kovář", "POR", 17, 2],
            ["Andrich", "MC", 8, 3], ["Adli", "EI", 21, 3], ["Tella", "ED", 11, 3],
            ["Hofmann", "MCO", 7, 3],
        ],
    },
    {
        "id": "psg", "nombre": "Paris Saint-Germain", "corto": "PSG",
        "liga": "Ligue 1", "pais": "Francia",
        "color_principal": "#004170", "color_secundario": "#da291c",
        "tactica": {"formacion": "4-3-3", "estilo": "posesion"},
        "jugadores": [
            ["Donnarumma", "POR", 99, 4], ["Hakimi", "LD", 2, 5], ["Marquinhos", "DFC", 5, 5],
            ["Pacho", "DFC", 51, 4], ["Nuno Mendes", "LI", 25, 4], ["Vitinha", "MCD", 17, 5],
            ["Zaïre-Emery", "MC", 33, 4], ["Ruiz", "MC", 8, 4], ["Dembélé", "ED", 10, 5],
            ["Ramos", "DC", 9, 4], ["Barcola", "EI", 29, 4], ["Safonov", "POR", 40, 3],
            ["Hernández", "LI", 21, 3], ["Beraldo", "DFC", 35, 3], ["Lee", "MCO", 19, 4],
            ["Doué", "ED", 14, 3],
        ],
    },
    {
        "id": "marsella", "nombre": "Olympique de Marsella", "corto": "OM",
        "liga": "Ligue 1", "pais": "Francia",
        "color_principal": "#2faee0", "color_secundario": "#ffffff",
        "tactica": {"formacion": "4-3-3", "estilo": "presion_alta"},
        "jugadores": [
            ["Rulli", "POR", 1, 4], ["Murillo", "LD", 62, 3], ["Balerdi", "DFC", 5, 3],
            ["Cornelius", "DFC", 2, 3], ["Merlin", "LI", 3, 3], ["Højbjerg", "MCD", 23, 4],
            ["Rongier", "MC", 21, 3], ["Rabiot", "MC", 25, 4], ["Greenwood", "ED", 10, 4],
            ["Maupay", "DC", 8, 3], ["Harit", "EI", 11, 3], ["De Lange", "POR", 30, 2],
            ["Brassier", "DFC", 4, 3], ["Kondogbia", "MC", 19, 3], ["Rowe", "EI", 7, 3],
            ["Wahi", "DC", 9, 3],
        ],
    },
    {
        "id": "monaco", "nombre": "AS Mónaco", "corto": "ASM",
        "liga": "Ligue 1", "pais": "Francia",
        "color_principal": "#e63312", "color_secundario": "#ffffff",
        "tactica": {"formacion": "4-2-3-1", "estilo": "contraataque"},
        "jugadores": [
            ["Köhn", "POR", 16, 3], ["Vanderson", "LD", 2, 3], ["Kehrer", "DFC", 5, 3],
            ["Salisu", "DFC", 22, 3], ["Henrique", "LI", 12, 4], ["Zakaria", "MCD", 6, 4],
            ["Camara", "MC", 8, 3], ["Golovin", "MCO", 17, 4], ["Akliouche", "ED", 11, 4],
            ["Embolo", "DC", 36, 3], ["Balogun", "DC", 9, 3], ["Majecki", "POR", 1, 2],
            ["Maripán", "DFC", 3, 3], ["Fofana", "MC", 19, 3], ["Minamino", "EI", 18, 3],
            ["Ben Seghir", "EI", 21, 4],
        ],
    },
]

# --- Más jugadores para los clubes de LaLiga que ya estaban -----------------
# Se les agregan los suplentes de verdad. Dorsales altos para no chocar con los
# que ya tienen los titulares.
EXTRA_LALIGA = {
    "real_madrid": [["Fran García", "LI", 20, 3], ["Brahim Díaz", "ED", 21, 3],
                    ["Ceballos", "MC", 19, 3], ["Jacobo Ramón", "DFC", 34, 2],
                    ["Gonzalo García", "DC", 30, 3]],
    "barcelona": [["Iñaki Peña", "POR", 26, 2], ["Christensen", "DFC", 15, 3],
                  ["Fermín López", "MC", 32, 4], ["Pau Víctor", "DC", 27, 2],
                  ["Héctor Fort", "LD", 28, 3]],
    "atletico": [["Lenglet", "DFC", 17, 3], ["Gallagher", "MC", 4, 4],
                 ["Correa", "ED", 10, 3], ["Lemar", "MCO", 11, 3], ["Galán", "LI", 21, 3]],
    "athletic": [["Unai Gómez", "MCO", 23, 3], ["Villalibre", "DC", 12, 3],
                 ["Adu Ares", "ED", 27, 2], ["Jauregizar", "MCD", 30, 3],
                 ["Serrano", "MD", 22, 2]],
    "real_sociedad": [["Olasagasti", "MC", 25, 3], ["Magunazelaia", "MCO", 33, 2],
                      ["Karrikaburu", "DC", 20, 2], ["Gorrotxategi", "MCD", 28, 2],
                      ["Ochieng", "LI", 31, 2]],
    "betis": [["Nobel Mendy", "DFC", 5, 2], ["Mateo Flores", "MC", 27, 2],
              ["Jesús Rodríguez", "EI", 26, 3], ["Ángel Ortiz", "LD", 28, 2],
              ["Iker Losada", "MCO", 21, 3]],
    "sevilla": [["Nianzou", "DFC", 24, 3], ["Marcao", "DFC", 23, 3],
                ["Jesús Navas", "LD", 16, 3], ["Idumbo", "EI", 33, 3],
                ["Collado", "MCO", 11, 2]],
    "villarreal": [["Denis Suárez", "MC", 8, 3], ["Gerard Moreno", "DC", 7, 4],
                   ["Rafa Marín", "DFC", 16, 3], ["Mouriño", "DFC", 26, 3],
                   ["Pacheco", "POR", 30, 2]],
    "valencia": [["Jaume Doménech", "POR", 1, 3], ["Guillamón", "DFC", 2, 3],
                 ["Yaremchuk", "DC", 17, 3], ["Tejón", "MC", 26, 2],
                 ["Íker Córdoba", "DFC", 27, 2]],
    "celta": [["Javi Rueda", "LD", 32, 2], ["Hugo Álvarez", "MC", 27, 3],
              ["Jones El Abdellaoui", "MCO", 30, 2], ["Fer López", "MCO", 33, 3],
              ["Miguel Rodríguez", "EI", 26, 2]],
    "osasuna": [["Nacho Vidal", "LD", 2, 3], ["Unai García", "DFC", 4, 3],
                ["Moi Gómez", "MC", 16, 3], ["Rubén García", "EI", 14, 3],
                ["Budimir", "DC", 17, 4]],
    "rayo_vallecano": [["Dimitrievski", "POR", 1, 4], ["Trejo", "MCO", 8, 3],
                       ["Camello", "DC", 14, 3], ["Bebé", "EI", 10, 3],
                       ["Gumbau", "MC", 20, 3]],
    "getafe": [["Alderete", "DFC", 4, 3], ["Milla", "MC", 5, 3],
               ["Uche", "DC", 9, 4], ["Coba da Costa", "MI", 11, 3],
               ["Juan Iglesias", "LD", 21, 3]],
    "alaves": [["Sedlar", "DFC", 24, 3], ["Blanco", "MCD", 6, 3],
               ["Guridi", "MC", 10, 3], ["Kike García", "DC", 9, 3],
               ["Abde Rebbach", "EI", 21, 3]],
    "mallorca": [["Raíllo", "DFC", 21, 3], ["Samú Costa", "MCD", 12, 4],
                 ["Asano", "ED", 11, 3], ["Valery", "EI", 10, 3],
                 ["Mascarell", "MC", 5, 3]],
    "girona": [["Blind", "DFC", 17, 3], ["Iván Martín", "MC", 8, 3],
               ["Tsygankov", "ED", 10, 4], ["Stuani", "DC", 9, 3],
               ["Bryan Gil", "MCO", 7, 4]],
    "espanyol": [["Kumbulla", "DFC", 3, 3], ["Král", "MCD", 21, 3],
                 ["Expósito", "MCO", 8, 3], ["Cheddira", "DC", 9, 3],
                 ["Pere Milla", "MI", 11, 3]],
    "las_palmas": [["Mika Mármol", "DFC", 5, 3], ["Essugo", "MCD", 6, 3],
                   ["Kirian Rodríguez", "MC", 8, 4], ["Moleiro", "EI", 24, 4],
                   ["Sandro Ramírez", "ED", 9, 3]],
    "leganes": [["Nastasić", "DFC", 22, 3], ["Cissé", "MCD", 4, 3],
                ["Óscar Rodríguez", "MCO", 11, 3], ["Munir", "EI", 23, 3],
                ["Miguel de la Fuente", "DC", 9, 3]],
    "valladolid": [["Luis Pérez", "LD", 2, 3], ["Monchu", "MC", 12, 3],
                   ["Machís", "MI", 11, 4], ["Sylla", "DC", 9, 3],
                   ["Anuar", "MD", 10, 3]],
}

# --- Plantillas COMPLETAS para todos los clubes ---------------------------
# Camilo pidió "todos los jugadores": se llenan las plantillas con los
# suplentes y los canteranos de cada club (los grandes con más). El script se
# salta solo a los que ya estén, así que se puede ampliar sin miedo.
EXTRA_CLUBES = {
    # --- Los 5 grandes, con plantilla larga ---
    "real_madrid": [["Raúl Asencio", "DFC", 35, 3], ["Chema Andrés", "MCD", 33, 2],
                    ["Jesús Fortea", "LD", 36, 1], ["Diego Aguado", "DFC", 37, 1],
                    ["Youssef Enríquez", "LI", 38, 1], ["Víctor Muñoz", "EI", 39, 1],
                    ["Alberto Leiva", "DC", 40, 1]],
    "barcelona": [["Marc Bernal", "MCD", 28, 3], ["Gerard Martín", "DFC", 35, 2],
                  ["Ander Astralaga", "POR", 30, 1], ["Noah Darvich", "MCO", 38, 1],
                  ["Sergi Domínguez", "DFC", 31, 1], ["Toni Fernández", "MCO", 39, 1],
                  ["Guille Fernández", "MC", 40, 1]],
    "man_city": [["Akanji", "DFC", 25, 4], ["Nunes", "MC", 27, 3], ["Lewis", "LD", 82, 3],
                 ["Bobb", "ED", 52, 3], ["McAtee", "MCO", 87, 2], ["Carson", "POR", 33, 1],
                 ["Wilson-Esbrand", "LI", 71, 2], ["Phillips", "MCD", 4, 2]],
    "man_united": [["Yoro", "DFC", 15, 4], ["Mazraoui", "LD", 3, 3], ["Malacia", "LI", 12, 2],
                   ["Amad Diallo", "ED", 16, 3], ["Antony", "ED", 21, 3],
                   ["Collyer", "MCD", 43, 2], ["Heaton", "POR", 22, 1],
                   ["Wheatley", "DC", 44, 1]],
    "liverpool": [["Bradley", "LD", 84, 3], ["Quansah", "DFC", 78, 3], ["Tsimikas", "LI", 21, 3],
                  ["Endo", "MCD", 3, 3], ["Elliott", "MCO", 19, 4], ["Chiesa", "ED", 14, 3],
                  ["Jaros", "POR", 56, 1], ["Danns", "DC", 76, 1]],
    # --- El resto de LaLiga ---
    "atletico": [["Musso", "POR", 1, 3], ["Witsel", "MCD", 20, 3], ["Barrios", "MCD", 8, 4],
                 ["Riquelme", "EI", 21, 3], ["Simeone", "ED", 22, 3]],
    "athletic": [["Adjutor", "MC", 34, 1], ["Villalibre", "DC", 12, 3],
                 ["Álex Padilla", "POR", 13, 2], ["Unai Vencedor", "MC", 26, 2],
                 ["Prados", "MC", 24, 2]],
    "real_sociedad": [["Zubiaurre", "POR", 32, 2], ["Aritz Elustondo", "DFC", 6, 3],
                      ["Urko González", "DFC", 24, 2], ["Sadiq", "DC", 19, 3],
                      ["Marín", "LI", 34, 2]],
    "betis": [["Adrián", "POR", 33, 2], ["Natan", "DFC", 6, 3], ["Sergi Altimira", "MC", 8, 3],
              ["Aitor Ruibal", "LD", 24, 3], ["Iker Losada", "MCO", 21, 3]],
    "sevilla": [["Flores", "POR", 33, 2], ["Carmona", "LD", 2, 4], ["Agoumé", "MC", 18, 3],
                ["Peque", "DC", 14, 3], ["Saúl", "MC", 8, 3]],
    "villarreal": [["Conde", "POR", 1, 2], ["Foyth", "LD", 8, 4], ["Terrats", "MC", 20, 3],
                   ["Pino", "ED", 21, 4], ["Pérez", "DC", 10, 3]],
    "valencia": [["Dimitrievski", "POR", 13, 3], ["Foulquier", "LD", 8, 3],
                 ["Cömert", "DFC", 24, 3], ["Canós", "MI", 11, 3], ["Duro", "DC", 9, 3]],
    "celta": [["Villar", "POR", 1, 3], ["Mingueza", "LD", 32, 4], ["Swedberg", "MCO", 14, 3],
              ["Bamba", "ED", 17, 3], ["Aspas", "SD", 10, 4]],
    "osasuna": [["Fernández", "POR", 1, 3], ["Areso", "LD", 12, 4], ["Moncayola", "MC", 10, 3],
                ["Moi Gómez", "MC", 16, 3], ["Raúl García", "DC", 19, 3]],
    "rayo_vallecano": [["Cárdenas", "POR", 1, 3], ["Lejeune", "DFC", 24, 3],
                       ["Pathé Ciss", "MCD", 6, 3], ["Isi Palazón", "MD", 7, 4],
                       ["Álvaro García", "MI", 11, 3]],
    "getafe": [["Letelier", "POR", 1, 2], ["Djené", "DFC", 2, 4], ["Arambarri", "MC", 8, 3],
               ["Carles Pérez", "MD", 17, 3], ["Mayoral", "DC", 19, 4]],
    "alaves": [["Owono", "POR", 1, 2], ["Tenaglia", "LD", 2, 3], ["Aleñá", "MCO", 8, 3],
               ["Carlos Vicente", "MD", 11, 3], ["Mariano", "DC", 19, 3]],
    "mallorca": [["Cuéllar", "POR", 1, 3], ["Maffeo", "LD", 23, 4], ["Muriqi", "DC", 7, 4],
                 ["Dani Rodríguez", "MCO", 14, 3], ["Larin", "DC", 17, 3]],
    "girona": [["Krapyvtsov", "POR", 25, 2], ["Arnau Martínez", "LD", 4, 3],
               ["Romeu", "MCD", 14, 3], ["Asprilla", "EI", 11, 3], ["Danjuma", "EI", 20, 4]],
    "espanyol": [["Fortuño", "POR", 13, 2], ["El Hilali", "LD", 23, 3],
                 ["Pol Lozano", "MC", 15, 3], ["Puado", "MD", 7, 4], ["Cheddira", "DC", 9, 3]],
    "las_palmas": [["Cillessen", "POR", 13, 4], ["Marvin Park", "LD", 2, 3],
                   ["Javi Muñoz", "MC", 16, 3], ["Fábio Silva", "DC", 11, 3],
                   ["Sandro Ramírez", "ED", 9, 3]],
    "leganes": [["Soriano", "POR", 1, 3], ["Rosier", "LD", 2, 3], ["Brasanac", "MC", 10, 3],
                ["Raba", "ED", 14, 3], ["Diego García", "DC", 19, 3]],
    "valladolid": [["Aceves", "POR", 13, 2], ["Javi Sánchez", "DFC", 5, 3],
                   ["Kike Pérez", "MC", 8, 3], ["Marcos André", "DC", 19, 3],
                   ["Latasa", "DC", 14, 3]],
    # --- El resto de Europa ---
    "arsenal": [["Zinchenko", "LI", 35, 3], ["Kiwior", "DFC", 15, 3], ["Jorginho", "MCD", 20, 3],
                ["Nwaneri", "MCO", 53, 4], ["Sterling", "EI", 30, 3], ["Hein", "POR", 31, 1]],
    "chelsea": [["Badiashile", "DFC", 5, 3], ["Gusto", "LD", 27, 3], ["Dewsbury-Hall", "MC", 22, 3],
                ["Sancho", "EI", 19, 4], ["George", "DC", 32, 2], ["Bettinelli", "POR", 13, 1]],
    "tottenham": [["Spence", "LI", 24, 3], ["Dragușin", "DFC", 6, 3], ["Bissouma", "MCD", 8, 3],
                  ["Bergvall", "MC", 15, 4], ["Moore", "EI", 47, 3], ["Austin", "POR", 40, 1]],
    "inter": [["Bisseck", "DFC", 31, 3], ["Carlos Augusto", "MI", 30, 4], ["Zieliński", "MC", 7, 4],
              ["Correa", "DC", 11, 3], ["Di Gennaro", "POR", 12, 1], ["Buchanan", "ED", 17, 3]],
    "milan": [["Thiaw", "DFC", 28, 3], ["Emerson", "LD", 22, 3], ["Musah", "MC", 80, 3],
              ["Zeroli", "MCO", 18, 2], ["Camarda", "DC", 73, 2], ["Torriani", "POR", 96, 1]],
    "juventus": [["Rugani", "DFC", 24, 3], ["Cabral", "LI", 32, 2], ["Weah", "MD", 22, 3],
                 ["Mbangula", "EI", 27, 3], ["Adžić", "MCO", 20, 2], ["Pinsoglio", "POR", 16, 1]],
    "napoli": [["Juan Jesus", "DFC", 5, 3], ["Mazzocchi", "LD", 30, 3], ["Folorunsho", "MC", 90, 2],
               ["Raspadori", "DC", 81, 4], ["Zerbin", "EI", 20, 2], ["Contini", "POR", 14, 1]],
    "bayern": [["Ito", "DFC", 21, 3], ["Guerreiro", "LI", 22, 4], ["Laimer", "MC", 27, 3],
               ["Tel", "DC", 7, 3], ["Ibrahimović", "DC", 39, 2], ["Peretz", "POR", 18, 2]],
    "dortmund": [["Can", "DFC", 23, 3], ["Bensebaïni", "LI", 5, 4], ["Nmecha", "MC", 8, 3],
                 ["Malen", "ED", 21, 3], ["Campbell", "EI", 33, 2], ["Lotka", "POR", 35, 1]],
    "leverkusen": [["Tapsoba", "DFC", 12, 4], ["Hincapié", "DFC", 3, 4], ["Andrich", "MC", 8, 3],
                   ["Tella", "ED", 11, 3], ["Hofmann", "MCO", 7, 3], ["Lomb", "POR", 36, 1]],
    "psg": [["Beraldo", "DFC", 35, 3], ["Hernández", "LI", 21, 3], ["Lee", "MCO", 19, 4],
            ["Doué", "ED", 14, 3], ["Kolo Muani", "DC", 23, 3], ["Tenas", "POR", 80, 1]],
    "marsella": [["Brassier", "DFC", 4, 3], ["Kondogbia", "MC", 19, 3], ["Rowe", "EI", 7, 3],
                 ["Wahi", "DC", 9, 3], ["Harit", "EI", 11, 3], ["Blanco", "POR", 36, 1]],
    "monaco": [["Maripán", "DFC", 3, 3], ["Fofana", "MC", 19, 3], ["Minamino", "EI", 18, 3],
               ["Ben Seghir", "EI", 21, 4], ["Balogun", "DC", 9, 3], ["Lienard", "POR", 40, 1]],
}

# --- La regla de las 4 estadísticas de campo -------------------------------
# Bases por puesto (con un jugador de nivel 3). Por cada nivel de más o de
# menos, se suman o restan los puntos de "por nivel".
BASES = {
    "POR": {"v": 50, "t": 20, "f": 84, "r": 82},
    "DEF": {"v": 78, "t": 45, "f": 84, "r": 83},
    "MED": {"v": 76, "t": 68, "f": 74, "r": 84},
    "DEL": {"v": 85, "t": 80, "f": 75, "r": 79},
}
POR_NIVEL = {"v": 4, "t": 5, "f": 4, "r": 3}

GRUPO = {
    "POR": "POR",
    "LD": "DEF", "DFC": "DEF", "LI": "DEF",
    "MCD": "MED", "MC": "MED", "MCO": "MED", "MD": "MED", "MI": "MED",
    "ED": "DEL", "SD": "DEL", "DC": "DEL", "EI": "DEL",
    "SD ": "DEL",
}


def toque(nombre: str) -> int:
    """Un numerito estable por jugador, de -4 a +4, para variar un poquito."""
    return (sum(ord(c) for c in nombre) % 9) - 4


def limite(valor: float) -> int:
    return max(1, min(TOPE, int(round(valor))))


def estadisticas(nombre: str, puesto: str, nivel: int) -> dict:
    """Las 4 estadísticas de campo de un jugador (y, en los arqueros, de dónde
    salen sus 6 estadísticas propias).

    OJO con los arqueros: la otra herramienta calcula sus 6 estadísticas
    (reflejos, manos, achique, juego aéreo, pie y saque) a partir de las de
    campo, y para eso necesita también el PASE. Si no se le da, se queda sin
    estadísticas y avisa "es arquero y le faltan estadísticas" (ya pasó).
    """
    grupo = GRUPO.get(puesto, "MED")
    base = BASES[grupo]
    t = toque(nombre)
    salida = {
        "v": limite(base["v"] + (nivel - 3) * POR_NIVEL["v"] + t),
        "t": limite(base["t"] + (nivel - 3) * POR_NIVEL["t"] + t),
        "f": limite(base["f"] + (nivel - 3) * POR_NIVEL["f"] - t),
        "r": limite(base["r"] + (nivel - 3) * POR_NIVEL["r"]),
    }
    if grupo == "POR":
        # Un arquero pasa regular y casi no regatea: de aquí le salen el pie y
        # el saque (0,70*pase y 0,60*pase).
        salida["pas"] = limite(52 + (nivel - 3) * 4 + t)
        salida["reg"] = limite(32 + (nivel - 3) * 2)
    return salida


def sin_acentos(texto: str) -> str:
    """El nombre en minúsculas y sin tildes, para comparar."""
    tabla = str.maketrans("áàäâãéèëêíìïîóòöôõúùüûñç", "aaaaaeeeeiiiiooooouuuunc")
    return texto.lower().translate(tabla).strip()


def apellido(nombre: str) -> str:
    """La última palabra del nombre (el apellido, casi siempre)."""
    partes = sin_acentos(nombre).split()
    return partes[-1] if partes else ""


def dorsal_libre(usados: set) -> int:
    """Un dorsal que no esté usado, desde el 2 para arriba."""
    for n in range(2, 100):
        if n not in usados:
            return n
    return 99


def armar_jugador(fila: list) -> dict:
    nombre, puesto, dorsal, nivel = str(fila[0]), str(fila[1]), int(fila[2]), int(fila[3])
    jugador = {"n": nombre, "p": puesto, "d": dorsal}
    jugador.update(estadisticas(nombre, puesto, nivel))
    return jugador


def arreglar_dorsales(datos: dict) -> int:
    """Revisa TODOS los clubes y le da un dorsal libre al que lo tenga repetido.

    Los dorsales repetidos en una misma plantilla son un error de verdad (dos
    jugadores no pueden llevar el mismo número), y son facilísimos de cometer al
    escribir plantillas a mano. Así el archivo se arregla solo.
    """
    arreglados = 0
    for club in datos["clubes"]:
        usados = set()
        for jugador in club["plantilla"]:
            d = int(jugador.get("d", 0))
            if d in usados:
                nuevo = dorsal_libre(usados)
                print("  dorsal repetido: %s / %s pasa de %d a %d" % (
                    str(club.get("nombre", "?")), str(jugador.get("n", "?")), d, nuevo))
                jugador["d"] = nuevo
                d = nuevo
                arreglados += 1
            usados.add(d)
    return arreglados


def main() -> None:
    solo_revisar = "--revisar" in sys.argv
    with open(RUTA, encoding="utf-8") as f:
        datos = json.load(f)

    por_id = {str(c.get("id", "")): c for c in datos["clubes"]}
    agregados = 0

    # 1) Los clubes nuevos (si ya existían, no se tocan).
    nuevos = 0
    for club in NUEVOS_CLUBES:
        if str(club["id"]) in por_id:
            continue
        nuevo = {
            "id": club["id"], "nombre": club["nombre"], "liga": club["liga"],
            "pais": club["pais"], "corto": club["corto"],
            "color_principal": club["color_principal"],
            "color_secundario": club["color_secundario"],
            "tactica": club["tactica"],
            "plantilla": [armar_jugador(j) for j in club["jugadores"]],
        }
        datos["clubes"].append(nuevo)
        por_id[club["id"]] = nuevo
        nuevos += 1
        agregados += len(nuevo["plantilla"])

    # 2) Más jugadores a los clubes (los de LaLiga y los demás). Los dos
    # diccionarios se juntan: EXTRA_LALIGA tiene los primeros refuerzos y
    # EXTRA_CLUBES las plantillas completas.
    todos_los_extras = {}
    for fuente in (EXTRA_LALIGA, EXTRA_CLUBES):
        for club_id, jugadores in fuente.items():
            todos_los_extras.setdefault(club_id, []).extend(jugadores)
    extras = 0
    for club_id, jugadores in todos_los_extras.items():
        club = por_id.get(club_id)
        if club is None:
            print("AVISO: no existe el club", club_id)
            continue
        ya = {str(j.get("n", "")) for j in club["plantilla"]}
        ya_apellidos = {apellido(str(j.get("n", ""))) for j in club["plantilla"]}
        usados = {int(j.get("d", 0)) for j in club["plantilla"]}
        for fila in jugadores:
            nombre = str(fila[0])
            # Se salta al que ya esté. OJO: también por APELLIDO, porque es
            # fácil escribir "Sergi Altimira" cuando ya está "Altimira" (pasó,
            # y eran jugadores repetidos en la misma plantilla).
            if nombre in ya or apellido(nombre) in ya_apellidos:
                continue
            nuevo = armar_jugador(fila)
            # Y si el dorsal ya está cogido, se le da el primero libre (los
            # dorsales repetidos en una plantilla son un error de verdad).
            if int(nuevo["d"]) in usados:
                nuevo["d"] = dorsal_libre(usados)
            usados.add(int(nuevo["d"]))
            ya.add(nombre)
            ya_apellidos.add(apellido(nombre))
            club["plantilla"].append(nuevo)
            extras += 1
    agregados += extras

    arreglados = arreglar_dorsales(datos)
    if arreglados:
        print("dorsales repetidos arreglados:", arreglados)

    print("clubes nuevos:", nuevos, "| jugadores nuevos en LaLiga:", extras, "| en total agregados:", agregados)
    print("clubes en el archivo:", len(datos["clubes"]),
          "| jugadores en el archivo:", sum(len(c["plantilla"]) for c in datos["clubes"]))
    ligas = {}
    for c in datos["clubes"]:
        ligas[c.get("liga", "?")] = ligas.get(c.get("liga", "?"), 0) + 1
    print("ligas:", ligas)

    if solo_revisar:
        print("(solo revisión: no se escribió nada)")
        return
    with open(RUTA, "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print("escrito:", RUTA)
    print("Ahora hay que correr: python3 herramientas/agregar_estadisticas.py")


if __name__ == "__main__":
    main()
