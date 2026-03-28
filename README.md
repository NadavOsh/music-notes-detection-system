# music-notes-detection-system
End-to-end embedded system for detecting musical notes includes camera, FPGA, SoC, image processing and microcontroller

A systen in which the user takes a number of photos (by his decision) with an OV7670 camera connected to an FPGA (Xilinx NEXYS A7 in that case) and displaying the camera's image/video with a VGA. Then sends it to a computer using the FPGA's internal microprocessor (Microblaze) with a UART protocol (PuTTY is being used here). The computer runs a Python code that creates a unique computer vision algorithm (which would be discussed later) and GUI (Tkinter) for the user. in the end of all of it it send the notes to an Arduino Uno microcontroller (UART), and the MCU plays them with a passive buzzer with a PWM method. 

Before diving deep it's important to mote that there are two way for doing the note detection algorithm: one (the naive way) is detecting the ellipse with fitellipse function (as part of a bigger algorithm which would be discussed  later), or the second option, using a red line that is being placed by the user while taking the photo. the fisrt way is more simple while the second is more accurate. Because the image comes from an OV7670 camera (low resulotion camera) we've decided to go with the second option. there is still an alterantive CV code that can be found in this project using the first method.


# A View on the System
<img width="1265" height="1077" alt="image" src="https://github.com/user-attachments/assets/c57bc8fc-3555-4153-bf42-426d6eafd3f4" />


# Block Diagram of the System
<img width="869" height="532" alt="image" src="https://github.com/user-attachments/assets/565cf6fa-fb7a-4b0c-a5d6-421c62b4ce88" />


# FPGA

# FPGA Block Diagram
<img width="794" height="695" alt="image" src="https://github.com/user-attachments/assets/e719f061-eaba-4f0f-a874-ed34f53bea8b" />

---


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
   * Pixel data (12-bit RGB)
   * Pixel address
   * Write enable signal

This data is streamed into BRAM.

## Frame Buffer (BRAM)

A dual-port BRAM is used as a frame buffer:

* Write Port (Camera domain):
  * Stores incoming pixel data
* Read Port (VGA / MicroBlaze domain):
  * Supplies pixel data for display or processing


### BRAM Read Arbitration (MUX)

A multiplexer controls access to the BRAM read interface:

```verilog
i_rd      = mux ? read_pixel_rising : 1'b1;
i_rd_addr = mux ? read_pixel_address : o_bram_pix_addr;
```

* MUX = 0 (Display Mode)
VGA reads BRAM sequentially for real-time display
* MUX = 1 (Processor Mode)
MicroBlaze controls:
  * Read address
  * Read trigger

This enables software-driven pixel inspection.

### MicroBlaze Integration

The design_1_wrapper module connects the MicroBlaze processor to the FPGA:

* Communicates via memory-mapped GPIO
* Sends:
   * Pixel read requests
   * Addresses
* Receives:
  * Pixel data from BRAM

A rising-edge detector converts software writes into hardware read triggers.


### Image Processing / Overlay Logic

Before writing to BRAM, pixel data is conditionally modified:

* A Region of Interest (ROI) is defined:
  * X: 170–340
  * Y: 140–340
* Inside ROI:
  * Original image is preserved
* Outside ROI:
  * Background is colored (blue)
* A dynamic horizontal red line is generated:
  * Controlled by a signal generator
  * Triggered via button input

This demonstrates real-time image manipulation directly in hardware.

### VGA Output (vga_top)
* Reads pixel data from BRAM
* Generates VGA timing signals
* Outputs RGB values to display

Operates at 640×480 resolution using a 25 MHz pixel clock.

### User Interface
* 7-Segment Display: Displays values based on switches
* Buttons:
  * Reset (debounced)
  * Red line control
* Switches:
  * Mode selection (MUX)
  * Debug / control signals
 
 ### Debugging (ILA)

An Integrated Logic Analyzer (ILA) is used to monitor:

* VGA signals
* Pixel data
* BRAM addresses
* MicroBlaze interactions

### Key Features
* Multi-clock domain design
* Real-time video pipeline
* Dual-port memory architecture
* Hardware–software co-design (FPGA + MicroBlaze)
* Dynamic image overlay (ROI + moving line)
* Flexible BRAM access via MUX arbitration

