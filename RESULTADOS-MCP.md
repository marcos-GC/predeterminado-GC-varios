# RESULTADOS — Pruebas MCP AceData Cloud

Fecha: 2026-09-13
Rama: `claude/acedata-mcp-pruebas`

> Nota previa: en la sesión anterior (`NETTEST.md`) los cuatro hosts de
> `acedata.cloud` devolvían `000` porque el proxy de egreso rechazaba el CONNECT.
> **Esa restricción ya no existe**: en esta sesión los tres endpoints responden
> `401` sin token y conectan correctamente con él.

---

## 1. Estado de conexión de los tres servidores

Registrados con:

```
claude mcp add seedance   --transport http https://seedance.mcp.acedata.cloud/mcp   -H "Authorization: Bearer ***"
claude mcp add openai     --transport http https://openai.mcp.acedata.cloud/mcp     -H "Authorization: Bearer ***"
claude mcp add nanobanana --transport http https://nanobanana.mcp.acedata.cloud/mcp -H "Authorization: Bearer ***"
```

Los tres se escribieron en la configuración **local** (`/root/.claude.json`,
fuera del repositorio), de modo que el token no entra en el control de versiones.

Salida literal de `claude mcp list`:

```
Checking MCP server health…

seedance: https://seedance.mcp.acedata.cloud/mcp (HTTP) - √ Connected
openai: https://openai.mcp.acedata.cloud/mcp (HTTP) - √ Connected
nanobanana: https://nanobanana.mcp.acedata.cloud/mcp (HTTP) - √ Connected
```

| Servidor | Conexión | Error |
|---|---|---|
| seedance | ✅ Connected | — |
| openai | ✅ Connected | — |
| nanobanana | ✅ Connected | — |

### Herramientas expuestas por cada servidor

- **seedance**: `seedance_list_models`, `seedance_list_resolutions`,
  `seedance_list_actions`, `seedance_get_task`, `seedance_get_tasks_batch`,
  `seedance_generate_video`, `seedance_generate_video_from_image`
- **openai**: `openai_text_to_speech`, `openai_transcribe_audio`,
  `openai_chat_completion`, `openai_create_embedding`, `openai_generate_image`,
  `openai_edit_image`, `openai_get_models`, `openai_get_realtime_connection_info`,
  `openai_list_chat_models`, `openai_list_image_models`,
  `openai_list_embedding_models`, `openai_get_usage_guide`,
  `openai_create_response`, `openai_get_task`, `openai_list_tasks`
- **nanobanana**: `nanobanana_generate_image`, `nanobanana_edit_image`,
  `nanobanana_get_task`, `nanobanana_get_tasks_batch`

---

## 2. Modelos disponibles

### Seedance (`seedance_list_models`)

```
doubao-seedance-2-5-260628
doubao-seedance-2-0-260128
doubao-seedance-2-0-fast-260128
doubao-seedance-2-0-mini-260615
doubao-seedance-1-5-pro-251215
doubao-seedance-1-0-pro-250528
doubao-seedance-1-0-pro-fast-251015
doubao-seedance-1-0-lite-t2v-250428
doubao-seedance-1-0-lite-i2v-250428
```

**¿Aparece `doubao-seedance-2-5-260628`? → SÍ.** Es el primero de la lista y el
modelo por defecto del servidor (hasta 30 s, referencia multimodal, edit/extend).

### OpenAI

`openai_list_image_models`:

```
gpt-image-1
gpt-image-1.5
gpt-image-2
gpt-image-2.5-flare
gpt-image-2.5-flare:official
gpt-image-2.5-sunburst
gpt-image-2.5-sunburst:official
gpt-image-2:reverse
gpt-image-2:official
dall-e-3
dall-e-2
nano-banana
nano-banana-2-lite
nano-banana-2
nano-banana-pro
```

`openai_list_chat_models`:

```
gpt-6-astra, gpt-5.6-luna, gpt-5.6-terra, gpt-5.6-sol, gpt-5.5, gpt-5.5-pro,
gpt-5.4, gpt-5.4-mini, gpt-5.4-nano, gpt-5.4-pro, gpt-5.2, gpt-5.1, gpt-5.1-all,
gpt-5, gpt-5-mini, gpt-5-nano, gpt-oss:free, gpt-5.5:free, gpt-5:free,
gpt-4.1:free, gpt-4o:free, gpt-4o-mini:free, gpt-4.1, gpt-4.1-mini, gpt-4.1-nano,
gpt-4o, gpt-4o-2024-05-13, gpt-4o-all, gpt-4o-image, gpt-4o-mini, gpt-4,
gpt-35-turbo-16k, o4-mini, o3, o3-mini, o3-pro, o1, o1-mini, o1-pro
```

`doubao-seedance-2-5-260628`: **no aparece** (servidor de OpenAI, no de vídeo).

### Nano Banana

