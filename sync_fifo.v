// sync_fifo.v -- Synchronous FIFO (single clock) with parameterized depth
module sync_fifo #(
    parameter DEPTH = 16,   // FIFO depth (maximum number of entries)
    parameter DWIDTH = 16   // Data width in bits
)(
    input wire rstn,        // Active low reset
    input wire clk,         // System clock
    input wire wr_en,       // Write enable
    input wire rd_en,       // Read enable
    input wire [DWIDTH-1:0] din,  // Data input bus
    output reg [DWIDTH-1:0] dout, // Data output bus
    output wire empty,      // Empty flag
    output wire full        // Full flag
);

    // Calculate the required address width based on the specified DEPTH.
    // $clog2 is a system function that computes the ceiling of log base 2.
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // Internal registers for pointers and memory
    reg [ADDR_WIDTH-1:0] wptr;      // Write pointer register
    reg [ADDR_WIDTH-1:0] rptr;      // Read pointer register
    reg [DWIDTH-1:0] fifo_mem [0:DEPTH-1]; // The internal memory array

    // Wires to hold the next calculated pointer values
    wire [ADDR_WIDTH-1:0] wptr_next;
    wire [ADDR_WIDTH-1:0] rptr_next;

    // Combinational logic for explicit pointer wraparound (non-power-of-two safe)
    // This uses a ternary operator: (condition) ? (value_if_true) : (value_if_false)
    // If the pointer is at the last address, wrap to 0. Otherwise, increment.
    assign wptr_next = (wptr == DEPTH - 1) ? {ADDR_WIDTH{1'b0}} : wptr + 1'b1;
    assign rptr_next = (rptr == DEPTH - 1) ? {ADDR_WIDTH{1'b0}} : rptr + 1'b1;

    // Write process: Synchronous logic block
    // Sensitive to the positive edge of the clock or negative edge of the reset.
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wptr <= {ADDR_WIDTH{1'b0}}; // Asynchronous reset for the write pointer
        end else begin
            // On clock edge, write only if enabled and not full
            if (wr_en && !full) begin
                fifo_mem[wptr] <= din;  // Store the input data into memory
                wptr <= wptr_next;      // Update the write pointer
            end
        end
    end

    // Read process: Synchronous logic block
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rptr <= {ADDR_WIDTH{1'b0}}; // Asynchronous reset for the read pointer
            dout <= {DWIDTH{1'b0}};     // Reset the output data register
        end else begin
            // On clock edge, read only if enabled and not empty
            if (rd_en && !empty) begin
                dout <= fifo_mem[rptr]; // Drive the output data from memory
                rptr <= rptr_next;      // Update the read pointer
            end
        end
    end

    // Status flag logic (combinational)
    // Full condition: The *next* write pointer will catch the current read pointer
    assign full = (wptr_next == rptr);
    // Empty condition: The write pointer and read pointer are at the same address
    assign empty = (wptr == rptr);

    // Simple runtime assertion checks (for simulation only)
    // These use $display to report potential protocol violations.
    always @(posedge clk) begin
        if (wr_en && full) begin
            $display("%0t ERROR: write attempted when FIFO full", $time);
        end
        if (rd_en && empty) begin
            $display("%0t ERROR: read attempted when FIFO empty", $time);
        end
    end

endmodule