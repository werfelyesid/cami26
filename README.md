# cami26 ⚽

Juego de fútbol para el celular, hecho en **Godot 4.6** por Camilo (con ayuda de su papá).

La cancha se ve **desde arriba**. Tú manejas a un jugador del equipo azul y tienes
que ganarle al equipo rojo. Son **16 jugadores por equipo**, cada uno con su puesto
y su número, como en el fútbol de verdad.

---

## Cómo jugar

### En el celular (Android)
| Control | Qué hace |
|---|---|
| **Joystick** (izquierda) | Mover al jugador |
| **TIRO** (rojo) | Disparar al arco |
| **PASE** (azul) | Tocar suave |
| **CAMBIAR** (amarillo) | Pasar a manejar otro jugador de tu equipo (el que esté más cerca del balón) |

El jugador que manejas tiene un **aro amarillo**. Los demás juegan solos.

### En la compu (para probar)
| Acción | Tecla |
|---|---|
| Mover | `W` `A` `S` `D` o las flechas |
| Tiro | `Espacio` |
| Pase | `Shift` |
| Cambiar de jugador | `Q` o `Tab` |

El mouse funciona como si fuera el dedo, porque en `project.godot` está activado
`input_devices/pointing/emulate_touch_from_mouse`.

---

## Las reglas

- **90 minutos** de reloj. Ojo: **1 segundo de verdad = 1 minuto de juego**,
  así que el partido dura 90 segundos.
- Al **minuto 45 hay descanso** y el reloj se para **10 segundos**.
- Si van **empatados al 90**, hay **tiempo extra hasta el 120**.
- Y si siguen empatados... **¡8 rondas de penales!**
  En los penales tú pateas (apunta con el joystick hacia arriba o abajo) y tu
  arquero trata de atajar los del rival.

## Los puestos y los números

| Número | Puesto | Qué hace |
|---|---|---|
| **1** | Arquero | Usa las **manitas** (un tercio de su tamaño) para tapar el arco. Atrapa el balón y lo despeja. **No puede salir del área.** |
| **2, 3, 4, 5, 6** | Defensas | Marcan a los atacantes rivales: se ponen entre el atacante y el arco, y **tapan los tiros** con el cuerpo. |
| **7, 8, 10, 11, 15, 16** | Medios | Presionan al que tiene el balón y acompañan el ataque. |
| **9, 12, 13, 14** | Delanteros | Van arriba a hacer los goles y se quedan listos para el contragolpe. |

---

## Cómo abrirlo

```bash
# Jugar
godot --path /home/yesid/cami26

# Abrir el editor
godot --editor --path /home/yesid/cami26
```

También hay lanzadores en el menú de aplicaciones: **cami26 — Jugar** y
**cami26 — Editor**.

---

## Mapa de archivos

```
cami26/
├── project.godot          Configuración: pantalla horizontal, motor liviano, autoloads
├── icon.svg               El ícono del juego
├── scenes/
│   ├── main_menu.tscn     Escena que arranca (el menú)
│   └── partido.tscn       Escena del partido (solo apunta al script)
└── scripts/
    ├── ajustes.gd         Dificultad (fácil / normal / difícil). Se carga sola
    ├── main_menu.gd       Menú: JUGAR, dificultad, CÓMO JUGAR, SALIR
    ├── cancha.gd          Dibuja césped, líneas, arcos, redes y gradas con gente.
    │                      También crea los muros y los palos
    ├── balon.gd           La pelota: rueda, se frena y rebota
    ├── futbolista.gd      UN jugador cualquiera: dibujo (con número y manitas),
    │                      movimiento, regate, tapar tiros, atajada del arquero
    │                      y la inteligencia de cada rol
    ├── controles_tactiles.gd  Joystick y botones dibujados en pantalla
    ├── hud.gd             Marcador, reloj, franja de fase, mensajes y pausa
    └── partido.gd         Arma los dos equipos de 16 y lleva todo:
                           reloj, descanso, tiempo extra, goles y penales
```

