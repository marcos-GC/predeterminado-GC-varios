# Manifiesto — Vídeo Edificio Hierro 5

## Brief
- Público: arquitecto. Vídeo narrativo que explica el proyecto.
- Orden: estado actual → alzado dibujado (base) → renders finales.
- Plano obligatorio: fachada explotada en 3D, capas separándose, transición de imagen real a vectorial.
- Duración: 30–45 s (ampliada a ~52 s al añadir G5). Audio: sin locución, solo música + efectos.
- Estética: mantener aspecto de maqueta (base de madera, fondo neutro de estudio).
- Motor: Seedance + Nano Banana vía MCP — **conectado** (2026-09-13). También disponibles Flux (BFL) y GPT Image como alternativas de imagen.

## Inventario (origen: ../fotos referencia/)
| Archivo | Qué es | Papel | URL |
|---|---|---|---|
| imagen estado actual1.jpg | Maqueta estado actual 3/4 (muro cortina azul, cilindro cobre, pirámide vidrio, carteles DISPONIBLE) | Fotograma inicial pieza; ref. volumetría y cámara | pendiente |
| alzados estado actial.jpg | 4 alzados coloreados estado actual (NE, SE, SO, NO) | Ref. técnica existente; plano "lectura" | pendiente |
| alzado arquitectonico 2d reformado.png | Alzado CAD reformado, versión A (marcos blancos en voladizo, verde, lamas) | Candidato base del proyecto — **elegido** | pendiente |
| " alzado arquitectonico 2d reformado.png" (con espacio) | Alzado CAD reformado, versión B (celosía perforada, bandejas amarillas, "pirámide existente", "pérgola acero lacado") | Descartado | pendiente |
| resultado final.png | Render maqueta propuesta (madera, lamas, jardineras piedra, cubierta vegetal, personas) | Fotograma final; ref. materiales | pendiente |
| Iron5_File_2026-09-13_10-47-19.jpg | Render maqueta propuesta, variante con máquinas de clima en cubierta | Alternativa fotograma final; ref. materiales | pendiente |

## Imágenes pegadas en el chat (2026-09-13, sesión de continuación)
El usuario volvió a pegar 5 imágenes directamente en el chat para desbloquear el proyecto. Identificación visual (sin URL ni archivo local extraíble — ver "Bloqueos"):
1. Alzado con trama de puntos, bandas amarillas, pirámide rotulada "PIRÁMIDE EXISTENTE" y "PERGOLA ACERO LACADO" → **alzado versión B** (descartada).
2. Alzado blanco/verde con marcos en voladizo → **alzado versión A** (la base elegida del proyecto).
3. Cuatro alzados con muro cortina azul y carteles "DISPONIBLE" → **alzados estado actual.jpg**.
4. Maqueta física/render azul, rótulo "ESTUDIO VOLUMÉTRICO: EDIFICIO HIERRO 5" → **imagen estado actual1.jpg**.
5. Maqueta con madera, plantas y jardineras, rótulo "ESTUDIO VOLUMÉTRICO COMPLETO" → **resultado final.png**.
Pendiente de que el usuario confirme esta identificación.

## Huecos detectados
- H1–H4 (ver guion.md) — todavía sin generar.

## Decisiones
- Alzado base: versión A (marcos blancos, sin espacio en el nombre).
- Arco: "La piel que cambia". 5 generaciones separadas (~52 s); G5 = explosión de la fachada renovada.
- Sin locución, solo música + efectos. Capa base de G5 = despiece del muro cortina existente al que se adapta la nueva fachada.
- Guion técnico completo en `guion.md`. Prompts finales en inglés (G1–G5) en `prompts_en.md`.
- 2026-09-13: se traspasa el trabajo al repo `predeterminado-GC-varios` (carpeta `Iron5/video_hierro5/`) para que sobreviva a cambios de sesión.

## Bloqueos pendientes
1. ~~Ace Data Cloud (Seedance + Nano Banana) sin conectar~~ — **RESUELTO 2026-09-13**: `mcp__seedance__*`, `mcp__nanobanana__*`, `mcp__Flux__*` y `mcp__gptimage__*` están cargados y operativos en esta sesión.
2. **Sigue sin existir ninguna imagen accesible.** Se repitió la búsqueda de archivos `.jpg/.png/.webp` en todo el sistema de archivos del contenedor tras confirmar los conectores: sigue sin haber ni un solo archivo de imagen. Las 5 imágenes que el usuario pegó en el chat se identificaron visualmente (ver arriba) pero no generan URL ni quedan guardadas como archivo — y tanto `nanobanana_edit_image` como `seedance_generate_video_from_image` necesitan, para cada imagen, una **URL https pública** o una **cadena base64 real de sus bytes**; no se dispone de ninguna de las dos. Este es ahora el único bloqueo real. Sigue haciendo falta una de estas dos cosas:
   - Que el usuario las suba como **archivo adjunto real** (arrastrar y soltar, no pegar) para que aparezcan en la carpeta de subidas de la sesión y se puedan leer con Read/Bash; o
   - Enlaces públicos ("cualquiera con el enlace") a las imágenes.

## Notas técnicas de Seedance (comprobado 2026-09-13)
- Modelo recomendado para este proyecto: `doubao-seedance-2-5-260628` (flagship, hasta 30 s, referencia multimodal, edit/extend) o `doubao-seedance-2-0-260128` (mejor resolución, hasta 4k). Ambos aceptan `first_frame_url` + `last_frame_url` + `reference_image_urls`, que es justo el esquema de anclaje usado en el guion.
- Resoluciones: 480p/720p/1080p/4k (4k solo en 2-0). Aspecto 16:9 por defecto, o `adaptive` para ajustarse a la imagen de entrada.
- Plan: probar primero G2 (el plano clave) a 480p para iterar barato antes de generaciones caras.

## Próximos pasos
1. Confirmar con el usuario la identificación de las 5 imágenes pegadas.
2. Resolver el único bloqueo que queda: conseguir las imágenes como archivo real o URL pública.
3. En cuanto lleguen: generar H1–H4 con `nanobanana_edit_image` combinando las fotos/alzados correspondientes, y pasárselas al usuario para que las apruebe.
4. Prueba a 480p de G2 (el plano más difícil) con `seedance_generate_video_from_image`. Revisar y corregir una variable cada vez.
5. Pedir confirmación antes de cada tanda de generaciones cara. Descargar a `clips/` y anotarlo aquí.

## Generaciones
(ninguna todavía)
