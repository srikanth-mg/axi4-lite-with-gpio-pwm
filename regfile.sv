`include "defines.sv"

module regfile
#(parameter ADDR_WIDTH = 4,
 parameter DATA_WIDTH = 32)
(
input logic clk,
input logic rst_n,

input logic write_en,
input logic [ADDR_WIDTH-1:0] write_addr,
input logic [DATA_WIDTH-1:0] write_data,

input logic [ADDR_WIDTH-1:0] read_addr,
output logic [DATA_WIDTH-1:0] read_data,

output logic [`GPIO_WIDTH-1:0] gpio_out,
input logic [`GPIO_WIDTH-1:0] gpio_in,

output logic [31:0] pwm_duty,
output logic [31:0] pwm_period
);

logic [31:0] reg_gpio_out;
logic [31:0] reg_pwm_ctrl;
logic [31:0] reg_pwm_period;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        reg_gpio_out  <= `GPIO_OUT_RST;
        reg_pwm_ctrl  <= `PWM_CTRL_RST;
        reg_pwm_period <= `PWM_PERIOD_RST;
    end else begin
        if (write_en) begin
            case (write_addr)
                `GPIO_OUT_ADDR:   reg_gpio_out   <= write_data;
                `PWM_CTRL_ADDR:   reg_pwm_ctrl   <= write_data;
                `PWM_PERIOD_ADDR: reg_pwm_period <= write_data;
                default: /* invalid*/ ;
            endcase
        end
    end
end

always_comb begin
    case (read_addr)
        `GPIO_OUT_ADDR:   read_data = reg_gpio_out;
        `GPIO_IN_ADDR:    read_data = {24'h0, gpio_in};
        `PWM_CTRL_ADDR:   read_data = reg_pwm_ctrl;
        `PWM_PERIOD_ADDR: read_data = reg_pwm_period;
        default:           read_data = 32'hDEAD_BEEF;
    endcase
end


assign gpio_out   = reg_gpio_out[`GPIO_WIDTH-1:0];
assign pwm_duty   = reg_pwm_ctrl;
assign pwm_period = reg_pwm_period;

endmodule