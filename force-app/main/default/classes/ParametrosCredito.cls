public with sharing class ParametrosCredito {
    public final Decimal montoMaximo;
    public final Integer plazoMaximoMeses;
    public final Decimal maxRelacionCuotaIngreso;
    public final Integer diasVigencia;

    public ParametrosCredito(
        Decimal monto,
        Integer plazo,
        Decimal relacion,
        Integer dias
    ) {
        this.montoMaximo = monto;
        this.plazoMaximoMeses = plazo;
        this.maxRelacionCuotaIngreso = relacion;
        this.diasVigencia = dias;
    }

    public static ParametrosCredito cargar() {
        Parametro_Credito__mdt parametro = Parametro_Credito__mdt.getInstance('Default');
        if (parametro == null) {
            throw new ConfiguracionCreditoException(
                'No existe el parámetro de crédito Default.'
            );
        }
        return new ParametrosCredito(
            parametro.Monto_Maximo__c,
            parametro.Plazo_Maximo_Meses__c.intValue(),
            parametro.Relacion_Cuota_Ingreso_Maxima__c,
            parametro.Dias_Vigencia__c.intValue()
        );
    }

    public class ConfiguracionCreditoException extends Exception {}
}
