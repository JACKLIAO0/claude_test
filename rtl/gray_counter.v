//==============================================================================
// File: gray_counter.v
// Description: Gray code counter for async FIFO pointer
//              Converts binary counter to Gray code for safe CDC crossing
//==============================================================================

module gray_counter #(
    parameter WIDTH = 4
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire             inc,
    output reg  [WIDTH:0]   gray_count,
    output wire [WIDTH:0]   binary_count
);

    reg [WIDTH:0] binary_count_reg;

    assign binary_count = binary_count_reg;

    // Binary counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_count_reg <= {(WIDTH+1){1'b0}};
        end else if (inc) begin
            binary_count_reg <= binary_count_reg + 1'b1;
        end
    end

    // Binary to Gray code conversion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_count <= {(WIDTH+1){1'b0}};
        end else begin
            gray_count <= binary_count_reg ^ (binary_count_reg >> 1);
        end
    end

endmodule
