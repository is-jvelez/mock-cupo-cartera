# Mock Cupo Cartera

Mock de la API de cupo de cartera (REQ 110049 - Control crédito cartera), hecho con [Mockoon](https://mockoon.com/) y empaquetado en Docker.

## Contenido

| Archivo | Descripción |
|---|---|
| `mock-cupo-cartera.json` | Entorno de Mockoon con los endpoints y sus respuestas |
| `Dockerfile` | Imagen basada en `mockoon/cli` que sirve el mock en el puerto `10000` |
| `Mock Cupo Cartera - E1 y E2.postman_collection.json` | Colección de Postman para probarlo |
| `CupoCartera.postman_environment.json` | Environment de Postman |

## Ejecutar con Docker

Construir la imagen:

```bash
docker build -t mock-cupo-cartera .
```

Levantar el contenedor:

```bash
docker run -d --name mock-cupo-cartera -p 10000:10000 mock-cupo-cartera
```

Ver logs:

```bash
docker logs mock-cupo-cartera
```

Detener y eliminar el contenedor:

```bash
docker rm -f mock-cupo-cartera
```

El mock queda disponible en `http://localhost:10000/api/v1/cupocartera/...`.
Si cambias `mock-cupo-cartera.json`, vuelve a construir la imagen y recrea el contenedor.

## Endpoints

Todos son `POST` con `Content-Type: application/json` y requieren el header `Authorization: Bearer token_api_cupo_cartera`.

### `/api/v1/cupocartera/consultar` (E1, Zoho)

Request:

```json
{
  "identificacion": "0990335028001",
  "calificacionTorres": "4-ALTO VALOR",
  "cupoTorres": 12000.00,
  "configuracion": {
    "umbralesVencimiento": { "1-MUY ALTO VALOR": 15, "4-ALTO VALOR": 20, "2-MEDIANO VALOR": 7, "3-BAJO VALOR": 7 },
    "porcentajeCupo": { "Cartera al día": 20, "Cartera vencida": 0 }
  }
}
```

| Condición | Status | `code` |
|---|---|---|
| Sin header `Authorization` o mal formado | 401 | `NO_AUTENTICADO` |
| Token distinto de `token_api_cupo_cartera` | 403 | `ACCESO_DENEGADO` |
| Falta `identificacion`, `calificacionTorres` o `configuracion` | 400 | `SOLICITUD_INVALIDA` |
| `identificacion` = `9999` | 404 | `NO_ENCONTRADO` |
| `identificacion` = `1792967058001` | 200 | `CALCULADO` (`estadoCarteraTorres` `0-Habilitado`) |
| `identificacion` = `1002` | 200 | `CALCULADO` (bloqueado, cartera vencida) |
| `identificacion` = `1003` | 200 | `CACHE_VIGENTE` (bloqueo manual) |
| Cualquier otra | 200 | `CALCULADO` (cartera al día) |

### `/api/v1/cupocartera/gestion-cobranza` (E2, Zoho "Habilitar manualmente")

Request: `identificacion`, `motivo` (`Manual`), `estado` (`0-Habilitado` o `1-Bloqueado`), `fechaBloqueo` (`yyyy-MM-dd`).

| Condición | Status | `code` |
|---|---|---|
| Falta un campo, `motivo` distinto de `Manual`, `estado` no permitido o `fechaBloqueo` con formato inválido | 400 | `SOLICITUD_INVALIDA` |
| `identificacion` = `9999` | 404 | `SIN_CALCULO_VIGENTE` |
| `identificacion` = `1003` | 409 | `MANUAL_VIGENTE` |
| `identificacion` = `1004` | 409 | `ESTADO_YA_APLICADO` |
| `identificacion` = `5030` | 503 | `CACHE_NO_DISPONIBLE` |
| Cualquier otra | 200 | `GESTION_GUARDADA` |

### `/api/v1/cupocartera/obtener` (E5, ECHO)

Request: `identificacion` y `montoPorFacturar` (>= 0).

| Condición | Status | `code` |
|---|---|---|
| Falta un campo o `montoPorFacturar` negativo | 400 | `SOLICITUD_INVALIDA` |
| `identificacion` = `9999` | 404 | `CLIENTE_NO_ENCONTRADO_ZOHO` |
| `identificacion` = `8888` | 422 | `NO_ES_CLIENTE_TORRES` |
| `identificacion` = `5020` | 502 | `DEPENDENCIA_NO_DISPONIBLE` |
| `identificacion` = `1002` | 200 | `CALCULADO` (bloqueado) |
| `identificacion` = `1003` | 200 | `MANUAL_CRM` |
| `identificacion` = `1005` | 200 | `CONTINGENCIA` |
| Cualquier otra | 200 | `CALCULADO` (habilitado) |

## Estructura de la respuesta

Todas las respuestas usan el mismo wrapper:

```json
{
  "success": true,
  "code": "CALCULADO",
  "message": "Cupo calculado correctamente.",
  "data": { },
  "errors": [],
  "meta": {
    "correlationId": "uuid",
    "timestamp": "2026-10-08T20:01:44.342+00:00"
  }
}
```

En los errores `success` es `false` y `data` es `null`.

## Prueba rápida

```bash
curl -X POST http://localhost:10000/api/v1/cupocartera/consultar \
  -H "Authorization: Bearer token_api_cupo_cartera" \
  -H "Content-Type: application/json" \
  -d '{"identificacion":"0990335028001","calificacionTorres":"4-ALTO VALOR","cupoTorres":12000.00,"configuracion":{}}'
```

Para usar la colección de Postman contra el contenedor local, cambia la URL base de `https://mock-cupo-cartera.onrender.com` a `http://localhost:10000`.
