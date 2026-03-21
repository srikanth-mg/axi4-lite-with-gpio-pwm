`ifndef DEFINES_SVH
`define DEFINES_SVH

// ---- Register Address Map ----
`define GPIO_OUT_ADDR    4'h0
`define GPIO_IN_ADDR     4'h4
`define PWM_CTRL_ADDR    4'h8
`define PWM_PERIOD_ADDR  4'hC

// ---- Reset Values ----
`define GPIO_OUT_RST     32'h0000_0000
`define PWM_CTRL_RST     32'h0000_0000
`define PWM_PERIOD_RST   32'd1000

// ---- Widths ----
`define GPIO_WIDTH       8

// ---- AXI Response Codes ----
`define RESP_OKAY        2'b00
`define RESP_SLVERR      2'b10
`define RESP_DECERR      2'b11

`endif
