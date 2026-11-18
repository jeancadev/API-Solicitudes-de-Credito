public with sharing class SolicitudCreditoResponse {
    public String externalId;
    public String estado;
    public String motivoRechazo;

    public static SolicitudCreditoResponse desde(Solicitud_Credito__c solicitud) {
        SolicitudCreditoResponse respuesta = new SolicitudCreditoResponse();
        respuesta.externalId = solicitud.External_Id__c;
        respuesta.estado = solicitud.Estado__c;
        respuesta.motivoRechazo = solicitud.Motivo_Rechazo__c;
        return respuesta;
    }
}
