/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module semisumador (
    input wire a,       // Entrada A
    input wire b,       // Entrada B
    output wire suma,   // Salida de Suma (A XOR B)
    output wire acarreo // Salida de Acarreo (A AND B)
);

    // Asignación de la suma mediante operador XOR
    assign suma = a ^ b;
    
    // Asignación del acarreo mediante operador AND
    assign acarreo = a & b;

endmodule
