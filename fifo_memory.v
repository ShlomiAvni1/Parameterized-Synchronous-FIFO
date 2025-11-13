// fifo_memory.v -- A simple synchronous, dual-port register-array memory.
// This implements a "read-first" behavior on the read port.
module fifo_memory #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 16
)(
    input wire clk,
    input wire we, // Write Enable
    input wire [$clog2(DEPTH)-1:0] waddr, // Write Address
    input wire [DATA_WIDTH-1:0] wdata, // Write Data
    input wire [$clog2(DEPTH)-1:0] raddr, // Read Address
    output reg [DATA_WIDTH-1:0] rdata  // Registered Read Data Output
);

    // Internal memory array: DEPTH words, each DATA_WIDTH bits wide
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // This single 'always' block implements both read and write logic
    always @(posedge clk) begin
        // Synchronous write: If write-enable is high, update memory at waddr
        if (we) begin
            mem[waddr] <= wdata;
        end
        
        // Synchronous read: The output register 'rdata' is *always* updated
        // on every clock cycle with the data from the 'raddr' location.
        rdata <= mem[raddr];
    end
    
endmodule