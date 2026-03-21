`timescale 1ns / 1ps
`include "defines.svh"
// ----------------------------------------------------------------------
// Module : axi_gpio_pwm_top
// Desc   : Top-level SoC peripheral integrating AXI4-Lite slave,
//          register file, GPIO (with CDC sync), and PWM.
// ----------------------------------------------------------------------
module axi_gpio_pwm_top #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  logic                        ACLK,
    input  logic                        ARESETn,

    // AXI4-Lite Slave Interface
    input  logic [ADDR_WIDTH-1:0]       AWADDR,
    input  logic                        AWVALID,
    output logic                        AWREADY,

    input  logic [DATA_WIDTH-1:0]       WDATA,
    input  logic [(DATA_WIDTH/8)-1:0]   WSTRB,
    input  logic                        WVALID,
    output logic                        WREADY,

    output logic [1:0]                  BRESP,
    output logic                        BVALID,
    input  logic                        BREADY,

    input  logic [ADDR_WIDTH-1:0]       ARADDR,
    input  logic                        ARVALID,
    output logic                        ARREADY,

    output logic [DATA_WIDTH-1:0]       RDATA,
    output logic [1:0]                  RRESP,
    output logic                        RVALID,
    input  logic                        RREADY,

    // External GPIO pads
    input  logic [`GPIO_WIDTH-1:0]      gpio_in,
    output logic [`GPIO_WIDTH-1:0]      gpio_out,

    // PWM output
    output logic                        pwm_out
);

    // ---- Internal wires ----
    logic                        write_en;
    logic [ADDR_WIDTH-1:0]       write_addr;
    logic [DATA_WIDTH-1:0]       write_data;
    logic [(DATA_WIDTH/8)-1:0]   write_strb;
    logic [DATA_WIDTH-1:0]       read_data;
    logic                        write_addr_valid;
    logic                        read_addr_valid;

    logic [`GPIO_WIDTH-1:0]      gpio_out_reg;
    logic [`GPIO_WIDTH-1:0]      gpio_in_synced;
    logic [31:0]                 pwm_duty;
    logic [31:0]                 pwm_period;

    // ---- AXI4-Lite Slave Interface ----
    axi4_lite_slave #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_axi_slave (
        .ACLK             (ACLK),
        .ARESETn          (ARESETn),
        // AW
        .AWADDR           (AWADDR),
        .AWVALID          (AWVALID),
        .AWREADY          (AWREADY),
        // W
        .WDATA            (WDATA),
        .WSTRB            (WSTRB),
        .WVALID           (WVALID),
        .WREADY           (WREADY),
        // B
        .BRESP            (BRESP),
        .BVALID           (BVALID),
        .BREADY           (BREADY),
        // AR
        .ARADDR           (ARADDR),
        .ARVALID          (ARVALID),
        .ARREADY          (ARREADY),
        // R
        .RDATA            (RDATA),
        .RRESP            (RRESP),
        .RVALID           (RVALID),
        .RREADY           (RREADY),
        // Regfile interface
        .write_en         (write_en),
        .write_addr       (write_addr),
        .write_data       (write_data),
        .write_strb       (write_strb),
        .read_data        (read_data),
        .write_addr_valid (write_addr_valid),
        .read_addr_valid  (read_addr_valid)
    );

    // ---- Register File ----
    regfile #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_regfile (
        .clk              (ACLK),
        .rst_n            (ARESETn),
        .write_en         (write_en),
        .write_addr       (write_addr),
        .write_data       (write_data),
        .write_strb       (write_strb),
        .read_addr        (ARADDR),
        .read_data        (read_data),
        .write_addr_valid (write_addr_valid),
        .read_addr_valid  (read_addr_valid),
        .gpio_out         (gpio_out_reg),
        .gpio_in_synced   (gpio_in_synced),
        .pwm_duty         (pwm_duty),
        .pwm_period       (pwm_period)
    );

    // ---- GPIO with CDC Synchroniser ----
    gpio u_gpio (
        .clk            (ACLK),
        .rst_n          (ARESETn),
        .gpio_out_reg   (gpio_out_reg),
        .gpio_out       (gpio_out),
        .gpio_in        (gpio_in),
        .gpio_in_synced (gpio_in_synced)
    );

    // ---- PWM Generator ----
    pwm u_pwm (
        .clk        (ACLK),
        .rst_n      (ARESETn),
        .duty_cycle (pwm_duty),
        .period     (pwm_period),
        .pwm_out    (pwm_out)
    );

endmodule
