`timescale 1ns/1ps

module tb_ring_johnson_counter;
    reg clk;
    reg reset;
    reg enable;
    reg mode;
    wire [3:0] q;

    ring_johnson_counter dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .mode(mode),
        .q(q)
    );

    always #5 clk = ~clk;

    task check_value;
        input [3:0] expected;
        input [8*48-1:0] message;
        begin
            if (q !== expected) begin
                $display("FAIL at %0t: %0s; expected %b, got %b",
                         $time, message, expected, q);
                $fatal(1);
            end else begin
                $display("PASS at %0t: %0s; q=%b",
                         $time, message, q);
            end
        end
    endtask

    integer i;
    reg [3:0] ring_expected [0:3];
    reg [3:0] johnson_expected [0:7];

    initial begin
        $dumpfile("ring_johnson_counter.vcd");
        $dumpvars(0, tb_ring_johnson_counter);
    end

    initial begin
        clk = 0;
        reset = 1;
        enable = 0;
        mode = 0;

        ring_expected[0] = 4'b0001;
        ring_expected[1] = 4'b0010;
        ring_expected[2] = 4'b0100;
        ring_expected[3] = 4'b1000;

        johnson_expected[0] = 4'b0000;
        johnson_expected[1] = 4'b0001;
        johnson_expected[2] = 4'b0011;
        johnson_expected[3] = 4'b0111;
        johnson_expected[4] = 4'b1111;
        johnson_expected[5] = 4'b1110;
        johnson_expected[6] = 4'b1100;
        johnson_expected[7] = 4'b1000;

        // Ring counter test: reset, then check two complete cycles.
        @(posedge clk); #1;
        check_value(4'b0001, "Ring reset state");
        reset = 0;
        enable = 1;
        for (i = 1; i <= 8; i = i + 1) begin
            @(posedge clk); #1;
            check_value(ring_expected[i % 4], "Ring sequence");
        end

        // Hold test.
        enable = 0;
        @(posedge clk); #1;
        check_value(4'b0001, "Enable low holds count");

        // Johnson counter test: reset in Johnson mode, then check two cycles.
        mode = 1;
        reset = 1;
        @(posedge clk); #1;
        check_value(4'b0000, "Johnson reset state");
        reset = 0;
        enable = 1;
        for (i = 1; i <= 16; i = i + 1) begin
            @(posedge clk); #1;
            check_value(johnson_expected[i % 8], "Johnson sequence");
        end

        // Hold test in Johnson mode.
        enable = 0;
        @(posedge clk); #1;
        check_value(4'b0000, "Johnson enable low holds state");

        // Mid-run synchronous reset in Johnson mode.
        enable = 1;
        repeat (3) @(posedge clk);
        #1;
        reset = 1;
        @(posedge clk); #1;
        check_value(4'b0000, "Johnson mid-run reset");
        reset = 0;

        // Switch Johnson -> Ring without reset: must load Ring start state.
        mode = 0;
        @(posedge clk); #1;
        check_value(4'b0001, "Mode switch to Ring loads 0001");
        @(posedge clk); #1;
        check_value(4'b0010, "Ring continues after mode switch");

        // Switch Ring -> Johnson without reset: must load Johnson start state.
        mode = 1;
        @(posedge clk); #1;
        check_value(4'b0000, "Mode switch to Johnson loads 0000");
        @(posedge clk); #1;
        check_value(4'b0001, "Johnson continues after mode switch");

        // Mid-run reset in Ring mode.
        mode = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        reset = 1;
        @(posedge clk); #1;
        check_value(4'b0001, "Ring mid-run reset");
        reset = 0;
        enable = 0;

        $display("ALL TESTS PASSED");
        $finish;
    end
endmodule