### Summary

The top module brings together camera input, memory buffering, real-time display, and processor control into a cohesive system. It demonstrates a complete embedded vision pipeline with both hardware acceleration and software interaction.

---


## Camera OV7670


<img width="691" height="681" alt="image" src="https://github.com/user-attachments/assets/682f9013-7d45-4451-b82a-850529c17bc2" />


The system interfaces with the **OV7670 CMOS image sensor** using a custom-built SCCB (Serial Camera Control Bus) controller. This allows the FPGA to configure the camera's internal registers for color space, resolution, and clock scaling.

### 🔌 Pin Mapping & Signal Description

| Pin Name | Direction | Function | FPGA Mapping |
| :--- | :--- | :--- | :--- |
| **SIOC** | Input | SCCB Clock (I2C Compatible) | `o_sioc` (Master Clock) |
| **SIOD** | Inout | SCCB Data (Bidirectional) | `io_siod` (Open-Drain) |
| **VSYNC** | Output | Vertical Sync | Frame Start Detection |
| **HREF** | Output | Horizontal Reference | Row Valid Signal |
| **PCLK** | Output | Pixel Clock | Data Sampling Clock |
| **XCLK** | Input | System Clock | 24MHz Master Input |
| **D[7:0]** | Output | 8-bit Parallel Data | Pixel Byte Stream |
| **RESET** | Input | Hardware Reset | Active Low |
| **PWDN** | Input | Power Down | Tied to GND (Always On) |


###  Camera Initialization Architecture

The initialization sequence is handled by a layered hardware stack to ensure modularity and reliability:

#### cam_rom
* Registers for OV7670 for configuration of RGB 444 
* LUT where each data contains 16 bits: 1 byte for register address in the camera + 1 byte data to send to it 

#### cam_config
control logic- sends data from ROM to a SCCB module.

FSM:
* IDLE
* SEND
* DONE
* TIMER (Give SCCB time to complete . Create delay between commands)

#### sccb_master


The `sccb_master` module utilizes a 12-state FSM to translate parallel data into the serial SCCB protocol. Each state is timed relative to a 400kHz clock, ensuring compatibility with the OV7670's internal timing requirements.

