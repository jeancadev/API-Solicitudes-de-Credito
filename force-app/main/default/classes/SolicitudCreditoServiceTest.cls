@IsTest
private class SolicitudCreditoServiceTest {
    private static User crearUsuarioApi() {
        String identificadorUnico = String.valueOf(Crypto.getRandomLong()).replace('-', '');
        User usuario = new User(
            Alias = 'credapi',
            Email = 'credito.api.' + identificadorUnico + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'API',
            LanguageLocaleKey = 'es',
            LocaleSidKey = 'es_GT',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Guatemala',
            Username = 'credito.api.' + identificadorUnico + '@example.com'
        );
        insert usuario;
        PermissionSet permisos = [
            SELECT Id FROM PermissionSet WHERE Name = 'SolicitudCreditoApi' LIMIT 1
        ];
        insert new PermissionSetAssignment(
            AssigneeId = usuario.Id,
            PermissionSetId = permisos.Id
        );
        return usuario;
    }

    private static Account crearClienteCompartido(User usuarioApi) {
        User administrador = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Account cliente;
        System.runAs(administrador) {
            cliente = new Account(Name = 'Cliente idempotencia');
            insert cliente;
        }
        return cliente;
    }

    @IsTest
    static void creaSolicitudYReintentarNoGeneraDuplicado() {
        User usuarioApi = crearUsuarioApi();
        Account cliente = crearClienteCompartido(usuarioApi);

        SolicitudCreditoRequest peticion = new SolicitudCreditoRequest();
        peticion.externalId = 'IDEMPOTENTE-001';
        peticion.clienteId = cliente.Id;
        peticion.monto = 4000;
        peticion.plazoMeses = 10;
        peticion.ingresoMensual = 1000;

        SolicitudCreditoService servicio = new SolicitudCreditoService(
            new EvaluadorCredito(new ParametrosCredito(10000, 24, 0.40, 30))
        );

        Solicitud_Credito__c primera;
        Solicitud_Credito__c segunda;
        System.runAs(usuarioApi) {
            primera = servicio.crear(peticion);
            segunda = servicio.crear(peticion);
        }

        Assert.areEqual(primera.Id, segunda.Id);
        Assert.areEqual(
            1,
            [SELECT COUNT() FROM Solicitud_Credito__c WHERE External_Id__c = 'IDEMPOTENTE-001']
        );
        Assert.areEqual(EstadoSolicitud.PREAPROBADA, primera.Estado__c);
    }
}
