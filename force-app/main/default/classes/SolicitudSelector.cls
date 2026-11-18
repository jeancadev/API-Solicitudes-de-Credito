public with sharing class SolicitudSelector {
    public static Solicitud_Credito__c porExternalId(String externalId) {
        List<Solicitud_Credito__c> solicitudes = [
            SELECT Id, External_Id__c, Estado__c, Motivo_Rechazo__c
            FROM Solicitud_Credito__c
            WHERE External_Id__c = :externalId
            WITH USER_MODE
            LIMIT 1
        ];
        return solicitudes.isEmpty() ? null : solicitudes[0];
    }
}
