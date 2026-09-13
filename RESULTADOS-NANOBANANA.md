# Resultados — MCP Nano Banana (AceData Cloud)

Fecha: 2026-09-13
Servidor: `https://nanobanana.mcp.acedata.cloud/mcp` (transporte HTTP)

## 1. Registro

Comando ejecutado (token enmascarado):

```
claude mcp add nanobanana --transport http https://nanobanana.mcp.acedata.cloud/mcp -H "Authorization: Bearer ***"
```

Nota: en esta versión del CLI (Claude Code 2.1.270) el flag corto `-h` es `--help`;
la cabecera debe pasarse con `-H` / `--header`. Con `-h` el comando solo imprime la ayuda
y NO registra el servidor.

Salida:

```
Added HTTP MCP server nanobanana with URL: https://nanobanana.mcp.acedata.cloud/mcp to local config
Headers: {
  "Authorization": "[REDACTED]"
}
File modified: /root/.claude.json [project: /home/user/predeterminado-GC-varios]
```

## 2. Estado de conexión

```
$ claude mcp list
Checking MCP server health…

nanobanana: https://nanobanana.mcp.acedata.cloud/mcp (HTTP) - √ Connected
```

Herramientas expuestas por el servidor:

- `mcp__nanobanana__nanobanana_generate_image`
- `mcp__nanobanana__nanobanana_edit_image`
- `mcp__nanobanana__nanobanana_get_task`
- `mcp__nanobanana__nanobanana_get_tasks_batch`

## 3. Generación de imagen (una sola)

Ejecutada en un proceso headless nuevo (los MCP recién añadidos no están cargados
en el proceso en curso):

```
claude -p "Llama a nanobanana_generate_image con prompt 'a single red apple on a white table, studio lighting' ..." \
  --allowedTools "mcp__nanobanana__nanobanana_generate_image,mcp__nanobanana__nanobanana_get_task"
```

**Resultado: OK.** Sin errores. No hubo bloqueo del clasificador de permisos.

| Campo | Valor |
|---|---|
| Estado | Completada con éxito |
| Modelo | `nano-banana` (por defecto) |
| Prompt | `a single red apple on a white table, studio lighting` |
| task_id | `cd356a32-89c7-4da2-8c7a-5621fc6ff681` |
| URL imagen | https://platform2.cdn.acedata.cloud/nanobanana/18b7655a-1953-4ade-a32d-283ba6acdf08.png |
| Coste | 0.14 créditos |
| Tiempo de proceso | 13,5 s |

## 4. Conclusión

El error anterior `token and api does not match` queda resuelto: era un token de otro
servicio de AceData. Con la clave específica de Nano Banana el servidor conecta y la
generación funciona de extremo a extremo, con cobro de créditos (0.14 por imagen con
el modelo por defecto).
