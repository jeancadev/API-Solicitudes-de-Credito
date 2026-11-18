@IsTest
private class EvaluadorCreditoTest {
    private static EvaluadorCredito crearEvaluador() {
        return new EvaluadorCredito(
            new ParametrosCredito(10000, 24, 0.40, 30)
        );
    }

    @IsTest
    static void apruebaCuandoCumpleTodasLasReglas() {
        EvaluadorCredito.Resultado resultado = crearEvaluador().evaluar(4000, 12, 1000);

        Assert.isTrue(resultado.aprobado);
        Assert.isNull(resultado.motivo);
    }

    @IsTest
    static void rechazaCuandoElMontoExcedeElMaximo() {
        EvaluadorCredito.Resultado resultado = crearEvaluador().evaluar(10001, 24, 2000);

        Assert.isFalse(resultado.aprobado);
        Assert.areEqual(Label.Credito_Monto_Excede_Maximo, resultado.motivo);
    }

    @IsTest
    static void rechazaCuandoElPlazoExcedeElMaximo() {
        EvaluadorCredito.Resultado resultado = crearEvaluador().evaluar(4000, 25, 1000);

        Assert.isFalse(resultado.aprobado);
        Assert.areEqual(Label.Credito_Plazo_Excede_Maximo, resultado.motivo);
    }

    @IsTest
    static void rechazaCuandoLaCuotaSuperaLaCapacidadDePago() {
        EvaluadorCredito.Resultado resultado = crearEvaluador().evaluar(5000, 10, 1000);

        Assert.isFalse(resultado.aprobado);
        Assert.areEqual(
            Label.Credito_Capacidad_Pago_Insuficiente,
            resultado.motivo
        );
    }

    @IsTest
    static void apruebaEnElBordeExactoDeRelacionCuotaIngreso() {
        // Cuota = 4000 / 10 = 400; 40 % de 1000 = 400.
        EvaluadorCredito.Resultado resultado = crearEvaluador().evaluar(4000, 10, 1000);

        Assert.isTrue(resultado.aprobado);
        Assert.isNull(resultado.motivo);
    }
}
