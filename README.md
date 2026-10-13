# cami26 ⚽

Juego de fútbol para el celular, hecho en **Godot 4.6** por Camilo (con ayuda de su papá).

La cancha se ve **desde arriba**. Tú manejas a un jugador del equipo azul y tienes
que ganarle al equipo rojo. Son **16 jugadores por equipo**, cada uno con su puesto
y su número, como en el fútbol de verdad.

Además del amistoso hay tres modos más, todos en el menú: **CARRERA** (una liga
con tabla de posiciones), **MI PLANTILLA** (armar tu equipo con las cartas que
ganas) y **SOBRES** (la tienda de cartas).

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
- **El balón va PEGADO a los pies** del que lo lleva: se corrige su posición cada
  cuadro, así no se le escapa al correr (antes, con un jugador rápido, el balón
  salía disparado y parecía que se le resbalaba). Un balón que viene fuerte sí
  hay que alcanzarlo primero: no se pega de un solo toque.
- **El arquero se queda pegadito a su línea de gol** (en los dos equipos). Antes
  salía hasta 7 m a tapar el ángulo y era casi imposible anotar. Solo se corre a
  lo largo de la línea, siguiendo el balón, y **solo acompaña la mitad del
  recorrido**: así las esquinas del arco quedan abiertas.
- **Los bots tiran al arco de verdad**: si tienen el balón y están a menos de
  22 m del arco, LE PEGAN (antes primero miraban si había un rival cerca y
  pasaban la pelota, así que casi nunca tiraban). Tiran al lado **contrario** al
  arquero, que es donde está el hueco. De más de 26 m no tiran (el balón frena y
  llega muerto).
- **El balón frena menos** (0,42 en vez de 1,1): un tiro fuerte recorre unos 50 m
  y llega al arco con fuerza. Antes moría a los 19 m, así que los tiros de lejos
  no llegaban nunca.
- **Si le pasas a un compañero, el compañero va a recibir**: cualquier jugador
  que vea venir el balón hacia él (a menos de 26 m) va a buscarlo. Antes solo el
  más cercano lo perseguía y los pases se perdían.
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
│   ├── carrera.tscn       MODO CARRERA (elegir club y jugar la liga)
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
    ├── alineaciones.gd    LA PANTALLA DE ALINEACIONES: antes de jugar muestra
    │                      tus jugadores (tu plantilla) y los del rival
    ├── carrera_liga.gd    LAS CUENTAS DE LA LIGA: el calendario, la tabla de
    │                      posiciones, los partidos simulados y los premios.
    │                      No guarda nada ni dibuja nada: solo calcula
    ├── carrera.gd         LA PANTALLA DE LA CARRERA: elegir club, la tabla y
    │                      los botones de jugar / simular / cobrar
    ├── sobres.gd          Las reglas de los sobres: precios, premios y suerte
    ├── pantalla_sobres.gd La pantalla de sobres: comprar, diario y abrir
    ├── marcas_penal.gd    Dibuja las tres zonas del arco en los penales
    ├── interfaz_penal.gd  El cartel de los penales y los botones del arquero
    ├── texto.gd           Ayuditas de texto (escribir los miles con puntos)
    ├── prueba_cartas.gd   Pantalla de prueba: muestra los 4 niveles de carta
    ├── main_menu.gd       Menú: JUGAR, CARRERA, dificultad, CÓMO JUGAR,
    │                      SOBRES, MI PLANTILLA y SALIR
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
- Arco de **17 m** (el real mide 7,32 m). Es más ancho a propósito, por dos razones:
  como el balón y los jugadores son grandes, con un arco de 7,32 m el arquero taparía
  todo y no se podría meter ni un gol; y además Camilo pidió agrandarlo **1,7 veces**
  más (se empezó con 10 m). El factor está en `FACTOR_ARCO` (`scripts/cancha.gd`).
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

**El progreso está blindado** (esto se añadió después de un susto: una prueba
automática llamó a borrar todo sobre la partida de verdad y se perdieron las
cartas del jugador):

1. **Copia de seguridad automática** (`partida_respaldo.json`): cada vez que se
   avanza, se copia el progreso anterior. Un progreso vacío **no** pisa la copia.
