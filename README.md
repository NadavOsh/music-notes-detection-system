# music-notes-detection-system
End-to-end embedded system for detecting musical notes includes camera, FPGA, SoC, image processing and microcontroller

A systen in which the user takes a number of photos (by his decision) with an OV7670 camera connected to an FPGA (Xilinx NEXYS A7 in that case) and displaying the camera's image/video with a VGA. Then sends it to a computer using the FPGA's internal microprocessor (Microblaze) with a UART protocol (PuTTY is being used here). The computer runs a Python code that creates a unique computer vision algorithm (which would be discussed later) and GUI (Tkinter) for the user. in the end of all of it it send the notes to an Arduino Uno microcontroller (UART), and the MCU plays them with a passive buzzer with a PWM method. 

Before diving deep it's important to mote that there are two way for doing the note detection algorithm: one (the naive way) is detecting the ellipse with fitellipse function (as part of a bigger algorithm which would be discussed  later), or the second option, using a red line that is being placed by the user while taking the photo. the fisrt way is more simple while the second is more accurate. Because the image comes from an OV7670 camera (low resulotion camera) we've decided to go with the second option. there is still an alterantive CV code that can be found in this project using the first method.

