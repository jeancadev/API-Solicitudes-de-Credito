public with sharing class EvaluadorCredito {
    public class Resultado {
        public Boolean aprobado;
        public String motivo;

        public Resultado(Boolean aprobado, String motivo) {
            this.aprobado = aprobado;
            this.motivo = motivo;
        }
    }

    private final ParametrosCredito parametros;

    public EvaluadorCredito(ParametrosCredito parametros) {
        this.parametros = parametros;
    }

    public Resultado evaluar(
        Decimal monto,
        Integer plazoMeses,
        Decimal ingresoMensual
    ) {
        if (monto > parametros.montoMaximo) {
            return new Resultado(false, Label.Credito_Monto_Excede_Maximo);
        }
        if (plazoMeses > parametros.plazoMaximoMeses) {
            return new Resultado(false, Label.Credito_Plazo_Excede_Maximo);
        }

        Decimal cuota = monto.divide(plazoMeses, 2, RoundingMode.HALF_UP);
        if (cuota > ingresoMensual * parametros.maxRelacionCuotaIngreso) {
            return new Resultado(false, Label.Credito_Capacidad_Pago_Insuficiente);
        }
        return new Resultado(true, null);
    }
}
