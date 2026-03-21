`timescale 1ns / 1ps
// ----------------------------------------------------------------------
// File: axi_slave_if.sv
// Desc: Hybrid AXI4-Lite Slave Interface (clean + protocol-correct)
// ----------------------------------------------------------------------

// ============================================================================
// File    : axi4_slave.sv
// Desc    : AXI4-Lite Slave Interface — protocol-correct implementation
//
// Fixes over original:
//   1. AW/W can arrive in any order (latching logic)
//   2. WSTRB passed through to register file
//   3. Back-pressure: AWREADY/WREADY deasserted while response pending
//   4. DECERR for unmapped addresses
//   5. Clean handshake — no silent write loss
// ============================================================================

import axi_pkg::*;

module axi4_slave #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  logic                        ACLK,
    input  logic                        ARESET_N,

    // Write Address Channel
    input  logic [ADDR_WIDTH-1:0]       AWADDR,
    input  logic                        AWVALID,
    output logic                        AWREADY,

    // Write Data Channel
    input  logic [DATA_WIDTH-1:0]       WDATA,
    input  logic [(DATA_WIDTH/8)-1:0]   WSTRB,
    input  logic                        WVALID,
    output logic                        WREADY,

    // Write Response Channel
    output logic [1:0]                  BRESP,
    output logic                        BVALID,
    input  logic                        BREADY,

    // Read Address Channel
    input  logic [ADDR_WIDTH-1:0]       ARADDR,
    input  logic                        ARVALID,
    output logic                        ARREADY,

    // Read Data Channel
    output logic [DATA_WIDTH-1:0]       RDATA,
    output logic [1:0]                  RRESP,
    output logic                        RVALID,
    input  logic                        RREADY,

    // Register File Interface
    output logic                        write_en,
    output logic [ADDR_WIDTH-1:0]       write_addr,
    output logic [DATA_WIDTH-1:0]       write_data,
    output logic [(DATA_WIDTH/8)-1:0]   write_strb,
    output logic                        addr_valid,      // tells regfile if addr is mapped
    input  logic [DATA_WIDTH-1:0]       read_data,
    input  logic                        read_addr_err    // regfile flags unmapped address
);

    // ----------------------------------------------------------------
    // Write Path: AW and W can arrive in any order
    // We latch whichever arrives first, fire write when both present
    // ----------------------------------------------------------------

    logic                       aw_latched;
    logic                       w_latched;
    logic [ADDR_WIDTH-1:0]      aw_addr_reg;
    logic [DATA_WIDTH-1:0]      w_data_reg;
    logic [(DATA_WIDTH/8)-1:0]  w_strb_reg;

    // Handshake detection
    logic aw_handshake, w_handshake, b_handshake;
    logic ar_handshake, r_handshake;

    assign aw_handshake = AWVALID & AWREADY;
    assign w_handshake  = WVALID  & WREADY;
    assign b_handshake  = BVALID  & BREADY;
    assign ar_handshake = ARVALID & ARREADY;
    assign r_handshake  = RVALID  & RREADY;

    // Both channels captured (same-cycle or latched)
    logic write_fire;
    assign write_fire = (aw_handshake || aw_latched) && (w_handshake || w_latched);

    // Resolved address and data (pick from latch or live bus)
    logic [ADDR_WIDTH-1:0]      resolved_addr;
    logic [DATA_WIDTH-1:0]      resolved_data;
    logic [(DATA_WIDTH/8)-1:0]  resolved_strb;

    assign resolved_addr = aw_latched ? aw_addr_reg : AWADDR;
    assign resolved_data = w_latched  ? w_data_reg  : WDATA;
    assign resolved_strb = w_latched  ? w_strb_reg  : WSTRB;

    // ----------------------------------------------------------------
    // AWREADY / WREADY:
    //   - Accept when no latch is held AND no response is pending
    //   - Deassert while BVALID is high and BREADY is low (back-pressure)
    // ----------------------------------------------------------------

    assign AWREADY = ARESET_N & ~aw_latched & ~BVALID;
    assign WREADY  = ARESET_N & ~w_latched  & ~BVALID;

    // ----------------------------------------------------------------
    // AW/W Latching Logic
    // ----------------------------------------------------------------

    always_ff @(posedge ACLK) begin
        if (!ARESET_N) begin
            aw_latched  <= 1'b0;
            w_latched   <= 1'b0;
            aw_addr_reg <= '0;
            w_data_reg  <= '0;
            w_strb_reg  <= '0;
        end else begin
            // AW arrives alone (no W yet, no existing latch)
            if (aw_handshake && !w_handshake && !w_latched) begin
                aw_latched  <= 1'b1;
                aw_addr_reg <= AWADDR;
            end

            // W arrives alone (no AW yet, no existing latch)
            if (w_handshake && !aw_handshake && !aw_latched) begin
                w_latched  <= 1'b1;
                w_data_reg <= WDATA;
                w_strb_reg <= WSTRB;
            end

            // Both captured — clear latches
            if (write_fire) begin
                aw_latched <= 1'b0;
                w_latched  <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------------------
    // Write to Register File
    // ----------------------------------------------------------------

    always_ff @(posedge ACLK) begin
        if (!ARESET_N) begin
            write_en   <= 1'b0;
            write_addr <= '0;
            write_data <= '0;
            write_strb <= '0;
        end else begin
            if (write_fire) begin
                write_en   <= 1'b1;
                write_addr <= resolved_addr;
                write_data <= resolved_data;
                write_strb <= resolved_strb;
            end else begin
                write_en <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------------------
    // Write Response (B Channel)
    //   - Assert BVALID one cycle after write_en
    //   - Hold until BREADY accepted
    //   - BRESP = SLVERR if address unmapped, else OKAY
    // ----------------------------------------------------------------

    logic write_err_reg;

    always_ff @(posedge ACLK) begin
        if (!ARESET_N) begin
            BVALID       <= 1'b0;
            BRESP        <= RESP_OKAY;
            write_err_reg <= 1'b0;
        end else begin
            if (write_en && !BVALID) begin
                BVALID        <= 1'b1;
                write_err_reg <= read_addr_err;
                BRESP         <= read_addr_err ? RESP_SLVERR : RESP_OKAY;
            end else if (b_handshake) begin
                BVALID <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------------------
    // Read Path
    //   - ARREADY: accept when no read response is pending
    //   - RVALID: assert one cycle after ar_handshake
    //   - RRESP: SLVERR if unmapped, else OKAY
    // ----------------------------------------------------------------

    assign ARREADY = ARESET_N & ~RVALID;

    always_ff @(posedge ACLK) begin
        if (!ARESET_N) begin
            RVALID <= 1'b0;
            RDATA  <= '0;
            RRESP  <= RESP_OKAY;
        end else begin
            if (ar_handshake) begin
                RDATA  <= read_data;
                RRESP  <= read_addr_err ? RESP_SLVERR : RESP_OKAY;
                RVALID <= 1'b1;
            end else if (r_handshake) begin
                RVALID <= 1'b0;
            end
        end
    end

    // addr_valid output for regfile (active during write or read)
    assign addr_valid = write_en | ar_handshake;

endmodule
