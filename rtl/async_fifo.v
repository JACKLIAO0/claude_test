//==============================================================================
// File: async_fifo.v
// Description: Asynchronous FIFO with Gray code pointers
//              Features:
//              - Parameterized data width and depth
//              - Gray code counters for CDC safety
//              - 2-stage synchronizers for pointer crossing
//              - Full and empty flag generation
//==============================================================================

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    // Write side
    input  wire                     wclk,
    input  wire                     wrst_n,
    input  wire                     wen,
    input  wire [DATA_WIDTH-1:0]    wdata,
    output wire                     wfull,

    // Read side
    input  wire                     rclk,
    input  wire                     rrst_n,
    input  wire                     ren,
    output wire [DATA_WIDTH-1:0]    rdata,
    output wire                     rempty
);

    // Internal signals
    wire [ADDR_WIDTH:0] wptr_gray, rptr_gray;
    wire [ADDR_WIDTH:0] wptr_binary, rptr_binary;
    wire [ADDR_WIDTH:0] wptr_gray_sync, rptr_gray_sync;

    wire wfull_internal, rempty_internal;
    wire wen_internal, ren_internal;

    // Only write when not full, only read when not empty
    assign wen_internal = wen & ~wfull_internal;
    assign ren_internal = ren & ~rempty_internal;

    assign wfull = wfull_internal;
    assign rempty = rempty_internal;

    //==========================================================================
    // Write pointer (Gray counter)
    //==========================================================================
    gray_counter #(
        .WIDTH(ADDR_WIDTH)
    ) wptr_counter (
        .clk          (wclk),
        .rst_n        (wrst_n),
        .inc          (wen_internal),
        .gray_count   (wptr_gray),
        .binary_count (wptr_binary)
    );

    //==========================================================================
    // Read pointer (Gray counter)
    //==========================================================================
    gray_counter #(
        .WIDTH(ADDR_WIDTH)
    ) rptr_counter (
        .clk          (rclk),
        .rst_n        (rrst_n),
        .inc          (ren_internal),
        .gray_count   (rptr_gray),
        .binary_count (rptr_binary)
    );

    //==========================================================================
    // Synchronize read pointer to write clock domain
    //==========================================================================
    synchronizer #(
        .WIDTH(ADDR_WIDTH+1)
    ) rptr_sync (
        .clk      (wclk),
        .rst_n    (wrst_n),
        .data_in  (rptr_gray),
        .data_out (rptr_gray_sync)
    );

    //==========================================================================
    // Synchronize write pointer to read clock domain
    //==========================================================================
    synchronizer #(
        .WIDTH(ADDR_WIDTH+1)
    ) wptr_sync (
        .clk      (rclk),
        .rst_n    (rrst_n),
        .data_in  (wptr_gray),
        .data_out (wptr_gray_sync)
    );

    //==========================================================================
    // Dual-port RAM
    //==========================================================================
    dual_port_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dpram (
        .wclk  (wclk),
        .wen   (wen_internal),
        .waddr (wptr_binary[ADDR_WIDTH-1:0]),
        .wdata (wdata),
        .rclk  (rclk),
        .raddr (rptr_binary[ADDR_WIDTH-1:0]),
        .rdata (rdata)
    );

    //==========================================================================
    // Full flag generation (in write clock domain)
    // Full when write pointer catches up to read pointer (after wrap)
    //==========================================================================
    assign wfull_internal = (wptr_gray == {~rptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1],
                                           rptr_gray_sync[ADDR_WIDTH-2:0]});

    //==========================================================================
    // Empty flag generation (in read clock domain)
    // Empty when read pointer equals write pointer
    //==========================================================================
    assign rempty_internal = (rptr_gray == wptr_gray_sync);

endmodule
