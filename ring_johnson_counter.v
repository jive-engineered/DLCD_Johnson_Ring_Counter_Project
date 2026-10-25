`timescale 1ns/1ps

// 4-bit Ring and Johnson counter with synchronous active-high reset,
// enable/hold control, and mode selection.
// mode = 0: Ring counter     (0001 -> 0010 -> 0100 -> 1000 -> 0001 ...)
// mode = 1: Johnson counter  (0000 -> 0001 -> 0011 -> 0111 -> 1111 -> 1110 -> 1100 -> 1000 -> 0000 ...)
//
// Whenever reset is asserted OR mode changes, the counter is loaded with the
// start state of the selected mode, so it can never stay in an illegal state
// after switching modes.
module ring_johnson_counter (
    input  wire       clk,
    input  wire       reset,
    input  wire       enable,
    input  wire       mode,
    output reg  [3:0] q
);

    reg mode_d;  // mode sampled at the previous clock edge

    always @(posedge clk) begin
        mode_d <= mode;

        if (reset || (mode != mode_d)) begin
            // Ring starts at 0001; Johnson starts at 0000.
            q <= (mode == 1'b0) ? 4'b0001 : 4'b0000;
        end else if (enable) begin
            if (mode == 1'b0)
                q <= {q[2:0], q[3]};   // Ring: circulate the MSB to the LSB
            else
                q <= {q[2:0], ~q[3]};  // Johnson: feed back inverted MSB
        end
        // When enable=0, no assignment is made: q holds its value.
    end

endmodule
