`timescale 1ns / 1ps


`include "defines.svh"
// ----------------------------------------------------------------------
// Module : regfile
// Desc   : 4-register file for GPIO + PWM with byte-lane write strobes,
//          address validity reporting, and clean reset.
// ----------------------------------------------------------------------
module regfile #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  logic                        clk,
    input  logic                        rst_n,

    // Write interface
    input  logic                        write_en,
    input  logic [ADDR_WIDTH-1:0]       write_addr,
    input  logic [DATA_WIDTH-1:0]       write_data,
    input  logic [(DATA_WIDTH/8)-1:0]   write_strb,

    // Read interface
    input  logic [ADDR_WIDTH-1:0]       read_addr,
    output logic [DATA_WIDTH-1:0]       read_data,

    // Address validity (combinational, for AXI response)
    output logic                        write_addr_valid,
    output logic                        read_addr_valid,

    // GPIO interface
    output logic [`GPIO_WIDTH-1:0]      gpio_out,
    input  logic [`GPIO_WIDTH-1:0]      gpio_in_synced,  // already synchronised externally

    // PWM interface
    output logic [31:0]                 pwm_duty,
    output logic [31:0]                 pwm_period
);

    // ---- Registers ----
    logic [31:0] reg_gpio_out;
    logic [31:0] reg_pwm_ctrl;
    logic [31:0] reg_pwm_period;

    // ---- Address Validity (combinational) ----
    always_comb begin
        case (write_addr)
            `GPIO_OUT_ADDR,
            `PWM_CTRL_ADDR,
            `PWM_PERIOD_ADDR: write_addr_valid = 1'b1;
            default:          write_addr_valid = 1'b0;  // GPIO_IN is read-only, others unmapped
        endcase
    end

    always_comb begin
        case (read_addr)
            `GPIO_OUT_ADDR,
            `GPIO_IN_ADDR,
            `PWM_CTRL_ADDR,
            `PWM_PERIOD_ADDR: read_addr_valid = 1'b1;
            default:          read_addr_valid = 1'b0;
        endcase
    end

    // ---- Write Logic with Byte-Lane Strobes ----
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            reg_gpio_out   <= `GPIO_OUT_RST;
            reg_pwm_ctrl   <= `PWM_CTRL_RST;
            reg_pwm_period <= `PWM_PERIOD_RST;
        end else if (write_en) begin
            case (write_addr)
                `GPIO_OUT_ADDR: begin
                    if (write_strb[0]) reg_gpio_out[7:0]   <= write_data[7:0];
                    if (write_strb[1]) reg_gpio_out[15:8]  <= write_data[15:8];
                    if (write_strb[2]) reg_gpio_out[23:16] <= write_data[23:16];
                    if (write_strb[3]) reg_gpio_out[31:24] <= write_data[31:24];
                end
                `PWM_CTRL_ADDR: begin
                    if (write_strb[0]) reg_pwm_ctrl[7:0]   <= write_data[7:0];
                    if (write_strb[1]) reg_pwm_ctrl[15:8]  <= write_data[15:8];
                    if (write_strb[2]) reg_pwm_ctrl[23:16] <= write_data[23:16];
                    if (write_strb[3]) reg_pwm_ctrl[31:24] <= write_data[31:24];
                end
                `PWM_PERIOD_ADDR: begin
                    if (write_strb[0]) reg_pwm_period[7:0]   <= write_data[7:0];
                    if (write_strb[1]) reg_pwm_period[15:8]  <= write_data[15:8];
                    if (write_strb[2]) reg_pwm_period[23:16] <= write_data[23:16];
                    if (write_strb[3]) reg_pwm_period[31:24] <= write_data[31:24];
                end
                default: ; // GPIO_IN is read-only; unmapped addrs ignored
            endcase
        end
    end

    // ---- Read Logic (combinational) ----
    always_comb begin
        case (read_addr)
            `GPIO_OUT_ADDR:   read_data = reg_gpio_out;
            `GPIO_IN_ADDR:    read_data = {{(32-`GPIO_WIDTH){1'b0}}, gpio_in_synced};
            `PWM_CTRL_ADDR:   read_data = reg_pwm_ctrl;
            `PWM_PERIOD_ADDR: read_data = reg_pwm_period;
            default:          read_data = 32'hDEAD_BEEF;  // unmapped — slave will report SLVERR
        endcase
    end

    // ---- Output Assignments ----
    assign gpio_out   = reg_gpio_out[`GPIO_WIDTH-1:0];
    assign pwm_duty   = reg_pwm_ctrl;
    assign pwm_period = reg_pwm_period;

endmodule
