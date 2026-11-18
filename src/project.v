module tt_um_semisumador (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    assign uo_out = {6'b0, ui_in[1] & ui_in[0],
                     ui_in[1] ^ ui_in[0]};
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Las señales no utilizadas pueden omitirse deliberadamente.
endmodule
