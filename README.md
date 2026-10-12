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
| **TIRO** (rojo) | **Un toque**: el balón sale ya, con toque suave. **Manteniéndolo apretado**: se carga la potencia (sale la barra de abajo, de 1 a 10) y sale más duro... pero menos preciso |
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

- El marcador muestra los **90 minutos** de un partido de verdad, pero el partido
  dura **160 segundos de verdad**: en cada segundo real el reloj avanza 33,75
  segundos de juego, así que llega al minuto 90 justo al final. (Antes duraba
  90 segundos y el reloj corría a 1 minuto por segundo.)
- Al **minuto 45 hay descanso** y el reloj se para **10 segundos**.
- Si van **empatados al 90**, hay **tiempo extra hasta el 120**.
- Y si siguen empatados... **¡8 rondas de penales!**

### Los penales, con zonas

El arco se agranda (de 10 m a **18 m**) y se parte en **tres zonas**: arriba,
el centro y abajo. El balón queda **en los pies del pateador**, en el punto de
penal (a 11 m del arco).

- **Si tiras tú:** eliges la zona moviendo el joystick (arriba/abajo) y la que
  elijas se ve **encendida en el arco**. Después, **TIRO**: un toque tira ya;
  mantener apretado carga la fuerza (y a más fuerza, más se puede desviar).
- **El arquero rival NO sabe para dónde va:** elige su zona **al azar en el
  momento del tiro**. Si se tira a tu zona, ataja; si no, es gol.
- **Si tira el rival:** el arquero es tuyo y lo mandas **tú** con los tres
  botones (ARRIBA, CENTRO y ABAJO). Si no eliges en **4 segundos**, se tira al
  azar. Después de que se tire, el rival patea en un ratito.

Así el penal es un duelo de "¿a dónde te tiras?": 1 de cada 3 se ataja si el
arquero acierta la zona.

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
├── datos/
│   ├── clubes.json        LaLiga: los 20 clubes con su plantilla, táctica y colores
│   ├── cartas/            Las pieles de las cartas y el sobre (PNG), por código
│   └── escudos/           Los escudos de los clubes (se llenan en otra fase)
├── herramientas/
│   └── generar_cartas.py  Dibuja y guarda los PNG de las cartas y del sobre
├── scenes/
│   ├── main_menu.tscn     Escena que arranca (el menú)
│   ├── partido.tscn       Escena del partido (solo apunta al script)
│   ├── sobres.tscn        La pantalla de los sobres (tienda y sobre abierto)
│   ├── plantilla.tscn     MI PLANTILLA (armar el equipo con las cartas)
│   └── prueba_cartas.tscn Pantalla de prueba de las cartas (fuera del menú)
└── scripts/
    ├── ajustes.gd         Dificultad (fácil / normal / difícil). Se carga sola
    ├── datos.gd           El progreso: monedas, gemas, cartas y carrera.
    │                      Se carga sola y se guarda en user://partida.json
    ├── clubes.gd          Lee datos/clubes.json: los clubes, las plantillas
    │                      (titulares y banquillo) y el OVR de cada jugador
    ├── cartas.gd          Las cartas: el nivel (bronce/plata/oro/especial),
    │                      la piel que le toca a cada una y las cartas al azar
    ├── tarjeta.gd         Dibuja UNA carta grande: el OVR y el puesto arriba a
    │                      la izquierda, el avatar, el nombre, el club y las 6 stats
    ├── mini_carta.gd      La carta chiquita de la plantilla (y la que se arrastra)
    ├── plantilla.gd       MI PLANTILLA: los 11 huecos, el banquillo, arrastrar
    │                      las cartas, las formaciones y el promedio del equipo
    ├── cancha_mini.gd     La cancha dibujada de la pantalla de plantilla
    ├── sobres.gd          Las reglas de los sobres: precios, premios y suerte
    ├── pantalla_sobres.gd La pantalla de sobres: comprar, diario y abrir
    ├── marcas_penal.gd    Dibuja las tres zonas del arco en los penales
    ├── interfaz_penal.gd  El cartel de los penales y los botones del arquero
    ├── texto.gd           Ayuditas de texto (escribir los miles con puntos)
    ├── prueba_cartas.gd   Pantalla de prueba: muestra los 4 niveles de carta
    ├── main_menu.gd       Menú: JUGAR, dificultad, CÓMO JUGAR, SOBRES, SALIR
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
- **En los penales el arco se agranda a 18 m** (con `poner_arco()`), para que
  quepan las tres zonas de tiro sin que el arquero tape dos de una sola tirida.