**No existe herramienta de listado de modelos** en este servidor (solo
`generate_image`, `edit_image`, `get_task`, `get_tasks_batch`). Los modelos
disponibles se declaran en el `enum` del parámetro `model` de
`nanobanana_generate_image`:

```
nano-banana            (alias de gemini-2.5-flash-image, por defecto)
nano-banana-2-lite
nano-banana-2          (alias de gemini-3.1-flash-image)
nano-banana-pro        (alias de gemini-3-pro-image, admite parámetro resolution)
```

Más los sufijos `:official` de cada uno (`nano-banana:official`,
`nano-banana-2-lite:official`, `nano-banana-2:official`, `nano-banana-pro:official`).

`doubao-seedance-2-5-260628`: **no aparece** (servidor de imagen, no de vídeo).

---

## 3. Pruebas de generación

### 4a. Nano Banana — ❌ ERROR (autenticación, no saldo)

Prompt: `a single red apple on a white table, studio lighting`
Herramienta: `nanobanana_generate_image` (una sola llamada, sin reintentos).

Error literal:

```
Error executing tool nanobanana_generate_image: token and api does not match.
```

No se devolvió `task_id`, ni URL, ni coste. **No es un error de saldo** (no es
`insufficient balance` ni 402), por lo que se continuó con el resto según lo
indicado. El servidor MCP conecta y autentica, pero el token no está habilitado
para la API de Nano Banana.

### 4b. OpenAI GPT Image — ⚠️ NO EJECUTADA (bloqueada localmente)

La llamada a `openai_generate_image` (`gpt-image-1`, mismo prompt) **no llegó a
realizarse**: el clasificador de permisos del entorno de Claude Code la denegó
antes de salir a la red.

Mensaje literal del bloqueo:

```
Permission for this action was denied by the Claude Code auto mode classifier.
Reason: [Real-World Transactions].
```

No se consumió saldo. **No es un fallo de AceData ni del token.** El mismo
clasificador permitió las llamadas de Nano Banana y Seedance, por lo que el
bloqueo es intermitente. Queda pendiente de repetir (ver sección 5).

### 4c. Seedance — ✅ OK

Prompt: `a calm sea at sunrise, slow camera push in`
Modelo: `doubao-seedance-2-5-260628` · `duration: 5` (**no** se usó `frames`,
que es exclusivo de la serie 1.0).

Generación asíncrona; se esperó el resultado con `seedance_get_task`.

```
task_id:    e9242e2e-9aa4-46f8-8bc8-233ca1bae635
trace_id:   97647393-60f8-444d-8f21-65c1811f4de9
id:         task_CWjXMVY7krwkJizQJbd0uzf9GhZHlCLy
model:      doubao-seedance-2-5-260628
status:     succeeded
duration:   5
resolution: 720p
ratio:      16:9
seed:       62783
usage:      108900 total_tokens
success:    true
```

**URL del vídeo:**
`https://platform2.cdn.acedata.cloud/seedance/e9242e2e-9aa4-46f8-8bc8-233ca1bae635.mp4`

---

## 4. Créditos consumidos

| Prueba | Coste declarado por la respuesta |
|---|---|
| Nano Banana | 0 (la llamada falló por autenticación) |
| OpenAI GPT Image | 0 (no ejecutada) |
| Seedance | `{"amount": 12.782608695652174, "currency": "credit"}` |

Total consumido en esta sesión: **12,78 créditos**, todos en la prueba de Seedance.

---

## 5. Requiere atención del usuario

1. **El saldo real no coincide con lo previsto.** Se avisó de ~2 créditos
   generales + 1 exclusivo de Seedance, pero la generación de Seedance se
   completó con éxito cobrando **12,78 créditos**. Conviene revisar el saldo real
   en el panel de AceData antes de planificar más pruebas: o bien el saldo era
   mayor de lo estimado, o bien la cuenta ha quedado en negativo.
2. **Nano Banana no funciona con este token**: `token and api does not match`.
   El servidor MCP conecta, pero la API de Nano Banana rechaza la credencial.
   Hay que habilitar ese producto para el token en el panel de AceData, o usar
   un token distinto. Alternativa inmediata: el servidor `openai` también expone
   los modelos `nano-banana`, `nano-banana-2`, `nano-banana-2-lite` y
   `nano-banana-pro` a través de `openai_generate_image`.
3. **Prueba 4b pendiente.** El clasificador de permisos de Claude Code denegó la
   llamada por "Real-World Transactions" y, siguiendo la instrucción de no
   insistir ante una denegación, no se reintentó. Para ejecutarla hace falta
   autorización explícita del usuario (o una regla de permisos de Bash en los
   ajustes). Es **una sola** generación pendiente.
4. **El token no está en el repositorio.** Los tres servidores se registraron con
   ámbito *local* (`/root/.claude.json`), no con `--scope project`, que habría
   creado un `.mcp.json` versionado con la credencial dentro del repo.
5. **Nota de red**: la conectividad con `acedata.cloud` que fallaba en `NETTEST.md`
   está ahora operativa desde este entorno.
