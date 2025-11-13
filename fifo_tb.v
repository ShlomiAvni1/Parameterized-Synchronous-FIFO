// fifo_tb.v -- Verilog testbench for the synchronous FIFO
// Verifies two test cases: DEPTH=8 (power-of-two) and DEPTH=9 (non-power-of-two).
`timescale 1ns/1ps

module tb;
    // -----------------------------------------------------------------------
    // Testbench Parameters
    // -----------------------------------------------------------------------
    parameter DATA_WIDTH = 16;
    parameter DEPTH_A = 8;
    parameter DEPTH_B = 9;

    // Verilog 2001 compatible function to compute address width.
    // This is a "pure" function, evaluated at compile/elaboration time.
    function integer calc_addr_width_tb;
        input integer depth;
        integer i;
        begin
            calc_addr_width_tb = 0;
            // Loop performs bitwise right-shift (>> 1) to count bits
            for (i = depth - 1; i > 0; i = i >> 1)
                calc_addr_width_tb = calc_addr_width_tb + 1;
        end
    endfunction

    // Calculate local parameters based on the function
    localparam ADDR_WIDTH_A = calc_addr_width_tb(DEPTH_A);
    localparam ADDR_WIDTH_B = calc_addr_width_tb(DEPTH_B);

    // -----------------------------------------------------------------------
    // Testbench Signals (reg and wire)
    // -----------------------------------------------------------------------
    reg clk;
    reg rstn;

    // Signals for Instance A (DUT A)
    // 'reg' types are driven by the testbench.
    reg  [DATA_WIDTH-1:0] din_a;
    reg                   wr_en_a;
    reg                   rd_en_a;
    // 'wire' types are outputs read from the DUT.
    wire [DATA_WIDTH-1:0] dout_a;
    wire                  full_a;
    wire                  empty_a;

    // Signals for Instance B (DUT B)
    reg  [DATA_WIDTH-1:0] din_b;
    reg                   wr_en_b;
    reg                   rd_en_b;
    wire [DATA_WIDTH-1:0] dout_b;
    wire                  full_b;
    wire                  empty_b;

    // -----------------------------------------------------------------------
    // Instantiate DUT A (DEPTH = 8)
    // The #() syntax overrides the default parameters of the module.
    // -----------------------------------------------------------------------
    sync_fifo #(.DEPTH(DEPTH_A), .DWIDTH(DATA_WIDTH)) dut_a (
        // Port mapping by name: .<port_in_module>(<signal_in_testbench>)
        .clk(clk),
        .rstn(rstn),
        .wr_en(wr_en_a),
        .rd_en(rd_en_a),
        .din(din_a),
        .dout(dout_a),
        .full(full_a),
        .empty(empty_a)
    );

    // -----------------------------------------------------------------------
    // Instantiate DUT B (DEPTH = 9)
    // -----------------------------------------------------------------------
    sync_fifo #(.DEPTH(DEPTH_B), .DWIDTH(DATA_WIDTH)) dut_b (
        .clk(clk),
        .rstn(rstn),
        .wr_en(wr_en_b),
        .rd_en(rd_en_b),
        .din(din_b),
        .dout(dout_b),
        .full(full_b),
        .empty(empty_b)
    );

    // -----------------------------------------------------------------------
    // Clock Generator
    // Creates a 10ns period (100MHz) clock.
    // -----------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // #5 means 5ns delay
    end

    // -----------------------------------------------------------------------
    // Waveform Dump (for simulation debugging)
    // -----------------------------------------------------------------------
    initial begin
        $dumpfile("fifo_cases.vcd"); // Set VCD (Value Change Dump) file name
        $dumpvars(0, tb);            // Dump all variables in the 'tb' module
    end

    // -----------------------------------------------------------------------
    // Main Test Sequence
    // -----------------------------------------------------------------------
    integer i;           // Loop counter
    integer write_count; // Tracks successful writes
    integer max_iters;   // Safety stop for loops
    reg stop_flag;       // Internal flag to break loops

    initial begin
        // Initialize all driving signals to a known state
        rstn    = 0;
        wr_en_a = 0; rd_en_a = 0; din_a = 0;
        wr_en_b = 0; rd_en_b = 0; din_b = 0;

        // Apply reset pulse
        #20;
        rstn = 1; // De-assert reset
        #1;

        // -------------------------
        // TEST A: DEPTH = 8
        // -------------------------
        $display("=== TEST A: DEPTH=%0d, ADDR_WIDTH=%0d ===", DEPTH_A, ADDR_WIDTH_A);

        write_count = 0;
        stop_flag = 0;
        max_iters = DEPTH_A + 4; // Safety margin to check 'full' logic

        for (i = 0; i < max_iters; i = i + 1) begin
            @(posedge clk); // Wait for the next clock edge
            
            // Drive signals based on FIFO status
            if (!full_a) begin
                wr_en_a = 1;
                din_a = i;
                write_count = write_count + 1;
            end else begin
                wr_en_a = 0;
                stop_flag = 1; // Mark that we have hit the full state
            end

            // Wait one more cycle to allow the DUT to process the write
            @(posedge clk);
            wr_en_a = 0; // De-assert write enable for the next iteration

            // Check if we should exit the loop early
            if (stop_flag) begin
                $display("A: FIFO filled after %0d writes (attempted i=%0d)", write_count, i);
                i = max_iters; // Force loop termination
            end
        end

        // Wait a few cycles, then read back all written entries
        repeat (2) @(posedge clk);

        for (i = 0; i < write_count; i = i + 1) begin
            @(posedge clk);
            if (!empty_a) begin
                rd_en_a = 1;
            end
            
            @(posedge clk);
            $display("A read dout=0x%0h empty=%b full=%b", dout_a, empty_a, full_a);
            rd_en_a = 0; // De-assert after one cycle
        end

        // Wait between tests
        repeat (5) @(posedge clk);

        // -------------------------
        // TEST B: DEPTH = 9
        // -------------------------
        $display("=== TEST B: DEPTH=%0d, ADDR_WIDTH=%0d (non-power-of-two) ===", DEPTH_B, ADDR_WIDTH_B);

        write_count = 0;
        stop_flag = 0;
        max_iters = DEPTH_B + 8; // Safety margin

        for (i = 0; i < max_iters; i = i + 1) begin
            @(posedge clk);
            
            if (!full_b) begin
                wr_en_b = 1;
                din_b = 16'h1000 + i; // Use a different data pattern
                write_count = write_count + 1;
            end else begin
                wr_en_b = 0;
                stop_flag = 1;
            end

            @(posedge clk);
            $display("B write attempt i=%0d din=0x%0h full=%b", i, 16'h1000 + i, full_b);
            wr_en_b = 0;

            if (stop_flag) begin
                $display("B: FIFO filled after %0d writes (attempted i=%0d)", write_count, i);
                i = max_iters; // Terminate loop
            end
        end

        // Read back all written entries for Test B
        repeat (2) @(posedge clk);
        for (i = 0; i < write_count; i = i + 1) begin
            @(posedge clk);
            if (!empty_b) begin
                rd_en_b = 1;
            end
            
            @(posedge clk);
            $display("B read dout=0x%0h empty=%b full=%b", dout_b, empty_b, full_b);
            rd_en_b = 0;
        end

        // Finish simulation
        #200;
        $display("SIMULATION COMPLETE");
        $finish; // End the simulation
    end

    // -----------------------------------------------------------------------
    // Optional runtime monitor
    // This 'always' block executes every clock cycle to print the state.
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        // $display is a system task for printing formatted strings
        // %0t = time, %b = binary, %0h = hex (no padding)
        $display("%0t MON: A wr=%b rd=%b din=0x%0h dout=0x%0h full=%b empty=%b | B wr=%b rd=%b din=0x%0h dout=0x%0h full=%b empty=%b",
                 $time, // System variable for current simulation time
                 wr_en_a, rd_en_a, din_a, dout_a, full_a, empty_a,
                 wr_en_b, rd_en_b, din_b, dout_b, full_b, empty_b);
    end

endmodule