### Medidas de la cancha
- Largo **100 m** (x de -50 a +50) y ancho **64 m** (y de -32 a +32). 1 unidad = 1 metro.
- Arco de **10 m** (el real mide 7,32 m). Es más ancho a propósito: como el balón y
  los jugadores son grandes, con un arco de 7,32 m el arquero taparía todo y no se
  podría meter ni un gol.
- Área de **16,5 m** de fondo y **20 m** para cada lado. Ahí manda el arquero.
- Punto de penal a **11 m**.

### Capas de choque (para que nada se enrede)
- Capa **1**: muros y palos.
- Capa **2**: jugadores (solo chocan con la 1).
- Capa **4**: el balón (solo choca con la 1).

El balón **no choca** con los jugadores: el regate y el "tapar la pateada" se
calculan a mano en `futbolista.gd` (`_tocar_balon` y `_bloquear_balon`). Así se
puede jugar cómodo sin que el balón salte para cualquier lado.

---

## Cosas que se pueden cambiar fácil

| Quiero... | Archivo | Qué tocar |
|---|---|---|
| Que la cámara se acerque o se aleje | `scripts/partido.gd` | `ZOOM_ALTO` (30 = se ven 30 m de alto; más chico = más cerca) |
| Que el partido dure más | `scripts/partido.gd` | `FIN_2T` (90 minutos) |
| Que el descanso dure más | `scripts/partido.gd` | `SEGUNDOS_DESCANSO` |
| Menos rondas de penales | `scripts/partido.gd` | `RONDAS_PENALES` |
| Que el rival sea más lento | `scripts/ajustes.gd` | `VELOCIDAD_RIVAL` |
| Agrandar o achicar el balón | `scripts/balon.gd` | `RADIO` (1.0 = 2 m de ancho) |
| Agrandar a los jugadores | `scripts/futbolista.gd` | `ESCALA` |
| Cuántos jugadores y dónde juegan | `scripts/partido.gd` | `FORMACION` |
| Que el arco sea más grande | `scripts/cancha.gd` | `ANCHO_PORTERIA` |

⚠️ **Si agrandas el balón, agranda el arco también**: si el balón es muy grande,
no cabe entre el arquero y el palo y no se puede meter gol nunca.

---

## Cosas que nos pasaron (para no repetirlas)

1. **En GDScript no se puede usar `:=` cuando el valor viene de algo sin tipo.**
   Ejemplo: en `for s in [-1.0, 1.0]`, la `s` es "Variant" y `var x := s * 2.0` da
   error de compilación. Hay que escribir el tipo: `var x: float = s * 2.0`.
   Lo mismo con `var mio := (dueno != null and dueno.equipo == 0)`.
   Nos pasó **tres veces**. Si el editor dice "Parse Error: Cannot infer the type",
   casi siempre es esto.
2. **El tamaño de la pantalla se pregunta con `get_viewport_rect().size`**, no con
   `size` dentro de `_ready()`. En `_ready()` el Control todavía mide 0 y los
   botones quedaban en cualquier parte (por eso no se podía mover al jugador).
3. **Los lanzadores `.desktop` NO llevan `StartupWMClass=Godot`**: si lo llevan,
   GNOME cree que todos los proyectos son la misma aplicación y abre el que ya
   estaba abierto.
4. **Abrir Godot desde una terminal que se cierra mata el editor.** Usar los
   lanzadores o `gio launch`.
5. **Cuidado al borrar archivos del proyecto desde afuera de Godot**: si borras un
   script que otra escena usa, el juego deja de arrancar. Después de tocar archivos,
   abrir el editor y probar.

---

## Historia del proyecto

1. **Versión 3D** (cámara de televisión, jugadores de cápsulas). Funcionaba, pero
   se veía muy "cuadrada" y para verse bien hacían falta modelos 3D.
   Está guardada en git: `git log` y busca el commit "primera version 3D".
2. **Versión 2D, 1 contra 1** (más limpia y fácil de mejorar).
3. **Versión 2D actual**: 16 contra 16, con puestos, números, arqueros con manitas,
   cambio de jugador, descanso, tiempo extra y penales.

---

Hecho con cariño para jugar en el celular. ⚽
