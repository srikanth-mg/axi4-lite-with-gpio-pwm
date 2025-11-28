`timescale 1ns / 1ps
`timescale 1ns/1ps

module tb_axi_gpio_pwm;

    logic ACLK = 0;
    always begin
    #5 ACLK = ~ACLK;        // 100 MHz clock
    end
    
    logic ARESET_N;

    initial begin
        ARESET_N = 0;
        #50;
        ARESET_N = 1;
    end

    // -------------------------------------------
    // AXI signals
    // -------------------------------------------
    logic [3:0]  AWADDR;
    logic        AWVALID;
    logic        AWREADY;

    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WVALID;
    logic        WREADY;

    logic [1:0]  BRESP;
    logic        BVALID;
    logic        BREADY;

    logic [3:0]  ARADDR;
    logic        ARVALID;
    logic        ARREADY;

    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RREADY;

    // DUT external IO
    logic [7:0]  gpio_in;
    logic [7:0]  gpio_out;
    logic        pwm_out;
    logic [31:0] rdata;

    // -------------------------------------------
    // DUT Instantiation
    // -------------------------------------------
    axi_gpio_pwm DUT (
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

        .gpio_in    (gpio_in),
        .gpio_out   (gpio_out),

        .pwm_out    (pwm_out)
    );

    // -------------------------------------------
    // AXI Write Task
    // -------------------------------------------
    task axi_write(input [3:0] addr, input [31:0] data);
    begin
        @(posedge ACLK);
        AWADDR  <= addr;
        AWVALID <= 1;
        WDATA   <= data;
        WSTRB   <= 4'b1111;     // write all bytes
        WVALID  <= 1;
        
        #1.5;
        BREADY  <= 1;

        // Wait for handshake
        wait (AWREADY && WREADY);
        @(posedge ACLK);

        AWVALID <= 0;
        WVALID  <= 0;

        wait (BVALID);
        @(posedge ACLK);
        BREADY <= 0;
    end
    endtask

    // -------------------------------------------
    // AXI Read Task
    // -------------------------------------------
    task axi_read(input [3:0] addr, output [31:0] data_out);
    begin
        @(posedge ACLK);
        ARADDR  <= addr;
        ARVALID <= 1;
        
        #1.5;
        RREADY  <= 1;

        wait (ARREADY);
        @(posedge ACLK);
        ARVALID <= 0;

        wait (RVALID);
        data_out = RDATA;

        @(posedge ACLK);
        RREADY <= 0;
    end
    endtask

    initial begin
        // initial stage
        AWADDR=0; AWVALID=0;
        WDATA=0;  WVALID=0;
        ARADDR=0; ARVALID=0;
        RREADY=0; BREADY=0;

        gpio_in = 8'h3C;   // random input

        @(posedge ARESET_N);
        axi_write(4'h0, 32'h000000AA);
        #20;
        axi_read(4'h0, rdata);
        $display("READ GPIO_OUT = %h", rdata);

        axi_write(4'h8, 32'd100); // duty_cycle of 100

        axi_write(4'hC, 32'd200); // duty_cycle of 200

        #2000;

        $display("Simulation DONE.");
        $stop;
    end

endmodule