### Capas de choque (para que nada se enrede)
- Capa **1**: muros y palos.
- Capa **2**: jugadores (solo chocan con la 1).
- Capa **4**: el balón (solo choca con la 1).

El balón **no choca** con los jugadores: el regate y el "tapar la pateada" se
calculan a mano en `futbolista.gd` (`_tocar_balon` y `_bloquear_balon`). Así se
puede jugar cómodo sin que el balón salte para cualquier lado.

---

## El progreso, las cartas y los clubes

### El guardado

El progreso (monedas, gemas, cartas y la carrera) se guarda solo en
`user://partida.json`. En Linux eso es
`~/.local/share/godot/app_userdata/cami26/partida.json`.

Si algún día cambia el formato, se sube `VERSION` en `scripts/datos.gd` y se
convierte lo viejo dentro de `_aplicar()`. La idea es **no perder nunca** la
partida de un jugador.

### Las cartas

Cada carta muestra **6 estadísticas**, como en el FIFA: **VEL** velocidad,
**TIR** tiro, **PAS** pase, **REG** regate, **FIS** físico y **RES** resistencia
(todas de 1 a 99).

El **OVR** (el número grande de arriba a la izquierda) **no** es el promedio de
las 6 parejo: se calcula **por puesto**, pesando las estadísticas que de verdad
importan ahí. Si se promediaran todas parejo, los arqueros saldrían siempre
bronce (Courtois quedaría en 53) porque no regatean ni tiran.

| Puesto | Qué pesa (y cuánto) |
|---|---|
| **Arquero** | físico 45% · resistencia 40% · pase 15% |
| **Defensa** | físico 30% · resistencia 20% · velocidad 20% · pase 15% · regate 10% · tiro 5% |
| **Medio** | pase 30% · regate 20% · resistencia 20% · velocidad 15% · físico 10% · tiro 5% |
| **Delantero** | tiro 35% · velocidad 25% · regate 25% · físico 8% · resistencia 7% |

Los pesos están en `PESOS_OVR` (`scripts/clubes.gd`) y se pueden cambiar.

El **nivel** lo decide el OVR: **bronce** hasta 74, **plata** de 75 a 82 y
**oro** de 83 para arriba. Así queda el reparto con los 325 jugadores: **27%
bronce · 63% plata · 9% oro**. De vez en cuando sale además una **especial**
(brillante): es una carta de oro, pero con la piel morada y dorada.

La parte bonita de la carta (el fondo, el borde y el reflejo) son imágenes PNG que
se **dibujan por código**, sin usar ninguna imagen ni diseño de FIFA:

```bash
python3 herramientas/generar_cartas.py
```

Si quieres cambiar los colores, se tocan en `ESTILOS` (arriba del todo del script)
y se vuelven a generar. Godot solo escribe encima los datos: el OVR, el puesto, el
nombre, el club y las 6 estadísticas.

### El pase y el regate (¡son inventados!)

Las 6 estadísticas son inventadas (ninguna sale de una base de datos real), pero
el **pase** y el **regate** los calcula una herramienta con una regla fija, no al
azar:

```bash
python3 herramientas/agregar_estadisticas.py --revisar   # solo muestra cómo quedan
python3 herramientas/agregar_estadisticas.py             # y los escribe
```

La regla: una base por puesto (un medio pasa mejor que un defensa, un delantero
regatea mejor que un arquero) y un ajuste según su velocidad y su tiro, más un
toque chiquito por jugador para que no queden todos iguales. Si algún día se
cambian los cortes de nivel, hay que cambiarlos también allí (`CORTE_PLATA`,
`CORTE_ORO`).

Para ver las cartas sin jugar un partido hay una pantalla de prueba (ya no está en
el menú, pero se puede abrir directo):

```bash
godot --path . res://scenes/prueba_cartas.tscn
```

### MI PLANTILLA (armar el equipo)

Es la pantalla donde viven las cartas: **MI PLANTILLA**, en el menú principal
(`scripts/plantilla.gd`).

- A la izquierda, la lista de tus cartas (con filtro por puesto). Las que ya
  están en el equipo se ven con un toque verde.
- A la derecha, la cancha con los **11 huecos** de la formación, y abajo el
  **banquillo** (7 huecos).
- Se arma **arrastrando**: se agarra una carta de la lista y se suelta en un
  hueco. También funciona **tocando y tocando** (plan B, por si el dedo no
  arrastra bien): se toca una carta y después el hueco, o al revés.
