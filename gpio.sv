`include "defines.sv"

module gpio
(
input logic [`GPIO_WIDTH-1:0] gpio_out_reg,
output logic [`GPIO_WIDTH-1:0] gpio_out,

input logic [`GPIO_WIDTH-1:0] gpio_in,
output logic [`GPIO_WIDTH-1:0] gpio_in_sampled
);

assign gpio_out = gpio_out_reg;
assign gpio_in_sampled = gpio_in;

endmodule
