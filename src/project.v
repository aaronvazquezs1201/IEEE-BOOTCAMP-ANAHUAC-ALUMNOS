module tt_um_bcd_to_7seg_decoder (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    wire [6:0] seg;

    bcd_to_7seg_decoder #(
        .ACTIVE_LOW(1'b0) // 0 = Cátodo común (1 enciende el segmento)
    ) display_decoder (
        .bcd(ui_in[3:0]),
        .seg(seg)
    );

    assign uo_out  = {ui_in[4], seg}; // ui_in[4] controla el punto decimal (dp)
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire _unused = &{ena, clk, rst_n, ui_in[7:5], uio_in, 1'b0};
endmodule

    assign seg = ACTIVE_LOW ? ~seg_active_high : seg_active_high;

endmodule
