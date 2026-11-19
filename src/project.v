`default_nettype none

module tt_um_digital_safe (
    input  wire [7:0] ui_in,    // Entradas dedicadas
    output wire [7:0] uo_out,   // Display 1 de 7 segmentos: {dp, g, f, e, d, c, b, a}
    input  wire [7:0] uio_in,   // IOs entrada (no usadas)
    output wire [7:0] uio_out,  // Display 2 de 7 segmentos: {dp, g, f, e, d, c, b, a}
    output wire [7:0] uio_oe,   // Habilitación de IOs (1 = salida)
    input  wire       ena,      // Siempre 1 cuando el chip está encendido
    input  wire       clk,      // Reloj
    input  wire       rst_n     // Reset activo en bajo
);

    // Contraseña inicial tras reset
    localparam [3:0] PIN_DEFAULT = 4'hA;

    // Estados de la FSM
    localparam [1:0] S_LOCKED   = 2'd0;
    localparam [1:0] S_UNLOCKED = 2'd1;
    localparam [1:0] S_LOCKOUT  = 2'd2;

    // Tipos de evento en el registro de accesos
    localparam [1:0] EVT_EMPTY   = 2'd0;
    localparam [1:0] EVT_GRANTED = 2'd1;
    localparam [1:0] EVT_DENIED  = 2'd2;
    localparam [1:0] EVT_LOCKOUT = 2'd3;

    // Caracteres especiales en 7 segmentos {g, f, e, d, c, b, a} (cátodo común)
    localparam [6:0] SEG_U    = 7'b0111110; // U (Abierta)
    localparam [6:0] SEG_L    = 7'b0111000; // L (Bloqueada)
    localparam [6:0] SEG_P    = 7'b1110011; // P (Programar contraseña)
    localparam [6:0] SEG_DASH = 7'b1000000; // - (Registro vacío)
    localparam [6:0] SEG_A    = 7'b1110111; // A (Acceso aceptado)
    localparam [6:0] SEG_D    = 7'b1011110; // d (Acceso denegado)
    localparam [6:0] SEG_E    = 7'b1111001; // E (Error / Bloqueo)

    // Mapeo de entradas
    wire [3:0] key_in    = ui_in[3:0];
    wire       enter_btn = ui_in[4];
    wire       lock_btn  = ui_in[5];
    wire       log_mode  = ui_in[6];
    wire       prog_mode = ui_in[7];
    wire [2:0] log_addr  = ui_in[2:0];

    // Registros internos
    reg [1:0] state;
    reg [3:0] current_pin;
    reg [1:0] attempts_left;
    reg [2:0] log_wr_ptr;

    // Buffer circular de 8 accesos: {tipo_evento[1:0], codigo_hex[3:0]}
    reg [5:0] access_log [0:7];

    // Detectores de flanco de subida
    reg enter_btn_d;
    reg lock_btn_d;
    wire enter_pulse = enter_btn & ~enter_btn_d;
    wire lock_pulse  = lock_btn  & ~lock_btn_d;

    integer i;

    // Lógica secuencial
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_LOCKED;
            current_pin   <= PIN_DEFAULT;
            attempts_left <= 2'd3;
            log_wr_ptr    <= 3'd0;
            enter_btn_d   <= 1'b0;
            lock_btn_d    <= 1'b0;
            for (i = 0; i < 8; i = i + 1) begin
                access_log[i] <= 6'b00_0000;
            end
        end else begin
            enter_btn_d <= enter_btn;
            lock_btn_d  <= lock_btn;

            if (!log_mode) begin
                case (state)
                    S_LOCKED: begin
                        if (enter_pulse) begin
                            if (key_in == current_pin) begin
                                state                  <= S_UNLOCKED;
                                attempts_left          <= 2'd3;
                                access_log[log_wr_ptr] <= {EVT_GRANTED, key_in};
                            end else begin
                                if (attempts_left == 2'd1) begin
                                    state                  <= S_LOCKOUT;
                                    attempts_left          <= 2'd0;
                                    access_log[log_wr_ptr] <= {EVT_LOCKOUT, key_in};
                                end else begin
                                    attempts_left          <= attempts_left - 2'd1;
                                    access_log[log_wr_ptr] <= {EVT_DENIED, key_in};
                                end
                            end
                            log_wr_ptr <= log_wr_ptr + 3'd1;
                        end
                    end

                    S_UNLOCKED: begin
                        if (prog_mode && enter_pulse) begin
                            // Guarda la nueva contraseña de 4 bits
                            current_pin <= key_in;
                        end else if (lock_pulse) begin
                            state <= S_LOCKED;
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
    end

    // Decodificador hexadecimal (0-F) a 7 segmentos {g, f, e, d, c, b, a}
    function [6:0] hex_to_7seg;
        input [3:0] hex;
        begin
            case (hex)
                4'h0: hex_to_7seg = 7'b0111111;
                4'h1: hex_to_7seg = 7'b0000110;
                4'h2: hex_to_7seg = 7'b1011011;
                4'h3: hex_to_7seg = 7'b1001111;
                4'h4: hex_to_7seg = 7'b1100110;
                4'h5: hex_to_7seg = 7'b1101101;
                4'h6: hex_to_7seg = 7'b1111101;
                4'h7: hex_to_7seg = 7'b0000111;
                4'h8: hex_to_7seg = 7'b1111111;
                4'h9: hex_to_7seg = 7'b1101111;
                4'hA: hex_to_7seg = 7'b1110111;
                4'hB: hex_to_7seg = 7'b1111100;
                4'hC: hex_to_7seg = 7'b0111001;
                4'hD: hex_to_7seg = 7'b1011110;
                4'hE: hex_to_7seg = 7'b1111001;
                4'hF: hex_to_7seg = 7'b1110001;
                default: hex_to_7seg = 7'b0000000;
            endcase
        end
    endfunction

    // Lectura del registro seleccionado
    wire [5:0] selected_log  = access_log[log_addr];
    wire [1:0] selected_evt  = selected_log[5:4];
    wire [3:0] selected_code = selected_log[3:0];

    reg [6:0] disp1_seg;
    reg       disp1_dp;
    reg [6:0] disp2_seg;
    reg       disp2_dp;

    // Multiplexado de salidas para los 2 displays
    always @(*) begin
        if (log_mode) begin
            disp1_seg = (selected_evt == EVT_EMPTY) ? SEG_DASH : hex_to_7seg(selected_code);
            disp1_dp  = 1'b1;

            case (selected_evt)
                EVT_GRANTED: begin disp2_seg = SEG_A;    disp2_dp = 1'b1; end
                EVT_DENIED:  begin disp2_seg = SEG_D;    disp2_dp = 1'b1; end
                EVT_LOCKOUT: begin disp2_seg = SEG_E;    disp2_dp = 1'b1; end
                default:     begin disp2_seg = SEG_DASH; disp2_dp = 1'b0; end
            endcase
        end else if ((state == S_UNLOCKED) && prog_mode) begin
            // Modo programación: Display 1 = nuevo dígito elegido | Display 2 = 'P.'
            disp1_seg = hex_to_7seg(key_in);
            disp1_dp  = 1'b1;
            disp2_seg = SEG_P;
            disp2_dp  = 1'b1;
        end else begin
            case (state)
                S_UNLOCKED: begin disp1_seg = SEG_U;               disp1_dp = 1'b1; end
                S_LOCKOUT:  begin disp1_seg = SEG_L;               disp1_dp = 1'b0; end
                default:    begin disp1_seg = hex_to_7seg(key_in); disp1_dp = 1'b0; end
            endcase

            disp2_seg = hex_to_7seg({2'b00, attempts_left});
            disp2_dp  = (state == S_LOCKOUT);
        end
    end

    assign uo_out  = {disp1_dp, disp1_seg};
    assign uio_out = {disp2_dp, disp2_seg};
    assign uio_oe  = 8'hFF;

    wire _unused = &{ena, uio_in, 1'b0};

endmodule
