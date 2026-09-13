# Manifiesto — Vídeo Edificio Hierro 5

## Brief
- Público: arquitecto. Vídeo narrativo que explica el proyecto.
- Orden: estado actual → alzado dibujado (base) → renders finales.
- Plano obligatorio: fachada explotada en 3D, capas separándose, transición de imagen real a vectorial.
- Duración: 30–45 s (ampliada a ~52 s al añadir G5). Audio: sin locución, solo música + efectos.
- Estética: mantener aspecto de maqueta (base de madera, fondo neutro de estudio).
- Motor: Ace Data Cloud (Seedance + Nano Banana) — PENDIENTE de conectar por el usuario.

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

## Bloqueos pendientes (sin cambios desde el traspaso anterior)
1. **Ace Data Cloud (Seedance + Nano Banana) sigue sin conectar.** Comprobado en esta sesión: no aparece en `ListConnectors`. Solo hay un conector llamado "Flux" instalado, pero está en estado `needs_reconnect` (requiere que el usuario reautorice desde los ajustes de conectores de claude.ai) y es un servicio distinto — genera imágenes fijas (FLUX de Black Forest Labs), no vídeo, así que como mucho serviría para generar H1–H4, nunca para Seedance.
2. **Siguen sin existir URLs ni archivos reales de las imágenes.** Las 5 imágenes pegadas en este chat se pudieron identificar visualmente (ver arriba) pero no generan una URL ni quedan guardadas como archivo accesible — no es posible pasarlas a ninguna API de generación así. Sigue haciendo falta una de estas dos cosas:
   - Que el usuario las suba como **archivo adjunto real** (arrastrar y soltar, no pegar), para que aparezcan en la carpeta de subidas de la sesión y se puedan leer con Read/Bash; o
   - Enlaces públicos ("cualquiera con el enlace") a las imágenes.
3. Pregunta abierta sin responder: seguir por (a) prompts para uso manual en Dreamina, Higgsfield o la web de Ace, (b) conectar Ace Data Cloud, o (c) reconectar Flux y usarlo solo para las imágenes fijas H1–H4 (habría que adaptar el flujo, ya que Flux no compone a partir de dos imágenes de referencia como Nano Banana).

## Próximos pasos
1. Confirmar con el usuario la identificación de las 5 imágenes pegadas.
2. Resolver el bloqueo de acceso a las imágenes (subida real o URLs).
3. Resolver el conector de generación (Ace Data Cloud, o alternativa con Flux solo para fijas).
4. `seedance_list_models` / `list_resolutions` en cuanto haya conector, para comprobar el modelo.
5. Generar H1–H4 y pasárselas al usuario para que las apruebe.
6. Prueba a 480p en nivel flex de G2 (el plano más difícil). Revisar y corregir una variable cada vez.
7. Pedir confirmación antes de cada tanda de generaciones cara. Descargar a `clips/` y anotarlo aquí.

## Generaciones
(ninguna todavía)
