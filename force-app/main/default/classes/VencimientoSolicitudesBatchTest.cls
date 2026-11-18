@IsTest
private class VencimientoSolicitudesBatchTest {
    @IsTest
    static void venceSoloLasSolicitudesPreaprobadasFueraDeVigencia() {
        Account cliente = new Account(Name = 'Cliente vencimiento');
        insert cliente;

        Solicitud_Credito__c antigua = new Solicitud_Credito__c(
            Cliente__c = cliente.Id,
            External_Id__c = 'VENCE-ANTIGUA',
            Monto__c = 1000,
            Plazo_Meses__c = 10,
            Ingreso_Mensual__c = 1000,
            Estado__c = EstadoSolicitud.PREAPROBADA
        );
        Solicitud_Credito__c reciente = new Solicitud_Credito__c(
            Cliente__c = cliente.Id,
            External_Id__c = 'VENCE-RECIENTE',
            Monto__c = 1000,
            Plazo_Meses__c = 10,
            Ingreso_Mensual__c = 1000,
            Estado__c = EstadoSolicitud.PREAPROBADA
        );
        insert new List<Solicitud_Credito__c>{ antigua, reciente };
        Test.setCreatedDate(antigua.Id, Datetime.now().addDays(-40));

        Test.startTest();
        Database.executeBatch(new VencimientoSolicitudesBatch(), 1);
        Test.stopTest();

        Map<Id, Solicitud_Credito__c> resultados = new Map<Id, Solicitud_Credito__c>([
            SELECT Estado__c
            FROM Solicitud_Credito__c
            WHERE Id IN :new Set<Id>{ antigua.Id, reciente.Id }
        ]);
        Assert.areEqual(EstadoSolicitud.VENCIDA, resultados.get(antigua.Id).Estado__c);
        Assert.areEqual(
            EstadoSolicitud.PREAPROBADA,
            resultados.get(reciente.Id).Estado__c
        );
    }
}
