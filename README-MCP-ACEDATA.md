# Servidores MCP de AceDataCloud

Este repositorio incluye un `.mcp.json` que registra tres servidores MCP de
AceDataCloud para cualquier sesión de Claude Code que abra este proyecto:

| Servidor | Endpoint | Para qué |
|---|---|---|
| `seedance` | `https://seedance.mcp.acedata.cloud/mcp` | Vídeo (Seedance 2.5 y anteriores) |
| `openai` | `https://openai.mcp.acedata.cloud/mcp` | Imagen (GPT Image), chat, audio |
| `nanobanana` | `https://nanobanana.mcp.acedata.cloud/mcp` | Imagen (Nano Banana / Gemini) |

## Claves

El `.mcp.json` **no contiene ninguna credencial**. Lee tres variables de entorno:

- `ACEDATA_SEEDANCE_KEY`
- `ACEDATA_OPENAI_KEY`
- `ACEDATA_NANOBANANA_KEY`

Cada servicio de AceDataCloud tiene **su propia clave**. No son intercambiables:
usar la de un servicio en otro devuelve `token and api does not match`.

Cada clave se obtiene en la página de documentación del servicio en
<https://platform.acedata.cloud>, en la fila `authorization` de "Encabezados de
solicitud", con el botón **Obtener**.

### En sesiones en la nube

Definir las tres variables en el campo "Variables de entorno" del entorno de
Claude Code (formato `.env`, una por línea).

### En local

Exportarlas en el perfil del shell (`~/.zshrc` o `~/.bashrc`):

```bash
export ACEDATA_SEEDANCE_KEY=...
export ACEDATA_OPENAI_KEY=...
export ACEDATA_NANOBANANA_KEY=...
```

## Comprobación

```bash
claude mcp list
```

Los tres deben aparecer como `√ Connected`.

## Notas

- Al abrir el proyecto por primera vez, Claude Code pide aprobar los servidores
  MCP definidos en `.mcp.json`. Es un aviso normal de seguridad.
- Si se registran a mano con `claude mcp add`, el flag de cabecera es `-H`
  (mayúscula). Con `-h` el CLI lo interpreta como `--help` y no registra nada,
  sin mostrar ningún error.

## Costes medidos (13-09-2026)

| Operación | Coste |
|---|---|
| Vídeo Seedance 2.5, 5 s, 720p | ~12,78 créditos |
| Imagen Nano Banana (modelo `nano-banana`) | ~0,14 créditos |
