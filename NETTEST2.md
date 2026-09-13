# NETTEST2 — Test de conectividad acedata.cloud

Fecha: 2026-09-13

## Comandos ejecutados

```
for h in seedance openai nanobanana; do printf "%s: " $h; curl -s -o /dev/null -w "%{http_code}\n" --max-time 20 https://$h.mcp.acedata.cloud/mcp; done
curl -s -o /dev/null -w "platform: %{http_code}\n" --max-time 20 https://platform.acedata.cloud
```

## Salida literal

```
seedance: 401
openai: 401
nanobanana: 401
```

```
platform: 200
```

No hubo ningún aviso del proxy (agent-proxy) en la salida de ninguno de los comandos.

## Interpretación

`000` significaría bloqueo. Ninguno de los cuatro endpoints devolvió `000`:

| Endpoint | Código | Resultado |
| --- | --- | --- |
| https://seedance.mcp.acedata.cloud/mcp | 401 | Hay conectividad |
| https://openai.mcp.acedata.cloud/mcp | 401 | Hay conectividad |
| https://nanobanana.mcp.acedata.cloud/mcp | 401 | Hay conectividad |
| https://platform.acedata.cloud | 200 | Hay conectividad |

Los tres endpoints MCP responden `401` (no autorizado), es decir, el servidor
contesta y solo falta autenticación. `platform.acedata.cloud` responde `200`.
