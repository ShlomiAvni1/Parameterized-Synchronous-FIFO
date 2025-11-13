// wptr_full.v -- Write pointer and 'full' detection for a power-of-two depth FIFO.
// This module uses binary arithmetic wraparound.
module wptr_full #(
    parameter ADDR_WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] rptr, // Receives read pointer for 'full' comparison
    output reg [ADDR_WIDTH-1:0] wptr,
    output wire full
);
    // Calculate DEPTH based on ADDR_WIDTH (e.g., 4 bits -> depth 16)
    localparam DEPTH = (1 << ADDR_WIDTH);

    // Calculate the next pointer value (simple binary increment)
    // This relies on Verilog's arithmetic overflow (e.g., 1111 + 1 = 0000)
    wire [ADDR_WIDTH-1:0] wptr_next = wptr + 1'b1;
    
    // Full condition: The next write pointer matches the current read pointer.
    // This implements the "one-slot-empty" convention.
    assign full = (wptr_next == rptr);

    // Register process for the write pointer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= {ADDR_WIDTH{1'b0}}; // Asynchronous reset
        end else begin
            // On clock edge, increment pointer if write is enabled and not full
            if (wr_en && !full) begin
                wptr <= wptr_next;
            end
        end
    end
    
endmodule