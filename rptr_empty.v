// rptr_empty.v -- Read pointer and 'empty' detection for a power-of-two depth FIFO.
// This module uses binary arithmetic wraparound.
module rptr_empty #(
    parameter ADDR_WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire rd_en,
    input wire [ADDR_WIDTH-1:0] wptr, // Receives write pointer for 'empty' comparison
    output reg [ADDR_WIDTH-1:0] rptr,
    output wire empty
);

    // Empty condition: The write pointer and read pointer are at the same address.
    assign empty = (wptr == rptr);

    // Calculate the next pointer value (simple binary increment)
    // This relies on Verilog's arithmetic overflow.
    wire [ADDR_WIDTH-1:0] rptr_next = rptr + 1'b1;

    // Register process for the read pointer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rptr <= {ADDR_WIDTH{1'b0}}; // Asynchronous reset
        end else begin
            // On clock edge, increment pointer if read is enabled and not empty
            if (rd_en && !empty) begin
                rptr <= rptr_next;
            end
        end
    end
    
endmodule