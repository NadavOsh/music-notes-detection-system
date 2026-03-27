`timescale 1ns / 1ps
`default_nettype none

/* 
 *  Polls for when FPGA is done initializing OV7670 and skips first
 *  two VGA frames to allow for the register changes to settle; 
 *  outputs pixel data after 1st byte is registered and 2nd byte is at the 
 *  input; increments pixel address on the same cycle new pixel data is sent
 *
 *
 *   NOTE: 
 *   - For RGB444, format of pixel data 
 *      1st byte: {   X,    X,    X,    X, R[3], R[2], R[1], R[0]}
 *      2nd byte: {G[3], G[2], G[1], G[0], B[3], B[2], B[1], B[0]
 *   
 *   - Format of output pixel data:
 *      o_pix_data = {RRRR GGGG BBBB};
 *
 */

module cam_capture
    (   input wire         i_pclk,
        input wire         i_vsync,
        input wire         i_href,    
        input wire  [7:0]  i_D,
        input wire         i_cam_done,
        output reg  [18:0] o_pix_addr, 
        output reg  [11:0] o_pix_data,      
        output reg         o_wr, 
        
        input wire i_cam_capture,
        input wire i_cam_video,
        
        output wire [1:0] state_out                  
    );
       
    // Negative/Positive Edge Detection of vsync for frame start/frame done signal
    reg         r1_vsync,    r2_vsync; 
    wire        frame_start, frame_done;
    
    initial { r1_vsync, r2_vsync } = 0; 
    always @(posedge i_pclk)
            {r2_vsync, r1_vsync} <= {r1_vsync, i_vsync}; 
  
    assign frame_start = (r1_vsync == 0) && (r2_vsync == 1);    // Negative Edge of vsync
    assign frame_done  = (r1_vsync == 1) && (r2_vsync == 0);    // Positive Edge of vsync
     
    // FSM for capturing pixel data in pclk domain
    localparam [1:0] WAIT   = 2'd0,
                     IDLE   = 2'd1,
                     CAPTURE = 2'd2,
                     CAPTURE2 = 2'd3;
                     
                     
    localparam   video = 0,
                 picture = 1;               
                     
    
    reg        r_half_data;             
    reg [1:0]  SM_state;
    reg [3:0]  pixel_data;
    reg SM_state_cap = 0;
    assign state_out = SM_state;
    
    
    // Create a 1D memory array with 307,200 elements, each 12 bits wide
   // reg [11:0] memory [0:307199];  // 307200 cells, each 12 bits wide
    reg [18:0] address,address2;      // 19-bit address for 307200 locations
    reg o_rd,o_wr_bram;
    reg start = 0;
    reg [11:0] data;
    wire [11:0] o_bram_pix_data;

    
    
     always @(posedge i_pclk)
     begin
        case(SM_state_cap)
            video:
            begin
                start <= 0;
                if(i_cam_capture)
                    SM_state_cap <= picture; 
            end
            picture:
            begin
                start <= 1;
                if(i_cam_video)
                    SM_state_cap <= video;     
            end
        endcase
     end
    
    
    
    
                                                                         
    always @(posedge i_pclk)
        begin
            r_half_data         <= 0;
            o_wr                <= 0;
            o_pix_data          <= o_pix_data;  
            o_pix_addr          <= o_pix_addr;
            SM_state            <= WAIT;
            address             <= 0;
            address2            <= 0;
            o_rd                <= 0;
            o_wr_bram           <= 0;
            data                <= 0;
            
            case(SM_state)
                WAIT: 
                    begin
                        // Skip the first two frames on start-up
                        SM_state    <= (frame_start && i_cam_done) ? IDLE : WAIT;
                        //start       <= 1'b0;
            
                    end
                IDLE:        
                    begin
                        if(start == 1'b1)    
                            SM_state   <= (frame_start) ? CAPTURE2 : IDLE;
                        else
                            SM_state   <= (frame_start) ? CAPTURE : IDLE;
                        address    <= 0;
                        address2   <= 0;
                        o_pix_addr <= 0;
                        o_pix_data <= 0; 
                        
                    end
                CAPTURE:
                    begin
                        SM_state   <= (frame_done) ? IDLE : CAPTURE;
                        o_pix_addr <= (r_half_data) ? o_pix_addr + 1'b1 : o_pix_addr;  
                        //start      <= 1'b1; 
                        if(i_href)
                            begin 
                                 // Register first byte
                                 if(!r_half_data)   
                                    pixel_data <= i_D[3:0];      
                                 r_half_data     <= ~r_half_data;                       
                                 o_wr            <= (r_half_data) ? 1'b1 : 1'b0;
                                 o_wr_bram       <= (r_half_data) ? 1'b1 : 1'b0;
                                 o_pix_data      <= (r_half_data) ? {pixel_data, i_D} : o_pix_data; 
                                 data            <= (r_half_data) ? {pixel_data, i_D} : o_pix_data; 
                                 address         <= (r_half_data) ? address + 1 : address;
                                 
                                 
                                 
                            end 
                    end  
            
                CAPTURE2:
                    begin
                        SM_state   <= (frame_done) ? IDLE : CAPTURE2;
                        o_pix_addr <= o_pix_addr; //(r_half_data) ? o_pix_addr + 1'b1 : o_pix_addr;   
                        if(i_href)
                            begin 
                                 // Register first byte
                                 if(!r_half_data)   
                                    pixel_data <= i_D[3:0];      
                                 r_half_data    <= ~r_half_data;                       
                                 o_wr           <= 1'b0;//(r_half_data) ? 1'b1 : 1'b0;
                                 o_rd           <= (r_half_data) ? 1'b1 : 1'b0;
                                 o_pix_data     <= (r_half_data) ? {pixel_data, i_D} : o_pix_data; 
                                 address2       <= (r_half_data) ? address2 + 1 : address2;
                            end 
                    end  
            
            
            
            
            
            
            
            
            endcase
        end
             
endmodule
