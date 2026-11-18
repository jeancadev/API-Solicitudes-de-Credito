public with sharing class SolicitudCreditoService {
    private final EvaluadorCredito evaluador;

    public SolicitudCreditoService(EvaluadorCredito evaluador) {
        this.evaluador = evaluador;
    }

    public SolicitudCreditoService() {
        this(new EvaluadorCredito(ParametrosCredito.cargar()));
    }

    public Solicitud_Credito__c crear(SolicitudCreditoRequest solicitud) {
        Solicitud_Credito__c existente = SolicitudSelector.porExternalId(
            solicitud.externalId
        );
        if (existente != null) {
            return existente;
        }

        EvaluadorCredito.Resultado resultado = evaluador.evaluar(
            solicitud.monto,
            solicitud.plazoMeses,
            solicitud.ingresoMensual
        );
        Solicitud_Credito__c nueva = new Solicitud_Credito__c(
            External_Id__c = solicitud.externalId,
            Cliente__c = solicitud.clienteId,
            Monto__c = solicitud.monto,
            Plazo_Meses__c = solicitud.plazoMeses,
            Ingreso_Mensual__c = solicitud.ingresoMensual,
            Estado__c = resultado.aprobado
                ? EstadoSolicitud.PREAPROBADA
                : EstadoSolicitud.RECHAZADA,
            Motivo_Rechazo__c = resultado.motivo
        );

        try {
            insert as user nueva;
            return nueva;
        } catch (DmlException excepcion) {
            // La restricción Unique resuelve la carrera entre dos POST iguales.
            Solicitud_Credito__c creadaPorOtraPeticion =
                SolicitudSelector.porExternalId(solicitud.externalId);
            if (creadaPorOtraPeticion != null) {
                return creadaPorOtraPeticion;
            }
            throw excepcion;
        }
    }
}
