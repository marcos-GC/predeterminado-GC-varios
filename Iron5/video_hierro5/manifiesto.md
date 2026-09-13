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

## Imágenes de origen — RECUPERADAS (2026-09-13)
El usuario pegó 5 imágenes directamente en el chat (dos veces). No llegaban como archivo adjunto normal ni generaban URL, pero estaban guardadas en base64 dentro del registro (transcript) de la propia sesión de Claude Code. Se extrajeron de ahí con un script y se guardaron en `Iron5/imagenes_origen/`:

| Archivo recuperado | Corresponde a |
|---|---|
| `imagen_estado_actual1.jpeg` | `imagen estado actual1.jpg` del inventario |
| `alzados_estado_actual.jpeg` | `alzados estado actial.jpg` (4 alzados, muro cortina azul, carteles DISPONIBLE) |
| `alzado_reformado_version_A_base.webp` | Alzado reformado versión A — **la base elegida** |
| `alzado_reformado_version_B_descartado.webp` | Alzado reformado versión B — descartada |
| `resultado_final.jpeg` | `resultado final.png` (render con madera, plantas, jardineras) |

Verificadas visualmente una por una: coinciden exactamente con la identificación anterior. **Este bloqueo queda resuelto** — ya se pueden usar como referencia real (convertidas a base64) en `nanobanana_edit_image` y `seedance_generate_video_from_image`.

Nota para el futuro: si el usuario vuelve a pegar imágenes en el chat y no aparecen como archivo, revisar `/root/.claude/projects/<ruta-del-proyecto>/<session-id>.jsonl` — ahí quedan los bloques `type: image` con los datos en base64, aunque no se guarden como archivo aparte.

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
2. ~~Sin imágenes accesibles~~ — **RESUELTO 2026-09-13**: recuperadas del transcript de la sesión, ver sección de arriba. Ya no queda ningún bloqueo técnico para empezar a generar H1–H4.

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
### 1. Prueba G4 (2026-09-13)
- **Modelo**: `doubao-seedance-2-0-260128`, 480p, 16:9, 10 s.
- **Anclaje**: primer fotograma = `alzado_reformado_version_A_base.webp` (URL raw.githubusercontent.com de este mismo repo/rama). Último fotograma = `resultado_final.jpeg` (se usó en vez de `Iron5_File_...jpg`, que no está recuperado; visualmente es casi el mismo render).
- **Prompt**: el de G4 en `prompts_en.md`.
- **Resultado**: éxito. `task_id` = `54a9df3b-bd69-4f2a-975e-f09bba4e4a0c`. Coste: 7.8 créditos.
- **Vídeo**: https://platform2.cdn.acedata.cloud/seedance/54a9df3b-bd69-4f2a-975e-f09bba4e4a0c.mp4
- **Nota técnica**: el sandbox de esta sesión bloquea por política de red la descarga directa desde `platform2.cdn.acedata.cloud` (egress proxy, 403), así que el .mp4 no se pudo copiar a `Iron5/clips/` esta vez. El usuario puede descargarlo directamente desde el enlace de arriba. Si hace falta guardarlo en el repo, probar en una sesión/entorno sin esa restricción, o pedir al usuario que lo suba él mismo.
- Pendiente de que el usuario lo revise y dé el visto bueno antes de seguir con el resto de generaciones.
