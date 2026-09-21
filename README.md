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
| **Joystick** (izquierda) | Mover al jugador. Si lo empujas **hasta el fondo**, el jugador **esprinta** |
| **TIRO** (rojo) | **Mantenlo apretado para cargar la potencia** (sale la barra de abajo, de 1 a 10) y suéltalo para patear |
| **PASE** (azul) | Pase a un compañero: busca al mejor (que esté adelante y sin marca). Si no hay, toca suave hacia adelante |
| **CAMBIAR** (amarillo) | Pasar a manejar otro jugador de tu equipo (el que esté más cerca del balón). **Si el balón está en tu área, también puedes pasar a manejar al arquero** |

El jugador que manejas tiene un **aro amarillo**. Los demás juegan solos.

### En la compu (para probar)
| Acción | Tecla |
|---|---|
| Mover | `W` `A` `S` `D` o las flechas |
| Tiro (mantener = cargar) | `Espacio` |
| Pase | `P` (o `E`) |
| Esprintar | `Shift` |
| Cambiar de jugador | `Q` o `Tab` |

Si manejas al **arquero**: `Espacio` es **atajar** y `Shift` es la **barrida**
para llegar a la pelota. Con el balón en las manos, mantén `Espacio` para cargar
el despeje y suéltalo para reventarla.

El mouse funciona como si fuera el dedo, porque en `project.godot` está activado
`input_devices/pointing/emulate_touch_from_mouse`.

---

## Las reglas

- **90 minutos** de reloj. Ojo: **1 segundo de verdad = 1 minuto de juego**,
  así que el partido dura 90 segundos.
- Al **minuto 45 hay descanso** y el reloj se para **10 segundos**.
- Si van **empatados al 90**, hay **tiempo extra hasta el 120**.
- Y si siguen empatados... **¡8 rondas de penales!**
  El penal se tira **desde el punto de penal** (a 11 m del arco), tú apuntas con
  el joystick (arriba o abajo) y disparas con TIRO. El arquero **se queda clavado
  en la línea hasta que pateas** (regla del fútbol de verdad) y recién ahí se
  puede mover para atajar.

Cada equipo juega con esta formación (16 jugadores):

```
                    ( 9 )  (13)          delanteros
   (11)                               (7)   extremos izq. y der.
             (10)                          enganche
        (15)        (16)                    medio centro izq. y der.
   (12)                    (14)              volantes
              ( 8 )                          mediocentro
   ( 3 )   ( 5 )   ( 6 )   ( 4 )   ( 2 )     5 defensas
                    ( 1 )                     arquero
```

## Lo que es como el fútbol de verdad

- **El balón se puede ir afuera.** Ya no hay paredes que lo frenen: si lo tiran
  mal, sale de la cancha y hay saque.
- **Saca el equipo contrario al que la tocó de última**, como manda la regla:
  - Por la **banda** → **saque de banda**, desde el mismo lugar donde salió.
  - Por la **línea de fondo**:
    - Si la tiró afuera el que **atacaba** → **saque de arco** (la saca el arquero).
    - Si la tocó el que **defendía** → **¡tiro de esquina!**
- Mientras se acomoda el saque, **los del otro equipo se alejan y no pueden tocar
  el balón**: hasta que el saque se hace, la pelota está "fuera de juego". Así los
  bots no te caen encima.
- **El saque de banda lo haces tú y CON LAS MANOS**: te quedas parado en la línea
  (no puedes caminar), **apuntas con el joystick** y lanzas con **TIRO** (fuerte) o
  **PASE** (suave). En la compu, el joystick es `W A S D`.
- Si el saque es del rival, lo hace **un bot solo** (también con las manos).
- El córner y el saque de arco se hacen con el pie, como en la vida real.
- **El arquero no atrapa todo**: si el pelotazo viene fuerte, la **rechaza** y el
  balón queda vivo (rebote); si viene suave, la agarra con las manos y después
  la despeja buscando un compañero.
