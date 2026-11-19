`default_nettype none

module tt_um_digital_safe (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    localparam [15:0] PIN_DEFAULT = 16'h1234;

    // Estados de la FSM
    localparam [1:0] S_LOCKED   = 2'd0;
    localparam [1:0] S_UNLOCKED = 2'd1;
    localparam [1:0] S_LOCKOUT  = 2'd2;

    // Códigos de evento para el registro de accesos
    localparam [1:0] EVT_GRANTED = 2'd1;
    localparam [1:0] EVT_DENIED  = 2'd2;
    localparam [1:0] EVT_LOCKOUT = 2'd3;

    // Mapeo de entradas
    wire [3:0] key_in    = ui_in[3:0];
    wire       key_valid = ui_in[4];
    wire       enter_btn = ui_in[5];
    wire       lock_btn  = ui_in[6];
    wire       log_mode  = ui_in[7];
    wire [2:0] log_addr  = uio_in[2:0];

    // Registros internos
    reg [1:0]  state;
    reg [15:0] pin_buffer;
    reg [2:0]  digit_cnt;
    reg [1:0]  fail_count;
    reg [5:0]  event_id;
    reg [2:0]  log_wr_ptr;
    reg [3:0]  log_count;

    // Buffer circular de 8 entradas de 8 bits: {evento[1:0], event_id[5:0]}
    reg [7:0] access_log [0:7];

    // Detectores de flanco de subida
    reg key_valid_d, enter_btn_d, lock_btn_d;
    wire key_pulse   = key_valid & ~key_valid_d;
    wire enter_pulse = enter_btn & ~enter_btn_d;
    wire lock_pulse  = lock_btn  & ~lock_btn_d;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_LOCKED;
            pin_buffer  <= 16'h0000;
            digit_cnt   <= 3'd0;
            fail_count  <= 2'd0;
            event_id    <= 6'd1;
            log_wr_ptr  <= 3'd0;
            log_count   <= 4'd0;
            key_valid_d <= 1'b0;
            enter_btn_d <= 1'b0;
            lock_btn_d  <= 1'b0;
            for (i = 0; i < 8; i = i + 1) begin
                access_log[i] <= 8'h00;
            end
        end else begin
            key_valid_d <= key_valid;
            enter_btn_d <= enter_btn;
            lock_btn_d  <= lock_btn;

            case (state)
                S_LOCKED: begin
                    if (key_pulse) begin
                        pin_buffer <= {pin_buffer[11:0], key_in};
                        if (digit_cnt < 3'd4)
                            digit_cnt <= digit_cnt + 3'd1;
                    end else if (enter_pulse) begin
                        if ((digit_cnt == 3'd4) && (pin_buffer == PIN_DEFAULT)) begin
                            state                  <= S_UNLOCKED;
                            fail_count             <= 2'd0;
                            access_log[log_wr_ptr] <= {EVT_GRANTED, event_id};
                        end else begin
                            if (fail_count == 2'd2) begin
                                state                  <= S_LOCKOUT;
                                fail_count             <= 2'd3;
                                access_log[log_wr_ptr] <= {EVT_LOCKOUT, event_id};
                            end else begin
                                fail_count             <= fail_count + 2'd1;
                                access_log[log_wr_ptr] <= {EVT_DENIED, event_id};
                            end
                        end

                        event_id   <= event_id + 6'd1;
                        log_wr_ptr <= log_wr_ptr + 3'd1;
                        if (log_count < 4'd8)
                            log_count <= log_count + 4'd1;

                        pin_buffer <= 16'h0000;
                        digit_cnt  <= 3'd0;
                    end
                end

                S_UNLOCKED: begin
                    if (lock_pulse) begin
                        state      <= S_LOCKED;
                        pin_buffer <= 16'h0000;
                        digit_cnt  <= 3'd0;
                    end
                end

                S_LOCKOUT: begin
                    state <= S_LOCKOUT;
                end

                default: begin
                    state <= S_LOCKED;
                end
            endcase
        end
    end

    wire unlocked = (state == S_UNLOCKED);
    wire alarm    = (state == S_LOCKOUT);
    wire [7:0] status_out = {log_count, fail_count, alarm, unlocked};

    assign uo_out  = log_mode ? access_log[log_addr] : status_out;
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    // Evitar warnings por señales no utilizadas
    wire _unused = &{ena, uio_in[7:3], 1'b0};

endmodule