2. **Se recupera solo**: si al abrir el juego la partida está vacía (0 cartas y
   0 de plata) y hay copia con progreso, se carga la copia.
3. **`borrar_todo()` ya no borra por accidente**: solo borra si se le pide a
   propósito con `forzar = true`.
4. **Las pruebas automáticas no tocan la partida de verdad**: ponen
   `Datos.modo_prueba = true` y trabajan sobre otro archivo (`prueba.json`).

⚠️ **Nunca borres `partida_respaldo.json`**: es la red de seguridad de las cartas.

Si algún día cambia el formato, se sube `VERSION` en `scripts/datos.gd` y se
convierte lo viejo dentro de `_aplicar()`. La idea es **no perder nunca** la
partida de un jugador (nos costó aprenderlo).

### Las cartas

Cada carta muestra **6 estadísticas**, como en el FIFA, pero **no son las mismas
para todos**:

| Quién | Las 6 estadísticas |
|---|---|
| **Jugadores de campo** | **VEL** velocidad · **TIR** tiro · **PAS** pase · **REG** regate · **FIS** físico · **RES** resistencia |
| **Arqueros** | **REF** reflejos · **MAN** manos · **ACH** achique · **AER** juego aéreo · **PIE** juego con los pies · **SAQ** saque |

¿Por qué? Porque a un arquero no le sirve el regate ni el tiro. Antes el arquero
usaba las mismas 6 que los de campo (y salía con REG 23, que no dice nada), y
ahora tiene las suyas, que sí se entienden. Las cartas de arquero viejas se
arreglan solas al abrir el juego.

Las estadísticas van de 1 a **119** (el FIFA usa 99, pero aquí las cartas de tu
equipo pueden pasar de 99). El tope está en `MAX_ESTADISTICA`
(`scripts/clubes.gd`).

El **OVR** (el número grande de arriba a la izquierda) **no** es el promedio de
las 6 parejo: se calcula **por puesto**, pesando las estadísticas que de verdad
importan ahí. Si se promediaran todas parejo, los arqueros saldrían siempre
bronce porque no regatean ni tiran.

| Puesto | Qué pesa (y cuánto) |
|---|---|
| **Arquero** | reflejos 25% · manos 25% · achique 25% · juego aéreo 25% (el PIE y el SAQ no cuentan) |
| **Defensa** | físico 30% · resistencia 20% · velocidad 20% · pase 15% · regate 10% · tiro 5% |
| **Medio** | pase 30% · regate 20% · resistencia 20% · velocidad 15% · físico 10% · tiro 5% |
| **Delantero** | tiro 35% · velocidad 25% · regate 25% · físico 8% · resistencia 7% |

Los pesos están en `PESOS_OVR` (`scripts/clubes.gd`) y se pueden cambiar. Los del
arquero se eligieron con cuidado para que **ningún arquero cambie de nivel** al
pasar a las estadísticas nuevas.

El **nivel** lo decide el OVR: **bronce** hasta 74, **plata** de 75 a 82 y
**oro** de 83 para arriba. Así queda el reparto con los 342 jugadores: **26%
bronce · 61% plata · 13% oro** (hay más oro que antes por el club de las
Leyendas). De vez en cuando sale además una **especial** (brillante): es una carta
de oro, pero con la piel morada y dorada.

La parte bonita de la carta (el fondo, el borde y el reflejo) son imágenes PNG que
se **dibujan por código**, sin usar ninguna imagen ni diseño de FIFA:

```bash
python3 herramientas/generar_cartas.py
```

Si quieres cambiar los colores, se tocan en `ESTILOS` (arriba del todo del script)
y se vuelven a generar. Godot solo escribe encima los datos: el OVR, el puesto, el
nombre, el club y las 6 estadísticas.

### El pase, el regate y las estadísticas del arquero (¡son inventados!)

Ninguna estadística sale de una base de datos real (¡son todas inventadas!), pero
el **pase** y el **regate** de los jugadores de campo, y las 6 estadísticas
propias de los arqueros, las calcula una herramienta con una regla fija, no al
azar:

