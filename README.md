# API de solicitudes de crédito

Proyecto Salesforce DX que expone una API REST para recibir y consultar solicitudes de crédito, evaluarlas con límites configurables y vencer automáticamente las preaprobaciones caducadas.

## Endpoints

### Crear o reenviar una solicitud

`POST /services/apexrest/solicitudes/v1`

```json
{
  "externalId": "SOL-1001",
  "clienteId": "001000000000001AAA",
  "monto": 12000,
  "plazoMeses": 12,
  "ingresoMensual": 3000
}
```

La respuesta contiene `externalId`, `estado` y, si fue rechazada, `motivoRechazo`. Reenviar el mismo `externalId` devuelve la solicitud ya registrada; el campo también es único en la base de datos para evitar duplicados ante peticiones concurrentes.

Asigna el Permission Set **API Solicitudes de Crédito** a los usuarios que consumirán el endpoint. Incluye acceso a la clase REST, al objeto y a sus campos, además de lectura de `Account`; el usuario también debe tener acceso de registro al cliente indicado.

### Consultar una solicitud

`GET /services/apexrest/solicitudes/v1/{externalId}`

## Reglas y vigencia

El registro `Default` de `Parametro_Credito__mdt` define monto máximo, plazo máximo, relación cuota/ingreso máxima y días de vigencia. La cuota se calcula como `monto / plazo`, sin intereses.

Una solicitud se preaprueba si cumple las tres reglas; de lo contrario queda rechazada con un mensaje de Custom Label. El batch `VencimientoSolicitudesBatch` pasa a `Vencida` las solicitudes preaprobadas cuya fecha de creación excede la vigencia. Para programarlo diariamente, por ejemplo:

```apex
System.schedule('Vencimiento diario de solicitudes', '0 0 1 * * ?', new VencimientoSolicitudesBatch());
```

## Diseño

- `EvaluadorCredito` contiene la lógica pura y recibe sus parámetros por constructor, de modo que sus pruebas no requieren base de datos.
- La configuración se lee desde Custom Metadata, por lo que se pueden cambiar límites sin desplegar Apex.
- `External_Id__c` es Unique + External ID: la consulta previa hace idempotente el flujo normal y la restricción de base de datos protege concurrencia.
- Las clases usan `with sharing`; la consulta usa `WITH USER_MODE` y el alta usa `insert as user`, para respetar acceso de objeto y campos del usuario invocador.
- La API responde explícitamente con 201, 400, 404 o 422 y errores JSON estructurados.

## Consideraciones de Salesforce

- `Monto_Maximo__c` es un campo `Number` en Custom Metadata porque Salesforce no admite `Currency` en este tipo de metadata.
- `Cliente__c` es un lookup obligatorio a `Account` con borrado restringido; no se puede eliminar un cliente mientras tenga solicitudes asociadas.
- El Permission Set es necesario para el acceso de la API: el endpoint no eleva privilegios, pues intencionalmente usa `WITH USER_MODE` e `insert as user`.

## Despliegue y pruebas

Después de autenticar una organización con Salesforce CLI, despliega el código y ejecuta las pruebas en pasos separados:

```bash
sf project deploy start --source-dir force-app --target-org <alias> --test-level NoTestRun
sf apex run test --target-org <alias> \
  --class-names EvaluadorCreditoTest \
  --class-names SolicitudCreditoServiceTest \
  --class-names SolicitudCreditoRestResourceTest \
  --class-names VencimientoSolicitudesBatchTest \
  --code-coverage --wait 30
```

Las pruebas del servicio y del endpoint crean un usuario de prueba con el Permission Set y usan `System.runAs`. Esto verifica el comportamiento con seguridad de usuario y evita combinar DML de configuración (`User`, `PermissionSetAssignment`) con datos de negocio en la misma transacción.

La última ejecución validada en la organización de desarrollo completó 12 de 12 métodos sin fallos.

No se usan frameworks, patrones adicionales, callouts ni procesos asíncronos que no aportan al caso.
