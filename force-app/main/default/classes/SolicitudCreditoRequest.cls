public with sharing class SolicitudCreditoRequest {
    public String externalId;
    public Id clienteId;
    public Decimal monto;
    public Integer plazoMeses;
    public Decimal ingresoMensual;

    public List<String> validar() {
        List<String> errores = new List<String>();
        if (String.isBlank(externalId)) {
            errores.add('externalId es requerido');
        }
        if (clienteId == null) {
            errores.add('clienteId es requerido');
        }
        if (monto == null || monto <= 0) {
            errores.add('monto debe ser mayor a 0');
        }
        if (plazoMeses == null || plazoMeses <= 0) {
            errores.add('plazoMeses debe ser mayor a 0');
        }
        if (ingresoMensual == null || ingresoMensual <= 0) {
            errores.add('ingresoMensual debe ser mayor a 0');
        }
        return errores;
    }
}
