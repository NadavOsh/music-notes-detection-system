module simple_seven_seg (
    input  wire        clk,          // Clock
    input  wire        sw11,         // SW[11] - count on rising edge
    input  wire [10:0] sw,           // SW[10:0] - value to display (up to 2047)
    output reg  [6:0]  seg,          // 7-segment segments (a-g)
    output wire        dp,           // Decimal point (off)
    output reg  [7:0]  an            // Anodes (active low)
);

    reg [13:0] counter = 1;          // Counter from 1 to 9999
    reg        prev_sw11 = 0;

    // Mask sw to ensure it doesn't exceed 9999
    wire [13:0] sw_limited = (sw > 9999) ? 9999 : sw;

    // Split counter digits
    wire [3:0] c_ones      =  counter       % 10;
    wire [3:0] c_tens      = (counter / 10)    % 10;
    wire [3:0] c_hundreds  = (counter / 100)   % 10;
    wire [3:0] c_thousands = (counter / 1000)  % 10;

    // Split SW digits
    wire [3:0] sw_ones      =  sw_limited       % 10;
    wire [3:0] sw_tens      = (sw_limited / 10)    % 10;
    wire [3:0] sw_hundreds  = (sw_limited / 100)   % 10;
    wire [3:0] sw_thousands = (sw_limited / 1000)  % 10;

    // Segment decoder
    function [6:0] seg_decode;
        input [3:0] value;
        begin
            case (value)
                4'h0: seg_decode = 7'b1000000;
                4'h1: seg_decode = 7'b1111001;
                4'h2: seg_decode = 7'b0100100;
                4'h3: seg_decode = 7'b0110000;
                4'h4: seg_decode = 7'b0011001;
                4'h5: seg_decode = 7'b0010010;
                4'h6: seg_decode = 7'b0000010;
                4'h7: seg_decode = 7'b1111000;
                4'h8: seg_decode = 7'b0000000;
                4'h9: seg_decode = 7'b0010000;
                default: seg_decode = 7'b1111111;
            endcase
        end
    endfunction

wire sw11_deb;

    debouncer debouncer_inst1
     (
      .i_clk(clk),
     .i_btn_in(sw11),
     .o_btn_db(sw11_deb) 
);

    // Rising edge detect
    always @(posedge clk) begin
        if (~prev_sw11 & sw11_deb)
            counter <= (counter == 9999) ? 0 : counter + 1;
        prev_sw11 <= sw11_deb;
    end

    // Refresh for multiplexing
    reg [19:0] refresh_counter = 0;
    reg [2:0]  current_digit = 0;

    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
        current_digit <= refresh_counter[18:16];
    end

    always @(*) begin
        case (current_digit)
            3'd0: begin seg = seg_decode(sw_ones);       an = 8'b11111110; end // an[0]
            3'd1: begin seg = seg_decode(sw_tens);       an = 8'b11111101; end // an[1]
            3'd2: begin seg = seg_decode(sw_hundreds);   an = 8'b11111011; end // an[2]
            3'd3: begin seg = seg_decode(sw_thousands);  an = 8'b11110111; end // an[3]
            3'd4: begin seg = seg_decode(c_ones);      an = 8'b11101111; end // an[4]
            3'd5: begin seg = seg_decode(c_tens);      an = 8'b11011111; end // an[5]
            3'd6: begin seg = seg_decode(c_hundreds);  an = 8'b10111111; end // an[6]
            3'd7: begin seg = seg_decode(c_thousands); an = 8'b01111111; end // an[7]
            default: begin seg = 7'b1111111; an = 8'b11111111; end
        endcase
    end

    assign dp = 1'b1;  // Decimal point off

endmodule
