
`timescale 1ns/1ps

// ================================================
// MULTIPLICADOR BINARIO DE 4 BITS
// Entrada: 8 bits (dos numeros de 4 bits)
// Salida: 8 bits
// Flip-flops: Tipo D
// ================================================


// ================================================
// MODULO 1: MULTIPLICADOR COMBINACIONAL
// ================================================

module tt_um_ multiplicador_4bits (
    input wire [7:0] datos_in,
    output wire [7:0] producto
);

    wire [3:0] A;
    wire [3:0] B;

    assign A = datos_in[7:4];
    assign B = datos_in[3:0];

    // Productos parciales
    wire [7:0] pp0;
    wire [7:0] pp1;
    wire [7:0] pp2;
    wire [7:0] pp3;

    assign pp0 = {4'b0000, (A & {4{B[0]}})};
    assign pp1 = {3'b000, (A & {4{B[1]}}), 1'b0};
    assign pp2 = {2'b00, (A & {4{B[2]}}), 2'b00};
    assign pp3 = {1'b0, (A & {4{B[3]}}), 3'b000};

    // Suma de productos parciales
    assign producto = pp0 + pp1 + pp2 + pp3;

endmodule


// ================================================
// MODULO 2: FLIP-FLOP TIPO D
// ================================================

module flip_flop_d (
    input wire clk,
    input wire reset,
    input wire D,
    output reg Q
);

    always @(posedge clk) begin
        if (reset)
            Q <= 1'b0;
        else
            Q <= D;
    end

endmodule


// ================================================
// MODULO 3: MULTIPLICADOR REGISTRADO
// MODULO PRINCIPAL DEL CIRCUITO
// ================================================

module multiplicador_registrado (
    input wire clk,
    input wire reset,
    input wire [7:0] datos_in,
    output wire [7:0] resultado
);

    wire [7:0] producto_interno;

    // Multiplicador de 4 bits
    multiplicador_4bits MULT (
        .datos_in(datos_in),
        .producto(producto_interno)
    );

    // Ocho flip-flops tipo D
    genvar i;

    generate
        for (i = 0; i < 8; i = i + 1) begin : FF_D

            flip_flop_d FF (
                .clk(clk),
                .reset(reset),
                .D(producto_interno[i]),
                .Q(resultado[i])
            );

        end
    endgenerate

endmodule


// ================================================
// MODULO 4: TESTBENCH
// COMPROBACION DE 256 MULTIPLICACIONES
// SOLO PARA SIMULACION
// ================================================

module tb_multiplicador;

    reg clk;
    reg reset;
    reg [7:0] datos_in;

    wire [7:0] resultado;

    integer a;
    integer b;
    integer errores;
    reg [7:0] esperado;

    // Instancia del circuito principal
    multiplicador_registrado DUT (
        .clk(clk),
        .reset(reset),
        .datos_in(datos_in),
        .resultado(resultado)
    );

    // Generador de reloj
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        reset = 1;
        datos_in = 8'b00000000;
        errores = 0;
        esperado = 0;

        // Aplicar reset durante un flanco
        @(posedge clk);
        #1;

        if (resultado !== 8'b00000000) begin
            $display("ERROR EN RESET");
            errores = errores + 1;
        end

        @(negedge clk);
        reset = 0;

        // Probar las 256 combinaciones
        for (a = 0; a < 16; a = a + 1) begin
            for (b = 0; b < 16; b = b + 1) begin

                @(negedge clk);

                datos_in = {a[3:0], b[3:0]};
                esperado = a * b;

                @(posedge clk);
                #1;

                if (resultado !== esperado) begin
                    $display(
                        "ERROR: %0d x %0d = %0d, esperado %0d",
                        a, b, resultado, esperado
                    );
                    errores = errores + 1;
                end
                else begin
                    $display(
                        "OK: %0d x %0d = %0d",
                        a, b, resultado
                    );
                end

            end
        end

        // Resultado final
        $display("================================");

        if (errores == 0)
            $display("EXITO: TODAS LAS PRUEBAS PASARON");
        else
            $display("TOTAL DE ERRORES: %0d", errores);

        $display("================================");

        $finish;

    end

endmodule
