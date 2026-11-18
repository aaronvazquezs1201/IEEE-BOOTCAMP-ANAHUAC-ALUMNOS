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
        .ACTIVE_LOW(1'b1)
    ) display_decoder (
        .bcd(ui_in[3:0]),
        .seg(seg)
    );

   assign uo_out  = {1'b0, seg};
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;
endmodule

module bcd_to_7seg_decoder #(
    parameter ACTIVE_LOW = 1'b0
) (
    input  wire [3:0] bcd,
    output wire [6:0] seg
);
    reg [6:0] seg_active_high;

    // Bit order: seg[6]=g, seg[5]=f, ..., seg[0]=a.
    always @(*) begin
        case (bcd)
            4'h0: seg_active_high = 7'b011_1111;
            4'h1: seg_active_high = 7'b000_0110;
            4'h2: seg_active_high = 7'b101_1011;
            4'h3: seg_active_high = 7'b100_1111;
            4'h4: seg_active_high = 7'b110_0110;
            4'h5: seg_active_high = 7'b110_1101;
            4'h6: seg_active_high = 7'b111_1101;
            4'h7: seg_active_high = 7'b000_0111;
            4'h8: seg_active_high = 7'b111_1111;
            4'h9: seg_active_high = 7'b110_1111;
            4'hA: seg_active_high = 7'b111_0111;
            4'hB: seg_active_high = 7'b111_1100;
            4'hC: seg_active_high = 7'b011_1001;
            4'hD: seg_active_high = 7'b101_1110;
            4'hE: seg_active_high = 7'b111_1001;
            4'hF: seg_active_high = 7'b111_0001;
            default: seg_active_high = 7'b000_0000;
        endcase
    end

    assign seg = ACTIVE_LOW ? ~seg_active_high : seg_active_high;

endmodule