- Si se suelta una carta sobre un hueco que ya tiene otra, **se cambian de
  lugar**. Si se suelta sobre la lista, la carta vuelve a quedar libre.
- **La única regla**: en el hueco del arco solo puede ir un arquero, y un
  arquero no puede jugar de campo. Todo lo demás va donde quieras (así lo pidió
  Camilo: "sencillo").
- Arriba se ve el **promedio del equipo** (el promedio de las cartas que
  pusiste) y el botón para **cambiar de formación** (4-3-3, 4-4-2 y 3-5-2).

La plantilla se guarda sola en el progreso, con la posición de cada carta en el
inventario, así que al volver está como la dejaste.

### Los sobres

Las reglas están en `scripts/sobres.gd` y la pantalla en
`scripts/pantalla_sobres.gd`. Un sobre se consigue de tres formas:

| Cómo | Qué trae |
|---|---|
| **Ganando un partido** | 1 jugador + **200 gemas** + **1.000 moneditas** |
| **El sobre diario** (uno por día) | 1 jugador + **200 gemas** + **1.000 moneditas** |
| **Comprándolo** | **Solo el jugador** (sin gemas ni moneditas) |

- Cuesta **200 gemas** o **5.000 moneditas**.
- Probabilidades: **bronce 55% · plata 34% · oro 10% · especial 1%**.
- La carta **especial** es una de oro (OVR 75 o más) con la piel brillante.

⚠️ **Ojo con un detalle que parece pequeño y no lo es:** el sobre COMPRADO no puede
traer las 200 gemas. Si las trajera, saldría gratis (pagas 200 y te devuelven 200) y
se podrían sacar cartas infinitas sin jugar. Por eso la plata solo viene en los
sobres ganados y en el diario.

Para probar la pantalla sin jugar un partido:

```bash
godot --path . res://scenes/sobres.tscn
# y para ver cómo queda un sobre abierto:
godot --path . res://scenes/sobres.tscn -- --simular-premio
```

### Los clubes

Están en `datos/clubes.json`, que es un archivo de texto que se puede editar a
mano. Las reglas son:

- La plantilla va **en orden**: los **11 primeros son los titulares** y los que
  siguen forman el banquillo.
- Cada jugador usa claves cortas: `n` nombre, `p` puesto, `d` dorsal, y
  `v` velocidad, `t` tiro, `f` físico, `r` resistencia (todas de 1 a 99).
- El **OVR no se guarda**: se calcula solo, como el promedio de las cuatro.
- Los puestos que existen son `POR`, `LD`, `LI`, `DFC`, `MCD`, `MC`, `MCO`,
  `MD`, `MI`, `ED`, `EI`, `DC` y `SD`. Cada uno sabe a qué rol del partido
  corresponde (ver `ROLES` en `scripts/clubes.gd`).

Para revisar el archivo sin abrir el editor, se puede llamar a
`Clubes.validar()`: devuelve la lista de problemas (dorsales repetidos, nombres
repetidos, estadísticas fuera de 1-99, un club sin arquero...).

⚠️ Las plantillas y los dorsales de verdad **cambian cada temporada**: los datos
de aquí son un punto de partida editable, no una verdad absoluta.

---

## Cosas que se pueden cambiar fácil

