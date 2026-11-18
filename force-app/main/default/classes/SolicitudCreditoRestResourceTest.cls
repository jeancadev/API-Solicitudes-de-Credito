@IsTest
private class SolicitudCreditoRestResourceTest {
    private static User crearUsuarioApi() {
        String identificadorUnico = String.valueOf(Crypto.getRandomLong()).replace('-', '');
        User usuario = new User(
            Alias = 'credapi',
            Email = 'credito.rest.' + identificadorUnico + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'API',
            LanguageLocaleKey = 'es',
            LocaleSidKey = 'es_GT',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Guatemala',
            Username = 'credito.rest.' + identificadorUnico + '@example.com'
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
            cliente = new Account(Name = 'Cliente REST');
            insert cliente;
        }
        return cliente;
    }

    private static void crearSolicitudPreaprobada(Account cliente) {
        User administrador = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(administrador) {
            insert new Solicitud_Credito__c(
                Cliente__c = cliente.Id,
                External_Id__c = 'GET-001',
                Monto__c = 1000,
                Plazo_Meses__c = 10,
                Ingreso_Mensual__c = 1000,
                Estado__c = EstadoSolicitud.PREAPROBADA
            );
        }
    }

    private static void prepararRequest(
        String metodo,
        String uri,
        String cuerpo
    ) {
        RestRequest peticion = new RestRequest();
        peticion.requestUri = uri;
        peticion.httpMethod = metodo;
        if (cuerpo != null) {
            peticion.requestBody = Blob.valueOf(cuerpo);
        }
        RestContext.request = peticion;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void postValidoDevuelve201() {
        User usuarioApi = crearUsuarioApi();
        Account cliente = crearClienteCompartido(usuarioApi);
        SolicitudCreditoRequest cuerpo = new SolicitudCreditoRequest();
        cuerpo.externalId = 'REST-001';
        cuerpo.clienteId = cliente.Id;
        cuerpo.monto = 4000;
        cuerpo.plazoMeses = 10;
        cuerpo.ingresoMensual = 1000;
        prepararRequest(
            'POST',
            '/services/apexrest/solicitudes/v1',
            JSON.serialize(cuerpo)
        );

        System.runAs(usuarioApi) {
            Test.startTest();
            SolicitudCreditoRestResource.crear();
            Test.stopTest();
        }

        Assert.areEqual(201, RestContext.response.statusCode);
        SolicitudCreditoResponse respuesta = (SolicitudCreditoResponse) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            SolicitudCreditoResponse.class
        );
        Assert.areEqual('REST-001', respuesta.externalId);
        Assert.areEqual(EstadoSolicitud.PREAPROBADA, respuesta.estado);
    }

    @IsTest
    static void postConCamposFaltantesDevuelve400() {
        prepararRequest('POST', '/services/apexrest/solicitudes/v1', '{}');

        SolicitudCreditoRestResource.crear();

        Assert.areEqual(400, RestContext.response.statusCode);
        Assert.isTrue(
            RestContext.response.responseBody.toString().contains('externalId es requerido')
        );
    }

    @IsTest
    static void postConJsonInvalidoDevuelve400() {
        prepararRequest('POST', '/services/apexrest/solicitudes/v1', '{ no-es-json }');

        SolicitudCreditoRestResource.crear();

        Assert.areEqual(400, RestContext.response.statusCode);
        Assert.isTrue(RestContext.response.responseBody.toString().contains('JSON inválido'));
    }

    @IsTest
    static void getExistenteDevuelve200() {
        User usuarioApi = crearUsuarioApi();
        Account cliente = crearClienteCompartido(usuarioApi);
        crearSolicitudPreaprobada(cliente);
        prepararRequest('GET', '/services/apexrest/solicitudes/v1/GET-001', null);

        System.runAs(usuarioApi) {
            SolicitudCreditoRestResource.obtener();
        }

        Assert.areEqual(200, RestContext.response.statusCode);
        Assert.isTrue(RestContext.response.responseBody.toString().contains('GET-001'));
    }

    @IsTest
    static void getInexistenteDevuelve404() {
        User usuarioApi = crearUsuarioApi();
        prepararRequest('GET', '/services/apexrest/solicitudes/v1/SIN-EXISTIR', null);

        System.runAs(usuarioApi) {
            SolicitudCreditoRestResource.obtener();
        }

        Assert.areEqual(404, RestContext.response.statusCode);
        Assert.isTrue(
            RestContext.response.responseBody.toString().contains('Solicitud no encontrada')
        );
    }
}
