`default_nettype none

module tt_um_digital_safe (
    input  wire [7:0] ui_in,    // Entradas dedicadas
    output wire [7:0] uo_out,   // Display 1 de 7 segmentos: {dp, g, f, e, d, c, b, a}
    input  wire [7:0] uio_in,   // IOs entrada (no usadas)
    output wire [7:0] uio_out,  // Display 2 de 7 segmentos: {dp, g, f, e, d, c, b, a}
    output wire [7:0] uio_oe,   // Habilitación de IOs (1 = salida)
    input  wire       ena,      // Siempre 1 cuando el chip está encendido
    input  wire       clk,      // Reloj
    input  wire       rst_n     // Reset activo en bajo (reinicia también LOCKOUT)
);

    // Contraseña hexadecimal de 4 bits (cámbiala aquí si lo deseas)
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
    localparam [6:0] SEG_U    = 7'b0111110; // U (Unlocked / Abierta)
    localparam [6:0] SEG_L    = 7'b0111000; // L (Lockout / Bloqueada)
    localparam [6:0] SEG_DASH = 7'b1000000; // - (Registro vacío)
    localparam [6:0] SEG_A    = 7'b1110111; // A (Acceso aceptado)
    localparam [6:0] SEG_D    = 7'b1011110; // d (Acceso denegado)
    localparam [6:0] SEG_E    = 7'b1111001; // E (Error / Bloqueo)

    // Mapeo de entradas
    wire [3:0] key_in    = ui_in[3:0];
    wire       enter_btn = ui_in[4];
    wire       lock_btn  = ui_in[5];
    wire       log_mode  = ui_in[6];
    wire [2:0] log_addr  = ui_in[2:0];

    // Registros internos
    reg [1:0] state;
    reg [1:0] attempts_left;
    reg [2:0] log_wr_ptr;

    // Buffer circular de 8 accesos: {tipo_evento[1:0], codigo_hex[3:0]}
    reg [5:0] access_log [0:7];

    // Detectores de flanco de subida para los botones
    reg enter_btn_d;
    reg lock_btn_d;
    wire enter_pulse = enter_btn & ~enter_btn_d;
    wire lock_pulse  = lock_btn  & ~lock_btn_d;

    integer i;

    // Lógica secuencial (FSM + Registro de accesos)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_LOCKED;
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
                            if (key_in == PIN_DEFAULT) begin
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
                        if (lock_pulse) begin
                            state <= S_LOCKED;
                        end
                    end

                    S_LOCKOUT: begin
                        // Permanece bloqueada hasta activar rst_n
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
                4'h0: hex_to_7seg = 7'b0111111; // 0
                4'h1: hex_to_7seg = 7'b0000110; // 1
                4'h2: hex_to_7seg = 7'b1011011; // 2
                4'h3: hex_to_7seg = 7'b1001111; // 3
                4'h4: hex_to_7seg = 7'b1100110; // 4
                4'h5: hex_to_7seg = 7'b1101101; // 5
                4'h6: hex_to_7seg = 7'b1111101; // 6
                4'h7: hex_to_7seg = 7'b0000111; // 7
                4'h8: hex_to_7seg = 7'b1111111; // 8
                4'h9: hex_to_7seg = 7'b1101111; // 9
                4'hA: hex_to_7seg = 7'b1110111; // A
                4'hB: hex_to_7seg = 7'b1111100; // b
                4'hC: hex_to_7seg = 7'b0111001; // C
                4'hD: hex_to_7seg = 7'b1011110; // d
                4'hE: hex_to_7seg = 7'b1111001; // E
                4'hF: hex_to_7seg = 7'b1110001; // F
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
            // Display 1: código hex registrado | Display 2: resultado (A, d, E, -)
            disp1_seg = (selected_evt == EVT_EMPTY) ? SEG_DASH : hex_to_7seg(selected_code);
            disp1_dp  = 1'b1;

            case (selected_evt)
                EVT_GRANTED: begin disp2_seg = SEG_A;    disp2_dp = 1'b1; end
                EVT_DENIED:  begin disp2_seg = SEG_D;    disp2_dp = 1'b1; end
                EVT_LOCKOUT: begin disp2_seg = SEG_E;    disp2_dp = 1'b1; end
                default:     begin disp2_seg = SEG_DASH; disp2_dp = 1'b0; end
            endcase
        end else begin
            // Display 1: estado o dígito actual | Display 2: intentos restantes (3..0)
            case (state)
                S_UNLOCKED: begin disp1_seg = SEG_U;               disp1_dp = 1'b1; end
                S_LOCKOUT:  begin disp1_seg = SEG_L;               disp1_dp = 1'b0; end
                default:    begin disp1_seg = hex_to_7seg(key_in); disp1_dp = 1'b0; end
            endcase

            disp2_seg = hex_to_7seg({2'b00, attempts_left});
            disp2_dp  = (state == S_LOCKOUT);
        end
    end

    // Si usaras displays de ánodo común (activos en bajo), invierte con ~
    assign uo_out  = {disp1_dp, disp1_seg};
    assign uio_out = {disp2_dp, disp2_seg};
    assign uio_oe  = 8'hFF; // Todos los pines bidireccionales como salida para el Display 2

    wire _unused = &{ena, ui_in[7], uio_in, 1'b0};

endmodule
