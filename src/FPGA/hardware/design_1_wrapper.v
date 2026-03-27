//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.1 (win64) Build 3247384 Thu Jun 10 19:36:33 MDT 2021
//Date        : Fri Apr 11 18:01:51 2025
//Host        : DESKTOP-VHJE80L running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (Clk,
    ext_reset_in_0,
    gpio2_io_o_0,
    gpio2_io_o_1,
    gpio_io_i_0,
    gpio_io_o_0,
    run_vitis,
    usb_uart_rxd,
    usb_uart_txd,
    vitis_finish,
    vitis_led,
    vitis_led_for);
  input Clk;
  input ext_reset_in_0;
  output [31:0]gpio2_io_o_0;
  output [31:0]gpio2_io_o_1;
  input [31:0]gpio_io_i_0;
  output [31:0]gpio_io_o_0;
  input [0:0]run_vitis;
  input usb_uart_rxd;
  output usb_uart_txd;
  output [0:0]vitis_finish;
  output [0:0]vitis_led;
  output [0:0]vitis_led_for;

  wire Clk;
  wire ext_reset_in_0;
  wire [31:0]gpio2_io_o_0;
  wire [31:0]gpio2_io_o_1;
  wire [31:0]gpio_io_i_0;
  wire [31:0]gpio_io_o_0;
  wire [0:0]run_vitis;
  wire usb_uart_rxd;
  wire usb_uart_txd;
  wire [0:0]vitis_finish;
  wire [0:0]vitis_led;
  wire [0:0]vitis_led_for;

  design_1 design_1_i
       (.Clk(Clk),
        .ext_reset_in_0(ext_reset_in_0),
        .gpio2_io_o_0(gpio2_io_o_0),
        .gpio2_io_o_1(gpio2_io_o_1),
        .gpio_io_i_0(gpio_io_i_0),
        .gpio_io_o_0(gpio_io_o_0),
        .run_vitis(run_vitis),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd),
        .vitis_finish(vitis_finish),
        .vitis_led(vitis_led),
        .vitis_led_for(vitis_led_for));
endmodule
