# GC Stretch — estirar grupos y componentes en SketchUp

Extensión de SketchUp (2017 o posterior, Windows y Mac) con dos herramientas para
alargar o acortar un objeto **sin deformar lo que no hace falta**: las patas, los
tiradores, los perfiles y los cantos conservan su medida.

Está inspirada en el funcionamiento de dos extensiones conocidas (el estirado por
caja de FredoScale y Curic Stretch), pero el código es propio y no usa nada de ellas.

## Instalar

1. En SketchUp: **Extensiones › Gestor de extensiones › Instalar extensión**.
2. Elegir `dist/gc_stretch.rbz`.
3. Aparecen la barra **GC Stretch** (dos botones) y el menú **Extensiones › GC Stretch**.

## La idea de fondo

Escalar multiplica todas las medidas: si un mueble de 100 pasa a 150, sus patas
también engordan un 50 %. **Estirar** es otra cosa: se elige una parte de los
vértices y se **desplaza** una distancia; el resto no se mueve. Solo se alarga lo
que une las dos partes.

Las dos herramientas hacen exactamente eso, y solo se diferencian en **cómo se
eligen los vértices que se mueven**:

| | Estirar por caja | Estirar por ventana |
|---|---|---|
| Se mueve… | todo lo que queda a un lado de un plano divisor | lo que se encierra en una ventana dibujada en pantalla |
| Dirección | a lo largo de un eje de la caja | cualquiera, de punto a punto, como Mover |
| Pensada para | cambiar una medida total (largo, ancho, alto) | mover un extremo, una esquina o un detalle concreto |

En ambas, los grupos y componentes anidados se tratan igual, nivel a nivel:

- **entero dentro** de la zona que se mueve → se desplaza tal cual, sin tocarlo;
- **a caballo** → se abre y se repite la regla con lo que tiene dentro;
- **fuera** → no se toca.

Si un componente que se va a deformar tiene copias, antes se hace **único** para
que las demás copias no cambien. Se puede desactivar en el menú (*Hacer únicos los
componentes que se deformen*); entonces cambian todas las copias y la vista previa
se pinta en rojo para avisar.

## Estirar por caja

1. Selecciona un grupo o componente (o haz clic en él con la herramienta activa).
2. Aparece una caja naranja con un **tirador verde** en cada cara, un **tirador
   azul** en cada esquina y un **plano divisor morado** en el centro.
3. Haz clic en un tirador, mueve el ratón y vuelve a hacer clic (o pulsa, arrastra
   y suelta). Se mueve lo que hay entre el divisor y ese tirador.

- **Tiradores de esquina**: estiran varios ejes a la vez (largo, ancho y alto),
  cada uno con su propio divisor; al pasar por una esquina se ven los tres
  planos. Con el ratón la esquina se desliza por la cara de la caja que mejor se
  ve desde la cámara, así que cambian dos medidas; la tercera cambia si ajustas
  el cursor a un punto o arista del modelo, o si escribes las medidas. Al
  escribir, una sola medida vale para todos los ejes (`100`) y varias separadas
  por punto y coma van en orden rojo; verde; azul (`100; 0; 50`, o las finales
  `=2400; 600; 900`).

- **Medida exacta**: mientras estiras, escribe cuánto debe crecer (`300`, o `-300`
  para acortar) o la medida final con un igual delante (`=2400`). La tecla Tab abre
  un cuadro para la medida final.
- **Mover el divisor**: haz clic en su borde, muévelo (se ajusta a los puntos del
  modelo) y haz clic; también puedes escribir su distancia al borde de la caja.
  Doble clic en el borde lo devuelve al centro. Colócalo donde no corte nada que
  no deba deformarse.
- **Simétrico**: Ctrl (Opción en Mac) hace que se abran los dos lados a la vez.
- **Ejes**: con un solo objeto la caja sigue los ejes del objeto, aunque esté
  girado. Flecha arriba = ejes del modelo; flecha abajo = ejes del objeto.
- Esc cancela; un segundo Esc quita la selección.

## Estirar por ventana

1. Arrastra una ventana alrededor de los vértices que quieres mover. Da igual en
   qué grupo o componente estén. También vale un clic en una arista o cara.
2. Ctrl + arrastrar añade otra ventana; Mayús + arrastrar quita.
3. Haz clic en el punto de partida, mueve y haz clic en el destino (con las mismas
   referencias que Mover), o escribe la distancia.

- Flechas derecha / izquierda / arriba bloquean el eje rojo / verde / azul; flecha
  abajo lo suelta.
- Si al activar la herramienta había algo seleccionado, solo se estira eso.
- Los vértices que coincidan exactamente con los de la arista o cara en la que se
  hizo clic se mueven con ella, aunque sean de otro objeto.

## Limitaciones conocidas

- Los objetos bloqueados no se tocan.
- Los componentes dinámicos se estiran como geometría normal: sus fórmulas no se
  recalculan.
- Si se mueve solo parte de un arco o un círculo, deja de ser un arco.
- Una cara inclinada a la que solo se le mueve parte de los vértices puede quedar
  plegada en triángulos, igual que con la herramienta Mover.

## Para desarrollar

```
sketchup-gc-stretch/
  src/gc_stretch.rb          registra la extensión
  src/gc_stretch/regions.rb  zonas del espacio que deciden qué vértices se mueven
  src/gc_stretch/engine.rb   motor común: recorre la jerarquía y mueve
  src/gc_stretch/stretch_box.rb, box_tool.rb   herramienta por caja
  src/gc_stretch/window_tool.rb                herramienta por ventana
  test/                      pruebas con un doble de la API de SketchUp
  build.sh                   pasa las pruebas y crea dist/gc_stretch.rbz
```

Las pruebas se ejecutan fuera de SketchUp (`./build.sh`) con un doble de su API:
comprueban la geometría y el recorrido de las herramientas, pero **no sustituyen a
probar la extensión dentro de SketchUp**.