- **El balón rebota en los palos.**
- **Las IA también pasan**: si un rival se les viene encima, le sueltan el balón
  a un compañero que esté adelante y sin marca.
- **No se amontonan**: además de cada uno quedarse en su puesto, los jugadores se
  "empujan" suavemente entre ellos para no quedar todos apelotonados.
- Con el balón en los pies se corre un poco más lento (por eso te alcanzan).

## La potencia del tiro

Manteniendo apretado **TIRO** (o `Espacio`) se carga la potencia y aparece la
barra abajo: **mínimo 1, máximo 10**.

| Potencia | Qué pasa |
|---|---|
| **1 a 3** | Toque suave y muy preciso |
| **4 a 7** | Buen tiro, un poco de desvío |
| **8 a 10** | Un misil, pero se puede ir **afuera** (como cuando le pegas muy fuerte y se va arriba del arco) |

Si un tiro se va afuera, el juego cobra el saque que corresponde.

## Faltas, amarillas y penales

- Si un rival **te atropella** (o tú a él), es **FALTA**.
- Si la falta es **dentro del área**, es **¡PENAL!** (se cobra desde el punto de penal).
- Todo el mundo se aleja del balón mientras se cobra la falta (como la regla de
  los 9,15 m) y nadie puede tocar el balón hasta que se haga el cobro.
- Las IA **no se te tiran encima**: cuando te tienen el balón se arriman con
  cuidado, porque si no les cobran falta.
- Al **arquero que tiene el balón en las manos no se le puede quitar**: el que se
  le arrime se lleva **TARJETA AMARILLA**.

## Los puestos y los números

| Número | Puesto | Qué hace |
|---|---|---|
| **1** | Arquero | Usa las **manitas** (un tercio de su tamaño) para tapar el arco. **Sigue al balón siempre**: se para entre el balón y el arco, y si el balón se acerca sale un poco a tapar el ángulo. Atrapa el balón y lo despeja. **No puede salir del área.** |
| **2, 3** | Laterales | El 2 por la derecha y el 3 por la izquierda. |
| **4, 5** | Centrales | Marcan a los delanteros rivales. |
| **6** | Líbero | El quinto defensor, queda atrás de los centrales. |
| **8** | Mediocentro | El que corta el juego delante de los defensas. |
| **15, 16** | Medio centro izq. y der. | Ayudan en el medio y acompañan el ataque. |
| **12, 14** | Volantes | Corren por las bandas, un poco más atrasados. |
| **10** | Enganche | El que arma el juego, va entre los medios y los delanteros. |
| **7, 11** | Extremos | El 7 por la derecha y el 11 por la izquierda. Van a desbordar y centrar. |
| **9, 13** | Delanteros | Los que van arriba a hacer los goles. |

Los **defensas** se ponen entre el atacante rival y tu arco y **tapan los tiros**
con el cuerpo. Los **medios** presionan al que tiene el balón y los **delanteros**
buscan el arco rival.

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
- Largo **120 m** (x de -60 a +60) y ancho **76 m** (y de -38 a +38). 1 unidad = 1 metro.
  (Es más grande que una cancha de verdad, de 105 x 68 m, para que quepan 32 jugadores
  sin que se amontonen.)
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
| Que la cámara se acerque o se aleje | `scripts/partido.gd` | `ZOOM_ALTO` (36 = se ven 36 m de alto; más chico = más cerca) |
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
3. **Versión 2D actual**: 16 contra 16, con puestos y números con sentido, arqueros
   con manitas que atajan y siguen al balón, cambio de jugador, tapar pateadas,
   pases de la IA, balón que se va afuera con saques de banda, córner y saque de
   arco, descanso, tiempo extra y 8 rondas de penales (con el arquero quieto
   hasta que pateen, como manda la regla).

---

Hecho con cariño para jugar en el celular. ⚽
