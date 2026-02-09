//==============================================================================
// File: dual_port_ram.v
// Description: Dual-port RAM for async FIFO
//              Supports independent read and write ports
//==============================================================================

module dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                     wclk,
    input  wire                     wen,
    input  wire [ADDR_WIDTH-1:0]    waddr,
    input  wire [DATA_WIDTH-1:0]    wdata,

    input  wire                     rclk,
    input  wire [ADDR_WIDTH-1:0]    raddr,
    output wire [DATA_WIDTH-1:0]    rdata
);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Write operation
    always @(posedge wclk) begin
        if (wen) begin
            mem[waddr] <= wdata;
        end
    end

    // Read operation - continuous read at current address
    assign rdata = mem[raddr];

endmodule
