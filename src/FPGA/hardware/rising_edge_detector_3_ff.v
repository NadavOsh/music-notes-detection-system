module rising_edge_detector_3_ff (
    input wire clk,        // Clock signal
    input wire rst,        // Reset signal
    input wire signal_in,  // Input signal
    output reg edge_detected // Output flag for rising edge detected
);

    // Registers to store the values of the signal at different times
    reg signal_in_ff1;     // First flip-flop: stores the current value of signal_in
    reg signal_in_ff2;     // Second flip-flop: stores the previous value of signal_in
    reg signal_in_ff3;     // Third flip-flop: stores the value before the previous value of signal_in

    // Always block that triggers on the positive edge of the clock or the reset signal
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all flip-flops and output
            signal_in_ff1 <= 0;
            signal_in_ff2 <= 0;
            signal_in_ff3 <= 0;
            edge_detected <= 0;
        end else begin
            // Shift signal through the flip-flops
            signal_in_ff1 <= signal_in;
            signal_in_ff2 <= signal_in_ff1;
            signal_in_ff3 <= signal_in_ff2;

            // Rising edge detection: when the signal changes from 0 to 1
            if (signal_in_ff1 && !signal_in_ff2 && !signal_in_ff3) begin
                edge_detected <= 1;  // Rising edge detected
            end else begin
                edge_detected <= 0;  // No rising edge detected
            end
        end
    end
endmodule