| State | Purpose | Description |
| :--- | :--- | :--- |
| **IDLE** | Wait | Default state; holds SDA and SCL High while waiting for `i_start`. |
| **START_1/2** | Start Condition | Pulls SDA Low while SCL is High to signal a new transaction. |
| **WAIT** | Byte Prep | Latches the next byte (Device Addr, Reg Addr, or Data) to the shift register. |
| **DATA_1-4** | Bit-Banging | The core loop: Shifts bits out on SDA and toggles SCL to sample data. |
| **DATA_DONE** | Byte Complete | Resets bit counters and pulses a `done` tick after 9 bits (8 data + 1 don't care). |
| **RESTART** | Repeat | Generates a repeated start condition if required by the protocol. |
| **END_1/2** | Stop Condition | Pulls SDA High while SCL is High to release the bus. |


Each write transaction consists of 3 bytes
* byte1 = {CAM_ADDR, WR_BIT, X}
* byte2 = {REGISTER_ADDR, X}
* byte3 = {DATA, X}
Where:
* CAM_ADDR = 0x21 (OV7670 address)
* WR_BIT = write enable
* X = don't care bit (SCCB does not use ACK like I²C)

#### cam_init
A module that is responsible for sending the desired settings to the camera component.

This part is made up of three sub-parts:
1. ROM memory whose function is to store the camera's initialization settings.
2. Config model whose function is to retrieve the values from the ROM and send them to the SCCB model -.
3. The SCCB model manages the actual sending to the camera model via the SIO_D data line and the SIO_C clock line

In general, this module works so that it waits for the i_cam_init_start signal and then the module waits for the SCCB module to signal when it is ready.
Only after that the module will start receiving the settings stored in ROM - and sending them to the camera module.

After all the settings have been sent, the o_cam_init_done signal goes to '1', indicating the end of the camera configuration phase.
In our project, o_cam_init_done is connected to LED1 in the development kit and its lighting indicates that the camera setup phase has ended and the camera is ready for use.


### cam_cap

#### Overview

The cam_capture module is responsible for capturing pixel data from the OV7670 camera and converting it into a format suitable for storage in BRAM and display via VGA.

It operates in the camera pixel clock domain (i_pclk) and handles:

* Frame synchronization (vsync)
* Line validity (href)
* Pixel reconstruction (RGB444)
* Memory addressing
* Write control to BRAM


#### Key Responsibilities
* Wait for camera initialization (i_cam_done)
* Synchronize to frame boundaries using vsync
* Convert incoming 2-byte pixel stream → 12-bit RGB
* Generate sequential pixel addresses
* Write valid pixels into BRAM
* Support two modes:
  * Continuous video
  * Single-frame capture

#### Input Pixel Format (OV7670 RGB444)

The camera sends pixel data in two bytes per pixel:
```text
Byte 1: XXXX RRRR
Byte 2: GGGG BBBB
```

The module reconstructs this into:
```text
o_pix_data = {RRRR, GGGG, BBBB}
```
#### Frame Synchronization
#### VSYNC Edge Detection
```verilog
frame_start = falling edge of vsync
frame_done  = rising edge of vsync
```
* frame_start → beginning of a new frame
* frame_done → end of frame

This ensures correct alignment of captured image data.

#### State Machine
Main States

| State    | Description                                        |
|----------|----------------------------------------------------|
| WAIT     | Wait for camera initialization + first valid frame |
| IDLE     | Wait for frame start                               |
| CAPTURE  |  Normal pixel capture (write to BRAM)              |
| CAPTURE2 | Alternate mode (read/processing mode)              |

State Flow
```text
WAIT → IDLE → CAPTURE → IDLE → ...
```
or
```text
WAIT → IDLE → CAPTURE2 → IDLE → ...
```
Depending on mode (video vs picture).

#### Frame Skipping
At startup:
``` verilog
SM_state <= (frame_start && i_cam_done) ? IDLE : WAIT;
```
* The module ignores initial frames
* Allows camera registers to stabilize after configuration

#### Pixel Capture Logic
Two-Byte Assembly
```verilog
if (!r_half_data)
    pixel_data <= i_D[3:0];  // First byte (R)

o_pix_data <= {pixel_data, i_D};  // Second byte (G+B)
```
**Control Signal:**
* r_half_data toggles every clock:
   * 0 → first byte
   * 1 → second byte (pixel complete)

**Address Generation**
```verilog
o_pix_addr <= (r_half_data) ? o_pix_addr + 1 : o_pix_addr;
```
* Address increments only when a full pixel is assembled
* Ensures correct mapping:
  ```text
  pixel 0 → address 0
pixel 1 → address 1
...

**Write Control (BRAM Interface)**
```verilog
o_wr <= (r_half_data) ? 1'b1 : 1'b0;
```
* Write enable is asserted only after full pixel is ready
* Prevents partial/invalid data from being written

**HREF (Line Valid Signal)**
```verilog
if (i_href)
```
* Ensures data is captured only during active line
* Ignores blanking intervals

**Capture Modes**
1. Video Mode (CAPTURE)
* Continuous streaming
* Writes pixels to BRAM
* Used for real-time display

3. Picture Mode (CAPTURE2)
* Triggered by:
  * i_cam_capture
  * i_cam_video
* Behavior:
  * Stops writing (o_wr = 0)
  * Enables read-like behavior (o_rd)
  * Used for processing or freezing a frame
 
#### Internal Signals

| Signal         | Purpose                              |
|----------------|--------------------------------------|
| r_half_data    | Tracks byte phase (1st/2nd byte)     |
| pixel_data     | Stores R component                   |
| o_pix_data     |  Final RGB444 pixel                  |
| o_pix_addr     | BRAM address                         |
| o_wr           | Write enable                         |
| start          | Mode-dependent capture enable        |

### cam_top


Top-Level for the camera.


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
| `0x40020008`   | Ready flag                   |
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



# Python-------
(sorry, youre a little bit early, still has to be written. 27.3.26)


# Arduino Uno-------
(sorry, youre a little bit early, still has to be written. 27.3.26)


