#!/usr/bin/env python3
"""Genera las pieles de las cartas (los PNG) para cami26.

Aquí se dibuja la PARTE BONITA de la carta (el fondo, el borde y el reflejo) y
Godot le escribe encima los datos: el OVR, el nombre y las 4 estadísticas.
Así el estilo se cambia en este archivo y el juego no se toca.

Todo se dibuja por código: no se usa ninguna imagen ni diseño de FIFA.

Uso:
    python3 herramientas/generar_cartas.py

Escribe en datos/cartas/: carta_bronce.png, carta_plata.png, carta_oro.png,
carta_especial.png, avatar.png y sobre.png
"""

import os
from PIL import Image, ImageDraw

# Se dibuja al doble de tamaño y después se reduce: así los bordes quedan suaves.
ESCALA = 2
ANCHO, ALTO = 512, 704
RADIO = 34

SALIDA = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "datos", "cartas")

# Los colores de cada nivel: (arriba, abajo, borde, brillo)
ESTILOS = {
    "bronce":   ((150, 104, 62),  (86, 52, 22),    (216, 168, 114), (255, 224, 186)),
    "plata":    ((198, 205, 213), (117, 125, 134), (240, 245, 250), (255, 255, 255)),
    "oro":      ((248, 208, 84),  (172, 118, 20),  (255, 238, 168), (255, 250, 214)),
    "especial": ((84, 48, 176),   (16, 8, 48),     (255, 208, 92),  (196, 234, 255)),
}


def mascara_carta(ancho, alto, radio):
    """La silueta de la carta: un rectángulo de esquinas redondeadas."""
    mascara = Image.new("L", (ancho, alto), 0)
    ImageDraw.Draw(mascara).rounded_rectangle((0, 0, ancho - 1, alto - 1), radius=radio, fill=255)
    return mascara


def degradado(arriba, abajo, ancho, alto):
    """Un fondo con degradado vertical (de un color al otro)."""
    tira = Image.new("RGB", (1, alto))
    px = tira.load()
    for y in range(alto):
        t = y / max(1, alto - 1)
        px[0, y] = tuple(int(arriba[i] + (abajo[i] - arriba[i]) * t) for i in range(3))
    return tira.resize((ancho, alto), Image.BILINEAR).convert("RGBA")


def reflejo(ancho, alto, radio, color, alfa):
    """Una franja diagonal semitransparente, como el reflejo de una carta."""
    capa = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))
    ancho_franja = int(ancho * 0.34)
    ImageDraw.Draw(capa).polygon(
        [(-ancho, alto), (int(ancho * 0.15), -alto),
         (int(ancho * 0.15) + ancho_franja, -alto), (-ancho + ancho_franja, alto)],
        fill=(color[0], color[1], color[2], alfa),
    )
    # Recortar la franja a la forma de la carta, para que no se salga.
    dentro = mascara_carta(ancho, alto, radio)
    capa.putalpha(Image.composite(capa.getchannel("A"), Image.new("L", (ancho, alto), 0), dentro))
    return capa


