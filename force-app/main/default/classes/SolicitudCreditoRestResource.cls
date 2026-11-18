@RestResource(urlMapping='/solicitudes/v1/*')
global with sharing class SolicitudCreditoRestResource {
    @HttpPost
    global static void crear() {
        try {
            if (RestContext.request == null || RestContext.request.requestBody == null) {
                responder(400, new ApiError(new List<String>{ 'JSON inválido' }));
                return;
            }
            SolicitudCreditoRequest solicitud =
                (SolicitudCreditoRequest) JSON.deserialize(
                    RestContext.request.requestBody.toString(),
                    SolicitudCreditoRequest.class
                );
            if (solicitud == null) {
                responder(400, new ApiError(new List<String>{ 'JSON inválido' }));
                return;
            }

            List<String> errores = solicitud.validar();
            if (!errores.isEmpty()) {
                responder(400, new ApiError(errores));
                return;
            }

            Solicitud_Credito__c creada = new SolicitudCreditoService().crear(solicitud);
            responder(201, SolicitudCreditoResponse.desde(creada));
        } catch (JSONException excepcion) {
            responder(400, new ApiError(new List<String>{ 'JSON inválido' }));
        } catch (DmlException excepcion) {
            responder(422, new ApiError(new List<String>{
                excepcion.getDmlMessage(0)
            }));
        }
    }

    @HttpGet
    global static void obtener() {
        String externalId = RestContext.request.requestURI.substringAfterLast('/');
        Solicitud_Credito__c solicitud = SolicitudSelector.porExternalId(externalId);
        if (solicitud == null) {
            responder(404, new ApiError(new List<String>{
                'Solicitud no encontrada'
            }));
            return;
        }
        responder(200, SolicitudCreditoResponse.desde(solicitud));
    }

    private static void responder(Integer estado, Object cuerpo) {
        RestResponse respuesta = RestContext.response;
        respuesta.statusCode = estado;
        respuesta.addHeader('Content-Type', 'application/json');
        respuesta.responseBody = Blob.valueOf(JSON.serialize(cuerpo));
    }

    private class ApiError {
        public List<String> errores;

        public ApiError(List<String> errores) {
            this.errores = errores;
        }
    }
}
