public with sharing class VencimientoSolicitudesBatch
    implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext contexto) {
        String estado = EstadoSolicitud.PREAPROBADA;
        Datetime limite = Datetime.now().addDays(
            -ParametrosCredito.cargar().diasVigencia
        );
        return Database.getQueryLocator([
            SELECT Id
            FROM Solicitud_Credito__c
            WHERE Estado__c = :estado
            AND CreatedDate < :limite
        ]);
    }

    public void execute(
        Database.BatchableContext contexto,
        List<SObject> registros
    ) {
        for (SObject registro : registros) {
            Solicitud_Credito__c solicitud = (Solicitud_Credito__c) registro;
            solicitud.Estado__c = EstadoSolicitud.VENCIDA;
        }
        update registros;
    }

    public void finish(Database.BatchableContext contexto) {
    }

    public void execute(SchedulableContext contexto) {
        Database.executeBatch(this, 200);
    }
}
