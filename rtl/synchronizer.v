//==============================================================================
// File: synchronizer.v
// Description: 2-stage synchronizer for CDC (Clock Domain Crossing)
//              Reduces metastability risk when crossing clock domains
//==============================================================================

module synchronizer #(
    parameter WIDTH = 5
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);

    reg [WIDTH-1:0] sync_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1 <= {WIDTH{1'b0}};
            data_out    <= {WIDTH{1'b0}};
        end else begin
            sync_stage1 <= data_in;
            data_out    <= sync_stage1;
        end
    end

endmodule
