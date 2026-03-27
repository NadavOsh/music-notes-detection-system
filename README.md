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





# Microblaze
## 🏗️ Hardware-Software Co-Design: MicroBlaze & FPGA Integration

This project implements a **Real-Time Image Processing Pipeline** where a Xilinx MicroBlaze soft-core processor interacts with an OV7670 camera feed stored in Block RAM (BRAM). The system allows for high-level C-based analysis of raw pixel data without interrupting the live VGA video output.

### 🔄 The "Memory Stealing" Mechanism
The core of the interface is a **Multiplexer (MUX)** logic that arbitrates access to the Frame Buffer (BRAM). The hardware operates in two primary modes:

1.  **VGA Mode (Default):** The VGA controller has full control of the BRAM address bus, scanning from index `0` to `307,199` to maintain a stable 640x480 display.
2.  **Processor Mode (Active):** When the C code initiates a read, the MUX "steals" the BRAM address bus for a single clock cycle. This allows the MicroBlaze to sample a specific pixel's color data at a targeted coordinate.



### 💻 Firmware Logic (`main.c`)
The firmware performs a structured scan of a specific **Region of Interest (ROI)** within the camera frame rather than processing the entire image, which optimizes performance for the soft-core CPU.

#### 1. Handshaking & Synchronization
The software ensures the hardware is ready before beginning a scan:
* **Trigger:** Writes `0x1` to the Control Register to signal the start of a processing task.
* **Polling:** Monitors a status bit to wait for the FPGA hardware to acknowledge readiness.
* **Visual Feedback:** Updates onboard LEDs to indicate the current state (Processing vs. Finished).

#### 2. ROI Pixel Extraction
The code targets a specific window ($170 \times 200$) defined by:
* **X-Coordinates:** 170 to 340
* **Y-Coordinates:** 140 to 340

For every pixel in this box, the software calculates the linear BRAM address ($Address = Y \times 640 + X$), toggles the MUX to grab the data, and prints the 12-bit RGB444 value to the UART console.

### 🛰️ Memory Map (AXI4-Lite)
The communication between the MicroBlaze and the FPGA fabric is handled via the following memory-mapped registers:

| Base Address | Function | Direction | Description |
| :--- | :--- | :--- | :--- |
| `0x4000_0000` | **MUX Trigger** | Out | `1` = Processor takes control; `0` = VGA control. |
| `0x4000_0008` | **Address Bus** | Out | Sends the 19-bit pixel index to the BRAM. |
| `0x4001_0000` | **Data Bus** | In | Reads the 12-bit RGB value from the BRAM. |
| `0x4002_0000` | **LED Control** | Out | Updates physical LEDs for status monitoring. |
| `0x4002_0008` | **Status Bit** | In | Checks if the hardware is ready for processing. |
| `0x4003_0000` | **Reset Trigger**| In | Waits for an external signal (button) to restart. |

### 🚀 Key Performance Features
* **Non-Destructive Monitoring:** High-speed MUXing allows the processor to analyze data with negligible impact on the live VGA feed.
* **Edge Detection Logic:** Uses a hardware-level rising edge detector to ensure that BRAM "Read Enable" pulses precisely once per software request, preventing data synchronization issues.
* **Flexible Sub-Sampling:** Coordinates can be adjusted in the C code to track specific objects (e.g., a Red Line) within the frame.
