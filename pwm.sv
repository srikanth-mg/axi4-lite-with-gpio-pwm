`timescale 1ns / 1ps
// ----------------------------------------------------------------------
// Module : pwm
// Desc   : PWM generator with registered output (glitch-free),
//          corrected period count, and zero-period protection.
//
// Fixes over original:
//   1. counter >= period-1 (not period) — correct cycle count
//   2. pwm_out is registered — no combinational glitch when
//      duty_cycle changes mid-count from a CPU write
//   3. Zero-period protection — output held low if period is 0
// ----------------------------------------------------------------------
module pwm (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] duty_cycle,
    input  logic [31:0] period,
    output logic        pwm_out
);

    logic [31:0] counter;
    logic        pwm_next;

    // ---- Counter ----
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            counter <= 32'd0;
        end else begin
            if (period == 32'd0 || counter >= period - 1)
                counter <= 32'd0;
            else
                counter <= counter + 32'd1;
        end
    end

    // ---- Compare (combinational) ----
    // Output high when counter < duty_cycle AND period is nonzero
    assign pwm_next = (period != 32'd0) && (counter < duty_cycle);

    // ---- Registered output — prevents glitch on mid-count duty change ----
    always_ff @(posedge clk) begin
        if (!rst_n)
            pwm_out <= 1'b0;
        else
            pwm_out <= pwm_next;
    end

endmodule
