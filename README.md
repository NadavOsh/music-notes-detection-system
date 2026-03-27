# music-notes-detection-system
End-to-end embedded system for detecting musical notes includes camera, FPGA, SoC, image processing and microcontroller

A systen in which the user takes a number of photos (by his decision) with an OV7670 camera connected to an FPGA (Xilinx NEXYS A7 in that case) and displaying the camera's image/video with a VGA. Then sends it to a computer using the FPGA's internal microprocessor (Microblaze) with a UART protocol (PuTTY is being used here). The computer runs a Python code that creates a unique computer vision algorithm (which would be discussed later) and GUI (Tkinter) for the user. in the end of all of it it send the notes to an Arduino Uno microcontroller (UART), and the MCU plays them with a passive buzzer with a PWM method. 

Before diving deep it's important to mote that there are two way for doing the note detection algorithm: one (the naive way) is detecting the ellipse with fitellipse function (as part of a bigger algorithm which would be discussed  later), or the second option, using a red line that is being placed by the user while taking the photo. the fisrt way is more simple while the second is more accurate. Because the image comes from an OV7670 camera (low resulotion camera) we've decided to go with the second option. there is still an alterantive CV code that can be found in this project using the first method.




# VGA

##  VGA Display Subsystem

The system includes a custom VGA controller implemented in Verilog to display image data using a standard 640×480 @ 60Hz interface.

---

###  VGA Timing Controller

A dedicated module (`vga_driver`) generates the required VGA synchronization signals using a 25 MHz pixel clock.

- Implements horizontal and vertical timing using counters:
  - Horizontal range: 0–799 pixels  
  - Vertical range: 0–524 lines  
- Generates synchronization signals based on VGA standard timing:
  - HSYNC (horizontal sync)
  - VSYNC (vertical sync)
- Outputs:
  - Pixel coordinates (`x`, `y`)
  - Active video signal (`video`)

The active display region is:
- X: 0–639  
- Y: 0–479  

This module was implemented from scratch based on VGA timing specifications, without using vendor IP cores.

---

###  Frame Buffer & Pixel Mapping

The `vga_top` module connects the VGA timing logic to a BRAM-based frame buffer.

- Resolution: 640 × 480 → 307,200 pixels  
- Pixel data is stored in **12-bit RGB (4:4:4)** format  
- A linear address generator maps 2D pixel coordinates into a 1D memory space  
- During inactive video periods, the output is forced to black  

---

###  Address Generation Logic

A finite state machine (FSM) is used to control pixel addressing:

- `WAIT_1`, `WAIT_2`: Skip initial frames to allow system stabilization  
- `READ`: Sequentially reads pixel data during active video  

Behavior:
- Address increments only during valid pixel output  
- Address resets at frame boundaries or when leaving the visible region  
- Ensures proper synchronization between VGA timing and memory access  

---

###  Key Design Considerations

- Accurate VGA timing generation using counters  
- Synchronization between pixel clock and memory reads  
- Efficient mapping from 2D screen space to linear memory  
- Separation between timing logic and pixel output logic  

---

###  Summary

This VGA subsystem enables real-time image display directly from FPGA memory, forming a key part of the system pipeline from image capture to visualization.
