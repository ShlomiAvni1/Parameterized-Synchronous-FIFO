// fifo_top.v -- A simple top-level wrapper for the parametric synchronous FIFO
// This is useful for synthesis, abstracting the internal parameters.
module fifo_top #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 4 // User provides address width
) (
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    output wire full,
    output wire empty
);

    // Calculate the internal DEPTH based on the provided ADDR_WIDTH
    localparam DEPTH = (1 << ADDR_WIDTH); // e.g., 4 bits -> 2^4 = 16 depth

    // Instantiate the core synchronous FIFO
    // This wrapper passes the calculated DEPTH to the underlying module.
    sync_fifo #(.DEPTH(DEPTH), .DWIDTH(DATA_WIDTH)) u_fifo (
        .rstn(rst_n), 
        .clk(clk), 
        .wr_en(wr_en), 
        .rd_en(rd_en), 
        .din(din), 
        .dout(dout), 
        .empty(empty), 
        .full(full)
    );

endmodule