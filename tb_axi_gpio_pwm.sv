`timescale 1ns / 1ps
`include "defines.svh"
// ----------------------------------------------------------------------
// Module : tb_axi_gpio_pwm
// Desc   : Directed testbench for AXI4-Lite GPIO/PWM peripheral.
//          iverilog-compatible (no 'iff', no 'automatic', Verilog-style tasks)
// ----------------------------------------------------------------------
module tb_axi_gpio_pwm;

    localparam ADDR_WIDTH = 4;
    localparam DATA_WIDTH = 32;
    localparam CLK_PERIOD = 10;

    reg                        ACLK;
    reg                        ARESETn;
    reg  [ADDR_WIDTH-1:0]      AWADDR;
    reg                        AWVALID;
    wire                       AWREADY;
    reg  [DATA_WIDTH-1:0]      WDATA;
    reg  [(DATA_WIDTH/8)-1:0]  WSTRB;
    reg                        WVALID;
    wire                       WREADY;
    wire [1:0]                 BRESP;
    wire                       BVALID;
    reg                        BREADY;
    reg  [ADDR_WIDTH-1:0]      ARADDR;
    reg                        ARVALID;
    wire                       ARREADY;
    wire [DATA_WIDTH-1:0]      RDATA;
    wire [1:0]                 RRESP;
    wire                       RVALID;
    reg                        RREADY;
    reg  [`GPIO_WIDTH-1:0]     gpio_in;
    wire [`GPIO_WIDTH-1:0]     gpio_out;
    wire                       pwm_out;

    integer pass_count;
    integer fail_count;
    reg [1:0]            wr_resp;
    reg [DATA_WIDTH-1:0] rd_data;
    reg [1:0]            rd_resp;
    integer              high_count;
    integer              i;

    // ---- Clock ----
    initial ACLK = 1'b0;
    always #(CLK_PERIOD/2) ACLK = ~ACLK;

    // ---- DUT ----
    axi_gpio_pwm_top #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) dut (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),
        .AWADDR  (AWADDR),
        .AWVALID (AWVALID),
        .AWREADY (AWREADY),
        .WDATA   (WDATA),
        .WSTRB   (WSTRB),
        .WVALID  (WVALID),
        .WREADY  (WREADY),
        .BRESP   (BRESP),
        .BVALID  (BVALID),
        .BREADY  (BREADY),
        .ARADDR  (ARADDR),
        .ARVALID (ARVALID),
        .ARREADY (ARREADY),
        .RDATA   (RDATA),
        .RRESP   (RRESP),
        .RVALID  (RVALID),
        .RREADY  (RREADY),
        .gpio_in (gpio_in),
        .gpio_out(gpio_out),
        .pwm_out (pwm_out)
    );

    // ================================================================
    //  Helper Tasks
    // ================================================================

    task reset_dut;
    begin
        ARESETn  = 1'b0;
        AWVALID  = 1'b0;
        WVALID   = 1'b0;
        BREADY   = 1'b0;
        ARVALID  = 1'b0;
        RREADY   = 1'b0;
        AWADDR   = 0;
        WDATA    = 0;
        WSTRB    = 0;
        ARADDR   = 0;
        gpio_in  = 0;
        pass_count = 0;
        fail_count = 0;
        repeat (5) @(posedge ACLK);
        ARESETn = 1'b1;
        repeat (2) @(posedge ACLK);
    end
    endtask

    // ---- Write: AW+W simultaneous ----
    task axi_write_simul;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        input [3:0]            strb;
    begin
        @(posedge ACLK);
        AWADDR  = addr;
        AWVALID = 1'b1;
        WDATA   = data;
        WSTRB   = strb;
        WVALID  = 1'b1;

        @(posedge ACLK);
        while (AWVALID || WVALID) begin
            if (AWREADY && AWVALID) AWVALID = 1'b0;
            if (WREADY  && WVALID)  WVALID  = 1'b0;
            if (AWVALID || WVALID) @(posedge ACLK);
        end

        BREADY = 1'b1;
        while (!BVALID) @(posedge ACLK);
        wr_resp = BRESP;
        @(posedge ACLK);
        BREADY = 1'b0;
    end
    endtask

    // ---- Write: AW first, then W after delay ----
    task axi_write_aw_first;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        input [3:0]            strb;
        input integer          delay_cycles;
        integer j;
    begin
        @(posedge ACLK);
        AWADDR  = addr;
        AWVALID = 1'b1;
        @(posedge ACLK);
        while (!AWREADY) @(posedge ACLK);
        AWVALID = 1'b0;

        for (j = 0; j < delay_cycles; j = j + 1) @(posedge ACLK);

        WDATA  = data;
        WSTRB  = strb;
        WVALID = 1'b1;
        @(posedge ACLK);
        while (!WREADY) @(posedge ACLK);
        WVALID = 1'b0;

        BREADY = 1'b1;
        while (!BVALID) @(posedge ACLK);
        wr_resp = BRESP;
        @(posedge ACLK);
        BREADY = 1'b0;
    end
    endtask

    // ---- Write: W first, then AW after delay ----
    task axi_write_w_first;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        input [3:0]            strb;
        input integer          delay_cycles;
        integer j;
    begin
        @(posedge ACLK);
        WDATA  = data;
        WSTRB  = strb;
        WVALID = 1'b1;
        @(posedge ACLK);
        while (!WREADY) @(posedge ACLK);
        WVALID = 1'b0;

        for (j = 0; j < delay_cycles; j = j + 1) @(posedge ACLK);

        AWADDR  = addr;
        AWVALID = 1'b1;
        @(posedge ACLK);
        while (!AWREADY) @(posedge ACLK);
        AWVALID = 1'b0;

        BREADY = 1'b1;
        while (!BVALID) @(posedge ACLK);
        wr_resp = BRESP;
        @(posedge ACLK);
        BREADY = 1'b0;
    end
    endtask

    // ---- Read ----
    task axi_read;
        input [ADDR_WIDTH-1:0] addr;
    begin
        @(posedge ACLK);
        ARADDR  = addr;
        ARVALID = 1'b1;
        @(posedge ACLK);
        while (!ARREADY) @(posedge ACLK);
        ARVALID = 1'b0;

        RREADY = 1'b1;
        while (!RVALID) @(posedge ACLK);
        rd_data = RDATA;
        rd_resp = RRESP;
        @(posedge ACLK);
        RREADY = 1'b0;
    end
    endtask

    // ---- Check ----
    task check;
        input [80*8-1:0] test_name;
        input [31:0]     actual;
        input [31:0]     expected;
    begin
        if (actual === expected) begin
            $display("[PASS] %0s : got 0x%08h", test_name, actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %0s : expected 0x%08h, got 0x%08h", test_name, expected, actual);
            fail_count = fail_count + 1;
        end
    end
    endtask

    task check_resp;
        input [80*8-1:0] test_name;
        input [1:0]      actual;
        input [1:0]      expected;
    begin
        if (actual === expected) begin
            $display("[PASS] %0s : RESP = %0b", test_name, actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %0s : expected RESP %0b, got %0b", test_name, expected, actual);
            fail_count = fail_count + 1;
        end
    end
    endtask

    // ================================================================
    //  Test Stimulus
    // ================================================================
    initial begin
        $display("========================================");
        $display(" AXI4-Lite GPIO/PWM Testbench Start");
        $display("========================================");

        reset_dut;

        // TEST 1: Simultaneous AW+W
        $display("\n--- TEST 1: Simultaneous AW+W write ---");
        axi_write_simul(`GPIO_OUT_ADDR, 32'h000000AA, 4'b1111);
        check_resp("T1 BRESP", wr_resp, `RESP_OKAY);
        axi_read(`GPIO_OUT_ADDR);
        check("T1 GPIO_OUT readback", rd_data, 32'h000000AA);

        // TEST 2: AW before W (2 cycle gap)
        $display("\n--- TEST 2: AW before W (2-cycle gap) ---");
        axi_write_aw_first(`PWM_CTRL_ADDR, 32'h000001F4, 4'b1111, 2);
        check_resp("T2 BRESP", wr_resp, `RESP_OKAY);
        axi_read(`PWM_CTRL_ADDR);
        check("T2 PWM_CTRL readback", rd_data, 32'h000001F4);

        // TEST 3: W before AW (3 cycle gap)
        $display("\n--- TEST 3: W before AW (3-cycle gap) ---");
        axi_write_w_first(`PWM_PERIOD_ADDR, 32'h00000064, 4'b1111, 3);
        check_resp("T3 BRESP", wr_resp, `RESP_OKAY);
        axi_read(`PWM_PERIOD_ADDR);
        check("T3 PWM_PERIOD readback", rd_data, 32'h00000064);

        // TEST 4: WSTRB byte masking
        $display("\n--- TEST 4: WSTRB byte masking ---");
        axi_write_simul(`GPIO_OUT_ADDR, 32'hDEADBEEF, 4'b1111);
        axi_write_simul(`GPIO_OUT_ADDR, 32'h000000FF, 4'b0001);
        check_resp("T4a BRESP", wr_resp, `RESP_OKAY);
        axi_read(`GPIO_OUT_ADDR);
        check("T4a WSTRB byte0 only", rd_data, 32'hDEADBEFF);

        axi_write_simul(`GPIO_OUT_ADDR, 32'h00420000, 4'b0100);
        axi_read(`GPIO_OUT_ADDR);
        check("T4b WSTRB byte2 only", rd_data, 32'hDE42BEFF);

        // TEST 5: Invalid address -> SLVERR
        $display("\n--- TEST 5: Write to invalid address ---");
        axi_write_simul(4'hF, 32'h00001234, 4'b1111);
        check_resp("T5a invalid addr", wr_resp, `RESP_SLVERR);
        axi_write_simul(`GPIO_IN_ADDR, 32'h00001234, 4'b1111);
        check_resp("T5b read-only addr", wr_resp, `RESP_SLVERR);

        // TEST 6: B channel backpressure
        $display("\n--- TEST 6: B channel backpressure ---");
        @(posedge ACLK);
        AWADDR  = `GPIO_OUT_ADDR;
        AWVALID = 1'b1;
        WDATA   = 32'h00000055;
        WSTRB   = 4'b1111;
        WVALID  = 1'b1;
        BREADY  = 1'b0;

        @(posedge ACLK);
        while (AWVALID || WVALID) begin
            if (AWREADY && AWVALID) AWVALID = 1'b0;
            if (WREADY  && WVALID)  WVALID  = 1'b0;
            if (AWVALID || WVALID) @(posedge ACLK);
        end

        repeat (3) @(posedge ACLK);
        check("T6 BVALID held", {31'd0, BVALID}, 32'h1);

        BREADY = 1'b1;
        while (!BVALID) @(posedge ACLK);
        wr_resp = BRESP;
        @(posedge ACLK);
        BREADY = 1'b0;
        check_resp("T6 BRESP", wr_resp, `RESP_OKAY);
        axi_read(`GPIO_OUT_ADDR);
        check("T6 data written", rd_data, 32'h00000055);

        // TEST 7: Read all valid registers
        $display("\n--- TEST 7: Read all registers ---");
        axi_read(`GPIO_OUT_ADDR);   check_resp("T7 GPIO_OUT",  rd_resp, `RESP_OKAY);
        axi_read(`GPIO_IN_ADDR);    check_resp("T7 GPIO_IN",   rd_resp, `RESP_OKAY);
        axi_read(`PWM_CTRL_ADDR);   check_resp("T7 PWM_CTRL",  rd_resp, `RESP_OKAY);
        axi_read(`PWM_PERIOD_ADDR); check_resp("T7 PWM_PERIOD",rd_resp, `RESP_OKAY);

        // TEST 8: Read invalid -> SLVERR
        $display("\n--- TEST 8: Read invalid address ---");
        axi_read(4'hF);
        check_resp("T8 RRESP", rd_resp, `RESP_SLVERR);
        check("T8 RDATA", rd_data, 32'hDEADBEEF);

        // TEST 9: GPIO CDC sync
        $display("\n--- TEST 9: GPIO input CDC sync ---");
        gpio_in = 8'hA5;
        repeat (4) @(posedge ACLK);
        axi_read(`GPIO_IN_ADDR);
        check("T9a GPIO_IN", rd_data, {24'd0, 8'hA5});
        gpio_in = 8'h3C;
        repeat (4) @(posedge ACLK);
        axi_read(`GPIO_IN_ADDR);
        check("T9b GPIO_IN", rd_data, {24'd0, 8'h3C});

        // TEST 10: PWM
        $display("\n--- TEST 10: PWM period and duty ---");
        axi_write_simul(`PWM_PERIOD_ADDR, 32'd10, 4'b1111);
        axi_write_simul(`PWM_CTRL_ADDR,   32'd5,  4'b1111);
        repeat (15) @(posedge ACLK);

        high_count = 0;
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge ACLK);
            if (pwm_out) high_count = high_count + 1;
        end
        if (high_count >= 4 && high_count <= 6) begin
            $display("[PASS] T10 PWM: %0d/10 high", high_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] T10 PWM: expected ~5, got %0d", high_count);
            fail_count = fail_count + 1;
        end

        // SUMMARY
        repeat (5) @(posedge ACLK);
        $display("\n========================================");
        $display(" Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================");
        if (fail_count == 0) $display(" ALL TESTS PASSED");
        else                 $display(" SOME TESTS FAILED");
        $display("========================================\n");
        $finish;
    end

    initial begin
        #100_000;
        $display("[TIMEOUT] Simulation hung");
        $finish;
    end

    initial begin
        $dumpfile("axi_gpio_pwm.vcd");
        $dumpvars(0, tb_axi_gpio_pwm);
    end

endmodule
