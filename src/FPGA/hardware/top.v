`timescale 1ns / 1ps

`default_nettype wire

module top
    (   input wire i_top_clk,
        input wire i_top_rst,
        
        input wire  i_top_cam_start, 
        output wire o_top_cam_done, 
        
        
        input wire  i_top_cam_capture,
        input wire  i_top_cam_video,
        input wire  i_top_cam_red_line,
        
        // I/O to camera
        input wire       i_top_pclk, 
        input wire [7:0] i_top_pix_byte,
        input wire       i_top_pix_vsync,
        input wire       i_top_pix_href,
        output wire      o_top_reset,
        output wire      o_top_pwdn,
        output wire      o_top_xclk,
        output wire      o_top_siod,
        output wire      o_top_sioc,
        
        // I/O to VGA 
        output wire [3:0] o_top_vga_red,
        output wire [3:0] o_top_vga_green,
        output wire [3:0] o_top_vga_blue,
        output wire       o_top_vga_vsync,
        output wire       o_top_vga_hsync,
        
        input wire   usb_uart_rxd,
        output wire  usb_uart_txd,
        
        input wire mux,
        input wire red,
        
        input wire run_vitis,
        output wire vitis_led,
        output wire vitis_led_for,
        output wire vitis_finish,
        
        
        
        output wire [6:0] seg,
        output wire dp,
        output wire [7:0] an,
        
        input seven_seg_counter,
        input [10:0] seven_seg_sw
        
    );
    
    
  
    
    
    simple_seven_seg simple_seven_seg_inst
    (
      .clk(i_top_clk),
      .sw(seven_seg_sw),        // Switches
      .sw11(seven_seg_counter),
      .dp(dp),
      .seg(seg),        // Segment outputs (a to g)
      .an(an)          // Digit enable (active low)
    );
    
    
    // Connect cam_top/vga_top modules to BRAM
    wire [11:0] i_bram_pix_data,    o_bram_pix_data;
    wire [18:0] i_bram_pix_addr,    o_bram_pix_addr; 
    wire        i_bram_pix_wr;
           
    // Reset synchronizers for all clock domains
    reg r1_rstn_top_clk,    r2_rstn_top_clk;
    reg r1_rstn_pclk,       r2_rstn_pclk;
    reg r1_rstn_clk25m,     r2_rstn_clk25m; 
        
    wire w_clk25m; 
    
    
    // Generate clocks for camera and VGA
    clock_gen
    clock_gen_inst
    (
        .clk_in1(i_top_clk          ),
        .clk_out1(w_clk25m          ),
        .clk_out2(o_top_xclk        )
    );
    wire [31:0] read_pixel;
    wire [31:0] read_pixel_address;
    wire [31:0] mux_sel;
    
    
    design_1_wrapper design_1_wrapper_inst
    (
      .Clk(w_clk25m),
      .gpio_io_o_0(read_pixel),
      .ext_reset_in_0(!r2_rstn_clk25m),
      .gpio_io_i_0(o_bram_pix_data),
      .gpio2_io_o_0(read_pixel_address),
      .gpio2_io_o_1(mux_sel),
      .usb_uart_rxd(usb_uart_rxd),
      .usb_uart_txd(usb_uart_txd),
      .vitis_led(vitis_led),
      .vitis_led_for(vitis_led_for),
      .vitis_finish(vitis_finish),
      .run_vitis(run_vitis)
    
    );
    
    
    
    wire read_pixel_rising;
  //  assign vitis_led = 1'b1;
    rising_edge_detector_3_ff rising_edge_detector_3_ff_inst
    (
      .clk           (w_clk25m), // Clock signal
      .rst           (!r2_rstn_clk25m),  // Reset signal
      .signal_in     (read_pixel[0]), // Input signal
      .edge_detected (read_pixel_rising)  // Output flag for rising edge detected
    
    
    
    );
    
   
    
    
    
    
    
    wire w_rst_btn_db; 
    wire i_bram_pix_write;

    // Debounce top level button - invert reset to have debounced negedge reset
    localparam DELAY_TOP_TB = 240_000; //240_000 when uploading to hardware, 10 when simulating in testbench 
    debouncer 
    #(  .DELAY(DELAY_TOP_TB)    )
    top_btn_db
    (
        .i_clk(i_top_clk        ),
        .i_btn_in(~i_top_rst    ),
        .o_btn_db(w_rst_btn_db  )
    ); 
    
    // Double FF for negedge reset synchronization 
    always @(posedge i_top_clk or negedge w_rst_btn_db)
        begin
            if(!w_rst_btn_db) {r2_rstn_top_clk, r1_rstn_top_clk} <= 0; 
            else              {r2_rstn_top_clk, r1_rstn_top_clk} <= {r1_rstn_top_clk, 1'b1}; 
        end 
    always @(posedge w_clk25m or negedge w_rst_btn_db)
        begin
            if(!w_rst_btn_db) {r2_rstn_clk25m, r1_rstn_clk25m} <= 0; 
            else              {r2_rstn_clk25m, r1_rstn_clk25m} <= {r1_rstn_clk25m, 1'b1}; 
        end
    always @(posedge i_top_pclk or negedge w_rst_btn_db)
        begin
            if(!w_rst_btn_db) {r2_rstn_pclk, r1_rstn_pclk} <= 0; 
            else              {r2_rstn_pclk, r1_rstn_pclk} <= {r1_rstn_pclk, 1'b1}; 
        end 
    
    
    wire [1:0] state_out;
    // FPGA-camera interface
    cam_top 
    #(  .CAM_CONFIG_CLK(100_000_000)    )
    OV7670_cam
    (
        .i_clk(i_top_clk                ),
        .i_rstn_clk(r2_rstn_top_clk     ),
        .i_rstn_pclk(r2_rstn_pclk       ),
        
        // I/O for camera init
        .i_cam_start(i_top_cam_start    ),
        .i_top_cam_capture(i_top_cam_capture),
        .i_top_cam_video(i_top_cam_video),
        .o_cam_done(o_top_cam_done      ), 
        
        // I/O camera
        .i_pclk(i_top_pclk              ),
        .i_pix_byte(i_top_pix_byte      ), 
        .i_vsync(i_top_pix_vsync        ), 
        .i_href(i_top_pix_href          ),
        .o_reset(o_top_reset            ),
        .o_pwdn(o_top_pwdn              ),
        .o_siod(o_top_siod              ),
        .o_sioc(o_top_sioc              ), 
        
        // Outputs from camera to BRAM
        .o_pix_wr( i_bram_pix_wr        ),
        .o_pix_data(i_bram_pix_data     ),
        .o_pix_addr(i_bram_pix_addr     ),
        
        .state_out  (state_out)
    );
    

    
 
    
//    ila_0 ila_1_inst
//    (
//     .clk    (i_top_pclk),
//     .probe0 (i_bram_pix_addr),//1
//     .probe1 (i_bram_pix_data),//1
//     .probe2 (i_top_cam_start),//1
//     .probe3 (o_top_cam_done),//1
//     .probe4 (i_top_cam_capture_deb_rising),//4
//     .probe5 (i_top_cam_capture_deb),//4
//     .probe6 (i_bram_pix_wr),//4
//     .probe7 ('h0),//12
//     .probe8 ('h0),//19
//     .probe9 (1'b0)
    
    
    
    
//    );

wire i_rd;
wire [18:0] i_rd_addr;

wire [11:0] i_bram_data;

assign  i_rd      = mux ? read_pixel_rising :1'b1 ;
assign  i_rd_addr = mux ? read_pixel_address[18:0] :o_bram_pix_addr;
    
//assign  i_bram_data = i_bram_pix_addr < 10200 || i_bram_pix_addr > 204800  
                      



//? 



//12'h00f : i_bram_pix_data;    


 wire i_top_cam_red_line_w;
      
      debouncer 
    #(  .DELAY(240_000)         )    
    cam_btn_capture_db
    (   .i_clk(i_top_pclk            ), 
        .i_btn_in(i_top_cam_red_line   ),
        
        // Debounced button to start cam init 
        .o_btn_db(i_top_cam_red_line_w    )
    );

wire [8:0] i_bram_pix_addr_red ;

SignalGenerator SignalGenerator_inst
(
    .clk(i_top_pclk),
    .rst_n(w_rst_btn_db),
    .i_top_cam_red_line_w(i_top_cam_red_line_w),
    .o_signal(i_bram_pix_addr_red)


);

assign i_bram_data = (i_bram_pix_addr % 640 >= 170 && i_bram_pix_addr % 640 < 340 && // axis x 
                      i_bram_pix_addr / 640 >= 140 && i_bram_pix_addr / 640 < 340 && // axis y
                      i_bram_pix_addr / 640 != i_bram_pix_addr_red  ) ?     
                      i_bram_pix_data :
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 140) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 150) || 
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 160) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 170) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 180) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 190) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 200) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 210) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 220) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 230) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 240) || 
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 250) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 260) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 270) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 280) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 290) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 300) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 310) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 320) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 330) ||
                      (i_bram_pix_addr / 640 == i_bram_pix_addr_red && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340 && i_bram_pix_addr_red == 340) 
                      ? //red line 
                      12'hf00 : 
                      12'h00f;
    

