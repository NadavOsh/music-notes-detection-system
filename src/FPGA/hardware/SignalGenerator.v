module SignalGenerator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        i_top_cam_red_line_w,
    output reg [8:0]  o_signal
);

    reg i_top_cam_red_line_w_d;
    wire rising_edge;

    // Detect rising edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            i_top_cam_red_line_w_d <= 0;
        else
            i_top_cam_red_line_w_d <= i_top_cam_red_line_w;
    end
    
    assign rising_edge = i_top_cam_red_line_w & ~i_top_cam_red_line_w_d;

    // Signal generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            o_signal <= 140;
        else if (rising_edge) begin
            if (o_signal >= 340)
                o_signal <= 140;
            else
                o_signal <= o_signal + 10;
        end
    end

endmodule