```bash
python3 herramientas/agregar_estadisticas.py --revisar   # solo muestra cómo quedan
python3 herramientas/agregar_estadisticas.py             # y los escribe
```

La regla: una base por puesto (un medio pasa mejor que un defensa, un delantero
regatea mejor que un arquero) y un ajuste según su velocidad y su tiro, más un
toque chiquito por jugador para que no queden todos iguales. Las 6 estadísticas
del arquero salen de sus viejas 6 (físico, resistencia, velocidad y pase), y la
herramienta se encarga de borrarle las viejas para que no queden dos juegos de
estadísticas en la misma ficha. Es estable: si se corre otra vez, no cambia nada.
Los cortes de nivel están allí (`CORTE_PLATA`, `CORTE_ORO`) y son los mismos de
`scripts/cartas.gd`.

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

### Las alineaciones (antes de cada partido)

Al darle a **JUGAR** (o al jugar una fecha de la carrera) primero sale una
pantalla con las **alineaciones**: a la izquierda tus jugadores y a la derecha
los del rival, con su puesto, su club y su **OVR**. Cualquier toque arranca el
partido.

- Si tienes **plantilla armada** (MI PLANTILLA), se muestran **tus 11 cartas**
  con el OVR del equipo.
- Si todavía no armaste plantilla, se muestra el equipo de siempre (los que
  juegan hoy en la cancha).
- Si el partido es de la **carrera**, el rival sale con la **plantilla de verdad
  de ese club** (con su formación y su liga).

### MODO CARRERA (la liga)

El menú tiene un botón **CARRERA**. Es una liga de verdad, con tabla de
posiciones:

- **Eliges tu club** entre los 21 (los 20 de LaLiga y las Leyendas).
- Son **21 fechas** (una sola vuelta, todos contra todos, 10 partidos por fecha
  porque siempre hay uno que descansa). Son 21 clubes: cada uno juega 20 partidos
  y descansa una fecha. Cuando te toca descansar, la pantalla te lo dice.
- **Tu partido lo juegas tú**; los otros 9 los simula la compu. Si no tienes
  ganas, el botón **SIMULAR LA FECHA** juega también el tuyo.
- En la liga **el empate vale**: si vas empatado al minuto 90 el partido termina
  1-1 y cada uno se lleva 1 punto (no hay tiempo extra ni penales, como en una
  liga de verdad). En un amistoso sigue habiendo tiempo extra y penales.
- Al final hay **premio según el puesto**: 1º → 20.000 moneditas + 500 gemas + 3
  cartas; 2º a 4º → 10.000 + 250 + 2 cartas; 5º a 10º → 5.000 + 100 + 1 carta;
  del 11º para abajo → 2.000 moneditas.
- Ganar un partido de liga da el mismo sobre que ganar un amistoso (1 jugador +
  200 gemas + 1.000 moneditas), y después la pantalla de sobres te devuelve a la
  carrera.

La liga se guarda sola: puedes cerrar el juego y seguir después en la misma
fecha. Cuando termines, el botón **JUGAR OTRA TEMPORADA** arranca una nueva (con
otro calendario) y **CAMBIAR DE CLUB** te deja empezar de cero con otro equipo.

Cómo se simulan los partidos que no juegas: cada club tiene una **fuerza** (el
promedio de OVR de sus 11 titulares) y el resultado sale de la diferencia de
fuerza, con un poquito de suerte y con la ventaja de jugar en casa. Los números
están en `scripts/carrera_liga.gd` (`GOLES_PROMEDIO`, `FUERZA_POR_GOL`,
`VENTAJA_LOCAL`) y con ellos salen unos **2,6 goles por partido**, como en la
vida real.

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
mano. Son **21 clubes**: los 20 de LaLiga y un club inventado, **Leyendas**, con
16 cracks de la historia (Maradona, Pelé, Ronaldinho, Ronaldo Nazário, Zidane,
Yashin…). Arda Güler va con el Real Madrid, que es su equipo de verdad. Las
reglas son:

- La plantilla va **en orden**: los **11 primeros son los titulares** y los que
  siguen forman el banquillo.