def hacer_carta(arriba, abajo, borde, brillo, especial=False):
    """Dibuja la piel de una carta."""
    w, h = ANCHO * ESCALA, ALTO * ESCALA
    radio = RADIO * ESCALA

    carta = degradado(arriba, abajo, w, h)
    carta = Image.alpha_composite(carta, reflejo(w, h, radio, brillo, 110 if especial else 70))

    dibujo = ImageDraw.Draw(carta)

    # El borde exterior, grueso.
    grosor = (9 if especial else 7) * ESCALA
    dibujo.rounded_rectangle(
        (grosor // 2, grosor // 2, w - 1 - grosor // 2, h - 1 - grosor // 2),
        radius=max(2, radio - grosor // 2), outline=borde + (255,), width=grosor,
    )

    # Una línea clara por dentro, para que la carta se vea con volumen.
    inset = grosor + 10 * ESCALA
    dibujo.rounded_rectangle(
        (inset, inset, w - 1 - inset, h - 1 - inset),
        radius=max(2, radio - inset), outline=brillo + (95,), width=2 * ESCALA,
    )

    # Las cartas especiales llevan una segunda línea dorada por dentro.
    if especial:
        inset2 = grosor + 22 * ESCALA
        dibujo.rounded_rectangle(
            (inset2, inset2, w - 1 - inset2, h - 1 - inset2),
            radius=max(2, radio - inset2), outline=(255, 216, 110, 170), width=2 * ESCALA,
        )

    # Recortar las esquinas y reducir al tamaño final.
    carta.putalpha(mascara_carta(w, h, radio))
    return carta.resize((ANCHO, ALTO), Image.LANCZOS)


def hacer_avatar(ancho=256, alto=256):
    """Una silueta genérica, para las cartas que todavía no tienen foto."""
    w, h = ancho * ESCALA, alto * ESCALA
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dibujo = ImageDraw.Draw(img)
    color = (20, 24, 36, 225)

    radio = int(w * 0.18)
    cx, cy = w // 2, int(h * 0.34)
    dibujo.ellipse((cx - radio, cy - radio, cx + radio, cy + radio),
                   fill=color, outline=(255, 255, 255, 130), width=3 * ESCALA)
    dibujo.rounded_rectangle(
        (int(w * 0.18), int(h * 0.58), int(w * 0.82), int(h * 1.05)),
        radius=int(w * 0.20), fill=color, outline=(255, 255, 255, 130), width=3 * ESCALA,
    )
    return img.resize((ancho, alto), Image.LANCZOS)


def hacer_sobre(ancho=320, alto=420):
    """El sobre cerrado: un paquete oscuro con una cinta dorada en diagonal."""
    w, h = ancho * ESCALA, alto * ESCALA
    radio = int(ancho * 0.06) * ESCALA

    img = degradado((64, 42, 150), (12, 10, 40), w, h)
    img = Image.alpha_composite(img, reflejo(w, h, radio, (255, 255, 255), 45))

    dibujo = ImageDraw.Draw(img)

    # La cinta dorada, en diagonal (de abajo a la izquierda hacia arriba a la derecha).
    ax, ay = int(w * 0.02), int(h * 1.05)
    bx, by = int(w * 0.98), int(h * -0.05)
    dx, dy = bx - ax, by - ay
    largo = (dx * dx + dy * dy) ** 0.5
    medio = int(w * 0.075)
    # Desplazamiento perpendicular a la cinta.
    nx, ny = -dy / largo * medio, dx / largo * medio
    dibujo.polygon(
        [(ax + nx, ay + ny), (bx + nx, by + ny), (bx - nx, by - ny), (ax - nx, ay - ny)],
        fill=(255, 202, 64, 255),
    )
    # Una línea clara dentro de la cinta, para que se vea con volumen.
    medio2 = int(w * 0.026)
    nx2, ny2 = -dy / largo * medio2, dx / largo * medio2
    dibujo.polygon(
        [(ax + nx2, ay + ny2), (bx + nx2, by + ny2), (bx - nx2, by - ny2), (ax - nx2, ay - ny2)],
        fill=(255, 240, 190, 150),
    )

    # Un emblema redondo en el centro.
    r = int(w * 0.13)
    cx, cy = w // 2, int(h * 0.47)
    dibujo.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(22, 16, 60, 255),
                   outline=(255, 214, 92, 255), width=6 * ESCALA)

    # El borde grueso y una línea clara por dentro.
    grosor = 8 * ESCALA
    dibujo.rounded_rectangle(
        (grosor // 2, grosor // 2, w - 1 - grosor // 2, h - 1 - grosor // 2),
        radius=max(2, radio - grosor // 2), outline=(255, 214, 92, 255), width=grosor,
    )
    inset = grosor + 10 * ESCALA
    dibujo.rounded_rectangle(
        (inset, inset, w - 1 - inset, h - 1 - inset),
        radius=max(2, radio - inset), outline=(255, 255, 255, 80), width=2 * ESCALA,
    )

    img.putalpha(mascara_carta(w, h, radio))
    return img.resize((ancho, alto), Image.LANCZOS)


def main():
    os.makedirs(SALIDA, exist_ok=True)
    for nombre, (arriba, abajo, borde, brillo) in ESTILOS.items():
        carta = hacer_carta(arriba, abajo, borde, brillo, especial=(nombre == "especial"))
        ruta = os.path.join(SALIDA, f"carta_{nombre}.png")
        carta.save(ruta)
        print("escrito:", ruta, carta.size)

    ruta_avatar = os.path.join(SALIDA, "avatar.png")
    hacer_avatar().save(ruta_avatar)
    print("escrito:", ruta_avatar, (256, 256))

    ruta_sobre = os.path.join(SALIDA, "sobre.png")
    hacer_sobre().save(ruta_sobre)
    print("escrito:", ruta_sobre, (320, 420))


if __name__ == "__main__":
    main()
