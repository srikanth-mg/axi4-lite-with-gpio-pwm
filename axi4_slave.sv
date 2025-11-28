`timescale 1ns / 1ps
// ----------------------------------------------------------------------
// File: axi_slave_if.sv
// Desc: Hybrid AXI4-Lite Slave Interface (clean + protocol-correct)
// ----------------------------------------------------------------------

module axi4_slave #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  logic     ACLK,
    input  logic     ARESET_N,

//write address inputs
    input  logic [ADDR_WIDTH-1:0]  AWADDR,
    input  logic                   AWVALID,
    output logic                   AWREADY,

//write data i/o's
    input  logic [DATA_WIDTH-1:0]       WDATA,
    input  logic [(DATA_WIDTH/8)-1:0]   WSTRB, //strobe, to tell from which byte the data need to be written
    input  logic                        WVALID,
    output logic                        WREADY,

 // Write Response i/o's
    output logic [1:0]      BRESP,
    output logic            BVALID,
    input  logic            BREADY,

 // Read Address i/o's
    input  logic [ADDR_WIDTH-1:0]   ARADDR,
    input  logic                    ARVALID,
    output logic                    ARREADY,

 // Read Data i/o's
    output logic [DATA_WIDTH-1:0]  RDATA,
    output logic [1:0]             RRESP,
    output logic                   RVALID,
    input  logic                   RREADY,

  // Register File Interface i/o's
    output logic                     write_en,
    output logic [ADDR_WIDTH-1:0]    write_addr,
    output logic [DATA_WIDTH-1:0]    write_data,

    input  logic [DATA_WIDTH-1:0]    read_data
);


logic aw_handshake;  //write address
logic w_handshake;   // write data
logic b_handshake;   // read data 
logic ar_handshake;   // read address

// Ready signals
assign AWREADY = ARESET_N ? 1'b1 : 1'b0;
assign WREADY  = ARESET_N ? 1'b1 : 1'b0;
assign ARREADY = ARESET_N ? 1'b1 : 1'b0;

// Handshakes
assign aw_handshake = AWVALID & AWREADY;
assign w_handshake  = WVALID  & WREADY;
assign ar_handshake = ARVALID & ARREADY;



always_ff @(posedge ACLK) begin
    if (!ARESET_N) begin
        write_en   <= 1'b0;
        write_addr <= '0;
        write_data <= '0;
    end else begin
        if (aw_handshake && w_handshake) begin
            write_en   <= 1'b1;
            write_addr <= AWADDR;
            write_data <= WDATA;
        end else begin
            write_en   <= 1'b0;
        end
    end
end

always_ff @(posedge ACLK) begin
    if (!ARESET_N) begin
        BVALID <= 1'b0;
        BRESP  <= 2'b00;  // OKAY
    end else begin
        if (write_en) begin
            BVALID <= 1'b1;
            BRESP  <= 2'b00;
        end else if (BVALID && BREADY) begin
            BVALID <= 1'b0;
        end
    end
end

always_ff @(posedge ACLK) begin
    if (!ARESET_N) begin
        RVALID <= 1'b0;
        RDATA  <= '0;
        RRESP  <= 2'b00;
    end else begin
        if (ar_handshake) begin
            RDATA  <= read_data;
            RRESP  <= 2'b00;
            RVALID <= 1'b1;
        end else if (RVALID && RREADY) begin
            RVALID <= 1'b0;
        end
    end
end

endmodule