- Cada jugador usa claves cortas: `n` nombre, `p` puesto, `d` dorsal, y después
  **6 estadísticas según el puesto** (todas de 1 a 119):
  - Jugadores de campo: `v` velocidad, `t` tiro, `pas` pase, `reg` regate,
    `f` físico y `r` resistencia.
  - Arqueros: `ref` reflejos, `man` manos, `ach` achique, `aer` juego aéreo,
    `pie` juego con los pies y `saq` saque.
- El **OVR no se guarda**: se calcula solo, pesando las estadísticas del puesto
  (ver `PESOS_OVR`).
- Los puestos que existen son `POR`, `LD`, `LI`, `DFC`, `MCD`, `MC`, `MCO`,
  `MD`, `MI`, `ED`, `EI`, `DC` y `SD`. Cada uno sabe a qué rol del partido
  corresponde (ver `ROLES` en `scripts/clubes.gd`).

Para revisar el archivo sin abrir el editor, se puede llamar a
`Clubes.validar()`: devuelve la lista de problemas (dorsales repetidos, nombres
repetidos, estadísticas fuera de 1-119, un club sin arquero...).

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
| Cuántos goles se meten en la liga | `scripts/carrera_liga.gd` | `GOLES_PROMEDIO` (1,3 por equipo) |
| Cuánta ventaja da jugar en casa | `scripts/carrera_liga.gd` | `VENTAJA_LOCAL` (2,5 de fuerza) |
| Los premios de la carrera | `scripts/carrera_liga.gd` | `PREMIOS` (`[hasta qué puesto, monedas, gemas, cartas]`) |

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
16. **NUNCA probar con `user://partida.json` (la partida de verdad).** Una prueba
    automática llamó a `borrar_todo()` y se llevaron por delante las cartas del
    jugador: no había copia de seguridad y se perdieron. Desde entonces:
    las pruebas ponen `Datos.modo_prueba = true` (y usan `prueba.json`),
    `borrar_todo()` solo borra si se lo piden a propósito, y hay respaldo +
    recuperación automática (ver *El guardado*). **Las partidas de los jugadores
    no se tocan para probar.**
17. **Los botones que "no hacen nada" casi siempre son eventos que no llegan.**
    El de TIRO no funcionaba porque un toque cortito se perdía entre dos cuadros.
    Antes de culpar al dibujo o a la lógica, comprobar que el toque llegue.
18. **El arquero no puede "seguir el balón" en el partido normal.** Si se mueve
    para tapar el ángulo, tapa todo y no se puede anotar. En los penales ya se
    había resuelto con zonas; en el partido se resuelve quedándose en la línea.
19. **Si el balón frena mucho, los tiros de lejos no llegan.** Con `FRENADO = 1,1`
    un tiro fuerte moría a los 19 m y por eso era tan difícil meter gol. Ahora
    frena menos (0,42) y los bots solo tiran cuando están a tiro (26 m o menos).
20. **Medir con el reloj, no con los cuadros, y ojo con el final del partido.**
    En headless el motor corre a otra velocidad, y al terminar el partido la
    escena cambia y libera el nodo: la prueba se queda colgada leyendo un nodo
    que ya no existe. Se para antes (`while is_instance_valid(p) and ...`).

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

### Las fases (por dónde va)

| Fase | Qué trajo |
|---|---|
| 0 | El guardado del progreso y los 20 clubes de LaLiga |
| 1 | Las cartas de jugador (bronce, plata, oro y especial) |
| 2 | Los sobres y la economía |
| 3 | MI PLANTILLA (el Ultimate Team, con arrastrar cartas) |
| 3,5 | Los arqueros con SUS estadísticas (reflejos, manos, achique…) y el club Leyendas |
| 4 | **EL MODO CARRERA**: la liga, la tabla de posiciones y los premios |
| 4,5 | Las alineaciones antes de jugar, el arco más grande (17 m), el arquero en su línea, los bots que tiran y el balón que no se resbala |

Lo que viene (si Camilo quiere): el mercado para comprar y vender cartas, subirle
estadísticas a una carta con moneditas, y los escudos de los clubes.

---

Hecho con cariño para jugar en el celular. ⚽
