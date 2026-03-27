# music-notes-detection-system
End-to-end embedded system for detecting musical notes includes camera, FPGA, SoC, image processing and microcontroller

A systen in which the user takes a number of photos (by his decision) with an OV7670 camera connected to an FPGA (Xilinx NEXYS A7 in that case) and displaying the camera's image/video with a VGA. Then sends it to a computer using the FPGA's internal microprocessor (Microblaze) with a UART protocol (PuTTY is being used here). The computer runs a Python code that creates a unique computer vision algorithm (which would be discussed later) and GUI (Tkinter) for the user. in the end of all of it it send the notes to an Arduino Uno microcontroller (UART), and the MCU plays them with a passive buzzer with a PWM method. 

Before diving deep it's important to mote that there are two way for doing the note detection algorithm: one (the naive way) is detecting the ellipse with fitellipse function (as part of a bigger algorithm which would be discussed  later), or the second option, using a red line that is being placed by the user while taking the photo. the fisrt way is more simple while the second is more accurate. Because the image comes from an OV7670 camera (low resulotion camera) we've decided to go with the second option. there is still an alterantive CV code that can be found in this project using the first method.


# A View on the System
<img width="1265" height="1077" alt="image" src="https://github.com/user-attachments/assets/c57bc8fc-3555-4153-bf42-426d6eafd3f4" />


# Block Diagram of the System
<img width="869" height="532" alt="image" src="https://github.com/user-attachments/assets/565cf6fa-fb7a-4b0c-a5d6-421c62b4ce88" />


# FPGA Block Diagram
<img width="794" height="695" alt="image" src="https://github.com/user-attachments/assets/e719f061-eaba-4f0f-a874-ed34f53bea8b" />

---
# FPGA

---
##  Top-Level System Integration (`top.v`)

The `top` module is the central integration point of the system, connecting all hardware and software components into a complete image acquisition, processing, and display pipeline.

---

###  System Overview

This module integrates the following subsystems:

-  Camera interface (OV7670)
-  Frame buffer (BRAM)
-  VGA display controller
-  MicroBlaze processor (via Vitis)
-  User input (buttons, switches, 7-segment display)
-  Debug tools (ILA)

---

###  High-Level Data Flow

```text
Camera → cam_top → Image Processing → BRAM → VGA → Display
                                      ↘
                                       MicroBlaze (optional access)
```

* The camera continuously writes pixel data into BRAM
* VGA reads from BRAM for real-time display
* MicroBlaze can optionally take control of BRAM access

### Clock Domains

 The design operates across multiple clock domains:

 | Clock          | Purpose                     |
 |----------------|-----------------------------|
 | i_top_clk      | System / control logic      |
 | i_top_pclk     | Camera pixel clock          |
 | w_clk25m       | VGA display clock (25MHz)   |


A dedicated clock_gen module generates:

* VGA clock (25 MHz)
* Camera XCLK

### Reset Synchronization

Each clock domain includes a double flip-flop synchronizer to ensure safe reset handling and avoid metastability:

* top_clk domain
* pclk (camera) domain
* clk25m (VGA) domain

A debouncer is used to clean the external reset signal.

### Camera Interface (cam_top)
* Configures and controls the OV7670 camera via I2C
* Captures pixel data using pclk, href, and vsync signals
* Outputs:
** Pixel data (12-bit RGB)
** Pixel address
** Write enable signal

This data is streamed into BRAM.

---


##  Dual-Port BRAM (Frame Buffer)

The system uses a custom dual-port Block RAM (BRAM) module as a frame buffer to store image data captured from the camera and provide it for display or processor access.

---

###  Overview

The `mem_bram` module implements a **dual-port memory** with separate clocks for read and write operations:

- **Write Port (Camera Domain)**  
  - Clock: `i_wclk` (camera pixel clock)  
  - Used by: Camera interface (`cam_top`)  
  - Function: Writes incoming pixel data into memory  

