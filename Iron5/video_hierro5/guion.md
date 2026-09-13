# Guion técnico — Hierro 5 · "La piel que cambia"

Duración total: ~52 s · 16:9 · Estética de maqueta de estudio (base de roble, fondo gris neutro, luz de softbox).
Sin locución: solo música y efectos (el ritmo lo marcan las transformaciones).
Estructura: 5 generaciones separadas (cada fase tiene su propio material de anclaje y hay saltos fuertes real → vectorial → real). Se montan con cortes y fundidos.

Línea física común (se repite en todos los prompts):
> Architectural scale model of a five-storey corner office building on a light oak plinth, glass pyramid skylight on the roof, neutral grey studio backdrop, soft overhead softbox light.

---

## G1 · Lo que hay (0–9 s)
- **Qué se ve / qué cambia**: maqueta del estado actual en 3/4. La cámara orbita despacio; los reflejos del muro cortina azul se deslizan por el vidrio. Termina encarando la fachada principal NE.
- **Plano**: general 3/4, altura de ojo ligeramente elevada.
- **Cámara**: slow orbit left ~25°, se detiene al quedar frontal.
- **Óptica**: 50 mm, profundidad de campo amplia.
- **Luz**: softbox cenital, 5000 K, sombra suave bajo el edificio.
- **Anclaje**: primer fotograma = `imagen estado actual1.jpg`. Final = hueco H1 (frontal de la maqueta existente).
- **Audio**: ambiente de estudio silencioso, música de piano mínima arrancando. Sin locución.

## G2 · La piel se desmonta (9–20 s) — PLANO CLAVE
- **Qué se ve / qué cambia**: fachada principal en frontal. Los elementos se separan en profundidad como una axonometría explotada: primero se despega el muro cortina azul, luego el cilindro de cobre y los carteles, dejando a la vista forjados y pilares. Al separarse, cada capa pierde textura y se convierte en línea vectorial negra sobre blanco. Termina en un plano 2D con líneas CAD.
- **Plano**: medio frontal → ligero giro a 3/4 para leer la explosión → vuelve a frontal.
- **Cámara**: slow arc right 15° mientras las capas se separan, regresa a eje frontal cuando todo es vector.
- **Óptica**: 85 mm, ortogonalidad casi total.
- **Luz**: la luz de estudio se aplana a blanco uniforme conforme el dibujo sustituye a la maqueta.
- **Anclaje**: primer fotograma = H1. Referencias: `alzados estado actial.jpg` (geometría de fachada existente). Fotograma final = H2 (fachada existente en dibujo vectorial) — o, si se aprueba, directamente fotograma de explosión H3 como referencia intermedia.
- **Audio**: efectos de desmontaje suave (clics mecánicos, aire), música crece.

## G3 · El dibujo del arquitecto (20–30 s)
- **Qué se ve / qué cambia**: el dibujo vectorial del edificio existente se redibuja en el alzado reformado: aparecen los marcos blancos en voladizo, las bandas verdes, las lamas y la cubierta ajardinada; los trazos se rellenan de color plano como en el CAD.
- **Plano**: frontal ortogonal a toda la fachada.
- **Cámara**: static locked-off shot, muy leve dolly in al final.
- **Anclaje**: primer fotograma = H2. Fotograma final = `alzado arquitectonico 2d reformado.png` (versión A).
- **Audio**: sonido de trazo/pluma sutil, música estable.

## G4 · El edificio renovado (30–40 s)
- **Qué se ve / qué cambia**: el alzado plano gana volumen: los marcos salen hacia delante, aparecen madera, piedra y plantas, y el dibujo se convierte en la maqueta renovada. Cierre con leve órbita mostrando jardineras y cubierta.
- **Plano**: frontal → 3/4 medio.
- **Cámara**: slow dolly out + arc left, una sola trayectoria continua que empieza cuando los marcos se extruyen.
- **Óptica**: 50 mm.
- **Luz**: softbox de estudio 5000 K, igual que G1 (rima visual).
- **Anclaje**: primer fotograma = `alzado arquitectonico 2d reformado.png`. Fotograma final = `Iron5_File_2026-09-13_10-47-19.jpg`. Referencia de materiales = `resultado final.png`.
- **Audio**: música sube, pájaros muy tenues.

## G5 · Anatomía de la nueva fachada (40–52 s) — SEGUNDA EXPLOSIÓN
- **Qué se ve / qué cambia**: desde el 3/4 del render final, la fachada nueva se descompone en capas que se separan en profundidad, de fuera hacia dentro: (1) vegetación y jardineras de piedra, (2) celosías y contraventanas de lamas de madera, (3) bastidor metálico bronce de montantes y bandejas, (4) carpinterías y vidrio nuevos, (5) despiece del muro cortina existente con su estructura de montantes y forjados, al que se adapta la nueva fachada (se conserva). Cada capa se detiene un instante para leerse y después todas vuelven a su sitio hasta recomponer el render.
- **Plano**: 3/4 medio → axonometría explotada más abierta → vuelta al 3/4 del render.
- **Cámara**: slow arc right ~20° y leve dolly out mientras las capas se separan; recorrido inverso cuando se recomponen. Un solo movimiento de ida y vuelta.
- **Óptica**: 50 mm, profundidad de campo amplia para leer todas las capas.
- **Luz**: softbox de estudio 5000 K, sombras suaves entre capas para marcar la profundidad.
- **Anclaje**: primer fotograma = `Iron5_File_2026-09-13_10-47-19.jpg`. Fotograma final = el mismo render (se recompone). Referencias: `resultado final.png` (materiales) y H4 (disposición de las capas separadas) + `alzado arquitectonico 2d reformado.png` (orden y modulación de los marcos).
- **Audio**: clics mecánicos suaves en cada separación, música que resuelve al recomponerse.

---

## Huecos a generar con Nano Banana (Fase 5)
- **H1** — Frontal de la maqueta existente (fachada NE), mismo estilo que `imagen estado actual1.jpg`. Combinar esa foto + alzado principal NE. **Imprescindible**.
- **H2** — Fachada existente NE en dibujo vectorial CAD de línea negra, mismo encuadre y escala que el alzado reformado A. **Imprescindible** (puente real→vector).
- **H3** — Fotograma fijo de la fachada explotada en axonometría (capas separadas, mitad maqueta / mitad vector). **Muy recomendable**: sirve como referencia de G2 y además como fotograma para la presentación.
- **H4** — Fotograma fijo de la fachada renovada explotada en axonometría, desde el 3/4 del render, con las 5 capas separadas (vegetación/jardineras, lamas de madera, bastidor bronce, carpinterías nuevas, despiece del muro cortina existente como capa base). Combinar los dos renders + alzado A. **Imprescindible** para G5: sin él, Seedance inventaría el orden de las capas.
- Seedance puede resolver solo la extrusión de G4 sin imagen intermedia.

## Prompts
Ver `prompts_en.md` para los 5 prompts finales en inglés (G1–G5), listos para Seedance en cuanto haya conector e imágenes.
