`include "defines.sv"

module axi_gpio_pwm #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  logic                         ACLK,
    input  logic                         ARESET_N,

    // AXI4-Lite Slave Interface i/o's
    input  logic [ADDR_WIDTH-1:0]        AWADDR,
    input  logic                         AWVALID,
    output logic                         AWREADY,

    input  logic [DATA_WIDTH-1:0]        WDATA,
    input  logic [(DATA_WIDTH/8)-1:0]    WSTRB,
    input  logic                         WVALID,
    output logic                         WREADY,

    output logic [1:0]                   BRESP,
    output logic                         BVALID,
    input  logic                         BREADY,

    input  logic [ADDR_WIDTH-1:0]        ARADDR,
    input  logic                         ARVALID,
    output logic                         ARREADY,

    output logic [DATA_WIDTH-1:0]        RDATA,
    output logic [1:0]                   RRESP,
    output logic                         RVALID,
    input  logic                         RREADY,

    // External GPIO pins i/o's
    input  logic [`GPIO_WIDTH-1:0]       gpio_in,
    output logic [`GPIO_WIDTH-1:0]       gpio_out,

    // PWM output
    output logic                         pwm_out
);

logic write_en;
logic [ADDR_WIDTH-1:0] write_addr;
logic [DATA_WIDTH-1:0] write_data;

logic [DATA_WIDTH-1:0] read_data;

logic [`GPIO_WIDTH-1:0] gpio_out_reg;

logic [`GPIO_WIDTH-1:0] gpio_in_sampled;

logic [31:0] pwm_duty;
logic [31:0] pwm_period;


axi4_slave #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) A1 (
    .ACLK       (ACLK),
    .ARESET_N    (ARESET_N),

    .AWADDR     (AWADDR),
    .AWVALID    (AWVALID),
    .AWREADY    (AWREADY),

    .WDATA      (WDATA),
    .WSTRB      (WSTRB),
    .WVALID     (WVALID),
    .WREADY     (WREADY),

    .BRESP      (BRESP),
    .BVALID     (BVALID),
    .BREADY     (BREADY),

    .ARADDR     (ARADDR),
    .ARVALID    (ARVALID),
    .ARREADY    (ARREADY),

    .RDATA      (RDATA),
    .RRESP      (RRESP),
    .RVALID     (RVALID),
    .RREADY     (RREADY),

    .write_en   (write_en),
    .write_addr (write_addr),
    .write_data (write_data),

    .read_data  (read_data)
);

regfile REGFILE (
    .clk         (ACLK),
    .rst_n        (ARESET_N),

    .write_en    (write_en),
    .write_addr  (write_addr),
    .write_data  (write_data),

    .read_addr   (ARADDR),
    .read_data   (read_data),

    .gpio_out    (gpio_out_reg),
    .gpio_in     (gpio_in),

    .pwm_duty    (pwm_duty),
    .pwm_period  (pwm_period)
);

gpio GPIO (
    .gpio_out_reg   (gpio_out_reg),
    .gpio_out       (gpio_out),
    .gpio_in        (gpio_in),
    .gpio_in_sampled(gpio_in_sampled)
);

pwm PWM (
    .clk        (ACLK),
    .rst_n       (ARESET_N),
    .duty_cycle   (pwm_duty),
    .period     (pwm_period),
    .pwm_out    (pwm_out)
);

endmodule