- **Read Port (Display / Processor Domain)**  
  - Clock: `i_rclk` (25 MHz VGA clock)  
  - Used by: VGA controller or MicroBlaze (via MUX)  
  - Function: Reads pixel data for display or software processing  

This allows safe data transfer between different clock domains.

---

###  Memory Configuration

- Resolution: `640 × 480`  
- Total depth: `307,200` pixels  
- Pixel format: `12-bit RGB (4:4:4)`  
- Addressing: Linear (row-major order)


address = y * 640 + x;

### Dual-Port Operation

The BRAM supports simultaneous read and write operations:

* Camera continuously writes pixels during image capture
* VGA or MicroBlaze reads pixels independently

This enables real-time image display while maintaining access for processing or debugging.

### Timing Behavior
* Read and write operations are synchronous to their respective clocks
* There is a one-clock-cycle latency for both read and write operations

### Memory Access Arbitration

A MUX-based control mechanism determines the source of the read address:

* VGA Mode: Sequential reads for continuous display
* Processor Mode: MicroBlaze provides custom read addresses

This allows switching between real-time visualization and software-driven inspection.

### Key Design Features
* True dual-port memory with independent clocks
* Safe crossing between camera and display clock domains
* Efficient 2D-to-1D address mapping
* Supports both streaming (VGA) and random access (MicroBlaze)

### Summary

The BRAM serves as the central data buffer in the system, enabling seamless integration between the camera input, FPGA processing, VGA output, and MicroBlaze-based control.

---


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





---

##  MicroBlaze Control & Data Extraction

The system integrates a MicroBlaze soft processor to enable software-driven access to image data stored in BRAM. This allows flexible inspection, debugging, and processing of selected image regions.

---

### 🔗 Hardware–Software Interface

Communication between the MicroBlaze and FPGA logic is implemented using **memory-mapped I/O registers**:

| Address        | Function                     |
|----------------|------------------------------|
| `0x40000000`   | Read trigger                 |
| `0x40000008`   | Pixel address input          |
| `0x40010000`   | Pixel data output            |
| `0x40020000`   | Control / status signals     |
| `0x40020008`   | Ready flag                  |
| `0x40030000`   | Restart trigger              |

The processor writes to these registers to control BRAM access and reads back pixel values.

---

###  Operating Modes (MUX-Based Control)

A multiplexer in the FPGA determines the source of BRAM read operations:

- **Normal Mode (`mux = 0`)**  
  VGA controller continuously reads from BRAM for real-time display.

- **Processor Mode (`mux = 1`)**  
  MicroBlaze takes control of BRAM access:
  - Provides pixel addresses  
  - Triggers read operations  
  - Receives pixel data  

This enables software-driven image scanning without interfering with the hardware pipeline.

---

###  Pixel Scanning Algorithm

The MicroBlaze scans a Region of Interest (ROI) within the image:

- X range: `170 → 340`  
- Y range: `140 → 340`  

Each pixel coordinate is converted into a linear BRAM address:

address = y * 640 + x;

For every pixel:

1. Write address to FPGA
2. Trigger read operation
3. Read pixel data from BRAM
4. Output result via UART (xil_printf)

---

### Read Synchronization

A rising-edge trigger mechanism is used to initiate BRAM reads:

* Writing 1 to the trigger register generates a rising edge
* FPGA detects the edge and performs a memory read
* Writing 0 resets the trigger for the next operation

Delays (usleep) are used to ensure proper synchronization between software and hardware timing.

---

### Data Output
Pixel values are transmitted over UART:

Format:

* Hexadecimal pixel value
* Corresponding memory address

---

### Purpose & Use Cases
* Selective pixel inspection from software
* Debugging image data in real-time
* Validating FPGA image processing stages
* Enabling hybrid HW/SW image processing workflows

---
### Summary
The MicroBlaze subsystem provides a flexible bridge between software and hardware, allowing direct access to frame buffer data through a controlled, memory-mapped interface. Combined with the MUX-based architecture, this enables dynamic switching between real-time display and software-driven analysis.


