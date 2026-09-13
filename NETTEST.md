# NETTEST — Conectividad con acedata.cloud

Fecha: 2026-09-13

## Comandos ejecutados

```
for h in seedance openai nanobanana; do printf "%s: " $h; curl -s -o /dev/null -w "%{http_code}\n" --max-time 15 https://$h.mcp.acedata.cloud/mcp; done
curl -s -o /dev/null -w "platform: %{http_code}\n" --max-time 15 https://platform.acedata.cloud
```

## Salida literal

```
seedance: 000
openai: 000
nanobanana: 000
platform: 000

[agent-proxy] While this command ran, 4 connections through the agent proxy failed:
- platform.acedata.cloud:443 — connect_rejected (the egress proxy denied the CONNECT (organization policy) or could not reach the destination)
- nanobanana.mcp.acedata.cloud:443 — connect_rejected (the egress proxy denied the CONNECT (organization policy) or could not reach the destination)
- openai.mcp.acedata.cloud:443 — connect_rejected (the egress proxy denied the CONNECT (organization policy) or could not reach the destination)
- and 1 more
For details: curl -sS http://127.0.0.1:35801/__agentproxy/status
```

Código de salida de curl: 56.

## Conclusión

Los cuatro hosts devuelven `000`: no hay conectividad. El proxy de egreso
(agent-proxy) rechaza el CONNECT por política de red de la organización, de modo
que el bloqueo ocurre antes de llegar al destino. Ninguno de los endpoints de
`acedata.cloud` es alcanzable desde este entorno.
