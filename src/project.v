module tt_um_bcd_to_7seg #(
    parameter ACTIVE_LOW = 1'b1 // 1 = Ánodo Común (enciende con 0), 0 = Cátodo Común (enciende con 1)
)(
    input  wire [3:0] bcd,      // Entrada BCD (0 a 9) o Hex (0 a F)
    output wire [6:0] seg       // Salida segmentos: {g, f, e, d, c, b, a} -> seg[0]=a ... seg[6]=g
);

    reg [6:0] seg_active_high;

    // Decodificación asumiendo lógica positiva (1 = segmento encendido)
    // Orden de bits: seg[6]=g, seg[5]=f, seg[4]=e, seg[3]=d, seg[2]=c, seg[1]=b, seg[0]=a
    always @(*) begin
        case (bcd)
            4'h0: seg_active_high = 7'b011_1111; // 0
            4'h1: seg_active_high = 7'b000_0110; // 1
            4'h2: seg_active_high = 7'b101_1011; // 2
            4'h3: seg_active_high = 7'b100_1111; // 3
            4'h4: seg_active_high = 7'b110_0110; // 4
            4'h5: seg_active_high = 7'b110_1101; // 5
            4'h6: seg_active_high = 7'b111_1101; // 6
            4'h7: seg_active_high = 7'b000_0111; // 7
            4'h8: seg_active_high = 7'b111_1111; // 8
            4'h9: seg_active_high = 7'b110_1111; // 9
            // Caracteres extra útiles para depuración o para la caja fuerte:
            4'hA: seg_active_high = 7'b111_0111; // A
            4'hB: seg_active_high = 7'b111_1100; // b
            4'hC: seg_active_high = 7'b011_1001; // C (Closed)
            4'hD: seg_active_high = 7'b101_1110; // d
            4'hE: seg_active_high = 7'b111_1001; // E (Error)
            4'hF: seg_active_high = 7'b111_0001; // F
            default: seg_active_high = 7'b000_0000; // Apagado
        endcase
    end

    // Invierte los bits automáticamente si se configura para Ánodo Común
    assign seg = ACTIVE_LOW ? ~seg_active_high : seg_active_high;

endmodule
