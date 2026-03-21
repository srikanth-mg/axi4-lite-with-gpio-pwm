`timescale 1ns / 1ps
`include "defines.svh"
// ----------------------------------------------------------------------
// Module : gpio
// Desc   : GPIO output driver + 2-flop synchroniser for async input pins.
//          The synchroniser prevents metastability when gpio_in comes
//          from external pads (asynchronous to ACLK).
// ----------------------------------------------------------------------
module gpio (
    input  logic                    clk,
    input  logic                    rst_n,

    // Register file interface
    input  logic [`GPIO_WIDTH-1:0]  gpio_out_reg,

    // External pad interface
    output logic [`GPIO_WIDTH-1:0]  gpio_out,
    input  logic [`GPIO_WIDTH-1:0]  gpio_in,

    // Synchronised input → goes to regfile for CPU reads
    output logic [`GPIO_WIDTH-1:0]  gpio_in_synced
);

    // ---- Output is direct drive from register ----
    assign gpio_out = gpio_out_reg;

    // ---- 2-flop synchroniser for async gpio_in ----
    logic [`GPIO_WIDTH-1:0] gpio_in_meta;  // first flop (may go metastable)
    logic [`GPIO_WIDTH-1:0] gpio_in_sync;  // second flop (stable)

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            gpio_in_meta <= '0;
            gpio_in_sync <= '0;
        end else begin
            gpio_in_meta <= gpio_in;       // capture async input
            gpio_in_sync <= gpio_in_meta;  // resolve metastability
        end
    end

    assign gpio_in_synced = gpio_in_sync;

endmodule