//assign i_bram_data = (i_bram_pix_addr % 640 >= 170 && i_bram_pix_addr % 640 < 340 && // axis x 
//                      i_bram_pix_addr / 640 >= 140 && i_bram_pix_addr / 640 < 340 && // axis y
//                      i_bram_pix_addr / 640 != 300) ? 
//                      i_bram_pix_data :
//                      (i_bram_pix_addr / 640 == 300 && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340) ? //red line 
//                      12'hf00 : 
//                      12'h00f;


    
//assign i_bram_data = (i_bram_pix_addr % 640 >= 170 && i_bram_pix_addr % 640 < 340 && // axis x 
//                      i_bram_pix_addr / 640 >= 140 && i_bram_pix_addr / 640 < 340 && // axis y
//                      i_bram_pix_addr / 640 != 300) ? 
//                      i_bram_pix_data :
//                      (i_bram_pix_addr / 640 == 300 && i_bram_pix_addr  % 640 >= 170 && i_bram_pix_addr  % 640 < 340) ? //red line 
//                      12'hf00 : 
//                      12'h00f;
    
    
    mem_bram
    #(  .WIDTH(12                       ), 
        .DEPTH(640*480)                 )
     pixel_memory
     (
        // BRAM Write signals (cam_top)
        .i_wclk(i_top_pclk              ),
        .i_wr(   i_bram_pix_wr                  ), 
        .i_wr_addr(i_bram_pix_addr      ),
        .i_bram_data(i_bram_data), //(i_bram_pix_data    ),
        .i_bram_en(1'b1                 ),
         
         // BRAM Read signals (vga_top)
        .i_rclk(w_clk25m                ),
        .i_rd(i_rd         ),//(1'b1),
        .i_rd_addr(i_rd_addr),//(o_bram_pix_addr      ), 
        .o_bram_data(o_bram_pix_data    )
     );
     
    wire X; 
    wire Y;
    
    
    
    ila_1 ila_1_inst
    (
     .clk    (w_clk25m),
     .probe0 (read_pixel),//1
     .probe1 (read_pixel_rising),//1
     .probe2 (o_top_vga_vsync),//1
     .probe3 (o_top_vga_hsync),//1
     .probe4 (o_top_vga_red),//12
     .probe5 (o_top_vga_blue),//12
     .probe6 (o_top_vga_green),//12
     .probe7 (o_bram_pix_data),//12
     .probe8 (read_pixel_address),//19
     .probe9 (r2_rstn_clk25m)
    
    
    
    
   );
    
    
    
    
    
//    ila_0 ila_0_inst
//    (
//     .clk    (i_top_pclk),
//     .probe0 (i_bram_pix_wr),//1
//     .probe1 (i_bram_pix_wr),//1
//     .probe2 (i_bram_pix_wr),//1
//     .probe3 (i_bram_pix_wr),//1
//     .probe4 (state_out),//2
//     .probe5 (state_out),//4
//     .probe6 (state_out),//4
//     .probe7 (i_bram_pix_data),//12
//     .probe8 (i_bram_pix_addr),//19
//     .probe9 (i_bram_pix_wr)
    
    
    
    
//   );
    
  
    
    
    
    vga_top
    display_interface
    (
        .i_clk25m(w_clk25m              ),
        .i_rstn_clk25m(r2_rstn_clk25m   ), 
        
        // VGA timing signals
        .o_VGA_x(X                      ),
        .o_VGA_y(Y                      ), 
        .o_VGA_vsync(o_top_vga_vsync    ),
        .o_VGA_hsync(o_top_vga_hsync    ), 
        .o_VGA_video(                   ),
        
        // VGA RGB Pixel Data
        .o_VGA_red(o_top_vga_red        ),
        .o_VGA_green(o_top_vga_green    ),
        .o_VGA_blue(o_top_vga_blue      ), 
        
        // VGA read/write from/to BRAM
        .i_pix_data(o_bram_pix_data     ), 
        .o_pix_addr(o_bram_pix_addr     )
    );
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
    
    
endmodule