| Quiero... | Archivo | Qué tocar |
|---|---|---|
| Que la cámara se acerque o se aleje | `scripts/partido.gd` | `ZOOM_ALTO` (36 = se ven 36 m de alto; más chico = más cerca) |
| Que el partido dure más | `scripts/partido.gd` | `PARTIDO_REAL` (160 s de verdad para 90 minutos) |
| Que el arco de los penales sea más ancho | `scripts/partido.gd` | `ARCO_PENAL` (18 m) |
| Dónde quedan las zonas del penal | `scripts/partido.gd` | `ZONA_FRACCION` (0,55 = al 55% de la mitad del arco) |
| Cuánto tienes para elegir la tirida del arquero | `scripts/partido.gd` | `SEGUNDOS_DECISION` (4 s) |
| Que el descanso dure más | `scripts/partido.gd` | `SEGUNDOS_DESCANSO` |
| Menos rondas de penales | `scripts/partido.gd` | `RONDAS_PENALES` |
| Que el rival sea más lento | `scripts/ajustes.gd` | `VELOCIDAD_RIVAL` |
| Agrandar o achicar el balón | `scripts/balon.gd` | `RADIO` (1.0 = 2 m de ancho) |
| Agrandar a los jugadores | `scripts/futbolista.gd` | `ESCALA` |
| Cuántos jugadores y dónde juegan | `scripts/partido.gd` | `FORMACION` |
| Que el arco sea más grande | `scripts/cancha.gd` | `ANCHO_PORTERIA` |
| Cuánto cuesta un sobre | `scripts/sobres.gd` | `COSTO_GEMAS` y `COSTO_MONEDAS` |
| Qué tan seguido sale cada nivel | `scripts/sobres.gd` | `NIVELES` (las probabilidades, tienen que sumar 1.0) |
| Qué trae un sobre ganado | `scripts/sobres.gd` | `MONEDAS_DEL_SOBRE` y `GEMAS_DEL_SOBRE` |
| A partir de qué OVR algo es plata u oro | `scripts/cartas.gd` | `OVR_PLATA` y `OVR_ORO` |
| Cuánto pesa cada estadística en el promedio | `scripts/clubes.gd` | `PESOS_OVR` |
| Las formaciones de la plantilla | `scripts/plantilla.gd` | `FORMACIONES` |
| Cuántos van al banquillo | `scripts/plantilla.gd` | `BANQUILLO` |

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
6. **Al crear un script nuevo con `class_name`, Godot no lo conoce todavía.** Si se
   corre el juego desde la terminal, sale
   `Parse Error: Identifier "Cartas" not declared in the current scope`. No es un
   error del código: es que falta la caché de clases. Se arregla abriendo el editor
   una vez, o con `godot --headless --path . --import`, que la regenera.
7. **Un nodo que se dibuja a mano (`_draw`) no se vuelve a pintar solo.** Hay que
   pedirlo con `queue_redraw()`. Las marcas de las zonas del penal no se veían
   nunca: dibujaban una sola vez, cuando todavía estaban apagadas. Si algo se
   dibuja por código y no aparece, esto es lo primero que hay que mirar.
8. **Apagar SIEMPRE las marcas de "el balón está en las manos" al empezar un
   penal.** Si el arquero se quedaba con el balón agarrado de un penal, en el
   siguiente el balón se le pegaba a las manos y parecía que aparecía "en el
   arquero". Ahora cada penal reinicia a los jugadores con
   `reiniciar_para_penal()`.
9. **Con un balón de 2 m y un arquero que llega a 2,87 m, el arco tiene que ser
   bien ancho para que haya tres zonas de verdad.** Con el arco de 10 m, el
   arquero parado en el centro tapaba las zonas de los lados. Por eso el arco de
   los penales es de 18 m y las zonas van al 55%: así la tirida del arquero tapa
   **solo su zona** (se comprobó con las 9 combinaciones de tiro y tirida).
10. **Un toque corto se puede perder entre dos cuadros.** El botón de TIRO se
    aprieta y se suelta antes de que corra la física, así que el jugador leía
    "no está apretado" y no pateaba nunca: el botón parecía no funcionar. Se
    arregla guardando el toque en una marca (`disparo_toque`) que el jugador
    consume.
11. **En headless el juego corre a ~155 cuadros por segundo.** Si una prueba
    espera "400 cuadros" creyendo que son 6 segundos, en realidad espera 2,6 s y
    falla. Para medir tiempos, usar reloj de verdad (`Time.get_ticks_msec()`).
12. **Cambiar las estadísticas de las cartas obliga a migrar las guardadas.** Al
    pasar de 4 estadísticas a 6, las cartas que ya estaban en el progreso
    mostraban PAS 0 y REG 0 (y su OVR viejo). Ahora `Datos._actualizar_cartas()`
    las rehace desde `clubes.json` al cargar: nunca hay que borrarle la partida a
    nadie.
13. **En Godot, inferir el tipo de un valor que viene de algo sin tipo es un
    ERROR en este proyecto** (el aviso viene como error): `var x := f()` cuando
    `f()` devuelve Variant no compila. Se escribe `var x: Variant = f()` o,
    mejor, se le pone tipo a la función.
14. **Ojo al probar con dos pantallas a la vez**: la que se agrega última se
    queda con los clics, así que un arrastre simulado termina en la otra pantalla
    (y parece que no funciona). Al probar, una sola pantalla en el árbol.
15. **Al refrescar una lista se liberan los nodos viejos.** Si la prueba se
    guardó una fila y después lee `fila.indice`, está leyendo un nodo liberado.

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
